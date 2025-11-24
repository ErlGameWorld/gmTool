-module(authMiddleware).
-export([authenticate/2]).

%% 认证中间件
authenticate(WsReq, Next) ->
	case eWSrv:get_header(<<"authorization">>, WsReq) of
		undefined ->
			{401, [{<<"Content-Type">>, <<"application/json">>}],
				json:encode(#{<<"error">> => <<"Authentication required">>})};
		Token ->
			case validateToken(Token) of
				{ok, UserInfo} ->
					% 将用户信息添加到请求上下文中
					NewWsReq = eWSrv:set_metadata(#{user => UserInfo}, WsReq),
					Next(NewWsReq);
				{error, Reason} ->
					{401, [{<<"Content-Type">>, <<"application/json">>}],
						json:encode(#{<<"error">> => Reason})}
			end
	end.

validateToken(Token) ->
	% 简化的token验证逻辑
	case binary:split(Token, <<" ">>) of
		[<<"Bearer">>, _ActualToken] ->
			% 这里应该实现实际的token验证逻辑
			{ok, #{userId => 1, username => <<"admin">>, role => <<"admin">>}};
		_ ->
			{error, <<"Invalid token format">>}
	end.