-module(logsGHer).
-export([handle/2]).

-include_lib("eWSrv/include/eWSrv.hrl").

handle(<<"/logs">>, WsReq) ->
	% 获取日志列表 - 从comGHer.erl迁移
	#wsReq{args = Args} = WsReq,
	Params = maps:from_list(Args),
	
	Page = case maps:get(<<"page">>, Params, <<"1">>) of
		<<"">> -> 1;
		P -> binary_to_integer(P)
	end,
	PageSize = case maps:get(<<"pageSize">>, Params, <<"10">>) of
		<<"">> -> 10;
		PS -> binary_to_integer(PS)
	end,
	Search = maps:get(<<"search">>, Params, <<"">>),
	Type = maps:get(<<"type">>, Params, <<"all">>),
	Severity = maps:get(<<"severity">>, Params, <<"all">>),
	
	% 获取日志数据
	Logs = get_logs(),
	FilteredLogs = filter_logs(Logs, Search, Type, Severity),
	PagedLogs = paginate_list(FilteredLogs, Page, PageSize),
	Total = length(FilteredLogs),
	
	Response = #{
		success => true,
		data => PagedLogs,
		total => Total,
		page => Page,
		pageSize => PageSize
	},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};

handle(<<"/logs/search">>, _WsReq) ->
	% 简单返回固定搜索结果
	Results = [#{id => 2, type => <<"gm">>, action => <<"command">>, gm_id => 1, timestamp => <<"2024-01-01 10:05:00">>, details => <<"执行GM命令"/utf8>>}],
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Results)};

handle(<<"/logs/export">>, _WsReq) ->
	% 导出日志（模拟返回导出链接或数据）
	Export = #{<<"success">> => true, <<"url">> => <<"http://localhost:8080/export/logs.csv">>},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Export)};

handle(_Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.

% 辅助函数 - 从comGHer.erl迁移
get_logs() ->
	[
		#{
			id => 1,
			timestamp => <<"2023-08-15 14:30:25">>,
			type => <<"player_login">>,
			severity => <<"info">>,
			message => <<"玩家张三登录游戏">>,
			playerId => 1,
			playerName => <<"张三">>,
			server => <<"GameServer-1">>
		},
		#{
			id => 2,
			timestamp => <<"2023-08-15 14:25:10">>,
			type => <<"gm_command">>,
			severity => <<"warning">>,
			message => <<"GM执行了添加金币命令">>,
			gmId => 1,
			gmName => <<"admin">>,
			targetPlayer => <<"李四">>,
			server => <<"GameServer-1">>
		},
		#{
			id => 3,
			timestamp => <<"2023-08-15 14:20:45">>,
			type => <<"system_error">>,
			severity => <<"error">>,
			message => <<"数据库连接超时">>,
			server => <<"DBServer-1">>
		},
		#{
			id => 4,
			timestamp => <<"2023-08-15 14:15:30">>,
			type => <<"player_logout">>,
			severity => <<"info">>,
			message => <<"玩家王五退出游戏">>,
			playerId => 3,
			playerName => <<"王五">>,
			server => <<"GameServer-1">>
		},
		#{
			id => 5,
			timestamp => <<"2023-08-15 14:10:15">>,
			type => <<"item_transaction">>,
			severity => <<"info">>,
			message => <<"玩家赵六购买了屠龙宝刀">>,
			playerId => 4,
			playerName => <<"赵六">>,
			itemId => 1,
			itemName => <<"屠龙宝刀">>,
			server => <<"GameServer-1">>
		}
	].

filter_logs(Logs, Search, Type, Severity) ->
	lists:filter(fun(Log) ->
		Message = maps:get(message, Log, <<"">>),
		LogType = maps:get(type, Log, <<"">>),
		LogSeverity = maps:get(severity, Log, <<"">>),
		
		MatchesSearch = Search =:= <<"">> orelse 
			string:str(binary_to_list(Message), binary_to_list(Search)) > 0,
		MatchesType = Type =:= <<"all">> orelse LogType =:= Type,
		MatchesSeverity = Severity =:= <<"all">> orelse LogSeverity =:= Severity,
		MatchesSearch andalso MatchesType andalso MatchesSeverity
	end, Logs).

paginate_list(List, Page, PageSize) ->
	StartIndex = (Page - 1) * PageSize + 1,
	EndIndex = Page * PageSize,
	lists:sublist(List, StartIndex, EndIndex - StartIndex + 1).