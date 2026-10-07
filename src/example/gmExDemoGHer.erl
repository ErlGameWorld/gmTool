%%%-------------------------------------------------------------------
%%% @doc 示例：各种返回格式 + 丰富参数输入演示（模块名 gmEx* 避免与宿主冲突）。
%%% @end
%%%-------------------------------------------------------------------
-module(gmExDemoGHer).
-export([handle/2]).

-include_lib("eWSrv/include/eWSrv.hrl").

%% ========== 返回格式 ==========

handle(<<"/demo/msg">>, _WsReq) ->
	{msg, <<"这是 {msg, Text} 简写返回"/utf8>>};

handle(<<"/demo/json">>, _WsReq) ->
	{json, #{
		hello => <<"world">>,
		nested => #{a => 1, b => [<<"x">>, <<"y">>]},
		hint => <<"这是 {json, Map} 返回"/utf8>>
	}, <<"JSON 结构化展示"/utf8>>};

handle(<<"/demo/table">>, _WsReq) ->
	Cols = [
		{id, <<"ID">>, #{width => 60}},
		{name, <<"名称"/utf8>>, #{
			link => #{menu => <<"menu_demo_kv">>, params => #{id => id}}
		}},
		{score, <<"分数"/utf8>>},
		{status, <<"状态"/utf8>>}
	],
	Rows = [
		#{id => 1, name => <<"甲"/utf8>>, score => 98, status => <<"active">>},
		#{id => 2, name => <<"乙"/utf8>>, score => 76, status => <<"idle">>},
		#{id => 3, name => <<"丙"/utf8>>, score => 88, status => <<"active">>}
	],
	{table, Cols, Rows, #{
		total => 3,
		pagination => false,
		actions => [
			#{
				key => <<"view">>,
				label => <<"看 KV"/utf8>>,
				menu => <<"menu_demo_kv">>,
				params => #{id => id}
			}
		]
	}};

handle(<<"/demo/kv">>, WsReq) ->
	Id = queryOrBodyId(WsReq),
	{kv, [
		{<<"编号"/utf8>>, Id},
		{<<"名称"/utf8>>, <<"演示角色"/utf8>>},
		{<<"说明"/utf8>>, <<"这是 {kv, Pairs} 键值对展示"/utf8>>},
		{<<"时间"/utf8>>, <<"2026-09-27 12:00:00">>}
	], #{title => <<"KV 详情"/utf8>>}};

handle(<<"/demo/cards">>, _WsReq) ->
	{cards, [
		#{title => <<"在线"/utf8>>, content => <<"1,250">>, footer => <<"玩家"/utf8>>},
		#{title => <<"CPU"/utf8>>, content => <<"45%">>, footer => <<"负载"/utf8>>},
		#{title => <<"内存"/utf8>>, content => <<"68%">>, footer => <<"占用"/utf8>>},
		{<<"磁盘"/utf8>>, <<"23% 已用"/utf8>>}
	], #{title => <<"卡片组 {cards, ...}"/utf8>>}};

handle(<<"/demo/form">>, _WsReq) ->
	{form, [
		#{name => <<"title">>, label => <<"标题"/utf8>>, type => <<"text">>,
			required => true, placeholder => <<"请输入标题"/utf8>>,
			options => #{defaultValue => <<"示例标题"/utf8>>}},
		#{name => <<"priority">>, label => <<"优先级"/utf8>>, type => <<"select">>,
			required => true,
			options => #{
				defaultValue => <<"normal">>,
				selectOptions => [
					#{value => <<"low">>, label => <<"低"/utf8>>},
					#{value => <<"normal">>, label => <<"中"/utf8>>},
					#{value => <<"high">>, label => <<"高"/utf8>>}
				]
			}},
		#{name => <<"note">>, label => <<"备注"/utf8>>, type => <<"textarea">>,
			required => false, options => #{rows => 3}}
	], #{
		title => <<"动态表单 {form, Params, Meta}"/utf8>>,
		submit => #{method => <<"POST">>, path => <<"/demo/form/submit">>}
	}};

handle(<<"/demo/form/submit">>, WsReq) ->
	case bodyMap(WsReq) of
		{ok, Body} ->
			{json, Body, <<"表单已提交（示例仅回显）"/utf8>>};
		{error, Reason} ->
			{error, Reason}
	end;

handle(<<"/demo/redirect">>, _WsReq) ->
	{redirect, #{
		menu => <<"menu_demo_table">>,
		params => #{},
		message => <<"即将跳转到表格演示菜单"/utf8>>
	}};

handle(<<"/demo/error">>, _WsReq) ->
	{error, <<"这是 {error, Reason} 演示"/utf8>>};

handle(<<"/demo/not-found">>, _WsReq) ->
	not_found;

%% 分页 + 表单排序示例（宿主自实现参考；非框架约定）
%% 列头仍只做前端本地排序；此处 sort/order 仅在点「执行」带参时生效
handle(<<"/demo/table-sort">>, WsReq) ->
	Q = eWSrv:mapargs(WsReq),
	Page = max(1, toInt(maps:get(<<"page">>, Q, <<"1">>), 1)),
	PageSize = max(1, min(100, toInt(maps:get(<<"pageSize">>, Q, <<"5">>), 5))),
	Sort = maps:get(<<"sort">>, Q, <<>>),
	Order = case maps:get(<<"order">>, Q, <<"asc">>) of
		<<"desc">> -> desc;
		<<"descend">> -> desc;
		_ -> asc
	end,
	All = demoSortRows(),
	Sorted = sortRows(All, Sort, Order),
	Total = length(Sorted),
	Start = (Page - 1) * PageSize,
	PageRows = lists:sublist(Sorted, Start + 1, PageSize),
	Cols = [
		{id, <<"ID">>, #{width => 70}},
		{name, <<"名称"/utf8>>},
		{score, <<"分数"/utf8>>},
		{level, <<"等级"/utf8>>},
		{status, <<"状态"/utf8>>}
	],
	{table, Cols, PageRows, #{
		total => Total,
		page => Page,
		pageSize => PageSize,
		pagination => true
	}};

%% 列过多截断：Meta.truncatedCols / totalCols 触发前端警告条
handle(<<"/demo/table-trunc">>, _WsReq) ->
	Cols = [
		{id, <<"ID">>},
		{name, <<"名称"/utf8>>},
		{c1, <<"字段1"/utf8>>},
		{c2, <<"字段2"/utf8>>},
		{c3, <<"字段3"/utf8>>}
	],
	Rows = [
		#{id => 1, name => <<"样例 A"/utf8>>, c1 => <<"a1">>, c2 => <<"a2">>, c3 => <<"a3">>},
		#{id => 2, name => <<"样例 B"/utf8>>, c1 => <<"b1">>, c2 => <<"b2">>, c3 => <<"b3">>}
	],
	{table, Cols, Rows, #{
		total => 2,
		pagination => false,
		truncatedCols => 37,
		totalCols => 42
	}};

%% 结构化 JSON：表结构面板（view=schema）
handle(<<"/demo/schema">>, _WsReq) ->
	{json, #{
		view => <<"schema">>,
		table => <<"demo_role">>,
		display => <<"演示角色表"/utf8>>,
		record => <<"#role">>,
		table_comment => <<"示例：字段清单 + Key 槽位"/utf8>>,
		summary => [
			#{label => <<"存储"/utf8>>, value => <<"game/role">>},
			#{label => <<"字段数"/utf8>>, value => 4}
		],
		key_slots => #{
			columns => [
				#{key => <<"slot">>, title => <<"槽位"/utf8>>},
				#{key => <<"field">>, title => <<"字段"/utf8>>},
				#{key => <<"desc">>, title => <<"说明"/utf8>>}
			],
			rows => [
				#{slot => 1, field => <<"uid">>, desc => <<"唯一 ID"/utf8>>},
				#{slot => 2, field => <<"name">>, desc => <<"角色名"/utf8>>}
			]
		},
		fields => #{
			columns => [
				#{key => <<"field">>, title => <<"字段"/utf8>>},
				#{key => <<"type">>, title => <<"类型"/utf8>>},
				#{key => <<"comment">>, title => <<"说明"/utf8>>}
			],
			rows => [
				#{field => <<"uid">>, type => <<"integer">>, comment => <<"唯一 ID"/utf8>>},
				#{field => <<"name">>, type => <<"binary">>, comment => <<"角色名"/utf8>>},
				#{field => <<"level">>, type => <<"integer">>, comment => <<"等级"/utf8>>},
				#{field => <<"exp">>, type => <<"integer">>, comment => <<"经验"/utf8>>}
			]
		}
	}, <<"结构化 schema 演示（view=schema）"/utf8>>};

%% 结构化 JSON：行详情（view=row）
handle(<<"/demo/row">>, WsReq) ->
	Id = queryOrBodyId(WsReq),
	{json, #{
		view => <<"row">>,
		table => <<"demo_role">>,
		key_text => integer_to_binary(toInt(Id, 1001)),
		display => <<"行详情"/utf8>>,
		summary => [
			#{label => <<"Key"/utf8>>, value => Id},
			#{label => <<"表"/utf8>>, value => <<"demo_role">>}
		],
		fields => [
			#{field => <<"uid">>, comment => <<"唯一 ID"/utf8>>, value => Id},
			#{field => <<"name">>, comment => <<"角色名"/utf8>>, value => <<"演示角色"/utf8>>},
			#{field => <<"level">>, comment => <<"等级"/utf8>>, value => 50},
			#{field => <<"bio">>, comment => <<"简介"/utf8>>,
				value => <<"这是一段较长的单元格文本，前端可点击展开查看全文……"/utf8>>}
		],
		raw_term => <<"{role,1001,<<\"演示角色\"/utf8>>,50}."/utf8>>,
		kv_term => <<"{1001, {role,1001,<<\"演示角色\"/utf8>>,50}}."/utf8>>,
		json => #{uid => Id, name => <<"演示角色"/utf8>>, level => 50}
	}, <<"结构化行详情演示（view=row）"/utf8>>};

%% ========== 参数输入回显 ==========

handle(<<"/demo/params">>, WsReq) when WsReq#wsReq.method =:= 'POST' ->
	case bodyMap(WsReq) of
		{ok, Body} ->
			{json, #{
				received => Body,
				typesHint => <<"前端按菜单 params 渲染控件，后端原样收到 JSON 字段"/utf8>>
			}, <<"参数接收成功"/utf8>>};
		{error, Reason} ->
			{error, Reason}
	end;

handle(<<"/demo/params">>, WsReq) ->
	%% GET：用 query
	Q = eWSrv:mapargs(WsReq),
	{json, #{received => Q}, <<"GET 参数回显"/utf8>>};

handle(_Path, _WsReq) ->
	not_found.

%% ========== helpers ==========

demoSortRows() ->
	[
		#{id => 1, name => <<"甲"/utf8>>, score => 98, level => 50, status => <<"active">>},
		#{id => 2, name => <<"乙"/utf8>>, score => 76, level => 30, status => <<"idle">>},
		#{id => 3, name => <<"丙"/utf8>>, score => 88, level => 40, status => <<"active">>},
		#{id => 4, name => <<"丁"/utf8>>, score => 65, level => 20, status => <<"ban">>},
		#{id => 5, name => <<"戊"/utf8>>, score => 91, level => 45, status => <<"active">>},
		#{id => 6, name => <<"己"/utf8>>, score => 70, level => 25, status => <<"idle">>},
		#{id => 7, name => <<"庚"/utf8>>, score => 82, level => 35, status => <<"active">>},
		#{id => 8, name => <<"辛"/utf8>>, score => 55, level => 15, status => <<"idle">>},
		#{id => 9, name => <<"壬"/utf8>>, score => 99, level => 60, status => <<"active">>},
		#{id => 10, name => <<"癸"/utf8>>, score => 60, level => 18, status => <<"ban">>},
		#{id => 11, name => <<"子"/utf8>>, score => 73, level => 28, status => <<"idle">>},
		#{id => 12, name => <<"丑"/utf8>>, score => 85, level => 38, status => <<"active">>}
	].

sortRows(Rows, <<>>, _Order) ->
	Rows;
sortRows(Rows, SortBin, Order) when is_binary(SortBin) ->
	Keys = [string:trim(P) || P <- binary:split(SortBin, <<",">>, [global]), P =/= <<>>],
	case Keys of
		[] ->
			Rows;
		_ ->
			lists:sort(
				fun(A, B) ->
					case compareByKeys(A, B, Keys) of
						eq -> false;
						lt -> Order =/= desc;
						gt -> Order =:= desc
					end
				end,
				Rows
			)
	end.

compareByKeys(_A, _B, []) ->
	eq;
compareByKeys(A, B, [KeyBin | Rest]) ->
	Key = try binary_to_existing_atom(KeyBin, utf8) catch _:_ -> KeyBin end,
	VA = maps:get(Key, A, maps:get(KeyBin, A, undefined)),
	VB = maps:get(Key, B, maps:get(KeyBin, B, undefined)),
	case cmpVal(VA, VB) of
		eq -> compareByKeys(A, B, Rest);
		Other -> Other
	end.

cmpVal(A, B) when A =:= B -> eq;
cmpVal(undefined, _) -> lt;
cmpVal(_, undefined) -> gt;
cmpVal(A, B) when is_number(A), is_number(B), A < B -> lt;
cmpVal(A, B) when is_number(A), is_number(B), A > B -> gt;
cmpVal(A, B) when is_number(A), is_number(B) -> eq;
cmpVal(A, B) ->
	BA = toBin(A),
	BB = toBin(B),
	if
		BA < BB -> lt;
		BA > BB -> gt;
		true -> eq
	end.

toInt(V, _Def) when is_integer(V) -> V;
toInt(V, Def) when is_binary(V) ->
	try binary_to_integer(V) catch _:_ -> Def end;
toInt(V, Def) when is_list(V) ->
	try list_to_integer(V) catch _:_ -> Def end;
toInt(_, Def) -> Def.

toBin(V) when is_binary(V) -> V;
toBin(V) when is_atom(V) -> atom_to_binary(V, utf8);
toBin(V) when is_integer(V) -> integer_to_binary(V);
toBin(V) -> iolist_to_binary(io_lib:format("~p", [V])).

queryOrBodyId(WsReq) ->
	Q = eWSrv:mapargs(WsReq),
	case maps:get(<<"id">>, Q, undefined) of
		undefined ->
			case bodyMap(WsReq) of
				{ok, #{<<"id">> := Id}} -> Id;
				_ -> 0
			end;
		Id -> Id
	end.

bodyMap(WsReq) ->
	Raw = try eWSrv:body(WsReq) of
		Bin when is_binary(Bin) -> Bin;
		List when is_list(List) -> iolist_to_binary(List);
		_ -> <<>>
	catch
		_:_ -> <<>>
	end,
	case Raw of
		<<>> -> {error, <<"Empty request body">>};
		JsonBin ->
			try {ok, json:decode(JsonBin)}
			catch _:_ -> {error, <<"Invalid JSON">>}
			end
	end.
