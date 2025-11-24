-module(serverGHer).

-export([handle/2]).

-include_lib("eWSrv/include/eWSrv.hrl").

handle(<<"/server/status">>, _WsReq) ->
	% 获取服务器状态 - 从comGHer.erl迁移
	Servers = get_servers(),
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Servers)};

handle(<<"/servers">>, _WsReq) ->
	% 获取服务器列表 - 从comGHer.erl迁移
	Servers = get_servers(),
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Servers)};

handle(<<"/server/statistics">>, _WsReq) ->
	% 获取服务器统计信息
	Statistics = #{
		<<"totalServers">> => 3,
		<<"totalPlayers">> => 800,
		<<"onlineServers">> => 2,
		<<"maintenanceServers">> => 1
	},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Statistics)};

handle(_Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.

% 辅助函数 - 从comGHer.erl迁移
get_servers() ->
	[
		#{
			id => 1,
			name => <<"主服务器"/utf8>>,
			status => <<"online">>,
			players => 1250 + rand:uniform(50) - 25,
			cpuLoad => 65 + rand:uniform(10) - 5,
			memoryUsage => 75 + rand:uniform(8) - 4,
			diskSpace => 80,
			uptime => <<"15天6小时30分钟">>,
			serverAddress => <<"127.0.0.1">>,
			port => 8080
		},
		#{
			id => 2,
			name => <<"副本服务器"/utf8>>,
			status => <<"online">>,
			players => 480 + rand:uniform(50) - 25,
			cpuLoad => 40 + rand:uniform(10) - 5,
			memoryUsage => 55 + rand:uniform(8) - 4,
			diskSpace => 70,
			uptime => <<"10天12小时15分钟"/utf8>>,
			serverAddress => <<"127.0.0.1">>,
			port => 8080
		},
		#{
			id => 3,
			name => <<"测试服务器"/utf8>>,
			status => <<"maintenance">>,
			players => 0,
			cpuLoad => 10 + rand:uniform(10) - 5,
			memoryUsage => 30 + rand:uniform(8) - 4,
			diskSpace => 90,
			uptime => <<"0天2小时45分钟"/utf8>>,
			serverAddress => <<"127.0.0.1">>,
			port => 8080
		},
		#{
			id => 4,
			name => <<"备用服务器"/utf8>>,
			status => <<"online">>,
			players => 50 + rand:uniform(50) - 25,
			cpuLoad => 25 + rand:uniform(10) - 5,
			memoryUsage => 40 + rand:uniform(8) - 4,
			diskSpace => 95,
			uptime => <<"7天8小时20分钟"/utf8>>,
			serverAddress => <<"127.0.0.1">>,
			port => 8080
		}
	].