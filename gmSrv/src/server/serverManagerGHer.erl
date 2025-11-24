-module(serverManagerGHer).

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

handle(<<"/servers">>, _WsReq) ->
    % 获取服务器列表 - 返回表格格式数据
    Servers = ?SERVER_DATA,
    
    % 转换为表格格式
    TableData = #{
        type => <<"table">>,
        dataSource => Servers,
        columns => [
            #{
                title => <<"ID">>,
                dataIndex => <<"id">>,
                key => <<"id">>,
                width => 60
            },
            #{
                title => <<"服务器名称"/utf8>>,
                dataIndex => <<"name">>,
                key => <<"name">>,
                width => 120
            },
            #{
                title => <<"服务器地址"/utf8>>,
                dataIndex => <<"serverAddress">>,
                key => <<"serverAddress">>,
                width => 120
            },
            #{
                title => <<"端口"/utf8>>,
                dataIndex => <<"port">>,
                key => <<"port">>,
                width => 80
            },
            #{
                title => <<"分组"/utf8>>,
                dataIndex => <<"group">>,
                key => <<"group">>,
                width => 100
            },
            #{
                title => <<"状态"/utf8>>,
                dataIndex => <<"status">>,
                key => <<"status">>,
                width => 100
            },
            #{
                title => <<"描述"/utf8>>,
                dataIndex => <<"description">>,
                key => <<"description">>,
                width => 150
            },
            #{
                title => <<"开放时间"/utf8>>,
                dataIndex => <<"openTime">>,
                key => <<"openTime">>,
                width => 150
            },
            #{
                title => <<"更新时间"/utf8>>,
                dataIndex => <<"updatedAt">>,
                key => <<"updatedAt">>,
                width => 150
            }
        ],
        total => length(Servers),
        pagination => true
    },
    
    Response = #{
        success => true,
        data => TableData
    },
    {200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};

handle(<<"/servers/groups">>, _WsReq) ->
    % 获取服务器分组信息
    Servers = ?SERVER_DATA,
    Groups = lists:usort([maps:get(group, Server) || Server <- Servers]),
    GroupInfo = [#{name => Group, count => length([S || S <- Servers, maps:get(group, S) == Group])} || Group <- Groups],
    {200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(GroupInfo)};

handle(<<"/servers/", ServerId/binary>>, _WsReq) ->
    % 获取单个服务器信息
    Id = binary_to_integer(ServerId),
    case find_server_by_id(Id) of
        false ->
            {404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Server not found">>})};
        Server ->
            {200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Server)}
    end;

handle(<<"/servers">>, WsReq) when WsReq#wsReq.method =:= 'POST' ->
    % 添加服务器
    Body = eWSrv:get_body(WsReq),
    case json:decode(Body, [return_maps]) of
        #{<<"name">> := Name, <<"serverAddress">> := Address, <<"port">> := Port} ->
            NewId = length(?SERVER_DATA) + 1,
            NewServer = #{
                id => NewId,
                name => Name,
                serverAddress => Address,
                port => Port,
                group => maps:get(<<"group">>, Body, <<"默认分组"/utf8>>),
                sortId => maps:get(<<"sortId">>, Body, NewId),
                description => maps:get(<<"description">>, Body, <<"">>),
                status => maps:get(<<"status">>, Body, <<"offline">>),
                openTime => maps:get(<<"openTime">>, Body, <<"">>),
                createdAt => list_to_binary(local_time_to_string(calendar:local_time())),
                updatedAt => list_to_binary(local_time_to_string(calendar:local_time()))
            },
            Response = #{<<"success">> => true, <<"server">> => NewServer},
            {201, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
        _ ->
            {400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid request format">>})}
    end;

handle(<<"/servers/", ServerId/binary>>, WsReq) when WsReq#wsReq.method =:= 'PUT' ->
    % 更新服务器信息
    Id = binary_to_integer(ServerId),
    Body = eWSrv:get_body(WsReq),
    case json:decode(Body, [return_maps]) of
        UpdateData when is_map(UpdateData) ->
            case find_server_by_id(Id) of
                false ->
                    {404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Server not found">>})};
                Server ->
                    UpdatedServer = maps:merge(Server, UpdateData#{updatedAt => list_to_binary(local_time_to_string(calendar:local_time()))}),
                    Response = #{<<"success">> => true, <<"server">> => UpdatedServer},
                    {200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)}
            end;
        _ ->
            {400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid request format">>})}
    end;

handle(<<"/servers/", ServerId/binary>>, _WsReq) when _WsReq#wsReq.method =:= 'DELETE' ->
    % 删除服务器
    Id = binary_to_integer(ServerId),
    case find_server_by_id(Id) of
        false ->
            {404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Server not found">>})};
        _Server ->
            Response = #{<<"success">> => true, <<"message">> => <<"Server deleted successfully">>},
            {200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)}
    end;

handle(_Path, _WsReq) ->
    {404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.

% 辅助函数
find_server_by_id(Id) ->
    lists:keyfind(Id, id, ?SERVER_DATA).

% 时间格式化辅助函数
local_time_to_string({{Year, Month, Day}, {Hour, Minute, Second}}) ->
    io_lib:format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B", [Year, Month, Day, Hour, Minute, Second]).