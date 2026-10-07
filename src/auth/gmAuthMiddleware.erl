-module(gmAuthMiddleware).
-export([isPublicPath/2]).

-include_lib("eWSrv/include/wsCom.hrl").

%% 公开路径放行；否则校验 Bearer Token。通过 → true，否则 → false。
isPublicPath(<<"/">>, _) -> true;
isPublicPath(<<"/index.html">>, _) -> true;
isPublicPath(<<"/login">>, _) -> true;
isPublicPath(<<"/auth/login">>, _) -> true;
isPublicPath(<<"/auth/logout">>, _) -> true;
isPublicPath(<<"/favicon.ico">>, _) -> true;
isPublicPath(<<"/manifest.json">>, _) -> true;
isPublicPath(<<"/assets/", _/binary>>, _) -> true;
isPublicPath(<<"/static/", _/binary>>, _) -> true;
isPublicPath(_Path, WsReq) ->
	case gmAuthGHer:getAuthHeader(eWSrv:headers(WsReq)) of
		<<"Bearer ", Token/binary>> when byte_size(Token) > 0 ->
			case gmAuthGHer:verifyToken(Token) of
				{ok, _} -> true;
				{error, _} -> false
			end;
		_ ->
			false
	end.
