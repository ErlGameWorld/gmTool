-module(gmExLogsGHer).
-export([handle/2]).

-include_lib("eWSrv/include/eWSrv.hrl").

handle(<<"/logs">>, WsReq) ->
	Query = eWSrv:mapargs(WsReq),
	Page0 = binInt(maps:get(<<"page">>, Query, <<"1">>), 1),
	PageSize0 = binInt(maps:get(<<"pageSize">>, Query, <<"20">>), 20),
	All = getLogs(),
	Total = length(All),
	PageSize = min(100, max(1, PageSize0)),
	Pages = max(1, (Total + PageSize - 1) div PageSize),
	Page = min(max(1, Page0), Pages),
	Start = (Page - 1) * PageSize + 1,
	Rows = lists:sublist(All, Start, PageSize),
	Cols = [
		{id, <<"ID">>},
		{timestamp, <<"时间"/utf8>>},
		{type, <<"类型"/utf8>>},
		{severity, <<"级别"/utf8>>},
		{message, <<"内容"/utf8>>},
		{server, <<"服务器"/utf8>>}
	],
	{table, Cols, Rows, #{
		total => Total,
		page => Page,
		pageSize => PageSize,
		pagination => true
	}};

handle(_Path, _WsReq) ->
	not_found.

getLogs() ->
	Base = [
		#{type => <<"player_login">>, level => <<"info">>,
			message => <<"玩家登录游戏"/utf8>>, server => <<"GameServer-1">>},
		#{type => <<"gm_command">>, level => <<"warning">>,
			message => <<"GM执行了添加金币命令"/utf8>>, server => <<"GameServer-1">>},
		#{type => <<"system_error">>, level => <<"error">>,
			message => <<"数据库连接超时"/utf8>>, server => <<"DBServer-1">>},
		#{type => <<"player_logout">>, level => <<"info">>,
			message => <<"玩家退出游戏"/utf8>>, server => <<"GameServer-1">>},
		#{type => <<"item_transaction">>, level => <<"info">>,
			message => <<"玩家购买了物品"/utf8>>, server => <<"GameServer-1">>}
	],
	[begin
		Tpl = lists:nth(((I - 1) rem length(Base)) + 1, Base),
		Hour = 10 + ((I - 1) div 60),
		Min = (I - 1) rem 60,
		Ts = iolist_to_binary(io_lib:format("2023-08-15 ~2..0B:~2..0B:00", [Hour, Min])),
		Tpl#{id => I, timestamp => Ts,
			message => iolist_to_binary([maps:get(message, Tpl), <<" #"/utf8>>, integer_to_binary(I)])}
	end || I <- lists:seq(1, 25)].

binInt(<<>>, Default) -> Default;
binInt(B, Default) when is_binary(B) ->
	try binary_to_integer(B) catch _:_ -> Default end;
binInt(I, _) when is_integer(I) -> I;
binInt(_, Default) -> Default.
