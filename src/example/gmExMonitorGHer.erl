-module(gmExMonitorGHer).
-export([handle/2]).

handle(<<"/monitor">>, _WsReq) ->
	{cards, [
		#{title => <<"CPU"/utf8>>, content => <<"45.6%">>, footer => <<"使用率"/utf8>>},
		#{title => <<"内存"/utf8>>, content => <<"67.8%">>, footer => <<"使用率"/utf8>>},
		#{title => <<"磁盘"/utf8>>, content => <<"23.4%">>, footer => <<"使用率"/utf8>>},
		#{title => <<"在线"/utf8>>, content => <<"1250">>, footer => <<"玩家"/utf8>>}
	], #{title => <<"实时监控"/utf8>>}};

handle(<<"/monitor/real-time">>, _WsReq) ->
	{json, getMonitorData()};

handle(<<"/monitor/alerts">>, _WsReq) ->
	Cols = [
		{id, <<"ID">>},
		{level, <<"级别"/utf8>>},
		{message, <<"内容"/utf8>>},
		{timestamp, <<"时间"/utf8>>}
	],
	%% 按列顺序的二维列表
	Rows = [
		[1, <<"warning">>, <<"CPU使用率过高"/utf8>>, <<"2024-01-01 10:00:00">>],
		[2, <<"info">>, <<"内存使用率正常"/utf8>>, <<"2024-01-01 09:50:00">>]
	],
	{table, Cols, Rows};

handle(_Path, _WsReq) ->
	not_found.

getMonitorData() ->
	#{
		cpuUsage => 45.6,
		memoryUsage => 67.8,
		diskUsage => 23.4,
		onlinePlayers => 1250,
		serverStatus => <<"running">>
	}.
