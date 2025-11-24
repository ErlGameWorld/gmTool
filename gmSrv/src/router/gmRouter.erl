-module(gmRouter).
-behaviour(wsHer).

-export([handle/3]).

-include_lib("eWSrv/include/eWSrv.hrl").
-include("common.hrl").

%% 约定优于配置的路由：按第一个路径段自动映射到模块 <segment>GHer

handle(Method, Path, WsReq) ->
	io:format("IMY********[gm_router] receive Method:~p Path:~p WsReq:~0p ~n", [Method, Path, WsReq]),

	% 处理CORS预检请求
	case Method of
		'OPTIONS' ->
			CorsHeaders = [
				{<<"Access-Control-Allow-Origin">>, <<"*">>},
				{<<"Access-Control-Allow-Methods">>, <<"GET, POST, PUT, DELETE, OPTIONS">>},
				{<<"Access-Control-Allow-Headers">>, <<"Content-Type, Authorization, X-API-Key, x-client-version">>},
				{<<"Access-Control-Allow-Credentials">>, <<"true">>}
			],
			{200, CorsHeaders, <<>>};
		_ ->
			<<_:8, LPath/binary>> = Path,
			[HerStr | _] = binary:split(LPath, <<"/">>),
			Ret = try
				case ?gmHerTable:getV(HerStr) of
					undefined ->
						comGHer:handle(Path, WsReq);
					Mod ->
						Mod:handle(Path, WsReq)
				end
			catch
				Class:Reason:Stacktrace ->
					ErrorInfo = parseStack(Class, Reason, Stacktrace),
					io:format("IMY********[gm_router222] ERROR: ~p:~p~nStacktrace : ~p~n", [Class, Reason, Stacktrace]),
					{500, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{success => false, error => ErrorInfo})}
			end,
			% 为所有响应添加CORS头
			{StatusCode, Headers, Body} = Ret,
			CorsHeaders = [
				{<<"Access-Control-Allow-Origin">>, <<"*">>},
				{<<"Access-Control-Allow-Methods">>, <<"GET, POST, PUT, DELETE, OPTIONS">>},
				{<<"Access-Control-Allow-Headers">>, <<"Content-Type, Authorization, X-API-Key, x-client-version">>},
				{<<"Access-Control-Allow-Credentials">>, <<"true">>}
			],
			NewHeaders = Headers ++ CorsHeaders,
			io:format("IMY********[gm_router] return ~p :~0p ~n", [StatusCode, NewHeaders]),
			{StatusCode, NewHeaders, Body}
	end.

%%  堆栈回溯（stacktrace）是{Module，Function，Arity，Location}元组的列表。
%%  Arity: 根据异常，Arity字段可以是该函数调用的参数列表，而不是arity整数。
%%  Location: 是一个二元组的列表（可能为空），可以指示该函数在源代码中的位置。
%%  第一个元素是描述第二个元素中信息类型的原子。可能发生以下情况：
%% [{file, 一个字符串, 代表函数源文件的文件名}, {line, 元组的第二个元素是发生异常或调用函数的源文件中的行号, 整数> 0} :
parseStack(Class, Reason, Stacktrace) ->
	list_to_binary(io_lib:format(<<"~n  Class:~s~n  Reason:~s~n  Stacktrace:~n~ts">>, [Class, Reason, parseStack(Stacktrace)])).

parseStack(Stacktrace) ->
	<<begin
		case Location of
			[] ->
				<<"     ", (atom_to_binary(Mod, utf8))/binary, ":", (atom_to_binary(Func, utf8))/binary, "(", (list_to_binary(io_lib:format("~0p", [Arity])))/binary, ")\n">>;
			[{file, File}, {line, Line}] ->
				<<"     ", (atom_to_binary(Mod, utf8))/binary, ":", (atom_to_binary(Func, utf8))/binary, "/", (integer_to_binary(Arity))/binary, "(", (unicode:characters_to_binary(File))/binary, ":", (integer_to_binary(Line))/binary, ")\n">>;
			_ ->
				<<"     ", (atom_to_binary(Mod, utf8))/binary, ":", (atom_to_binary(Func, utf8))/binary, "(", (list_to_binary(io_lib:format("~0p", [Arity])))/binary, ")", (list_to_binary(io_lib:format("~0p", [Location])))/binary, "\n">>
		end
	end || {Mod, Func, Arity, Location} <- Stacktrace
>>.