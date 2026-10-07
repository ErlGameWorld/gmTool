-module(gmInputValidator).

-include_lib("eWSrv/include/eWSrv.hrl").

-export([
	validateString/3,
	validateNumber/4,
	validateEmail/1,
	validatePhone/1,
	validateJson/1,
	validateParams/2,
	sanitizeInput/1
]).


%% 验证字符串参数
validateString(Value, MinLength, MaxLength) when is_binary(Value) ->
	case byte_size(Value) of
		Size when Size >= MinLength, Size =< MaxLength ->
			{ok, Value};
		Size when Size < MinLength ->
			{error, unicode:characters_to_binary(io_lib:format("字符串长度不能少于 ~p 个字符", [MinLength]))};
		_ ->
			{error, unicode:characters_to_binary(io_lib:format("字符串长度不能超过 ~p 个字符", [MaxLength]))}
	end;
validateString(_, _, _) ->
	{error, <<"参数必须是字符串类型"/utf8>>}.

%% 验证数字参数
validateNumber(Value, Min, Max, Type) when is_number(Value) ->
	case Type of
		integer when not is_integer(Value) ->
			{error, <<"参数必须是整数类型"/utf8>>};
		float when not is_float(Value) ->
			{error, <<"参数必须是浮点数类型"/utf8>>};
		_ ->
			case Value of
				V when V >= Min, V =< Max ->
					{ok, Value};
				V when V < Min ->
					{error, unicode:characters_to_binary(io_lib:format("数值不能小于 ~p", [Min]))};
				_ ->
					{error, unicode:characters_to_binary(io_lib:format("数值不能大于 ~p", [Max]))}
			end
	end;
validateNumber(_, _, _, _) ->
	{error, <<"参数必须是数字类型"/utf8>>}.

%% 验证邮箱格式
validateEmail(Email) when is_binary(Email) ->
	Pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
	case re:run(Email, Pattern, [unicode]) of
		{match, _} -> {ok, Email};
		_ -> {error, <<"邮箱格式不正确"/utf8>>}
	end;
validateEmail(_) ->
	{error, <<"邮箱参数必须是字符串"/utf8>>}.

%% 验证手机号格式（中国手机号）
validatePhone(Phone) when is_binary(Phone) ->
	Pattern = "^1[3-9]\\d{9}$",
	case re:run(Phone, Pattern) of
		{match, _} -> {ok, Phone};
		_ -> {error, <<"手机号格式不正确"/utf8>>}
	end;
validatePhone(_) ->
	{error, <<"手机号参数必须是字符串"/utf8>>}.

%% 验证JSON格式（json:decode/1 直接返回值、出错 raise）
validateJson(JsonString) when is_binary(JsonString) ->
	try
		{ok, json:decode(JsonString)}
	catch
		_:_ -> {error, <<"JSON格式不正确"/utf8>>}
	end;
validateJson(_) ->
	{error, <<"JSON参数必须是字符串"/utf8>>}.

%% 批量验证参数
validateParams(Params, Rules) ->
	validateParams(Params, Rules, #{}).

validateParams(Params, Rules, Acc) ->
	case Rules of
		[] -> {ok, Acc};
		[{ParamName, Type, Constraints} | Rest] ->
			Value = maps:get(ParamName, Params, undefined),
			case validateParam(Value, Type, Constraints) of
				{ok, ValidatedValue} ->
					validateParams(Params, Rest, maps:put(ParamName, ValidatedValue, Acc));
				{error, Reason} ->
					{error, unicode:characters_to_binary(
						io_lib:format("参数 ~ts 验证失败: ~ts", [toBin(ParamName), Reason]))}
			end
	end.

validateParam(undefined, _, {required, _}) ->
	{error, <<"参数不能为空"/utf8>>};
validateParam(undefined, _, _) ->
	{ok, undefined};
validateParam(Value, string, {Min, Max}) ->
	validateString(Value, Min, Max);
validateParam(Value, number, {Min, Max, Type}) ->
	validateNumber(Value, Min, Max, Type);
validateParam(Value, email, _) ->
	validateEmail(Value);
validateParam(Value, phone, _) ->
	validatePhone(Value);
validateParam(Value, json, _) ->
	validateJson(Value);
validateParam(Value, _, _) ->
	{ok, Value}.

%% 输入清理（防止XSS攻击）
sanitizeInput(Input) when is_binary(Input) ->
	Sanitized = re:replace(Input, "<script[^>]*>.*?</script>", "", [global, {return, binary}, caseless]),
	Sanitized1 = re:replace(Sanitized, "<iframe[^>]*>.*?</iframe>", "", [global, {return, binary}, caseless]),
	Sanitized2 = re:replace(Sanitized1, "javascript:", "", [global, {return, binary}, caseless]),
	re:replace(Sanitized2, "on\\w+=", "", [global, {return, binary}, caseless]);
sanitizeInput(Input) ->
	Input.

toBin(B) when is_binary(B) -> B;
toBin(A) when is_atom(A) -> atom_to_binary(A, utf8);
toBin(L) when is_list(L) -> unicode:characters_to_binary(L);
toBin(O) -> unicode:characters_to_binary(io_lib:format("~0p", [O])).
