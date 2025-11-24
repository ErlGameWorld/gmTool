-module(monitorGHer).
-export([handle/2]).

handle(<<"/monitor/real-time">>, _WsReq) ->
	% 获取实时监控数据 - 从comGHer.erl迁移
	MonitorData = get_monitor_data(),
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(MonitorData)};

handle(<<"/monitor/data">>, _WsReq) ->
	% 获取监控数据 - 从comGHer.erl迁移
	MonitorData = get_monitor_data(),
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(MonitorData)};

handle(<<"/monitor/alerts">>, _WsReq) ->
	% 获取监控告警
	Alerts = [
		#{id => 1, level => <<"warning">>, message => <<"CPU使用率过高"/utf8>>, timestamp => <<"2024-01-01 10:00:00">>},
		#{id => 2, level => <<"info">>, message => <<"内存使用率正常"/utf8>>, timestamp => <<"2024-01-01 09:50:00">>}
	],
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Alerts)};

handle(<<"/monitor/trends">>, _WsReq) ->
	% 获取监控趋势数据
	TrendData = #{
		<<"cpuTrend">> => [45, 48, 52, 49, 46, 43, 45],
		<<"memoryTrend">> => [65, 67, 68, 66, 64, 67, 68],
		<<"playersTrend">> => [1200, 1250, 1300, 1280, 1250, 1230, 1250]
	},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(TrendData)};

handle(_Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.

% 辅助函数 - 从comGHer.erl迁移
get_monitor_data() ->
	#{
		<<"cpuUsage">> => 45.6 + rand:uniform(10) - 5,
		<<"memoryUsage">> => 67.8 + rand:uniform(5) - 2.5,
		<<"diskUsage">> => 23.4 + rand:uniform(3) - 1.5,
		<<"onlinePlayers">> => 1250 + rand:uniform(100) - 50,
		<<"serverStatus">> => <<"running">>,
		<<"timestamp">> => list_to_binary(io_lib:format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B", 
			[2024, 1, 1, 10, 0, 0]))
	}.