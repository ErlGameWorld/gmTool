-module(statisticsGHer).

-export([handle/2]).

-include_lib("eWSrv/include/wsCom.hrl").

handle(<<"/server/statistics">>, _WsReq) ->
	% 获取统计数据
	Statistics = #{
		<<"totalPlayers">> => 10000,
		<<"onlinePlayers">> => 1250,
		<<"dailyActive">> => 3000,
		<<"revenueToday">> => 5000.00,
		<<"revenueMonth">> => 150000.00,
		<<"timestamp">> => <<"2024-01-01 10:00:00">>
	},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Statistics)};

handle(<<"/gm/execute">>, WsReq) ->
	% GM命令执行 - 从comGHer.erl迁移
	#wsReq{body = Body} = WsReq,
	case Body of
		<<>> ->
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{error => <<"Empty request body">>})};
		_ ->
			try
				Decoded = json:decode(Body),
				case Decoded of
					#{<<"commandId">> := CommandId, <<"params">> := Params} ->
						Result = execute_gm_command(CommandId, Params),
						{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Result)};
					_ ->
						{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid request format">>})}
				end
			catch
				_:_ ->
					{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid JSON format">>})}
			end
	end;

handle(_Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.

% GM命令执行函数 - 从comGHer.erl迁移
execute_gm_command(1, Params) ->
	#{player_id := PlayerId, amount := Amount} = Params,
	io:format("Adding ~p gold to player ~p~n", [Amount, PlayerId]),
	#{success => true, message => list_to_binary(io_lib:format("Added ~p gold to player ~p", [Amount, PlayerId]))};

execute_gm_command(2, Params) ->
	#{player_id := PlayerId, duration := Duration} = Params,
	Reason = maps:get(reason, Params, <<"No reason specified">>),
	io:format("Banning player ~p for ~p hours, reason: ~p~n", [PlayerId, Duration, Reason]),
	#{success => true, message => list_to_binary(io_lib:format("Player ~p banned for ~p hours", [PlayerId, Duration]))};

execute_gm_command(3, Params) ->
	#{message := Message} = Params,
	Duration = maps:get(duration, Params, 10),
	io:format("Broadcasting message: ~p for ~p seconds~n", [Message, Duration]),
	#{success => true, message => list_to_binary(io_lib:format("Message broadcasted for ~p seconds", [Duration]))};

execute_gm_command(4, Params) ->
	#{player_id := PlayerId, item_id := ItemId, quantity := Quantity} = Params,
	io:format("Adding item ~p (quantity: ~p) to player ~p~n", [ItemId, Quantity, PlayerId]),
	#{success => true, message => list_to_binary(io_lib:format("Added item ~p (quantity: ~p) to player ~p", [ItemId, Quantity, PlayerId]))};

execute_gm_command(5, Params) ->
	#{player_id := PlayerId, title := Title, content := Content} = Params,
	Attachments = maps:get(attachments, Params, []),
	io:format("Sending mail to player ~p: title=~p, content=~p, attachments=~p~n", [PlayerId, Title, Content, Attachments]),
	#{success => true, message => list_to_binary(io_lib:format("Mail sent to player ~p", [PlayerId]))};

execute_gm_command(6, Params) ->
	#{player_id := PlayerId, duration := Duration} = Params,
	Reason = maps:get(reason, Params, <<"No reason specified">>),
	io:format("Muting player ~p for ~p minutes, reason: ~p~n", [PlayerId, Duration, Reason]),
	#{success => true, message => list_to_binary(io_lib:format("Player ~p muted for ~p minutes", [PlayerId, Duration]))};

execute_gm_command(7, Params) ->
	#{player_id := PlayerId, level := Level} = Params,
	io:format("Setting player ~p level to ~p~n", [PlayerId, Level]),
	#{success => true, message => list_to_binary(io_lib:format("Player ~p level set to ~p", [PlayerId, Level]))};

execute_gm_command(8, Params) ->
	#{dungeon_id := DungeonId} = Params,
	io:format("Resetting dungeon ~p progress~n", [DungeonId]),
	#{success => true, message => list_to_binary(io_lib:format("Dungeon ~p progress reset", [DungeonId]))};

execute_gm_command(CommandId, _Params) ->
	#{success => false, error => list_to_binary(io_lib:format("Unknown command ID: ~p", [CommandId]))}.