%%%-------------------------------------------------------------------
%%% @doc Her 简写返回值打包为 HTTP 响应。
%%%
%%% 业务 / 宿主只需返回约定数据，不必调用本模块函数。
%%%
%%%   ok | {msg, Bin} | {json, Data} | {json, Data, Msg}
%%%
%%%   {table, Cols, Rows} | {table, Cols, Rows, Meta}
%%%     Cols = [{Key, Title} | {Key, Title, Extra}]
%%%       Extra 可含:
%%%         link => #{menu => MenuId, params => #{ParamName => RowFieldKey}}
%%%         sortable => true|false   %% 默认 true
%%%         width => N
%%%     Rows = [[...]] | [#{...}]
%%%     Meta 可含: total, page, pageSize, pagination, sortable,
%%%                truncatedCols, totalCols, actions
%%%       sortable: 列头是否允许前端本地排序（默认 true；不请求接口）
%%%       truncatedCols/totalCols: 列截断提示（可选）
%%%       actions => [
%%%         #{key, label, menu, params}           %% 跳转菜单
%%%         #{key, label, confirm, api => #{method, path}}  %% 调接口，path 可含 {id}
%%%       }
%%%
%%%   {kv, Pairs} | {kv, Pairs, Meta}
%%%     Pairs = [{Label, Value}, ...] | #{Key => Value}
%%%
%%%   {cards, [Card]} | {cards, [Card], Meta}
%%%     Card = #{title, content} | #{title, description, extra}
%%%
%%%   {form, Params, Meta}
%%%     Params 同菜单 params 列表；Meta.submit = #{method, path}
%%%
%%%   {redirect, #{menu := MenuId} | #{menu, params, message}}
%%%
%%%   {error, R} | {error, Code, R} | not_found
%%% @end
%%%-------------------------------------------------------------------
-module(gmReply).

-export([
	pack/1
	, jsonHeaders/0
]).

-define(JSON_CT, {<<"Content-Type">>, <<"application/json">>}).

-spec pack(term()) -> {pos_integer(), [{binary(), binary()}], binary() | iolist()}.
pack({Status, Headers, _Body} = Raw) when is_integer(Status), is_list(Headers) ->
	Raw;

pack(ok) ->
	reply(200, #{success => true});

pack({msg, Msg}) ->
	reply(200, #{success => true, message => toBin(Msg), data => #{type => <<"msg">>, text => toBin(Msg)}});

pack({json, Data}) ->
	reply(200, #{success => true, data => wrapJson(Data)});

pack({json, Data, Msg}) ->
	reply(200, #{success => true, message => toBin(Msg), data => wrapJson(Data)});

pack({table, Columns, Rows}) ->
	pack({table, Columns, Rows, #{}});

pack({table, Columns, Rows, Meta}) when is_list(Columns), is_list(Rows), is_map(Meta) ->
	NormCols = normalizeColumns(Columns),
	ColKeys = [maps:get(dataIndex, C) || C <- NormCols],
	case normalizeRows(Rows, ColKeys) of
		{error, Reason} ->
			pack({error, 500, Reason});
		{ok, NormRows} ->
			Actions = normalizeActions(maps:get(actions, Meta, maps:get(<<"actions">>, Meta, []))),
			Pag = case maps:get(pagination, Meta, maps:get(<<"pagination">>, Meta, undefined)) of
				undefined -> hasPageMeta(Meta);
				Explicit -> Explicit
			end,
			Table0 = stringifyKeys(#{
				type => <<"table">>,
				columns => NormCols,
				dataSource => NormRows,
				pagination => Pag,
				sortable => maps:get(sortable, Meta, maps:get(<<"sortable">>, Meta, true))
			}),
			Table1 = case Actions of
				[] -> Table0;
				_ -> Table0#{<<"actions">> => Actions}
			end,
			%% Meta 后合并且两侧都 stringify，避免 atom/binary 同名键重复
			Table = maps:merge(Table1, maps:without([<<"pagination">>, <<"sortable">>, <<"actions">>], stringifyKeys(Meta))),
			reply(200, #{success => true, data => Table})
	end;

pack({kv, Pairs}) ->
	pack({kv, Pairs, #{}});

pack({kv, Pairs, Meta}) when is_map(Meta) ->
	case normalizeKv(Pairs) of
		{error, Reason} ->
			pack({error, 500, Reason});
		{ok, Items} ->
			Data = maps:merge(stringifyKeys(#{type => <<"kv">>, items => Items}), stringifyKeys(Meta)),
			reply(200, #{success => true, data => Data})
	end;

pack({cards, Cards}) ->
	pack({cards, Cards, #{}});

pack({cards, Cards, Meta}) when is_list(Cards), is_map(Meta) ->
	Data = maps:merge(
		stringifyKeys(#{type => <<"cards">>, items => [normalizeCard(C) || C <- Cards]}),
		stringifyKeys(Meta)
	),
	reply(200, #{success => true, data => Data});

pack({form, Params}) ->
	pack({form, Params, #{}});

pack({form, Params, Meta}) when is_list(Params), is_map(Meta) ->
	Data = maps:merge(stringifyKeys(#{type => <<"form">>, params => Params}), stringifyKeys(Meta)),
	reply(200, #{success => true, data => Data});

pack({redirect, Spec}) when is_map(Spec) ->
	Data = maps:merge(#{type => <<"redirect">>}, stringifyKeys(Spec)),
	Msg = maps:get(<<"message">>, Data, <<"正在跳转..."/utf8>>),
	reply(200, #{success => true, message => Msg, data => Data});

pack(not_found) ->
	reply(404, #{success => false, error => <<"Not Found">>});

pack({error, Reason}) ->
	reply(400, #{success => false, error => toBin(Reason)});

pack({error, Code, Reason}) when is_integer(Code) ->
	reply(Code, #{success => false, error => toBin(Reason)});

pack(Data) when is_map(Data); is_list(Data) ->
	reply(200, #{success => true, data => wrapJson(Data)});

pack(Other) ->
	reply(500, #{success => false, error => <<"bad_reply">>, detail => list_to_binary(io_lib:format("~0p", [Other]))}).

jsonHeaders() ->
	[?JSON_CT].

%% ========== internal ==========
reply(Status, Map) ->
	{Status, [?JSON_CT], json:encode(Map)}.

wrapJson(#{<<"type">> := _} = Data) -> Data;
wrapJson(#{type := _} = Data) -> stringifyKeys(Data);
wrapJson(Data) ->
	#{type => <<"json">>, value => Data}.

normalizeColumns(Cols) ->
	[normalizeCol(C) || C <- Cols].

normalizeCol({Key, Title}) ->
	K = toBin(Key),
	#{title => toBin(Title), dataIndex => K, key => K, sortable => true};
normalizeCol({Key, Title, Extra}) when is_map(Extra) ->
	K = toBin(Key),
	Base = #{title => toBin(Title), dataIndex => K, key => K, sortable => true},
	maps:merge(Base, normalizeColExtra(Extra));
normalizeCol(#{title := _, dataIndex := _} = C) ->
	C1 = case maps:is_key(key, C) of
		true -> C;
		false -> C#{key => maps:get(dataIndex, C)}
	end,
	case maps:is_key(sortable, C1) of
		true -> C1;
		false -> C1#{sortable => true}
	end.

normalizeColExtra(Extra) ->
	E0 = stringifyKeys(Extra),
	case maps:get(<<"link">>, E0, undefined) of
		undefined -> E0;
		Link when is_map(Link) -> E0#{<<"link">> => stringifyKeys(Link)};
		_ -> E0
	end.

normalizeActions(Actions) when is_list(Actions) ->
	[stringifyKeys(A) || A <- Actions, is_map(A)];
normalizeActions(_) ->
	[].

normalizeKv(Pairs) when is_list(Pairs) ->
	case [X || X <- Pairs, not is_kv_pair(X)] of
		[] ->
			{ok, [#{label => toBin(L), value => V} || {L, V} <- Pairs]};
		_Bad ->
			{error, <<"kv pairs must be {Label, Value} tuples"/utf8>>}
	end;
normalizeKv(Map) when is_map(Map) ->
	{ok, maps:fold(
		fun(K, V, Acc) ->
			[#{label => toBin(K), value => V} | Acc]
		end,
		[],
		Map
	)};
normalizeKv(_) ->
	{error, <<"kv data must be list or map"/utf8>>}.

is_kv_pair({_, _}) -> true;
is_kv_pair(_) -> false.

normalizeCard(C) when is_map(C) ->
	stringifyKeys(C);
normalizeCard({Title, Content}) ->
	#{title => toBin(Title), content => Content};
normalizeCard(Other) ->
	#{content => Other}.

normalizeRows(Rows, ColKeys) when is_list(Rows) ->
	try
		{ok, finishRows([normalizeOneRow(R, ColKeys) || R <- Rows])}
	catch
		throw:{bad_row, Reason} ->
			{error, Reason}
	end;
normalizeRows(_, _) ->
	{error, <<"table rows must be a list"/utf8>>}.

normalizeOneRow(R, _ColKeys) when is_map(R) ->
	stringifyKeys(R);
normalizeOneRow(R, ColKeys) when is_list(R) ->
	listToRowMap(R, ColKeys);
normalizeOneRow(_R, _ColKeys) ->
	throw({bad_row, <<"table row must be map or list"/utf8>>}).

listToRowMap(Vals, Keys) ->
	maps:from_list([{K, V} || {K, V} <- zipPad(Keys, Vals)]).

zipPad([], _) -> [];
zipPad([K | Ks], [V | Vs]) -> [{K, V} | zipPad(Ks, Vs)];
zipPad([K | Ks], []) -> [{K, null} | zipPad(Ks, [])].

finishRows(Rows) ->
	{Mapped, _} = lists:mapfoldl(
		fun(R1, Idx) ->
			R2 = case maps:is_key(<<"key">>, R1) of
				true -> R1;
				false ->
					Key = case maps:get(<<"id">>, R1, undefined) of
						undefined -> integer_to_binary(Idx);
						Id -> toBin(Id)
					end,
					R1#{<<"key">> => Key}
			end,
			{R2, Idx + 1}
		end,
		1,
		Rows
	),
	Mapped.

hasPageMeta(Meta) ->
	(maps:is_key(page, Meta) orelse maps:is_key(<<"page">>, Meta))
		andalso (maps:is_key(pageSize, Meta) orelse maps:is_key(<<"pageSize">>, Meta)).

stringifyKeys(Map) when is_map(Map) ->
	maps:fold(fun(K, V, Acc) -> Acc#{toBin(K) => maybeStringifyNested(V)} end, #{}, Map);
stringifyKeys(Other) ->
	Other.

maybeStringifyNested(V) when is_map(V) -> stringifyKeys(V);
maybeStringifyNested(V) when is_list(V) ->
	case V of
		[H | _] when is_map(H) -> [stringifyKeys(X) || X <- V];
		_ -> V
	end;
maybeStringifyNested(V) -> V.

toBin(B) when is_binary(B) -> B;
toBin(A) when is_atom(A) -> atom_to_binary(A, utf8);
toBin(I) when is_integer(I) -> integer_to_binary(I);
toBin(L) when is_list(L) -> unicode:characters_to_binary(L);
toBin(Other) -> list_to_binary(io_lib:format("~0p", [Other])).
