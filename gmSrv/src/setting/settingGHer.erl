-module(settingGHer).
-export([handle/2]).

-include_lib("eWSrv/include/eWSrv.hrl").

handle(<<"/setting">>, _WsReq) ->
	% 获取系统设置 - 从comGHer.erl迁移
	Settings = get_settings(),
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Settings)};

handle(<<"/settings">>, _WsReq) ->
	% 获取系统设置列表 - 从comGHer.erl迁移
	Settings = get_settings(),
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Settings)};

handle(<<"/setting/update">>, WsReq) ->
	% 更新系统设置
	Body = eWSrv:get_body(WsReq),
	case json:decode(Body, [return_maps]) of
		#{<<"serverName">> := ServerName, <<"maxPlayers">> := MaxPlayers, <<"maintenanceMode">> := MaintenanceMode} ->
			Response = #{
				<<"success">> => true,
				<<"message">> => <<"系统设置更新成功"/utf8>>,
				<<"updatedSettings">> => #{<<"serverName">> => ServerName, <<"maxPlayers">> => MaxPlayers, <<"maintenanceMode">> => MaintenanceMode}
			},
			{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
		_ ->
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid request format">>})}
	end;

handle(<<"/settings">>, WsReq) when WsReq#wsReq.method =:= 'PUT' ->
	% 更新系统设置 - 从comGHer.erl迁移
	case eWSrv:get_body(WsReq) of
		{ok, Body} ->
			case json:decode(Body) of
				Settings when is_map(Settings) ->
					% 模拟保存设置
					Response = #{
						success => true,
						message => <<"设置保存成功">>
					},
					{200, [{<<"content-type">>, <<"application/json">>}], json:encode(Response)};
				_ ->
					{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid settings data">>})}
			end;
		_ ->
			{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid request body">>})}
	end;

handle(<<"/settings/test-connection">>, WsReq) when WsReq#wsReq.method =:= 'POST' ->
	% 测试连接 - 从comGHer.erl迁移
	% 模拟连接测试
	Response = #{
		success => true,
		message => <<"连接测试成功">>,
		responseTime => rand:uniform(200) + 50
	},
	{200, [{<<"content-type">>, <<"application/json">>}], json:encode(Response)};

handle(_Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.

% 辅助函数 - 从comGHer.erl迁移
get_settings() ->
	#{
		<<"serverName">> => <<"游戏服务器">>,
		<<"maxPlayers">> => 1000,
		<<"maintenanceMode">> => false,
		<<"language">> => <<"zh-CN">>,
		<<"timezone">> => <<"Asia/Shanghai">>,
		<<"logLevel">> => <<"info">>,
		<<"backupInterval">> => 24,
		<<"autoRestart">> => true,
		<<"notifications">> => true
	}.