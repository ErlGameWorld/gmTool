%%%-------------------------------------------------------------------
%%% @doc 框架公共 HTTP：SPA 入口 + 侧栏菜单 + 工具面板。
%%% @end
%%%-------------------------------------------------------------------
-module(gmComGHer).
-include_lib("eWSrv/include/wsCom.hrl").
-include("common.hrl").
-export([handle/2]).

%% ========== SPA ==========
handle(<<"/">>, _WsReq) ->
	indexPage();
handle(<<"/index.html">>, _WsReq) ->
	indexPage();
handle(<<"/login">>, _WsReq) ->
	indexPage();
handle(<<"/favicon.ico">>, _WsReq) ->
	{204, [], <<>>};
handle(<<"/manifest.json">>, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"not found">>})};
handle(<<"/assets/", _/binary>>, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"not found">>})};
handle(<<"/static/", _/binary>>, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"not found">>})};

%% ========== 侧栏菜单 ==========
handle(<<"/menus">>, _WsReq) ->
	{200, gmReply:jsonHeaders(), gmMenus:menusJson()};

handle(<<"/menus/reload">>, WsReq) when WsReq#wsReq.method =:= 'POST' ->
	try
		gmMenus:reloadMenus(),
		Mod = gmMenus:menuModule(),
		Msg = iolist_to_binary([
			<<"菜单已刷新 (menuModule="/utf8>>,
			atom_to_binary(Mod, utf8),
			<<")">>
		]),
		{msg, Msg}
	catch
		Class:Reason ->
			{error, unicode:characters_to_binary(
				io_lib:format("刷新失败: ~p:~p", [Class, Reason]))}
	end;
handle(<<"/menus/reload">>, _WsReq) ->
	{error, 405, <<"Method Not Allowed">>};

%% ========== 工具面板 ==========
handle(<<"/icons">>, _WsReq) ->
	{msg, <<"请使用侧栏「查看图标」打开预览"/utf8>>};

handle(<<"/utils/param-types">>, WsReq) when WsReq#wsReq.method =:= 'POST' ->
	case bodyMap(WsReq) of
		{ok, Params} ->
			{json, #{
				receivedParams => Params,
				paramCount => maps:size(Params),
				validation => #{
					basic_text => validateText(maps:get(<<"basic_text">>, Params, undefined)),
					limited_number => validateLimited(maps:get(<<"limited_number">>, Params, undefined)),
					unlimited_number => validateNumber(maps:get(<<"unlimited_number">>, Params, undefined)),
					email_demo => validateEmail(maps:get(<<"email_demo">>, Params, undefined)),
					url_demo => validateUrl(maps:get(<<"url_demo">>, Params, undefined)),
					number_range_demo => validateNumRange(maps:get(<<"number_range_demo">>, Params, undefined))
				}
			}, <<"参数类型测试成功"/utf8>>};
		{error, Reason} ->
			{error, Reason}
	end;
handle(<<"/utils/param-types">>, _WsReq) ->
	{error, 405, <<"Method Not Allowed">>};

handle(Path, _WsReq) ->
	SafePath = safePathForError(Path),
	{404, [{<<"Content-Type">>, <<"application/json">>}],
		json:encode(#{<<"error">> => <<"undefined path:", SafePath/binary>>})}.

%% ========== internal ==========
indexPage() ->
	Headers = [
		{<<"Content-Type">>, gmWebShow:contentType()},
		{<<"Cache-Control">>, <<"no-store, no-cache, must-revalidate">>},
		{<<"Pragma">>, <<"no-cache">>}
	],
	{200, Headers, gmWebShow:indexHtml()}.

safePathForError(Path) when is_binary(Path) ->
	case unicode:characters_to_binary(Path, utf8, utf8) of
		Bin when is_binary(Bin) ->
			case byte_size(Bin) > 200 of
				true -> <<(binary:part(Bin, 0, 200))/binary, "...">>;
				false -> Bin
			end;
		_ ->
			<<"<invalid utf-8 path>">>
	end;
safePathForError(_) ->
	<<"<invalid path>">>.

bodyMap(WsReq) ->
	Raw = try eWSrv:body(WsReq) of
		Bin when is_binary(Bin) -> Bin;
		List when is_list(List) -> iolist_to_binary(List);
		_ -> <<>>
	catch
		_:_ -> <<>>
	end,
	case Raw of
		<<>> -> {error, <<"Invalid request body">>};
		JsonBin ->
			try
				case json:decode(JsonBin) of
					Map when is_map(Map) -> {ok, Map};
					_ -> {error, <<"Invalid request format">>}
				end
			catch
				_:_ -> {error, <<"Invalid request format">>}
			end
	end.

validateText(undefined) -> <<"未提供"/utf8>>;
validateText(V) when is_binary(V), byte_size(V) > 0 -> <<"通过"/utf8>>;
validateText(_) -> <<"格式错误"/utf8>>.

validateLimited(undefined) -> <<"未提供"/utf8>>;
validateLimited(V) when is_number(V), V >= 1, V =< 100 -> <<"通过"/utf8>>;
validateLimited(_) -> <<"格式错误"/utf8>>.

validateNumber(undefined) -> <<"未提供"/utf8>>;
validateNumber(V) when is_number(V) -> <<"通过"/utf8>>;
validateNumber(_) -> <<"格式错误"/utf8>>.

validateEmail(undefined) -> <<"未提供"/utf8>>;
validateEmail(V) when is_binary(V) ->
	case binary:match(V, <<"@">>) of
		nomatch -> <<"格式错误"/utf8>>;
		_ -> <<"通过"/utf8>>
	end;
validateEmail(_) -> <<"格式错误"/utf8>>.

validateUrl(undefined) -> <<"未提供"/utf8>>;
validateUrl(<<"http://", _/binary>>) -> <<"通过"/utf8>>;
validateUrl(<<"https://", _/binary>>) -> <<"通过"/utf8>>;
validateUrl(_) -> <<"格式错误"/utf8>>.

validateNumRange(undefined) -> <<"未提供"/utf8>>;
validateNumRange(#{<<"min">> := Min, <<"max">> := Max})
  when is_number(Min), is_number(Max), Min =< Max ->
	<<"通过"/utf8>>;
validateNumRange(#{min := Min, max := Max})
  when is_number(Min), is_number(Max), Min =< Max ->
	<<"通过"/utf8>>;
validateNumRange(_) -> <<"格式错误"/utf8>>.
