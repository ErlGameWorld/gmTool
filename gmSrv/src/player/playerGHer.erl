-module(playerGHer).
-export([handle/2]).

-include_lib("eWSrv/include/eWSrv.hrl").

handle(<<"/players">>, WsReq) ->
	% 获取玩家列表 - 从comGHer.erl迁移
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
	Status = maps:get(<<"status">>, Params, <<"all">>),
	
	% 获取玩家数据
	Players = get_players(),
	FilteredPlayers = filter_players(Players, Search, Status),
	PagedPlayers = paginate_list(FilteredPlayers, Page, PageSize),
	Total = length(FilteredPlayers),
	
	Response = #{
		success => true,
		data => PagedPlayers,
		total => Total,
		page => Page,
		pageSize => PageSize
	},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};

handle(<<"/player">>, WsReq) ->
	% 获取玩家列表 - 支持表格格式返回
	QueryParams = maps:from_list(eWSrv:get_args(WsReq)),

	Page = case maps:get(<<"page">>, QueryParams, <<"1">>) of
		<<"">> -> 1;
		P -> binary_to_integer(P)
	end,
	PageSize = case maps:get(<<"pageSize">>, QueryParams, <<"10">>) of
		<<"">> -> 10;
		PS -> binary_to_integer(PS)
	end,
	Keyword = maps:get(<<"keyword">>, QueryParams, <<>>),

	% 模拟玩家数据
	AllPlayers = [
		#{id => 1001, name => <<"张三"/utf8>>, level => 50, vipLevel => 3, status => <<"在线"/utf8>>, lastLogin => <<"2024-01-15 09:00:00">>, registerTime => <<"2023-12-01 10:00:00">>},
		#{id => 1002, name => <<"李四"/utf8>>, level => 45, vipLevel => 2, status => <<"离线"/utf8>>, lastLogin => <<"2024-01-14 18:30:00">>, registerTime => <<"2023-12-05 14:20:00">>},
		#{id => 1003, name => <<"王五"/utf8>>, level => 60, vipLevel => 5, status => <<"在线"/utf8>>, lastLogin => <<"2024-01-15 10:00:00">>, registerTime => <<"2023-11-20 08:15:00">>},
		#{id => 1004, name => <<"赵六"/utf8>>, level => 35, vipLevel => 1, status => <<"离线"/utf8>>, lastLogin => <<"2024-01-13 22:10:00">>, registerTime => <<"2024-01-05 16:45:00">>},
		#{id => 1005, name => <<"钱七"/utf8>>, level => 55, vipLevel => 4, status => <<"在线"/utf8>>, lastLogin => <<"2024-01-15 11:30:00">>, registerTime => <<"2023-12-25 09:30:00">>},
		#{id => 1006, name => <<"孙八"/utf8>>, level => 42, vipLevel => 2, status => <<"离线"/utf8>>, lastLogin => <<"2024-01-12 15:20:00">>, registerTime => <<"2024-01-08 11:10:00">>},
		#{id => 1007, name => <<"周九"/utf8>>, level => 48, vipLevel => 3, status => <<"在线"/utf8>>, lastLogin => <<"2024-01-15 08:45:00">>, registerTime => <<"2023-12-18 13:25:00">>},
		#{id => 1008, name => <<"吴十"/utf8>>, level => 52, vipLevel => 4, status => <<"离线"/utf8>>, lastLogin => <<"2024-01-14 20:15:00">>, registerTime => <<"2023-12-28 17:40:00">>},
		#{id => 1009, name => <<"郑十一"/utf8>>, level => 38, vipLevel => 1, status => <<"在线"/utf8>>, lastLogin => <<"2024-01-15 12:00:00">>, registerTime => <<"2024-01-10 10:30:00">>},
		#{id => 1010, name => <<"王十二"/utf8>>, level => 61, vipLevel => 5, status => <<"离线"/utf8>>, lastLogin => <<"2024-01-13 19:45:00">>, registerTime => <<"2023-11-15 12:20:00">>}
	],

	% 关键词过滤
	FilteredPlayers = case Keyword of
		<<>> -> AllPlayers;
		_ -> lists:filter(fun(Player) ->
			binary:match(maps:get(name, Player), Keyword) =/= nomatch orelse
				integer_to_binary(maps:get(id, Player)) =:= Keyword
		end, AllPlayers)
	end,

	% 分页
	Total = length(FilteredPlayers),
	StartIndex = (Page - 1) * PageSize + 1,
	PagedPlayers = lists:sublist(FilteredPlayers, StartIndex, PageSize),

	% 构建表格格式数据
	% 为每个玩家记录添加key属性
	PagedPlayersWithKey = lists:map(fun(Player) ->
		Player#{key => integer_to_binary(maps:get(id, Player))}
	end, PagedPlayers),

	TableData = #{
		type => <<"table">>,
		columns => [
			#{title => <<"玩家ID"/utf8>>, dataIndex => <<"id">>, key => <<"id">>},
			#{title => <<"玩家名"/utf8>>, dataIndex => <<"name">>, key => <<"name">>},
			#{title => <<"等级"/utf8>>, dataIndex => <<"level">>, key => <<"level">>},
			#{title => <<"VIP等级"/utf8>>, dataIndex => <<"vipLevel">>, key => <<"vipLevel">>},
			#{title => <<"状态"/utf8>>, dataIndex => <<"status">>, key => <<"status">>},
			#{title => <<"最后登录"/utf8>>, dataIndex => <<"lastLogin">>, key => <<"lastLogin">>},
			#{title => <<"注册时间"/utf8>>, dataIndex => <<"registerTime">>, key => <<"registerTime">>}
		],
		dataSource => PagedPlayersWithKey,
		total => Total,
		pagination => true
	},

	Response = #{
		success => true,
		data => TableData,
		pageInfo => #{
			page => Page,
			pageSize => PageSize,
			total => Total,
			totalPages => (Total + PageSize - 1) div PageSize
		}
	},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};

handle(<<"/player/", PlayerId/binary>>, _WsReq) ->
	% 获取单个玩家信息
	Player = #{id => binary_to_integer(PlayerId), name => <<"玩家"/utf8>>, level => 50, vipLevel => 3, lastLogin => <<"2024-01-01 09:00:00">>},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Player)};

handle(<<"/player/update/", PlayerId/binary>>, WsReq) ->
	% 更新玩家信息
	Body = eWSrv:get_body(WsReq),
	case json:decode(Body, [return_maps]) of
		#{<<"name">> := Name, <<"level">> := Level, <<"vipLevel">> := VipLevel} ->
			Response = #{
				<<"success">> => true,
				<<"message">> => <<"玩家信息更新成功"/utf8>>,
				<<"playerId">> => binary_to_integer(PlayerId),
				<<"updatedFields">> => #{<<"name">> => Name, <<"level">> => Level, <<"vipLevel">> => VipLevel}
			},
			{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
		_ ->
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid request format">>})}
	end;

handle(<<"/player/kick/", PlayerId/binary>>, _WsReq) ->
	% 踢出玩家
	Response = #{
		<<"success">> => true,
		<<"message">> => <<"玩家踢出成功">>,
		<<"playerId">> => binary_to_integer(PlayerId),
		<<"action">> => <<"kick">>
	},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};

handle(<<"/player/ban/", PlayerId/binary>>, WsReq) ->
	% 封禁玩家
	Body = eWSrv:get_body(WsReq),
	case json:decode(Body, [return_maps]) of
		#{<<"reason">> := Reason, <<"duration">> := Duration} ->
			Response = #{
				<<"success">> => true,
				<<"message">> => <<"玩家封禁成功">>,
				<<"playerId">> => binary_to_integer(PlayerId),
				<<"action">> => <<"ban">>,
				<<"reason">> => Reason,
				<<"duration">> => Duration
			},
			{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
		_ ->
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid request format">>})}
	end;

handle(_Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.

% 辅助函数 - 从comGHer.erl迁移
get_players() ->
	[
		{1, <<"张三">>, 45, 10000, 3, <<"2023-08-15 14:30:00">>, <<"online">>},
		{2, <<"李四">>, 52, 15000, 5, <<"2023-08-15 13:45:00">>, <<"online">>},
		{3, <<"王五">>, 38, 5000, 1, <<"2023-08-14 20:15:00">>, <<"offline">>},
		{4, <<"赵六">>, 60, 25000, 6, <<"2023-08-15 12:20:00">>, <<"online">>},
		{5, <<"钱七">>, 30, 3000, 0, <<"2023-08-13 18:10:00">>, <<"offline">>},
		{6, <<"孙八">>, 48, 12000, 4, <<"2023-08-15 11:30:00">>, <<"online">>},
		{7, <<"周九">>, 55, 18000, 5, <<"2023-08-15 10:05:00">>, <<"online">>},
		{8, <<"吴十">>, 25, 2000, 0, <<"2023-08-12 09:40:00">>, <<"offline">>},
		{9, <<"郑十一">>, 42, 8000, 2, <<"2023-08-15 09:20:00">>, <<"online">>},
		{10, <<"王十二">>, 58, 20000, 7, <<"2023-08-15 08:15:00">>, <<"online">>},
		{11, <<"李十三">>, 35, 4500, 1, <<"2023-08-14 22:30:00">>, <<"offline">>},
		{12, <<"赵十四">>, 65, 30000, 8, <<"2023-08-15 07:45:00">>, <<"online">>},
		{13, <<"钱十五">>, 28, 2500, 0, <<"2023-08-11 16:20:00">>, <<"offline">>},
		{14, <<"孙十六">>, 50, 14000, 4, <<"2023-08-15 06:30:00">>, <<"online">>},
		{15, <<"周十七">>, 62, 22000, 6, <<"2023-08-15 05:15:00">>, <<"online">>}
	].

filter_players(Players, Search, Status) when is_binary(Search) ->
	filter_players(Players, binary_to_list(Search), Status);
filter_players(Players, Search, Status) ->
	lists:filter(fun({Id, Name, _Level, _Gold, _Vip, _LastLogin, PlayerStatus}) ->
		MatchesSearch = Search =:= "" orelse 
			string:str(integer_to_list(Id), Search) > 0 orelse
			string:str(binary_to_list(Name), Search) > 0,
		MatchesStatus = Status =:= "all" orelse 
			string:equal(binary_to_list(PlayerStatus), Status),
		MatchesSearch andalso MatchesStatus
	end, Players).

paginate_list(List, Page, PageSize) ->
	StartIndex = (Page - 1) * PageSize + 1,
	EndIndex = Page * PageSize,
	lists:sublist(List, StartIndex, EndIndex - StartIndex + 1).