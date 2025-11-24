-module(validator).
-export([validateRequest/2, validateInteger/2, validateString/2, validateRequired/2, reply_json/2]).

%% 请求数据验证
validateRequest(Body, Rules) ->
	case json:decode(Body, [return_maps]) of
		{ok, Data} ->
			validateFields(Data, Rules);
		{error, _} ->
			{error, <<"Invalid JSON format">>}
	end.

validateFields(Data, Rules) ->
	validateFields(Data, Rules, #{}).

validateFields(Data, [], Acc) ->
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
validateType(Value, _) -> {error, <<"Invalid data type">>}.

%% 便捷验证函数
validateInteger(Value, Field) ->
	validateType(Value, integer).

validateString(Value, Field) ->
	validateType(Value, string).

validateRequired(Value, Field) when Value =:= undefined ->
	{error, <<"Field ", Field/binary, " is required">>};
validateRequired(Value, _Field) ->
	{ok, Value}.

%% JSON回复函数
reply_json(Status, Data) ->
	JsonData = json:encode(Data),
	Headers = [{<<"content-type">>, <<"application/json">>}],
	{Status, Headers, JsonData}.