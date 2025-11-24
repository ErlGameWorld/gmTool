-module(authGHer).

-export([handle/2]).

-include_lib("eWSrv/include/wsCom.hrl").

%% 用户认证信息（模拟数据库）
-define(USERS, [
	#{username => <<"admin">>, password => <<"admin123">>, role => <<"admin">>, permissions => all},
	#{username => <<"gm">>, password => <<"gm123">>, role => <<"gm">>, permissions => [players, items, commands, logs]},
	#{username => <<"operator">>, password => <<"op123">>, role => <<"operator">>, permissions => [players, logs]}
]).

handle(<<"/auth/login">>, WsReq) ->
	% 用户登录
	#wsReq{body = Body} = WsReq,
	io:format("Received login request with body: ~p~n", [Body]),
	% 检查请求体是否为空
	case Body of
		<<>> ->
			io:format("Empty request body received~n"),
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Empty request body">>})};
		_ ->
			% 尝试解码JSON
			try
				Decoded = json:decode(Body),
				io:format("Decoded JSON: ~p~n", [Decoded]),
				case Decoded of
					#{<<"username">> := Username} ->
						% 检查是否是加密请求
						IsEncrypted = is_encrypted_request(WsReq),
						io:format("Login YYYYYYYYYY request is encrypted: ~p~n", [IsEncrypted]),
						
						% 根据是否加密选择处理方式
						FinalPassword = if
							IsEncrypted ->
								% 如果是加密请求，需要检查是否有加密数据
								case Decoded of
									#{<<"encryptedPassword">> := EncryptedPassword, <<"salt">> := Salt} ->
										% 使用加密密码验证
										{encrypted, EncryptedPassword, Salt};
									_ ->
										% 缺少加密数据，使用原始密码
										#{ <<"password">> := Password} = Decoded,
										Password
								end;
							true ->
								#{ <<"password">> := Password} = Decoded,
								% 不加密，直接使用原始密码
								Password
						end,
						
						% 使用authenticateUser函数验证用户名和密码
						case authenticateUser(Username, FinalPassword) of
							{ok, UserInfo} ->
								Token = generateToken(UserInfo),
								Response = #{<<"success">> => true, <<"token">> => Token, <<"user">> => UserInfo},
								{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
							{error, ErrorMsg} ->
								{401, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => ErrorMsg})}
						end;
					_ ->
						io:format("Missing username or password in JSON~n"),
						{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Missing username or password">>})}
				end
			catch
				throw:{json_decode_error, Reason} ->
					io:format("JSON decode error: ~p~n", [Reason]),
					{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid JSON format">>})};
				error:{invalid_byte, Byte} ->
					io:format("JSON decode error: invalid byte ~p in body ~p~n", [Byte, Body]),
					{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid JSON format">>})};
				Exception:Reason:StackTrace ->
					io:format("Unexpected error during JSON decoding: ~p:~p~nStack trace: ~p~n", [Exception, Reason, StackTrace]),
					{500, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Internal server error">>})}
			end
	end;

handle(<<"/auth/verify">>, WsReq) ->
	% 验证token
	#wsReq{headers = Headers} = WsReq,
	% 简化authorization头搜索
	AuthHeader = proplists:get_value('Authorization', Headers),
	io:format("AuthHeader selected: ~p~n", [AuthHeader]),
	try
		case AuthHeader of
			undefined ->
				io:format("No authorization header found~n"),
				{401, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Missing token">>})};
			<<"Bearer ", Token/binary>> ->
				io:format("Token extracted: ~p~n", [Token]),
				% 使用verifyToken函数验证token
				case verifyToken(Token) of
					{ok, UserInfo} ->
						Response = #{<<"valid">> => true, <<"user">> => UserInfo},
						{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
					{error, ErrorMsg} ->
						io:format("Token verification failed: ~p~n", [ErrorMsg]),
						{401, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => ErrorMsg})}
				end;
			_ ->
				io:format("Invalid authorization header format: ~p~n", [AuthHeader]),
				{401, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid token format">>})}
		end
	catch
		_:Error ->
			io:format("Exception in auth verify: ~p~n", [Error]),
			{500, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Internal server error">>})}
	end;

handle(<<"/auth/refresh">>, WsReq) ->
	% Token刷新接口
	#wsReq{headers = Headers} = WsReq,
	AuthHeader = proplists:get_value('Authorization', Headers),
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
		_:Error ->
			io:format("Exception in auth refresh: ~p~n", [Error]),
			{500, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Internal server error">>})}
	end;

handle(<<"/auth/logout">>, _WsReq) ->
	% 用户登出
	Response = #{<<"success">> => true, <<"message">> => <<"登出成功"/utf8>>},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};

handle(_Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.

%% 辅助函数

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

%% 生成Token（业界通用方案：包含过期时间和签名）
generateToken(UserInfo) ->
	Timestamp = integer_to_binary(erlang:system_time(second)),
	ExpiryTime = integer_to_binary(erlang:system_time(second) + 24 * 60 * 60), % 24小时过期
	Username = maps:get(<<"username">>, UserInfo),
	
	% 生成签名密钥（使用固定密钥+动态盐值）
	SecretKey = <<"gm_tool_secret_key_2024">>,
	Salt = crypto:strong_rand_bytes(16),
	
	% 生成待签名数据
	DataToSign = <<Username/binary, ":", Timestamp/binary, ":", ExpiryTime/binary>>,
	
	% 使用HMAC-SHA256生成签名
	Signature = crypto:mac(hmac, sha256, SecretKey, <<DataToSign/binary, Salt/binary>>),
	SignatureBase64 = base64:encode(Signature),
	
	% 构建完整token数据
	TokenData = <<"token:", Username/binary, ":", Timestamp/binary, ":", ExpiryTime/binary, ":", Salt/binary, ":", SignatureBase64/binary>>,
	io:format("Generated token data: ~p~n", [TokenData]),
	base64:encode(TokenData).

%% 查找Authorization头
find_authorization_header(Headers) ->
	% 检查最常见的authorization头键变体 (原子类型)
	case proplists:get_value('Authorization', Headers) of
		undefined ->
			case proplists:get_value('Authorization', Headers) of
				undefined ->
					case proplists:get_value('AUTHORIZATION', Headers) of
						undefined ->
							% 如果常见的变体都找不到，返回undefined
							undefined;
						Value -> Value
					end;
				Value -> Value
			end;
		Value -> Value
	end.

%% 将二进制字符串转换为小写
str_to_lower(Bin) ->
	<<<<(char_to_lower(Char))/utf8>> || <<Char/utf8>> <= Bin>>.

%% 将单个字符转换为小写
char_to_lower(Char) when Char >= $A, Char =< $Z ->
	Char + 32;
char_to_lower(Char) ->
	Char.

%% 验证Token（业界通用方案：检查过期时间和签名）
verifyToken(Token) ->
	try
		Decoded = base64:decode(Token),
		io:format("Decoded token: ~p~n", [Decoded]),
		Parts = binary:split(Decoded, <<":">>, [global]),
		io:format("Token parts: ~p~n", [Parts]),
		
		% 签名验证密钥
		SecretKey = <<"gm_tool_secret_key_2024">>,
		
		case Parts of
			[<<"token">>, Username, Timestamp, ExpiryTimeBin, Salt, ReceivedSignature] ->
				%% 重新计算签名进行验证
				DataToSign = <<Username/binary, ":", Timestamp/binary, ":", ExpiryTimeBin/binary>>,
				ExpectedSignature = crypto:mac(hmac, sha256, SecretKey, <<DataToSign/binary, Salt/binary>>),
				ExpectedSignatureBase64 = base64:encode(ExpectedSignature),
				
				io:format("Received signature: ~p~n", [ReceivedSignature]),
				io:format("Expected signature: ~p~n", [ExpectedSignatureBase64]),
				
				%% 验证签名
				if
					ReceivedSignature =/= ExpectedSignatureBase64 ->
						io:format("Token signature invalid!~n"),
						{error, <<"Token签名无效"/utf8>>};
					true ->
						%% 检查Token是否过期
						CurrentTime = erlang:system_time(second),
						ExpiryTime = binary_to_integer(ExpiryTimeBin),
						io:format("Current time: ~p, Expiry time: ~p~n", [CurrentTime, ExpiryTime]),
						
						if
							CurrentTime > ExpiryTime ->
								io:format("Token expired!~n"),
								{error, <<"Token已过期"/utf8>>};
							true ->
								%% 查找用户信息
								case lists:search(fun(User) ->
									maps:get(username, User) =:= Username
								end, ?USERS) of
									{value, User} ->
										UserInfo = #{
											<<"username">> => maps:get(username, User),
											<<"role">> => maps:get(role, User),
											<<"permissions">> => maps:get(permissions, User)
										},
										io:format("Token valid, user: ~p~n", [UserInfo]),
										{ok, UserInfo};
									false ->
										io:format("User not found: ~p~n", [Username]),
										{error, <<"用户不存在"/utf8>>}
								end
						end
				end;
			_ ->
				io:format("Invalid token format, expected 6 parts but got ~p~n", [length(Parts)]),
				{error, <<"无效的Token格式"/utf8>>}
		end
	catch
		Error:Reason ->
			io:format("Token verification error: ~p:~p~n", [Error, Reason]),
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