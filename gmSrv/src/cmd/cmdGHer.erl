-module(cmdGHer).

-include_lib("eWSrv/include/wsCom.hrl").

-export([handle/2]).

handle(<<"/menus">>, _WsReq) ->
	% 获取GM配置信息 - 返回前端期望的menuGroups格式，包含完整的参数配置
	MenuGroups = [
		#{
			id => <<"cmd_monitor">>,
			name => <<"监控面板12"/utf8>>,
			icon => <<"fa-chart-line">>,
			order => 1,
			menus => [
				#{
					id => <<"cmd_server_status">>,
					name => <<"服务器状态22"/utf8>>,
					description => <<"查看服务器运行状态和性能指标"/utf8>>,
					icon => <<"fa-server">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/server/status">>
					},
					order => 1,
					params => []
				},
				#{
					id => <<"cmd_realtime_monitor">>,
					name => <<"实时监控"/utf8>>,
					description => <<"实时监控服务器性能指标"/utf8>>,
					icon => <<"fa-heartbeat">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/monitor/real-time">>
					},
					order => 2,
					params => []
				},
				#{
					id => <<"cmd_log_viewer">>,
					name => <<"日志查看"/utf8>>,
					description => <<"查看系统日志和操作记录"/utf8>>,
					icon => <<"fa-file-alt">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/logs">>
					},
					order => 3,
					params => [
						#{
							name => <<"page">>,
							label => <<"页码"/utf8>>,
							type => <<"number">>,
							required => false,
							defaultValue => 1,
							validation => #{min => 1, max => 1000},
							description => <<"指定要查看的日志页码，从1开始"/utf8>>
						},
						#{
							name => <<"pageSize">>,
							label => <<"每页条数"/utf8>>,
							type => <<"select">>,
							required => false,
							defaultValue => <<"20">>,
							options => [
								#{value => <<"10">>, label => <<"10条"/utf8>>},
								#{value => <<"20">>, label => <<"20条"/utf8>>},
								#{value => <<"50">>, label => <<"50条"/utf8>>},
								#{value => <<"100">>, label => <<"100条"/utf8>>}
							],
							description => <<"设置每页显示的日志条数，可选10、20、50、100条"/utf8>>
						},
						#{
							name => <<"logType">>,
							label => <<"日志类型"/utf8>>,
							type => <<"checkbox">>,
							required => false,
							options => [
								#{value => <<"system">>, label => <<"系统日志"/utf8>>},
								#{value => <<"player">>, label => <<"玩家日志"/utf8>>},
								#{value => <<"error">>, label => <<"错误日志"/utf8>>}
							],
							defaultValue => [<<"system">>],
							description => <<"选择要查看的日志类型，可多选：系统日志、玩家日志、错误日志"/utf8>>
						}
					]
				}
			]
		},
		#{
			id => <<"cmd_player">>,
			name => <<"玩家管理"/utf8>>,
			icon => <<"fa-users">>,
			order => 2,
			menus => [
				#{
					id => <<"cmd_kick_player">>,
					name => <<"踢出玩家"/utf8>>,
					description => <<"将指定玩家踢出游戏"/utf8>>,
					icon => <<"fa-user-times">>,
					apiConfig => #{
						method => <<"POST">>,
						path => <<"/players/{player_id}/kick">>
					},
					order => 1,
					params => [
						#{
							name => <<"player_id">>,
							label => <<"玩家ID"/utf8>>,
							type => <<"number">>,
							required => true,
							placeholder => <<"请输入玩家ID"/utf8>>,
							validation => #{min => 1, max => 999999},
							description => <<"输入要踢出的玩家ID，必须是有效的玩家ID"/utf8>>
						},
						#{
							name => <<"reason">>,
							label => <<"踢出原因"/utf8>>,
							type => <<"textarea">>,
							required => false,
							placeholder => <<"请输入踢出原因"/utf8>>,
							rows => 3,
							maxLength => 200,
							description => <<"填写踢出玩家的原因，便于后续追溯和管理"/utf8>>
						}
					]
				},
				#{
					id => <<"cmd_ban_player">>,
					name => <<"封禁玩家"/utf8>>,
					description => <<"封禁指定玩家"/utf8>>,
					icon => <<"fa-user-lock">>,
					apiConfig => #{
						method => <<"POST">>,
						path => <<"/players/{player_id}/ban">>
					},
					order => 2,
					params => [
						#{
							name => <<"player_id">>,
							label => <<"玩家ID"/utf8>>,
							type => <<"number">>,
							required => true,
							placeholder => <<"请输入玩家ID"/utf8>>,
							validation => #{min => 1, max => 999999},
							description => <<"输入要封禁的玩家ID，必须是有效的玩家ID"/utf8>>
						},
						#{
							name => <<"duration">>,
							label => <<"封禁时长"/utf8>>,
							type => <<"select">>,
							required => true,
							options => [
								#{value => <<"1h">>, label => <<"1小时"/utf8>>},
								#{value => <<"6h">>, label => <<"6小时"/utf8>>},
								#{value => <<"24h">>, label => <<"24小时"/utf8>>},
								#{value => <<"7d">>, label => <<"7天"/utf8>>},
								#{value => <<"30d">>, label => <<"30天"/utf8>>},
								#{value => <<"permanent">>, label => <<"永久封禁"/utf8>>}
							],
							description => <<"选择封禁时长，从1小时到永久封禁，请根据违规严重程度选择"/utf8>>
						},
						#{
							name => <<"reason">>,
							label => <<"封禁原因"/utf8>>,
							type => <<"textarea">>,
							required => true,
							placeholder => <<"请输入封禁原因"/utf8>>,
							rows => 3,
							maxLength => 500,
							description => <<"详细填写封禁玩家的原因，必须填写，便于后续追溯和管理"/utf8>>
						}
					]
				}
			]
		},
		#{
			id => <<"cmd_item">>,
			name => <<"物品管理"/utf8>>,
			icon => <<"fa-box">>,
			order => 3,
			menus => [
				#{
					id => <<"cmd_add_item">>,
					name => <<"添加物品"/utf8>>,
					description => <<"给指定玩家添加物品"/utf8>>,
					icon => <<"fa-plus-circle">>,
					apiConfig => #{
						method => <<"POST">>,
						path => <<"/players/{player_id}/items">>
					},
					order => 1,
					params => [
						#{
							name => <<"player_id">>,
							label => <<"玩家ID"/utf8>>,
							type => <<"number">>,
							required => true,
							placeholder => <<"请输入玩家ID"/utf8>>,
							validation => #{min => 1, max => 999999},
							description => <<"输入要添加物品的玩家ID，必须是有效的玩家ID"/utf8>>
						},
						#{
							name => <<"item_id">>,
							label => <<"物品ID"/utf8>>,
							type => <<"number">>,
							required => true,
 							placeholder => <<"请输入物品ID"/utf8>>,
							validation => #{min => 1},
							description => <<"输入要添加的物品ID，必须是有效的物品ID"/utf8>>
						},
						#{
							name => <<"quantity">>,
							label => <<"数量"/utf8>>,
							type => <<"number">>,
							required => true,
							defaultValue => 1,
							validation => #{min => 1, max => 9999},
							description => <<"输入要添加的物品数量，范围1-9999"/utf8>>
						},
						#{
							name => <<"bind">>,
							label => <<"是否绑定"/utf8>>,
							type => <<"radio">>,
							required => true,
							options => [
								#{value => <<"true">>, label => <<"绑定"/utf8>>},
								#{value => <<"false">>, label => <<"不绑定"/utf8>>}
							],
							defaultValue => <<"false">>
						}
					]
				}
			]
		},
		#{
			id => <<"cmd_system">>,
			name => <<"系统管理"/utf8>>,
			icon => <<"fa-cogs">>,
			order => 4,
			menus => [
				#{
					id => <<"cmd_broadcast">>,
					name => <<"广播消息"/utf8>>,
					description => <<"向所有在线玩家发送广播消息"/utf8>>,
					icon => <<"fa-bullhorn">>,
					apiConfig => #{
						method => <<"POST">>,
						path => <<"/system/broadcast">>
					},
					order => 1,
					params => [
						#{
							name => <<"message">>,
							label => <<"广播内容"/utf8>>,
							type => <<"textarea">>,
							required => true,
							placeholder => <<"请输入广播内容"/utf8>>,
							rows => 4,
							maxLength => 500
						},
						#{
							name => <<"type">>,
							label => <<"消息类型"/utf8>>,
							type => <<"radio">>,
							required => true,
							options => [
								#{value => <<"normal">>, label => <<"普通消息"/utf8>>},
								#{value => <<"important">>, label => <<"重要消息"/utf8>>},
								#{value => <<"urgent">>, label => <<"紧急消息"/utf8>>}
							],
							defaultValue => <<"normal">>
						},
						#{
							name => <<"channels">>,
							label => <<"广播频道"/utf8>>,
							type => <<"checkbox">>,
							required => false,
							options => [
								#{value => <<"world">>, label => <<"世界频道"/utf8>>},
								#{value => <<"guild">>, label => <<"公会频道"/utf8>>},
								#{value => <<"team">>, label => <<"队伍频道"/utf8>>}
							],
							defaultValue => [<<"world">>]
						}
					]
				}
			]
		},
		#{
			id => <<"cmd_tools">>,
			name => <<"工具面板"/utf8>>,
			icon => <<"fa-tools">>,
			order => 5,
			menus => [
				#{
					id => <<"cmd_system_settings">>,
					name => <<"系统设置"/utf8>>,
					description => <<"系统配置和管理"/utf8>>,
					icon => <<"fa-cog">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/settings">>
					},
					order => 1,
					params => []
				}
			]
		}
	],
	Config = #{menuGroups => MenuGroups},
	validator:reply_json(200, Config);

handle(_Path, _WsReq) ->
	validator:reply_json(404, #{error => <<"Not Found">>}).