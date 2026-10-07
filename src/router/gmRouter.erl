-module(gmRouter).
-behaviour(wsHer).

-export([
	handle/3,
	handleCall/3,
	handleCast/2,
	handleInfo/2
]).

-include_lib("eWSrv/include/eWSrv.hrl").
-include("common.hrl").

%%% 约定优于配置：未在 handlers/0 登记时，按路径首段推导 <Seg>GHer。
%%% 本仓库示例一律用 gmEx* 并通过 handlers/0 显式登记，避免与宿主撞名。

-define(ALLOWED_METHODS, ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']).

handle(Method, Path, WsReq) ->
	% io:format("IMY********[gm_router] receive Method:~p Path:~p WsReq:~p ~n", [Method, Path, WsReq]),
	case Method of
		'OPTIONS' ->
			{200, corsHeaders(), <<>>};
		_ ->
			{StatusCode, Headers, Body} = try
				Ret0 = case gmAuthMiddleware:isPublicPath(Path, WsReq) of
					true ->
						<<_:8, LPath/binary>> = Path,
						[HerStr | _] = binary:split(LPath, <<"/">>),
						case ?gmHerTable:getV(HerStr) of
							undefined ->
								gmComGHer:handle(Path, WsReq);
							Mod ->
								Mod:handle(Path, WsReq)
						end;
					false ->
						{error, 401, <<"Authentication required">>}
				end,
				gmReply:pack(Ret0)
			catch
				Class:Reason:Stacktrace ->
					ErrorInfo = parseStack(Class, Reason, Stacktrace),
					{500, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{success => false, error => ErrorInfo})}
			end,
			{StatusCode, Headers ++ corsHeaders(), Body}
	end.

corsHeaders() ->
	[
		{<<"Access-Control-Allow-Origin">>, <<"*">>},
		{<<"Access-Control-Allow-Methods">>, <<"GET, POST, PUT, DELETE, OPTIONS">>},
		{<<"Access-Control-Allow-Headers">>, <<"Content-Type, Authorization, X-API-Key, x-client-version, X-Password-Encrypted">>}
	].

%% wsHer 必需回调（HTTP 业务不走这些；提供忽略实现以消除 behaviour 告警）
handleCall(_Request, _State, _From) -> kpS.
handleCast(_Request, _State) -> kpS.
handleInfo(_Info, _State) -> kpS.

parseStack(Class, Reason, Stacktrace) ->
	unicode:characters_to_binary(
		io_lib:format("~n  Class:~0p~n  Reason:~0p~n  Stacktrace:~n~ts",
			[Class, Reason, parseStack(Stacktrace)])).

parseStack(Stacktrace) ->
	<<begin
		ArityBin = arityToBin(Arity),
		case Location of
			[] ->
				<<"     ", (atom_to_binary(Mod, utf8))/binary, ":", (atom_to_binary(Func, utf8))/binary, "(", ArityBin/binary, ")\n">>;
			[{file, File}, {line, Line} | _] ->
				<<"     ", (atom_to_binary(Mod, utf8))/binary, ":", (atom_to_binary(Func, utf8))/binary, "/", ArityBin/binary, "(", (unicode:characters_to_binary(File))/binary, ":", (integer_to_binary(Line))/binary, ")\n">>;
			_ ->
				<<"     ", (atom_to_binary(Mod, utf8))/binary, ":", (atom_to_binary(Func, utf8))/binary, "(", ArityBin/binary, ")", (unicode:characters_to_binary(io_lib:format("~0p", [Location])))/binary, "\n">>
		end
	end || {Mod, Func, Arity, Location} <- Stacktrace
>>.

arityToBin(N) when is_integer(N) -> integer_to_binary(N);
arityToBin(Args) when is_list(Args) -> integer_to_binary(length(Args));
arityToBin(Other) -> unicode:characters_to_binary(io_lib:format("~0p", [Other])).
