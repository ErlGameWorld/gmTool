-module(gmAuthGHer).

-export([handle/2, verifyToken/1, getAuthHeader/1]).

-include_lib("eWSrv/include/wsCom.hrl").

%% 用户认证信息（模拟数据库）
-define(USERS, [
	#{username => <<"admin">>, password => <<"admin123">>, role => <<"admin">>, permissions => all},
	#{username => <<"gm">>, password => <<"gm123">>, role => <<"gm">>, permissions => [players, items, commands, logs]},
	#{username => <<"operator">>, password => <<"op123">>, role => <<"operator">>, permissions => [players, logs]}
]).

handle(<<"/auth/login">>, WsReq) ->
	#wsReq{body = Body} = WsReq,
	case Body of
		<<>> ->
			{400, [{<<"Content-Type">>, <<"application/json">>}],
				json:encode(#{<<"error">> => <<"Empty request body">>})};
		_ ->
			try
				Decoded = json:decode(Body),
				case Decoded of
					#{<<"username">> := Username} ->
						case extractPassword(Decoded, is_encrypted_request(WsReq)) of
							{error, ErrMsg} ->
								{400, [{<<"Content-Type">>, <<"application/json">>}],
									json:encode(#{<<"error">> => ErrMsg})};
							{ok, FinalPassword} ->
								case authenticateUser(Username, FinalPassword) of
									{ok, UserInfo} ->
										Token = generateToken(UserInfo),
										Response = #{<<"success">> => true, <<"token">> => Token, <<"user">> => UserInfo},
										{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
									{error, ErrorMsg} ->
										{401, [{<<"Content-Type">>, <<"application/json">>}],
											json:encode(#{<<"error">> => ErrorMsg})}
								end
						end;
					_ ->
						{400, [{<<"Content-Type">>, <<"application/json">>}],
							json:encode(#{<<"error">> => <<"Missing username or password">>})}
				end
			catch
				error:{invalid_byte, _Byte} ->
					{400, [{<<"Content-Type">>, <<"application/json">>}],
						json:encode(#{<<"error">> => <<"Invalid JSON format">>})};
				_:_ ->
					{400, [{<<"Content-Type">>, <<"application/json">>}],
						json:encode(#{<<"error">> => <<"Invalid JSON format">>})}
			end
	end;

handle(<<"/auth/verify">>, WsReq) ->
	% 验证token
	AuthHeader = getAuthHeader(WsReq#wsReq.headers),
	try
		case AuthHeader of
			undefined ->
				{401, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Missing token">>})};
			<<"Bearer ", Token/binary>> ->
				case verifyToken(Token) of
					{ok, UserInfo} ->
						Response = #{<<"valid">> => true, <<"user">> => UserInfo},
						{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
					{error, ErrorMsg} ->
						{401, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => ErrorMsg})}
				end;
			_ ->
				{401, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid token format">>})}
		end
	catch
		_:_ ->
			{500, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Internal server error">>})}
	end;

handle(<<"/auth/refresh">>, WsReq) ->
	% Token刷新接口
	AuthHeader = getAuthHeader(WsReq#wsReq.headers),
	try
		case AuthHeader of
			undefined ->
				{401, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Missing token">>})};
			<<"Bearer ", Token/binary>> ->
				% 验证现有token
				case verifyToken(Token) of
					{ok, UserInfo} ->
						% 生成新的token
						NewToken = generateToken(UserInfo),
						Response = #{<<"success">> => true, <<"token">> => NewToken},
						{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
					{error, ErrorMsg} ->
						{401, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => ErrorMsg})}
				end;
			_ ->
				{401, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid token format">>})}
		end
	catch
		_:_ ->
			{500, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Internal server error">>})}
	end;

handle(<<"/auth/logout">>, _WsReq) ->
	% 用户登出
	Response = #{<<"success">> => true, <<"message">> => <<"登出成功"/utf8>>},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};

handle(_Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.

%% 辅助函数

%% 从登录 body 提取口令（明文或加密）；缺字段返回 400 友好错误
extractPassword(Decoded, true) ->
	case Decoded of
		#{<<"encryptedPassword">> := EP, <<"salt">> := Salt}
		  when is_binary(EP), is_binary(Salt), EP =/= <<>>, Salt =/= <<>> ->
			{ok, {encrypted, EP, Salt}};
		_ ->
			%% 声明加密但缺字段时，允许回退明文 password
			extractPassword(Decoded, false)
	end;
extractPassword(Decoded, false) ->
	case maps:get(<<"password">>, Decoded, undefined) of
		undefined -> {error, <<"Missing password">>};
		<<>> -> {error, <<"Missing password">>};
		Password -> {ok, Password}
	end.

%% 用户认证
authenticateUser(Username, Password) ->
	case lists:search(fun(User) ->
		maps:get(username, User) =:= Username
	end, ?USERS) of
		{value, User} ->
			StoredPassword = maps:get(password, User),
			
			% 检查密码类型并验证
			PasswordValid = case Password of
				{encrypted, EncryptedPassword, Salt} ->
					% 加密密码验证
					verify_password(StoredPassword, Salt, EncryptedPassword);
				_ ->
					% 明文密码验证
					Password =:= StoredPassword
			end,
			
			case PasswordValid of
				true ->
					UserInfo = #{
						<<"username">> => maps:get(username, User),
						<<"role">> => maps:get(role, User),
						<<"permissions">> => maps:get(permissions, User)
					},
					{ok, UserInfo};
				false ->
					{error, <<"用户名或密码错误"/utf8>>}
			end;
		false ->
			{error, <<"用户名或密码错误"/utf8>>}
	end.

%% 生成Token（Salt/Signature 均 base64，避免 ':' 拆分歧义）
generateToken(UserInfo) ->
	Timestamp = integer_to_binary(erlang:system_time(second)),
	ExpiryTime = integer_to_binary(erlang:system_time(second) + 24 * 60 * 60),
	Username = maps:get(<<"username">>, UserInfo),
	SecretKey = <<"gm_tool_secret_key_2024">>,
	Salt = crypto:strong_rand_bytes(16),
	SaltB64 = base64:encode(Salt),
	DataToSign = <<Username/binary, ":", Timestamp/binary, ":", ExpiryTime/binary>>,
	Signature = crypto:mac(hmac, sha256, SecretKey, <<DataToSign/binary, Salt/binary>>),
	SignatureBase64 = base64:encode(Signature),
	TokenData = <<"token:", Username/binary, ":", Timestamp/binary, ":", ExpiryTime/binary, ":", SaltB64/binary, ":", SignatureBase64/binary>>,
	base64:encode(TokenData).

%% 兼容 atom / binary Authorization 头
getAuthHeader(Headers) when is_list(Headers) ->
	Keys = [
		<<"authorization">>, <<"Authorization">>,
		'Authorization', 'authorization', 'AUTHORIZATION'
	],
	getAuthHeader(Keys, Headers);
getAuthHeader(_) ->
	undefined.

getAuthHeader([], _Headers) ->
	undefined;
getAuthHeader([K | Rest], Headers) ->
	case proplists:get_value(K, Headers) of
		undefined -> getAuthHeader(Rest, Headers);
		Value -> Value
	end.

verifyToken(Token) ->
	try
		Decoded = base64:decode(Token),
		Parts = binary:split(Decoded, <<":">>, [global]),
		SecretKey = <<"gm_tool_secret_key_2024">>,
		case Parts of
			[<<"token">>, Username, Timestamp, ExpiryTimeBin, SaltB64, ReceivedSignature] ->
				Salt = try base64:decode(SaltB64) catch _:_ -> SaltB64 end,
				DataToSign = <<Username/binary, ":", Timestamp/binary, ":", ExpiryTimeBin/binary>>,
				ExpectedSignature = crypto:mac(hmac, sha256, SecretKey, <<DataToSign/binary, Salt/binary>>),
				ExpectedSignatureBase64 = base64:encode(ExpectedSignature),
				if
					ReceivedSignature =/= ExpectedSignatureBase64 ->
						{error, <<"Token签名无效"/utf8>>};
					true ->
						CurrentTime = erlang:system_time(second),
						ExpiryTime = binary_to_integer(ExpiryTimeBin),
						if
							CurrentTime > ExpiryTime ->
								{error, <<"Token已过期"/utf8>>};
							true ->
								case lists:search(fun(User) ->
									maps:get(username, User) =:= Username
								end, ?USERS) of
									{value, User} ->
										{ok, #{
											<<"username">> => maps:get(username, User),
											<<"role">> => maps:get(role, User),
											<<"permissions">> => maps:get(permissions, User)
										}};
									false ->
										{error, <<"用户不存在"/utf8>>}
								end
						end
				end;
			_ ->
				{error, <<"无效的Token格式"/utf8>>}
		end
	catch
		_Error:_Reason ->
			{error, <<"无效的Token"/utf8>>}
	end.

%% 检查请求头中是否包含加密标记
is_encrypted_request(WsReq) ->
	#wsReq{headers = Headers} = WsReq,
	case proplists:get_value(<<"X-Password-Encrypted">>, Headers) of
		<<"true">> -> true;
		_ -> false
	end.

%% 使用SHA-256哈希密码
hash_password(Password, Salt) ->
	% 将密码和盐值组合
	Combined = <<Password/binary, Salt/binary>>,
	% 计算SHA-256哈希
	Hash = crypto:hash(sha256, Combined),
	% 返回base64编码的哈希值
	base64:encode(Hash).

%% 验证密码
verify_password(Password, Salt, HashedPassword) ->
	% 计算输入密码的哈希值
	CalculatedHash = hash_password(Password, Salt),
	% 比较哈希值
	CalculatedHash =:= HashedPassword.