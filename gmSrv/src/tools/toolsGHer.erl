-module(toolsGHer).
-export([handle/2]).

-include_lib("eWSrv/include/wsCom.hrl").

handle(<<"/utils/param-types">>, WsReq) when WsReq#wsReq.method =:= 'POST' ->
	% 参数类型测试 - 从comGHer.erl迁移
	case eWSrv:get_body(WsReq) of
		{ok, Body} ->
			case json:decode(Body) of
				Params when is_map(Params) ->
					io:format("Received parameter type test data: ~p~n", [Params]),
					% 处理各种参数类型
					Response = #{
						success => true,
						message => <<"参数类型测试成功">>,
						receivedParams => Params,
						timestamp => list_to_binary(calendar:local_time_to_string(calendar:local_time())),
						validation => #{
							basic_text => case maps:get(<<"basic_text">>, Params, undefined) of
								undefined -> <<"未提供文本参数">>;
								Value when is_binary(Value) andalso byte_size(Value) > 0 -> <<"文本参数验证通过">>;
								_ -> <<"文本参数格式错误">>
							end,
							limited_number => case maps:get(<<"limited_number">>, Params, undefined) of
								undefined -> <<"未提供有限制数字参数">>;
								Value when is_number(Value) andalso Value >= 1 andalso Value =< 100 -> <<"有限制数字参数验证通过">>;
								_ -> <<"有限制数字参数格式错误">>
							end,
							unlimited_number => case maps:get(<<"unlimited_number">>, Params, undefined) of
								undefined -> <<"未提供无限制数字参数">>;
								Value when is_number(Value) -> <<"无限制数字参数验证通过">>;
								_ -> <<"无限制数字参数格式错误">>
							end,
							email_demo => case maps:get(<<"email_demo">>, Params, undefined) of
								undefined -> <<"未提供邮箱参数">>;
								Value when is_binary(Value) -> 
									case binary:match(Value, <<"@">>) of
										{match, _} -> <<"邮箱参数验证通过">>;
										nomatch -> <<"邮箱参数格式错误">>
									end;
								_ -> <<"邮箱参数格式错误">>
							end,
							url_demo => case maps:get(<<"url_demo">>, Params, undefined) of
								undefined -> <<"未提供URL参数">>;
								Value when is_binary(Value) -> 
									case binary:match(Value, <<"http://">>) of
										{match, _} -> <<"URL参数验证通过">>;
										nomatch -> 
											case binary:match(Value, <<"https://">>) of
												{match, _} -> <<"URL参数验证通过">>;
											nomatch -> <<"URL参数格式错误">>
										end
									end;
								_ -> <<"URL参数格式错误">>
							end,
							date_range_demo => case maps:get(<<"date_range_demo">>, Params, undefined) of
								undefined -> <<"未提供日期范围参数">>;
								Value when is_map(Value) -> 
									case {maps:get(<<"min">>, Value, undefined), maps:get(<<"max">>, Value, undefined)} of
										{Min, Max} when is_binary(Min) andalso is_binary(Max) -> <<"日期范围参数验证通过">>;
										_ -> <<"日期范围参数格式错误">>
									end;
								Value when is_list(Value) -> <<"日期范围参数为数组格式，期望对象格式">>;
								_ -> <<"日期范围参数格式错误">>
							end,
							datetime_range_demo => case maps:get(<<"datetime_range_demo">>, Params, undefined) of
								undefined -> <<"未提供日期时间范围参数">>;
								Value when is_map(Value) -> 
									case {maps:get(<<"min">>, Value, undefined), maps:get(<<"max">>, Value, undefined)} of
										{Min, Max} when is_binary(Min) andalso is_binary(Max) -> <<"日期时间范围参数验证通过">>;
										_ -> <<"日期时间范围参数格式错误">>
									end;
								Value when is_list(Value) -> <<"日期时间范围参数为数组格式，期望对象格式">>;
								_ -> <<"日期时间范围参数格式错误">>
							end,
							number_range_demo => case maps:get(<<"number_range_demo">>, Params, undefined) of
								undefined -> <<"未提供数字范围参数">>;
								Value when is_map(Value) -> 
									case {maps:get(<<"min">>, Value, undefined), maps:get(<<"max">>, Value, undefined)} of
										{Min, Max} when is_number(Min) andalso is_number(Max) -> <<"数字范围参数验证通过">>;
										_ -> <<"数字范围参数格式错误">>
									end;
								Value when is_list(Value) -> <<"数字范围参数为数组格式，期望对象格式">>;
								_ -> <<"数字范围参数格式错误">>
							end
						}
					},
					{200, [{<<"content-type">>, <<"application/json">>}], json:encode(Response)};
				_ ->
					{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid request format">>})}
			end;
		_ ->
			{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid request body">>})}
	end;

handle(_Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.