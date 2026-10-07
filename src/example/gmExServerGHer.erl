-module(gmExServerGHer).
-export([handle/2]).

-include_lib("eWSrv/include/eWSrv.hrl").

handle(<<"/server/status">>, _WsReq) ->
	Cols = [
		{id, <<"ID">>, #{width => 60}},
		{name, <<"名称"/utf8>>},
		{status, <<"状态"/utf8>>},
		{players, <<"在线人数"/utf8>>},
		{cpuLoad, <<"CPU%">>},
		{memoryUsage, <<"内存%"/utf8>>},
		{uptime, <<"运行时长"/utf8>>}
	],
	{table, Cols, getServers(), #{total => 4}};

handle(<<"/server/statistics">>, _WsReq) ->
	{json, #{
		totalServers => 3,
		totalPlayers => 800,
		onlineServers => 2,
		maintenanceServers => 1
	}};

handle(_Path, _WsReq) ->
	not_found.

getServers() ->
	[
		#{id => 1, name => <<"主服务器"/utf8>>, status => <<"online">>,
			players => 1250, cpuLoad => 65, memoryUsage => 75, diskSpace => 80,
			uptime => <<"15天6小时"/utf8>>, serverAddress => <<"127.0.0.1">>, port => 8080},
		#{id => 2, name => <<"副本服务器"/utf8>>, status => <<"online">>,
			players => 480, cpuLoad => 40, memoryUsage => 55, diskSpace => 70,
			uptime => <<"10天12小时"/utf8>>, serverAddress => <<"127.0.0.1">>, port => 8081},
		#{id => 3, name => <<"测试服务器"/utf8>>, status => <<"maintenance">>,
			players => 0, cpuLoad => 10, memoryUsage => 30, diskSpace => 90,
			uptime => <<"0天2小时"/utf8>>, serverAddress => <<"127.0.0.1">>, port => 8082},
		#{id => 4, name => <<"备用服务器"/utf8>>, status => <<"online">>,
			players => 50, cpuLoad => 25, memoryUsage => 40, diskSpace => 95,
			uptime => <<"7天8小时"/utf8>>, serverAddress => <<"127.0.0.1">>, port => 8083}
	].
