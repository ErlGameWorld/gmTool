%%%-------------------------------------------------------------------
%%% @doc 玩家相关示例接口（演示约定返回格式，不调用 gm* 函数）。
%%% 列表存 persistent_term，DELETE 会真正从示例数据里去掉（进程重启后还原）。
%%% @end
%%%-------------------------------------------------------------------
-module(gmExPlayerGHer).
-export([handle/2]).

-include_lib("eWSrv/include/eWSrv.hrl").

-define(PLAYERS_KEY, {gmExPlayer, players}).
-define(MAX_PAGE_SIZE, 100).

handle(<<"/player">>, WsReq) ->
	Query = eWSrv:mapargs(WsReq),
	Page0 = binInt(maps:get(<<"page">>, Query, <<"1">>), 1),
	PageSize0 = binInt(maps:get(<<"pageSize">>, Query, <<"10">>), 10),
	Keyword = maps:get(<<"keyword">>, Query, <<>>),
	All = players(),
	Filtered = filterByKeyword(All, Keyword),
	Total = length(Filtered),
	PageSize = min(?MAX_PAGE_SIZE, max(1, PageSize0)),
	Pages = max(1, (Total + PageSize - 1) div PageSize),
	Page = min(max(1, Page0), Pages),
	Rows = pageOf(Filtered, Page, PageSize),
	Cols = [
		{id, <<"玩家ID"/utf8>>},
		{name, <<"玩家名"/utf8>>, #{
			link => #{menu => <<"menu_player_details">>, params => #{player_id => id}}
		}},
		{level, <<"等级"/utf8>>},
		{vipLevel, <<"VIP等级"/utf8>>},
		{status, <<"状态"/utf8>>},
		{lastLogin, <<"最后登录"/utf8>>},
		{registerTime, <<"注册时间"/utf8>>}
	],
	{table, Cols, Rows, #{
		total => Total,
		page => Page,
		pageSize => PageSize,
		pagination => true,
		actions => [
			#{
				key => <<"detail">>,
				label => <<"详情"/utf8>>,
				menu => <<"menu_player_details">>,
				params => #{player_id => id}
			},
			#{
				key => <<"kick">>,
				label => <<"踢出"/utf8>>,
				menu => <<"menu_kick_player">>,
				params => #{player_id => id}
			},
			#{
				key => <<"delete">>,
				label => <<"删除"/utf8>>,
				confirm => <<"确认删除该玩家？"/utf8>>,
				api => #{method => <<"DELETE">>, path => <<"/players/{id}">>, refresh => true}
			}
		]
	}};

handle(<<"/players/details">>, WsReq) ->
	case bodyOrQueryId(WsReq) of
		{ok, PlayerId} ->
			case findPlayer(PlayerId) of
				undefined -> not_found;
				P ->
					{kv, [
						{<<"玩家ID"/utf8>>, maps:get(id, P)},
						{<<"玩家名"/utf8>>, maps:get(name, P)},
						{<<"等级"/utf8>>, maps:get(level, P)},
						{<<"VIP"/utf8>>, maps:get(vipLevel, P)},
						{<<"状态"/utf8>>, maps:get(status, P)},
						{<<"最后登录"/utf8>>, maps:get(lastLogin, P)},
						{<<"注册时间"/utf8>>, maps:get(registerTime, P)}
					], #{title => <<"玩家详情"/utf8>>}}
			end;
		{error, Reason} ->
			{error, Reason}
	end;

handle(<<"/players/kick">>, WsReq) ->
	case bodyMap(WsReq) of
		{ok, #{<<"player_id">> := PlayerId} = Body} ->
			Reason = maps:get(<<"reason">>, Body, <<>>),
			{msg, unicode:characters_to_binary(
				io_lib:format("已踢出玩家 ~ts，原因: ~ts", [toStr(PlayerId), toStr(Reason)]))};
		{ok, _} ->
			{error, <<"缺少 player_id"/utf8>>};
		{error, Reason} ->
			{error, Reason}
	end;

handle(<<"/players/ban">>, WsReq) ->
	case bodyMap(WsReq) of
		{ok, #{<<"player_id">> := PlayerId, <<"duration">> := Duration} = Body} ->
			Reason = maps:get(<<"reason">>, Body, <<>>),
			{json, #{
				playerId => PlayerId,
				duration => Duration,
				reason => Reason,
				action => <<"ban">>
			}, <<"玩家封禁成功"/utf8>>};
		{ok, _} ->
			{error, <<"缺少 player_id 或 duration"/utf8>>};
		{error, Reason} ->
			{error, Reason}
	end;

handle(<<"/players/unban">>, WsReq) ->
	case bodyMap(WsReq) of
		{ok, #{<<"player_id">> := PlayerId} = Body} ->
			Reason = maps:get(<<"reason">>, Body, <<>>),
			{json, #{playerId => PlayerId, reason => Reason, action => <<"unban">>}, <<"玩家解封成功"/utf8>>};
		{ok, _} ->
			{error, <<"缺少 player_id"/utf8>>};
		{error, Reason} ->
			{error, Reason}
	end;

handle(<<"/players/", PlayerId/binary>>, WsReq) when WsReq#wsReq.method =:= 'DELETE' ->
	case binInt(PlayerId, 0) of
		Id when Id > 0 ->
			case deletePlayer(Id) of
				ok ->
					{msg, unicode:characters_to_binary(
						io_lib:format("已删除玩家 ~ts", [integer_to_binary(Id)]))};
				not_found ->
					not_found
			end;
		_ ->
			{error, 400, <<"非法 ID"/utf8>>}
	end;

handle(<<"/player/", PlayerId/binary>>, _WsReq) ->
	case findPlayer(binInt(PlayerId, 0)) of
		undefined -> not_found;
		Player -> {json, Player}
	end;

handle(_Path, _WsReq) ->
	not_found.

%% ========== 示例数据（可删） ==========

players() ->
	case persistent_term:get(?PLAYERS_KEY, undefined) of
		undefined ->
			List = seedPlayers(),
			persistent_term:put(?PLAYERS_KEY, List),
			List;
		List when is_list(List) ->
			List
	end.

deletePlayer(Id) when is_integer(Id) ->
	List = players(),
	case lists:any(fun(P) -> maps:get(id, P) =:= Id end, List) of
		true ->
			persistent_term:put(?PLAYERS_KEY, [P || P <- List, maps:get(id, P) =/= Id]),
			ok;
		false ->
			not_found
	end.

seedPlayers() ->
	[
		#{id => 1001, name => <<"张三"/utf8>>, level => 50, vipLevel => 3, status => <<"在线"/utf8>>,
			lastLogin => <<"2024-01-15 09:00:00">>, registerTime => <<"2023-12-01 10:00:00">>},
		#{id => 1002, name => <<"李四"/utf8>>, level => 45, vipLevel => 2, status => <<"离线"/utf8>>,
			lastLogin => <<"2024-01-14 18:30:00">>, registerTime => <<"2023-12-05 14:20:00">>},
		#{id => 1003, name => <<"王五"/utf8>>, level => 60, vipLevel => 5, status => <<"在线"/utf8>>,
			lastLogin => <<"2024-01-15 10:00:00">>, registerTime => <<"2023-11-20 08:15:00">>},
		#{id => 1004, name => <<"赵六"/utf8>>, level => 35, vipLevel => 1, status => <<"离线"/utf8>>,
			lastLogin => <<"2024-01-13 22:10:00">>, registerTime => <<"2024-01-05 16:45:00">>},
		#{id => 1005, name => <<"钱七"/utf8>>, level => 55, vipLevel => 4, status => <<"在线"/utf8>>,
			lastLogin => <<"2024-01-15 11:30:00">>, registerTime => <<"2023-12-25 09:30:00">>},
		#{id => 1006, name => <<"孙八"/utf8>>, level => 42, vipLevel => 2, status => <<"离线"/utf8>>,
			lastLogin => <<"2024-01-12 15:20:00">>, registerTime => <<"2024-01-08 11:10:00">>},
		#{id => 1007, name => <<"周九"/utf8>>, level => 48, vipLevel => 3, status => <<"在线"/utf8>>,
			lastLogin => <<"2024-01-15 08:45:00">>, registerTime => <<"2023-12-18 13:25:00">>},
		#{id => 1008, name => <<"吴十"/utf8>>, level => 52, vipLevel => 4, status => <<"离线"/utf8>>,
			lastLogin => <<"2024-01-14 20:15:00">>, registerTime => <<"2023-12-28 17:40:00">>},
		#{id => 1009, name => <<"郑十一"/utf8>>, level => 38, vipLevel => 1, status => <<"在线"/utf8>>,
			lastLogin => <<"2024-01-15 12:00:00">>, registerTime => <<"2024-01-02 09:00:00">>},
		#{id => 1010, name => <<"冯十二"/utf8>>, level => 41, vipLevel => 2, status => <<"离线"/utf8>>,
			lastLogin => <<"2024-01-11 16:40:00">>, registerTime => <<"2023-12-12 11:00:00">>},
		#{id => 1011, name => <<"陈十三"/utf8>>, level => 47, vipLevel => 3, status => <<"在线"/utf8>>,
			lastLogin => <<"2024-01-15 07:20:00">>, registerTime => <<"2023-11-30 15:30:00">>},
		#{id => 1012, name => <<"褚十四"/utf8>>, level => 33, vipLevel => 1, status => <<"离线"/utf8>>,
			lastLogin => <<"2024-01-10 21:05:00">>, registerTime => <<"2024-01-09 10:10:00">>},
		#{id => 1013, name => <<"卫十五"/utf8>>, level => 58, vipLevel => 5, status => <<"在线"/utf8>>,
			lastLogin => <<"2024-01-15 13:15:00">>, registerTime => <<"2023-10-18 08:00:00">>},
		#{id => 1014, name => <<"蒋十六"/utf8>>, level => 44, vipLevel => 2, status => <<"离线"/utf8>>,
			lastLogin => <<"2024-01-09 19:50:00">>, registerTime => <<"2023-12-22 14:00:00">>},
		#{id => 1015, name => <<"ZhangSan">>, level => 40, vipLevel => 2, status => <<"在线"/utf8>>,
			lastLogin => <<"2024-01-15 14:00:00">>, registerTime => <<"2024-01-01 12:00:00">>}
	].

findPlayer(Id) when is_integer(Id) ->
	case lists:search(fun(P) -> maps:get(id, P) =:= Id end, players()) of
		{value, P} -> P;
		false -> undefined
	end;
findPlayer(_) ->
	undefined.

filterByKeyword(List, <<>>) -> List;
filterByKeyword(List, Keyword) ->
	KwLower = string:lowercase(Keyword),
	lists:filter(
		fun(P) ->
			NameLower = string:lowercase(maps:get(name, P)),
			IdBin = integer_to_binary(maps:get(id, P)),
			binary:match(NameLower, KwLower) =/= nomatch
				orelse binary:match(IdBin, Keyword) =/= nomatch
		end,
		List
	).

pageOf(List, Page, PageSize) ->
	Start = (Page - 1) * PageSize + 1,
	lists:sublist(List, Start, PageSize).

bodyMap(WsReq) ->
	Raw = try eWSrv:body(WsReq) of
		Bin when is_binary(Bin) -> Bin;
		List when is_list(List) -> iolist_to_binary(List);
		_ -> <<>>
	catch
		_:_ -> <<>>
	end,
	case Raw of
		<<>> -> {error, <<"Empty request body">>};
		JsonBin ->
			try {ok, json:decode(JsonBin)}
			catch _:_ -> {error, <<"Invalid JSON">>}
			end
	end.

bodyOrQueryId(WsReq) ->
	case bodyMap(WsReq) of
		{ok, #{<<"player_id">> := Id}} ->
			{ok, binInt(Id, 0)};
		_ ->
			Query = eWSrv:mapargs(WsReq),
			case maps:get(<<"player_id">>, Query, undefined) of
				undefined -> {error, <<"缺少 player_id"/utf8>>};
				Id -> {ok, binInt(Id, 0)}
			end
	end.

binInt(<<>>, Default) -> Default;
binInt(B, Default) when is_binary(B) ->
	try binary_to_integer(B) catch _:_ -> Default end;
binInt(I, _) when is_integer(I) -> I;
binInt(_, Default) -> Default.

toStr(B) when is_binary(B) -> B;
toStr(I) when is_integer(I) -> integer_to_binary(I);
toStr(A) when is_atom(A) -> atom_to_binary(A, utf8);
toStr(O) -> unicode:characters_to_binary(io_lib:format("~0p", [O])).
