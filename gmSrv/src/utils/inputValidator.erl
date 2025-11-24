-module(inputValidator).

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
            {error, list_to_binary(io_lib:format("字符串长度不能少于 ~p 个字符", [MinLength]))};
        _ ->
            {error, list_to_binary(io_lib:format("字符串长度不能超过 ~p 个字符", [MaxLength]))}
    end;
validateString(_, _, _) ->
    {error, <<"参数必须是字符串类型">>}.

%% 验证数字参数
validateNumber(Value, Min, Max, Type) when is_number(Value) ->
    case Type of
        integer when not is_integer(Value) ->
            {error, <<"参数必须是整数类型">>};
        float when not is_float(Value) ->
            {error, <<"参数必须是浮点数类型">>};
        _ ->
            case Value of
                V when V >= Min, V =< Max ->
                    {ok, Value};
                V when V < Min ->
                    {error, list_to_binary(io_lib:format("数值不能小于 ~p", [Min]))};
                _ ->
                    {error, list_to_binary(io_lib:format("数值不能大于 ~p", [Max]))}
            end
    end;
validateNumber(_, _, _, _) ->
    {error, <<"参数必须是数字类型">>}.

%% 验证邮箱格式
validateEmail(Email) when is_binary(Email) ->
    Pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
    case re:run(Email, Pattern, [unicode]) of
        {match, _} -> {ok, Email};
        _ -> {error, <<"邮箱格式不正确">>}
    end;
validateEmail(_) ->
    {error, <<"邮箱参数必须是字符串">>}.

%% 验证手机号格式（中国手机号）
validatePhone(Phone) when is_binary(Phone) ->
    Pattern = "^1[3-9]\\d{9}$",
    case re:run(Phone, Pattern) of
        {match, _} -> {ok, Phone};
        _ -> {error, <<"手机号格式不正确">>}
    end;
validatePhone(_) ->
    {error, <<"手机号参数必须是字符串">>}.

%% 验证JSON格式
validateJson(JsonString) when is_binary(JsonString) ->
    try
        case json:decode(JsonString) of
            {ok, Decoded} -> {ok, Decoded};
            {error, Reason} -> {error, list_to_binary(io_lib:format("JSON解析错误: ~p", [Reason]))}
        end
    catch
        _:_ -> {error, <<"JSON格式不正确">>}
    end;
validateJson(_) ->
    {error, <<"JSON参数必须是字符串">>}.

%% 批量验证参数
validateParams(Params, Rules) ->
    validate_params(Params, Rules, #{}).

validate_params(Params, Rules, Acc) ->
    case Rules of
        [] -> {ok, Acc};
        [{ParamName, Type, Constraints} | Rest] ->
            Value = maps:get(ParamName, Params, undefined),
            case validate_param(Value, Type, Constraints) of
                {ok, ValidatedValue} ->
                    validate_params(Params, Rest, maps:put(ParamName, ValidatedValue, Acc));
                {error, Reason} ->
                    {error, list_to_binary(io_lib:format("参数 ~s 验证失败: ~s", [ParamName, Reason]))}
            end
    end.

validate_param(undefined, _, {required, _}) ->
    {error, <<"参数不能为空">>};
validate_param(undefined, _, _) ->
    {ok, undefined};
validate_param(Value, string, {Min, Max}) ->
    validateString(Value, Min, Max);
validate_param(Value, number, {Min, Max, Type}) ->
    validateNumber(Value, Min, Max, Type);
validate_param(Value, email, _) ->
    validateEmail(Value);
validate_param(Value, phone, _) ->
    validatePhone(Value);
validate_param(Value, json, _) ->
    validateJson(Value);
validate_param(Value, _, _) ->
    {ok, Value}.

%% 输入清理（防止XSS攻击）
sanitizeInput(Input) when is_binary(Input) ->
    % 移除危险HTML标签和属性
    Sanitized = re:replace(Input, "<script[^>]*>.*?</script>", "", [global, {return, binary}, caseless]),
    Sanitized1 = re:replace(Sanitized, "<iframe[^>]*>.*?</iframe>", "", [global, {return, binary}, caseless]),
    Sanitized2 = re:replace(Sanitized1, "javascript:", "", [global, {return, binary}, caseless]),
    re:replace(Sanitized2, "on\w+=", "", [global, {return, binary}, caseless]);
sanitizeInput(Input) ->
    Input.