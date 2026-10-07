-module(gmExServerMgrGHer).

-export([handle/2]).

-include_lib("eWSrv/include/eWSrv.hrl").

% 模拟服务器数据存储
-define(SERVER_DATA, [
    #{
        id => 1,
        name => <<"主服务器"/utf8>>,
        serverAddress => <<"127.0.0.1">>,
        port => 8080,
        group => <<"正式服"/utf8>>,
        sortId => 1,
        description => <<"主要游戏服务器"/utf8>>,
        status => <<"online">>,
        openTime => <<"2024-01-01 00:00:00">>,
        createdAt => <<"2024-01-01 00:00:00">>,
        updatedAt => <<"2024-01-01 00:00:00">>
    },
    #{
        id => 2,
        name => <<"副本服务器"/utf8>>,
        serverAddress => <<"127.0.0.1">>,
        port => 8080,
        group => <<"正式服"/utf8>>,
        sortId => 2,
        description => <<"副本专用服务器"/utf8>>,
        status => <<"online">>,
        openTime => <<"2024-01-01 00:00:00">>,
        createdAt => <<"2024-01-01 00:00:00">>,
        updatedAt => <<"2024-01-01 00:00:00">>
    },
    #{
        id => 3,
        name => <<"测试服务器"/utf8>>,
        serverAddress => <<"127.0.0.1">>,
        port => 8080,
        group => <<"测试服"/utf8>>,
        sortId => 1,
        description => <<"测试环境服务器"/utf8>>,
        status => <<"maintenance">>,
        openTime => <<"2024-01-01 00:00:00">>,
        createdAt => <<"2024-01-01 00:00:00">>,
        updatedAt => <<"2024-01-01 00:00:00">>
    },
    #{
        id => 4,
        name => <<"备用服务器"/utf8>>,
        serverAddress => <<"127.0.0.1">>,
        port => 8080,
        group => <<"备用服"/utf8>>,
        sortId => 1,
        description => <<"备用服务器"/utf8>>,
        status => <<"offline">>,
        openTime => <<"2024-01-01 00:00:00">>,
        createdAt => <<"2024-01-01 00:00:00">>,
        updatedAt => <<"2024-01-01 00:00:00">>
    },
	#{
		id => 5,
		name => <<"备用服务器5"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	},
	#{
		id => 6,
		name => <<"备用服务器6"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	},
	#{
		id => 7,
		name => <<"备用服务器7"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	},
	#{
		id => 8,
		name => <<"备用服务器8"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	},
	#{
		id => 9,
		name => <<"备用服务器9"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	},
	#{
		id => 10,
		name => <<"备用服务器10"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	},
	#{
		id => 11,
		name => <<"备用服务器11"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	},
	#{
		id => 12,
		name => <<"备用服务器12"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	},
	#{
		id => 13,
		name => <<"备用服务器13"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	},
	#{
		id => 14,
		name => <<"备用服务器14"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	},
	#{
		id => 15,
		name => <<"备用服务器15"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	},
	#{
		id => 16,
		name => <<"备用服务器16"/utf8>>,
		serverAddress => <<"127.0.0.1">>,
		port => 8080,
		group => <<"备用服"/utf8>>,
		sortId => 1,
		description => <<"备用服务器"/utf8>>,
		status => <<"offline">>,
		openTime => <<"2024-01-01 00:00:00">>,
		createdAt => <<"2024-01-01 00:00:00">>,
		updatedAt => <<"2024-01-01 00:00:00">>
	}


]).

handle(<<"/servers">>, WsReq) when WsReq#wsReq.method =:= 'POST' ->
	case decodeBody(WsReq) of
		#{<<"name">> := Name, <<"serverAddress">> := Address, <<"port">> := Port} = M ->
			NewId = length(?SERVER_DATA) + 1,
			NewServer = #{
				id => NewId,
				name => Name,
				serverAddress => Address,
				port => Port,
				group => maps:get(<<"group">>, M, <<"默认分组"/utf8>>),
				status => maps:get(<<"status">>, M, <<"offline">>),
				description => maps:get(<<"description">>, M, <<>>)
			},
			{json, NewServer, <<"服务器添加成功"/utf8>>};
		_ ->
			{error, <<"Invalid request format">>}
	end;

handle(<<"/servers">>, WsReq) ->
	Query = eWSrv:mapargs(WsReq),
	All = ?SERVER_DATA,
	Total = length(All),
	Cols = [
		{id, <<"ID">>, #{width => 60}},
		{name, <<"服务器名称"/utf8>>, #{width => 120}},
		{serverAddress, <<"服务器地址"/utf8>>, #{width => 120}},
		{port, <<"端口"/utf8>>, #{width => 80}},
		{group, <<"分组"/utf8>>, #{width => 100}},
		{status, <<"状态"/utf8>>, #{width => 100}},
		{description, <<"描述"/utf8>>, #{width => 150}},
		{openTime, <<"开放时间"/utf8>>, #{width => 150}},
		{updatedAt, <<"更新时间"/utf8>>, #{width => 150}}
	],
	%% 未带 page/pageSize → 全量（顶栏选服要用）；带了才真分页（菜单表格翻页）
	HasPage = maps:is_key(<<"page">>, Query) orelse maps:is_key(<<"pageSize">>, Query),
	case HasPage of
		false ->
			{table, Cols, All, #{total => Total, pagination => false}};
		true ->
			Page0 = binInt(maps:get(<<"page">>, Query, <<"1">>), 1),
			PageSize0 = binInt(maps:get(<<"pageSize">>, Query, <<"10">>), 10),
			PageSize = min(100, max(1, PageSize0)),
			Pages = max(1, (Total + PageSize - 1) div PageSize),
			Page = min(max(1, Page0), Pages),
			Start = (Page - 1) * PageSize + 1,
			Rows = lists:sublist(All, Start, PageSize),
			{table, Cols, Rows, #{
				total => Total,
				page => Page,
				pageSize => PageSize,
				pagination => true
			}}
	end;

handle(<<"/servers/groups">>, _WsReq) ->
	Servers = ?SERVER_DATA,
	Groups = lists:usort([maps:get(group, Server) || Server <- Servers]),
	GroupInfo = [#{name => Group, count => length([S || S <- Servers, maps:get(group, S) == Group])} || Group <- Groups],
	{json, GroupInfo};

handle(<<"/servers/", ServerId/binary>>, WsReq) when WsReq#wsReq.method =:= 'PUT' ->
	case parseId(ServerId) of
		{error, Reason} ->
			{error, 400, Reason};
		{ok, Id} ->
			case findServerById(Id) of
				false ->
					{error, 404, <<"Server not found">>};
				Server ->
					case decodeBody(WsReq) of
						UpdateData when is_map(UpdateData) ->
							Allowed = [
								<<"name">>, <<"serverAddress">>, <<"port">>,
								<<"group">>, <<"status">>, <<"description">>
							],
							Update = maps:with(Allowed, stringifyKeys(UpdateData)),
							Merged = maps:merge(stringifyKeys(Server), Update),
							{json, Merged, <<"服务器更新成功"/utf8>>};
						_ ->
							{error, <<"Invalid request format">>}
					end
			end
	end;

handle(<<"/servers/", ServerId/binary>>, WsReq) when WsReq#wsReq.method =:= 'DELETE' ->
	case parseId(ServerId) of
		{error, Reason} ->
			{error, 400, Reason};
		{ok, Id} ->
			case findServerById(Id) of
				false -> {error, 404, <<"Server not found">>};
				_ -> {msg, <<"Server deleted successfully">>}
			end
	end;

handle(<<"/servers/", ServerId/binary>>, _WsReq) ->
	case parseId(ServerId) of
		{error, Reason} ->
			{error, 400, Reason};
		{ok, Id} ->
			case findServerById(Id) of
				false ->
					{error, 404, <<"Server not found">>};
				Server ->
					{json, Server}
			end
	end;

handle(_Path, _WsReq) ->
	not_found.

parseId(Bin) ->
	try
		{ok, binary_to_integer(Bin)}
	catch
		_:_ -> {error, <<"非法 ID"/utf8>>}
	end.

findServerById(Id) ->
	case lists:search(fun(S) -> maps:get(id, S) =:= Id end, ?SERVER_DATA) of
		{value, S} -> S;
		false -> false
	end.

decodeBody(WsReq) ->
	Raw = try eWSrv:body(WsReq) of
		Bin when is_binary(Bin) -> Bin;
		List when is_list(List) -> iolist_to_binary(List);
		_ -> <<>>
	catch
		_:_ -> <<>>
	end,
	case Raw of
		<<>> -> error;
		JsonBin ->
			try json:decode(JsonBin)
			catch _:_ -> error
			end
	end.

binInt(<<>>, Default) -> Default;
binInt(B, Default) when is_binary(B) ->
	try binary_to_integer(B) catch _:_ -> Default end;
binInt(I, _) when is_integer(I) -> I;
binInt(_, Default) -> Default.

stringifyKeys(Map) when is_map(Map) ->
	maps:fold(fun(K, V, Acc) -> Acc#{toBin(K) => V} end, #{}, Map).

toBin(B) when is_binary(B) -> B;
toBin(A) when is_atom(A) -> atom_to_binary(A, utf8);
toBin(I) when is_integer(I) -> integer_to_binary(I);
toBin(L) when is_list(L) -> unicode:characters_to_binary(L);
toBin(Other) -> list_to_binary(io_lib:format("~0p", [Other])).