-module(gmValidator).
-export([validateRequest/2, validateInteger/2, validateString/2, validateRequired/2, replyJson/2]).

%% 请求数据验证
%% json:decode/1 直接返回值、出错 raise；不用 decode/2（stdlib 无此 arity）
validateRequest(Body, Rules) ->
	try
		Data = json:decode(Body),
		validateFields(Data, Rules)
	catch
		_:_ -> {error, <<"Invalid JSON format">>}
	end.

validateFields(Data, Rules) ->
	validateFields(Data, Rules, #{}).

validateFields(_Data, [], Acc) ->
	{ok, Acc};
validateFields(Data, [{Field, Type, Required} | Rules], Acc) ->
	case maps:get(Field, Data, undefined) of
		undefined when Required ->
			{error, <<"Field ", Field/binary, " is required">>};
		undefined ->
			validateFields(Data, Rules, Acc);
		Value ->
			case validateType(Value, Type) of
				{ok, ValidatedValue} ->
					validateFields(Data, Rules, Acc#{Field => ValidatedValue});
				{error, Reason} ->
					{error, Reason}
			end
	end.

validateType(Value, integer) when is_integer(Value) -> {ok, Value};
validateType(Value, integer) when is_binary(Value) ->
	try {ok, binary_to_integer(Value)}
	catch _:_ -> {error, <<"Invalid integer format">>}
	end;
validateType(Value, string) when is_binary(Value) -> {ok, Value};
validateType(Value, boolean) when is_boolean(Value) -> {ok, Value};
validateType(_Value, _) -> {error, <<"Invalid data type">>}.

%% 便捷验证函数
validateInteger(Value, _Field) ->
	validateType(Value, integer).

validateString(Value, _Field) ->
	validateType(Value, string).

validateRequired(Value, Field) when Value =:= undefined ->
	{error, <<"Field ", Field/binary, " is required">>};
validateRequired(Value, _Field) ->
	{ok, Value}.

%% JSON回复函数（兼容旧调用；新代码请直接返回 gmReply 简写）
replyJson(Status, Data) ->
	gmReply:pack({Status, gmReply:jsonHeaders(), json:encode(Data)}).
