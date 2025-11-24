-module(menusGHer).

-include_lib("eWSrv/include/wsCom.hrl").
-include("common.hrl").

-define(menusJson, menusJson).

-on_load(loadMenus/0).

-export([
	menus/0
	, allHer/0
	, handle/2
]).

%% 菜单分组
-define(MenuGroup(Id, Name, Icon, Menus), #{id => Id, name => Name, icon => Icon, menus => Menus}).
%% 游戏服菜单栏
-define(MenuBar(Id, Name, Desc, Icon, Method, Path, Params), #{id => Id, name => Name, description => Desc, icon => Icon, apiConfig => #{method => Method, path => Path}, params => Params}).
%% GM服菜单栏
-define(MenuGMBar(Id, Name, Desc, Icon, Method, Path, Params), #{id => Id, name => Name, description => Desc, icon => Icon, apiConfig => #{method => Method, path => Path, sendToGMSrv => true}, params => Params}).
%% 输入参数
-define(IParam(Name, Label, Type, Required, Options), #{name => Name, label => Label, type => Type, required => Required, options => Options}).
-define(IParam(Name, Label, Type, Required, Options, Description), #{name => Name, label => Label, type => Type, required => Required, options => Options, description => Description}).

%% 参数选项宏定义
-define(SELECT_OPTIONS(Options), #{selectOptions => Options}).
-define(SELECT_OPTION(Value, Label), #{value => Value, label => Label}).

-define(textareaOpts(Placeholder, Rows, MaxLength), #{placeholder => Placeholder, rows => Rows, maxLength => MaxLength}).

%% 玩家管理菜单栏
-define(PlayerMenus(), [
	?MenuBar(<<"mbKickPlayer">>, <<"踢出玩家"/utf8>>, <<"将指定玩家踢出游戏"/utf8>>, <<"fa-user-times">>, <<"POST">>, <<"/players/kick">>,
		[
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入玩家ID"/utf8>>}, <<"输入要踢出的玩家ID，必须是有效的玩家ID"/utf8>>),
			?IParam(<<"reason">>, <<"踢出原因"/utf8>>, <<"textarea">>, false, #{placeholder => <<"请输入踢出原因"/utf8>>, rows => 3, maxLength => 200}, <<"填写踢出玩家的原因，便于后续追溯和管理"/utf8>>)
		]),
	?MenuBar(<<"menu_ban_player">>, <<"封禁玩家"/utf8>>, <<"封禁指定玩家"/utf8>>, <<"fa-user-lock">>, <<"POST">>, <<"/players/{player_id}/ban">>,
		[
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入玩家ID"/utf8>>, min => 1, max => 999999}, <<"输入要封禁的玩家ID，必须是有效的玩家ID"/utf8>>),
			?IParam(<<"duration">>, <<"封禁时长"/utf8>>, <<"select">>, true, #{
				placeholder => <<"请选择封禁时长"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"1h">>, <<"1小时"/utf8>>),
					?SELECT_OPTION(<<"6h">>, <<"6小时"/utf8>>),
					?SELECT_OPTION(<<"24h">>, <<"24小时"/utf8>>),
					?SELECT_OPTION(<<"7d">>, <<"7天"/utf8>>),
					?SELECT_OPTION(<<"30d">>, <<"30天"/utf8>>),
					?SELECT_OPTION(<<"permanent">>, <<"永久封禁"/utf8>>)
				]
			}, <<"选择封禁时长，从1小时到永久封禁，请根据违规严重程度选择"/utf8>>),
			?IParam(<<"reason">>, <<"封禁原因"/utf8>>, <<"textarea">>, true, #{placeholder => <<"请输入封禁原因"/utf8>>, rows => 3, maxLength => 500}, <<"详细填写封禁玩家的原因，必须填写，便于后续追溯和管理"/utf8>>)
		]),
	?MenuBar(<<"menu_unban_player">>, <<"解封玩家"/utf8>>, <<"解除指定玩家的封禁状态"/utf8>>, <<"fa-user-check">>, <<"POST">>, <<"/players/{player_id}/unban">>,
		[
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入玩家ID"/utf8>>}, <<"输入要解封的玩家ID，必须是有效的玩家ID"/utf8>>),
			?IParam(<<"reason">>, <<"解封原因"/utf8>>, <<"textarea">>, false, #{
				placeholder => <<"请输入解封原因"/utf8>>,
				rows => 3,
				maxLength => 200
			}, <<"填写解封玩家的原因，便于后续追溯和管理"/utf8>>)
		]),
	?MenuBar(<<"menu_query_players">>, <<"查询玩家列表"/utf8>>, <<"查询玩家列表，支持分页和关键词搜索"/utf8>>, <<"fa-search">>, <<"GET">>, <<"/player">>,
		[
			?IParam(<<"keyword">>, <<"搜索关键词"/utf8>>, <<"text">>, false, #{placeholder => <<"请输入玩家ID或玩家名"/utf8>>}, <<"输入玩家ID或玩家名进行搜索，支持模糊匹配"/utf8>>),
			?IParam(<<"page">>, <<"页码"/utf8>>, <<"number">>, false, #{
				defaultValue => 1,
				min => 1,
				max => 1000
			}, <<"指定要查看的页码，从1开始，最大1000页"/utf8>>),
			?IParam(<<"pageSize">>, <<"每页条数"/utf8>>, <<"select">>, false, #{
				defaultValue => <<"10">>,
				selectOptions => [
					?SELECT_OPTION(<<"5">>, <<"5条"/utf8>>),
					?SELECT_OPTION(<<"11">>, <<"11条"/utf8>>),
					?SELECT_OPTION(<<"20">>, <<"20条"/utf8>>),
					?SELECT_OPTION(<<"50">>, <<"50条"/utf8>>),
					?SELECT_OPTION(<<"88">>, <<"88条"/utf8>>)
				]
			}, <<"设置每页显示的玩家数量，可选5、11、20、50、88条"/utf8>>)
		]),
	?MenuBar(<<"menu_player_details">>, <<"玩家详情"/utf8>>, <<"查看指定玩家的详细信息"/utf8>>, <<"fa-user-circle">>, <<"GET">>, <<"/players/{player_id}/details">>,
		[
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入玩家ID"/utf8>>}, <<"输入要查看详情的玩家ID，必须是有效的玩家ID"/utf8>>)
		]),
	?MenuBar(<<"menu_player_equipment">>, <<"玩家装备"/utf8>>, <<"查看和修改玩家装备信息"/utf8>>, <<"fa-tshirt">>, <<"GET">>, <<"/players/{player_id}/equipment">>,
		[
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入玩家ID"/utf8>>}, <<"输入要查看装备的玩家ID，必须是有效的玩家ID"/utf8>>)
		]),
	?MenuBar(<<"menu_player_inventory">>, <<"玩家背包"/utf8>>, <<"查看玩家背包物品"/utf8>>, <<"fa-briefcase">>, <<"GET">>, <<"/players/{player_id}/inventory">>,
		[
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入玩家ID"/utf8>>}, <<"输入要查看背包的玩家ID，必须是有效的玩家ID"/utf8>>)
		]),
	?MenuBar(<<"menu_player_skills">>, <<"玩家技能"/utf8>>, <<"查看和修改玩家技能信息"/utf8>>, <<"fa-magic">>, <<"GET">>, <<"/players/{player_id}/skills">>,
		[
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入玩家ID"/utf8>>}, <<"输入要查看技能的玩家ID，必须是有效的玩家ID"/utf8>>)
		]),
	?MenuBar(<<"menu_player_mail">>, <<"玩家邮件"/utf8>>, <<"查看玩家邮件记录"/utf8>>, <<"fa-envelope">>, <<"GET">>, <<"/players/{player_id}/mails">>,
		[
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入玩家ID"/utf8>>}, <<"输入要查看邮件的玩家ID，必须是有效的玩家ID"/utf8>>),
			?IParam(<<"page">>, <<"页码"/utf8>>, <<"number">>, false, #{defaultValue => 1, min => 1, max => 100}, <<"指定要查看的邮件页码，从1开始，最大100页"/utf8>>)
		]),
	?MenuBar(<<"menu_player_currency">>, <<"玩家货币"/utf8>>, <<"查看和修改玩家货币数量"/utf8>>, <<"fa-coins">>, <<"GET">>, <<"/players/{player_id}/currency">>,
		[
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入玩家ID"/utf8>>}, <<"输入要查看货币的玩家ID，必须是有效的玩家ID"/utf8>>)
		]),
	?MenuBar(<<"menu_player_online_status">>, <<"在线状态"/utf8>>, <<"查看玩家在线状态"/utf8>>, <<"fa-signal">>, <<"GET">>, <<"/players/online">>,
		[
			?IParam(<<"keyword">>, <<"搜索关键词"/utf8>>, <<"text">>, false, #{placeholder => <<"请输入玩家ID或玩家名"/utf8>>}, <<"输入玩家ID或玩家名搜索在线玩家，支持模糊匹配"/utf8>>)
		])
]).

%% 物品管理菜单栏
-define(ItemMenus(), []).
%% 邮件管理菜单栏
-define(MailMenus(), []).
%% 服务器设置菜单栏
-define(ServerMenus(), []).
%% 系统监控与日志菜单栏
-define(SystemMenus(), []).
%% 工具面板菜单栏
-define(ToolsMenus(), []).


%% 物品管理菜单宏定义
-define(ITEM_MANAGEMENT_MENUS, [
	?MenuBar(<<"menu_add_item">>, <<"添加物品"/utf8>>, <<"给指定玩家添加物品"/utf8>>, <<"fa-plus-circle">>,
		<<"POST">>, <<"/items/add">>, [
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{
				placeholder => <<"请输入玩家ID"/utf8>>,
				min => 1,
				max => 999999
			}, <<"输入要添加物品的玩家ID，必须是有效的玩家ID"/utf8>>),
			?IParam(<<"item_id">>, <<"物品ID"/utf8>>, <<"number">>, true, #{
				placeholder => <<"请输入物品ID"/utf8>>,
				min => 1
			}, <<"输入要添加的物品ID，必须是有效的物品ID"/utf8>>),
			?IParam(<<"quantity">>, <<"数量"/utf8>>, <<"number">>, true, #{
				defaultValue => 1,
				min => 1,
				max => 9999
			}, <<"输入要添加的物品数量，范围1-9999"/utf8>>),
			?IParam(<<"bind">>, <<"是否绑定"/utf8>>, <<"radio">>, true, #{
				placeholder => <<"请选择绑定状态"/utf8>>,
				defaultValue => <<"false">>,
				selectOptions => [
					?SELECT_OPTION(<<"true">>, <<"绑定"/utf8>>),
					?SELECT_OPTION(<<"false">>, <<"不绑定"/utf8>>)
				]
			}, <<"选择物品是否绑定给玩家，绑定后物品不可交易"/utf8>>)
		]),
	?MenuBar(<<"menu_remove_item">>, <<"删除物品"/utf8>>, <<"删除指定玩家的物品"/utf8>>, <<"fa-minus-circle">>,
		<<"POST">>, <<"/items/remove">>, [
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入玩家ID"/utf8>>}, <<"输入要删除物品的玩家ID，必须是有效的玩家ID"/utf8>>),
			?IParam(<<"item_id">>, <<"物品ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入物品ID"/utf8>>}, <<"输入要删除的物品ID，必须是有效的物品ID"/utf8>>),
			?IParam(<<"quantity">>, <<"数量"/utf8>>, <<"number">>, true, #{
				defaultValue => 1,
				min => 1,
				max => 9999
			}, <<"输入要删除的物品数量，范围1-9999"/utf8>>),
			?IParam(<<"reason">>, <<"删除原因"/utf8>>, <<"textarea">>, true, #{
				placeholder => <<"请输入删除原因"/utf8>>,
				rows => 3,
				maxLength => 200
			}, <<"详细填写删除物品的原因，便于后续追溯和管理"/utf8>>)
		]),
	?MenuBar(<<"menu_item_list">>, <<"物品列表"/utf8>>, <<"查看游戏物品列表"/utf8>>, <<"fa-list">>,
		<<"GET">>, <<"/items">>, [
			?IParam(<<"keyword">>, <<"搜索关键词"/utf8>>, <<"text">>, false, #{placeholder => <<"请输入物品名称或ID"/utf8>>}, <<"输入物品名称或ID进行搜索，支持模糊匹配"/utf8>>),
			?IParam(<<"item_type">>, <<"物品类型"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择物品类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"equipment">>, <<"装备"/utf8>>),
					?SELECT_OPTION(<<"consumable">>, <<"消耗品"/utf8>>),
					?SELECT_OPTION(<<"material">>, <<"材料"/utf8>>),
					?SELECT_OPTION(<<"quest">>, <<"任务物品"/utf8>>)
				]
			}, <<"选择要查看的物品类型，可筛选装备、消耗品、材料、任务物品"/utf8>>),
			?IParam(<<"page">>, <<"页码"/utf8>>, <<"number">>, false, #{
				defaultValue => 1,
				min => 1,
				max => 100
			}, <<"指定要查看的页码，从1开始，最大100页"/utf8>>),
			?IParam(<<"pageSize">>, <<"每页条数"/utf8>>, <<"select">>, false, #{
				defaultValue => <<"20">>,
				selectOptions => [
					?SELECT_OPTION(<<"10">>, <<"10条"/utf8>>),
					?SELECT_OPTION(<<"20">>, <<"20条"/utf8>>),
					?SELECT_OPTION(<<"50">>, <<"50条"/utf8>>)
				]
			}, <<"设置每页显示的物品数量，可选10、20、50条"/utf8>>)
		]),
	?MenuBar(<<"menu_item_details">>, <<"物品详情"/utf8>>, <<"查看物品详细信息"/utf8>>, <<"fa-info-circle">>,
		<<"GET">>, <<"/items/{item_id}/details">>, [
			?IParam(<<"item_id">>, <<"物品ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入物品ID"/utf8>>}, <<"输入要查看详情的物品ID，必须是有效的物品ID"/utf8>>)
		]),
	?MenuBar(<<"menu_item_search">>, <<"物品搜索"/utf8>>, <<"搜索物品信息"/utf8>>, <<"fa-search">>,
		<<"GET">>, <<"/items/search">>, [
			?IParam(<<"name">>, <<"物品名称"/utf8>>, <<"text">>, false, #{placeholder => <<"请输入物品名称"/utf8>>}, <<"输入物品名称进行搜索，支持模糊匹配"/utf8>>),
			?IParam(<<"quality">>, <<"品质"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择品质"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"common">>, <<"普通"/utf8>>),
					?SELECT_OPTION(<<"uncommon">>, <<"优秀"/utf8>>),
					?SELECT_OPTION(<<"rare">>, <<"稀有"/utf8>>),
					?SELECT_OPTION(<<"epic">>, <<"史诗"/utf8>>),
					?SELECT_OPTION(<<"legendary">>, <<"传说"/utf8>>)
				]
			}, <<"选择物品品质进行筛选，可选普通、优秀、稀有、史诗、传说"/utf8>>),
			?IParam(<<"level">>, <<"等级要求"/utf8>>, <<"number">>, false, #{placeholder => <<"请输入等级要求"/utf8>>}, <<"输入物品的等级要求，用于筛选特定等级范围的物品"/utf8>>)
		]),
	?MenuBar(<<"menu_item_batch_add">>, <<"批量添加物品"/utf8>>, <<"批量给多个玩家添加物品"/utf8>>, <<"fa-layer-group">>,
		<<"POST">>, <<"/items/batch-add">>, [
			?IParam(<<"player_ids">>, <<"玩家ID列表"/utf8>>, <<"textarea">>, true, #{
				placeholder => <<"请输入玩家ID，每行一个"/utf8>>,
				rows => 4
			}, <<"输入要添加物品的玩家ID列表，每行一个玩家ID，必须是有效的玩家ID"/utf8>>),
			?IParam(<<"item_id">>, <<"物品ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入物品ID"/utf8>>}, <<"输入要添加的物品ID，必须是有效的物品ID"/utf8>>),
			?IParam(<<"quantity">>, <<"数量"/utf8>>, <<"number">>, true, #{
				defaultValue => 1,
				min => 1,
				max => 9999
			}, <<"输入要添加的物品数量，范围1-9999"/utf8>>)
		])
]).

%% 监控面板菜单宏定义
-define(MONITOR_MENUS, [
	?MenuBar(<<"menu_server_status">>, <<"服务器状态"/utf8>>, <<"查看服务器运行状态和性能指标"/utf8>>, <<"fa-server">>,
		<<"GET">>, <<"/server/status">>, []),
	?MenuBar(<<"menu_realtime_monitor">>, <<"实时监控"/utf8>>, <<"实时监控服务器性能指标"/utf8>>, <<"fa-heartbeat">>,
		<<"GET">>, <<"/monitor/real-time">>, []),
	?MenuBar(<<"menu_log_viewer">>, <<"日志查看"/utf8>>, <<"查看系统日志和操作记录"/utf8>>, <<"fa-file-alt">>,
		<<"GET">>, <<"/logs">>, [
			?IParam(<<"page">>, <<"页码"/utf8>>, <<"number">>, false, #{
				defaultValue => 1,
				min => 1,
				max => 1000
			}),
			?IParam(<<"pageSize">>, <<"每页条数"/utf8>>, <<"select">>, false, #{
				defaultValue => <<"20">>,
				selectOptions => [
					?SELECT_OPTION(<<"10">>, <<"10条"/utf8>>),
					?SELECT_OPTION(<<"20">>, <<"20条"/utf8>>),
					?SELECT_OPTION(<<"50">>, <<"50条"/utf8>>),
					?SELECT_OPTION(<<"100">>, <<"100条"/utf8>>)
				]
			}),
			?IParam(<<"logType">>, <<"日志类型"/utf8>>, <<"checkbox">>, false, #{
				defaultValue => [<<"system">>],
				selectOptions => [
					?SELECT_OPTION(<<"system">>, <<"系统日志"/utf8>>),
					?SELECT_OPTION(<<"player">>, <<"玩家日志"/utf8>>),
					?SELECT_OPTION(<<"error">>, <<"错误日志"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_performance_metrics">>, <<"性能指标"/utf8>>, <<"查看服务器性能指标统计"/utf8>>, <<"fa-chart-line">>,
		<<"GET">>, <<"/monitor/performance">>, [
			?IParam(<<"metric_type">>, <<"指标类型"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择指标类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"cpu">>, <<"CPU使用率"/utf8>>),
					?SELECT_OPTION(<<"memory">>, <<"内存使用"/utf8>>),
					?SELECT_OPTION(<<"network">>, <<"网络流量"/utf8>>),
					?SELECT_OPTION(<<"disk">>, <<"磁盘IO"/utf8>>)
				]
			}),
			?IParam(<<"time_range">>, <<"时间范围"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择时间范围"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"1h">>, <<"1小时"/utf8>>),
					?SELECT_OPTION(<<"6h">>, <<"6小时"/utf8>>),
					?SELECT_OPTION(<<"24h">>, <<"24小时"/utf8>>),
					?SELECT_OPTION(<<"7d">>, <<"7天"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_online_players">>, <<"在线玩家"/utf8>>, <<"查看当前在线玩家统计"/utf8>>, <<"fa-users">>,
		<<"GET">>, <<"/monitor/online-players">>, [
			?IParam(<<"server_id">>, <<"服务器ID"/utf8>>, <<"number">>, false, #{placeholder => <<"请输入服务器ID"/utf8>>})
		]),
	?MenuBar(<<"menu_database_status">>, <<"数据库状态"/utf8>>, <<"查看数据库连接和性能状态"/utf8>>, <<"fa-database">>,
		<<"GET">>, <<"/monitor/database">>, []),
	?MenuBar(<<"menu_alerts">>, <<"告警管理"/utf8>>, <<"查看和管理系统告警信息"/utf8>>, <<"fa-bell">>,
		<<"GET">>, <<"/monitor/alerts">>, [
			?IParam(<<"alert_level">>, <<"告警级别"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择告警级别"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"info">>, <<"信息"/utf8>>),
					?SELECT_OPTION(<<"warning">>, <<"警告"/utf8>>),
					?SELECT_OPTION(<<"error">>, <<"错误"/utf8>>),
					?SELECT_OPTION(<<"critical">>, <<"严重"/utf8>>)
				]
			}),
			?IParam(<<"status">>, <<"状态"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择状态"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"active">>, <<"活跃"/utf8>>),
					?SELECT_OPTION(<<"resolved">>, <<"已解决"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_backup_status">>, <<"备份状态"/utf8>>, <<"查看数据备份状态和日志"/utf8>>, <<"fa-hdd">>,
		<<"GET">>, <<"/monitor/backup">>, []),
	?MenuBar(<<"menu_operation_logs">>, <<"操作日志"/utf8>>, <<"查看GM操作记录"/utf8>>, <<"fa-history">>,
		<<"GET">>, <<"/monitor/operations">>, [
			?IParam(<<"operator">>, <<"操作人"/utf8>>, <<"text">>, false, #{placeholder => <<"请输入操作人名称"/utf8>>}),
			?IParam(<<"start_time">>, <<"开始时间"/utf8>>, <<"datetime">>, false, #{placeholder => <<"请选择开始时间"/utf8>>}),
			?IParam(<<"end_time">>, <<"结束时间"/utf8>>, <<"datetime">>, false, #{placeholder => <<"请选择结束时间"/utf8>>})
		])
]).

%% 服务器管理菜单宏定义
-define(SERVER_MANAGEMENT_MENUS, [
	?MenuGMBar(<<"menu_server_list">>, <<"服务器列表"/utf8>>, <<"查看和管理游戏服务器列表"/utf8>>, <<"fa-list">>,
		<<"GET">>, <<"/servers">>, []),
	?MenuGMBar(<<"menu_add_server">>, <<"增加服务器"/utf8>>, <<"添加新的游戏服务器配置"/utf8>>, <<"fa-plus-circle">>,
		<<"POST">>, <<"/servers">>, [
			?IParam(<<"server_name">>, <<"服务器名称"/utf8>>, <<"text">>, true, #{placeholder => <<"请输入服务器名称"/utf8>>}),
			?IParam(<<"server_ip">>, <<"服务器IP地址"/utf8>>, <<"text">>, true, #{placeholder => <<"请输入服务器IP地址"/utf8>>}),
			?IParam(<<"server_port">>, <<"服务器端口"/utf8>>, <<"number">>, true, #{
				placeholder => <<"请输入服务器端口"/utf8>>,
				min => 1,
				max => 65535
			}),
			?IParam(<<"server_type">>, <<"服务器类型"/utf8>>, <<"select">>, true, #{
				placeholder => <<"请选择服务器类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"game">>, <<"游戏服务器"/utf8>>),
					?SELECT_OPTION(<<"login">>, <<"登录服务器"/utf8>>),
					?SELECT_OPTION(<<"gateway">>, <<"网关服务器"/utf8>>)
				]
			})
		]),
	?MenuGMBar(<<"menu_delete_server">>, <<"删除服务器"/utf8>>, <<"删除指定的游戏服务器配置"/utf8>>, <<"fa-trash">>,
		<<"DELETE">>, <<"/servers/{server_id}">>, [
			?IParam(<<"server_id">>, <<"服务器ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入要删除的服务器ID"/utf8>>})
		]),
	?MenuGMBar(<<"menu_server_status">>, <<"服务器状态"/utf8>>, <<"查看服务器运行状态和性能指标"/utf8>>, <<"fa-heartbeat">>,
		<<"GET">>, <<"/server/status">>, []),
	?MenuGMBar(<<"menu_edit_server">>, <<"编辑服务器"/utf8>>, <<"修改服务器配置信息"/utf8>>, <<"fa-edit">>,
		<<"PUT">>, <<"/servers/{server_id}">>, [
			?IParam(<<"server_id">>, <<"服务器ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入服务器ID"/utf8>>}),
			?IParam(<<"server_name">>, <<"服务器名称"/utf8>>, <<"text">>, false, #{placeholder => <<"请输入服务器名称"/utf8>>}),
			?IParam(<<"server_ip">>, <<"服务器IP地址"/utf8>>, <<"text">>, false, #{placeholder => <<"请输入服务器IP地址"/utf8>>}),
			?IParam(<<"server_port">>, <<"服务器端口"/utf8>>, <<"number">>, false, #{
				placeholder => <<"请输入服务器端口"/utf8>>,
				min => 1,
				max => 65535
			}),
			?IParam(<<"server_type">>, <<"服务器类型"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择服务器类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"game">>, <<"游戏服务器"/utf8>>),
					?SELECT_OPTION(<<"login">>, <<"登录服务器"/utf8>>),
					?SELECT_OPTION(<<"gateway">>, <<"网关服务器"/utf8>>)
				]
			})
		]),
	?MenuGMBar(<<"menu_server_restart">>, <<"重启服务器"/utf8>>, <<"重启指定的游戏服务器"/utf8>>, <<"fa-redo">>,
		<<"POST">>, <<"/servers/{server_id}/restart">>, [
			?IParam(<<"server_id">>, <<"服务器ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入服务器ID"/utf8>>})
		]),
	?MenuGMBar(<<"menu_server_stop">>, <<"停止服务器"/utf8>>, <<"停止指定的游戏服务器"/utf8>>, <<"fa-stop">>,
		<<"POST">>, <<"/servers/{server_id}/stop">>, [
			?IParam(<<"server_id">>, <<"服务器ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入服务器ID"/utf8>>})
		]),
	?MenuGMBar(<<"menu_server_start">>, <<"启动服务器"/utf8>>, <<"启动指定的游戏服务器"/utf8>>, <<"fa-play">>,
		<<"POST">>, <<"/servers/{server_id}/start">>, [
			?IParam(<<"server_id">>, <<"服务器ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入服务器ID"/utf8>>})
		]),
	?MenuGMBar(<<"menu_server_config">>, <<"服务器配置"/utf8>>, <<"查看和修改服务器配置文件"/utf8>>, <<"fa-cog">>,
		<<"GET">>, <<"/servers/{server_id}/config">>, [
			?IParam(<<"server_id">>, <<"服务器ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入服务器ID"/utf8>>})
		]),
	?MenuGMBar(<<"menu_server_logs">>, <<"服务器日志"/utf8>>, <<"查看服务器运行日志"/utf8>>, <<"fa-file-alt">>,
		<<"GET">>, <<"/servers/{server_id}/logs">>, [
			?IParam(<<"server_id">>, <<"服务器ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入服务器ID"/utf8>>}),
			?IParam(<<"log_type">>, <<"日志类型"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择日志类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"system">>, <<"系统日志"/utf8>>),
					?SELECT_OPTION(<<"error">>, <<"错误日志"/utf8>>),
					?SELECT_OPTION(<<"access">>, <<"访问日志"/utf8>>)
				]
			})
		]),
	?MenuGMBar(<<"menu_server_backup">>, <<"服务器备份"/utf8>>, <<"备份服务器数据和配置"/utf8>>, <<"fa-hdd">>,
		<<"POST">>, <<"/servers/{server_id}/backup">>, [
			?IParam(<<"server_id">>, <<"服务器ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入服务器ID"/utf8>>}),
			?IParam(<<"backup_type">>, <<"备份类型"/utf8>>, <<"select">>, true, #{
				placeholder => <<"请选择备份类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"full">>, <<"完整备份"/utf8>>),
					?SELECT_OPTION(<<"incremental">>, <<"增量备份"/utf8>>)
				]
			})
		])
]).

%% 系统管理菜单宏定义
-define(SYSTEM_MANAGEMENT_MENUS, [
	?MenuBar(<<"menu_broadcast">>, <<"广播消息"/utf8>>, <<"向所有在线玩家发送广播消息"/utf8>>, <<"fa-bullhorn">>,
		<<"POST">>, <<"/system/broadcast">>, [
			?IParam(<<"message">>, <<"广播内容"/utf8>>, <<"textarea">>, true, #{
				placeholder => <<"请输入广播内容"/utf8>>,
				rows => 4,
				maxLength => 500
			}),
			?IParam(<<"type">>, <<"消息类型"/utf8>>, <<"radio">>, true, #{
				placeholder => <<"请选择消息类型"/utf8>>,
				defaultValue => <<"normal">>,
				selectOptions => [
					?SELECT_OPTION(<<"normal">>, <<"普通消息"/utf8>>),
					?SELECT_OPTION(<<"important">>, <<"重要消息"/utf8>>),
					?SELECT_OPTION(<<"urgent">>, <<"紧急消息"/utf8>>)
				]
			}),
			?IParam(<<"channels">>, <<"广播频道"/utf8>>, <<"checkbox">>, false, #{
				defaultValue => [<<"world">>],
				selectOptions => [
					?SELECT_OPTION(<<"world">>, <<"世界频道"/utf8>>),
					?SELECT_OPTION(<<"guild">>, <<"公会频道"/utf8>>),
					?SELECT_OPTION(<<"team">>, <<"队伍频道"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_system_config">>, <<"系统配置"/utf8>>, <<"管理系统全局配置参数"/utf8>>, <<"fa-cogs">>,
		<<"GET">>, <<"/system/config">>, []),
	?MenuBar(<<"menu_user_management">>, <<"用户管理"/utf8>>, <<"管理GM平台用户账号"/utf8>>, <<"fa-user-cog">>,
		<<"GET">>, <<"/system/users">>, [
			?IParam(<<"page">>, <<"页码"/utf8>>, <<"number">>, false, #{
				defaultValue => 1,
				min => 1,
				max => 1000
			}),
			?IParam(<<"pageSize">>, <<"每页条数"/utf8>>, <<"select">>, false, #{
				defaultValue => <<"20">>,
				selectOptions => [
					?SELECT_OPTION(<<"10">>, <<"10条"/utf8>>),
					?SELECT_OPTION(<<"20">>, <<"20条"/utf8>>),
					?SELECT_OPTION(<<"50">>, <<"50条"/utf8>>),
					?SELECT_OPTION(<<"100">>, <<"100条"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_role_management">>, <<"角色管理"/utf8>>, <<"管理用户角色和权限"/utf8>>, <<"fa-user-shield">>,
		<<"GET">>, <<"/system/roles">>, []),
	?MenuBar(<<"menu_permission_management">>, <<"权限管理"/utf8>>, <<"配置系统功能权限"/utf8>>, <<"fa-key">>,
		<<"GET">>, <<"/system/permissions">>, []),
	?MenuBar(<<"menu_audit_logs">>, <<"审计日志"/utf8>>, <<"查看系统操作审计记录"/utf8>>, <<"fa-clipboard-list">>,
		<<"GET">>, <<"/system/audit-logs">>, [
			?IParam(<<"operator">>, <<"操作人"/utf8>>, <<"text">>, false, #{placeholder => <<"请输入操作人名称"/utf8>>}),
			?IParam(<<"start_time">>, <<"开始时间"/utf8>>, <<"datetime">>, false, #{placeholder => <<"请选择开始时间"/utf8>>}),
			?IParam(<<"end_time">>, <<"结束时间"/utf8>>, <<"datetime">>, false, #{placeholder => <<"请选择结束时间"/utf8>>}),
			?IParam(<<"action_type">>, <<"操作类型"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择操作类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"login">>, <<"登录"/utf8>>),
					?SELECT_OPTION(<<"logout">>, <<"登出"/utf8>>),
					?SELECT_OPTION(<<"create">>, <<"创建"/utf8>>),
					?SELECT_OPTION(<<"update">>, <<"更新"/utf8>>),
					?SELECT_OPTION(<<"delete">>, <<"删除"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_backup_management">>, <<"备份管理"/utf8>>, <<"管理系统数据备份和恢复"/utf8>>, <<"fa-database">>,
		<<"GET">>, <<"/system/backup">>, []),
	?MenuBar(<<"menu_system_monitor">>, <<"系统监控"/utf8>>, <<"监控系统运行状态和性能"/utf8>>, <<"fa-chart-bar">>,
		<<"GET">>, <<"/system/monitor">>, []),
	?MenuBar(<<"menu_log_management">>, <<"日志管理"/utf8>>, <<"管理系统日志文件"/utf8>>, <<"fa-file-alt">>,
		<<"GET">>, <<"/system/logs">>, [
			?IParam(<<"log_type">>, <<"日志类型"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择日志类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"system">>, <<"系统日志"/utf8>>),
					?SELECT_OPTION(<<"error">>, <<"错误日志"/utf8>>),
					?SELECT_OPTION(<<"access">>, <<"访问日志"/utf8>>),
					?SELECT_OPTION(<<"audit">>, <<"审计日志"/utf8>>)
				]
			}),
			?IParam(<<"date_range">>, <<"日期范围"/utf8>>, <<"daterange">>, false, #{placeholder => <<"请选择日期范围"/utf8>>})
		]),
	?MenuBar(<<"menu_license_management">>, <<"许可证管理"/utf8>>, <<"管理系统许可证信息"/utf8>>, <<"fa-id-card">>,
		<<"GET">>, <<"/system/license">>, [])
]).

%% 工具面板菜单宏定义
-define(TOOLS_MENUS, [
	?MenuBar(<<"menu_icon_viewer">>, <<"查看图标"/utf8>>, <<"预览和选择Ant Design图标，方便在功能中使用"/utf8>>, <<"fa-images">>,
		<<"GET">>, <<"/icons">>, []),
	?MenuBar(<<"menu_system_settings">>, <<"系统设置"/utf8>>, <<"系统配置和管理"/utf8>>, <<"fa-cog">>,
		<<"GET">>, <<"/settings">>, []),
	?MenuBar(<<"menu_param_type_tester">>, <<"参数类型测试"/utf8>>, <<"测试所有GM参数类型的演示功能"/utf8>>, <<"fa-flask">>,
		<<"POST">>, <<"/utils/param-types">>, [
			?IParam(<<"basic_text">>, <<"基础文本"/utf8>>, <<"text">>, false, #{placeholder => <<"请输入文本"/utf8>>}),
			?IParam(<<"limited_number">>, <<"有限制数字(1-100)"/utf8>>, <<"number">>, false, #{
				placeholder => <<"请输入1-100之间的数字"/utf8>>,
				min => 1,
				max => 100
			}),
			?IParam(<<"unlimited_number">>, <<"无限制数字"/utf8>>, <<"number">>, false, #{placeholder => <<"请输入任意数字"/utf8>>}),
			?IParam(<<"basic_textarea">>, <<"多行文本"/utf8>>, <<"textarea">>, false, #{
				placeholder => <<"请输入多行文本"/utf8>>,
				rows => 3
			}),
			?IParam(<<"select_demo">>, <<"下拉选择"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请下拉选择"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"option1">>, <<"选项一"/utf8>>),
					?SELECT_OPTION(<<"option2">>, <<"选项二"/utf8>>),
					?SELECT_OPTION(<<"option3">>, <<"选项三"/utf8>>)
				]
			}),
			?IParam(<<"radio_demo">>, <<"单选按钮"/utf8>>, <<"radio">>, false, #{
				placeholder => <<"请选择"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"yes">>, <<"是"/utf8>>),
					?SELECT_OPTION(<<"no">>, <<"否"/utf8>>),
					?SELECT_OPTION(<<"yes1">>, <<"是"/utf8>>),
					?SELECT_OPTION(<<"no2">>, <<"否"/utf8>>),
					?SELECT_OPTION(<<"yes3">>, <<"是"/utf8>>),
					?SELECT_OPTION(<<"no4">>, <<"否"/utf8>>),
					?SELECT_OPTION(<<"yes5">>, <<"是"/utf8>>),
					?SELECT_OPTION(<<"no6">>, <<"否"/utf8>>),
					?SELECT_OPTION(<<"yes7">>, <<"是"/utf8>>),
					?SELECT_OPTION(<<"no8">>, <<"否"/utf8>>),
					?SELECT_OPTION(<<"yes9">>, <<"是"/utf8>>),
					?SELECT_OPTION(<<"no10">>, <<"否"/utf8>>),
					?SELECT_OPTION(<<"no11">>, <<"否"/utf8>>),
					?SELECT_OPTION(<<"no12">>, <<"否"/utf8>>),
					?SELECT_OPTION(<<"no13">>, <<"否"/utf8>>)
				]
			}),
			?IParam(<<"checkbox_demo">>, <<"多选框"/utf8>>, <<"checkbox">>, false, #{
				defaultValue => [<<"option1">>, <<"option2">>],
				selectOptions => [
					?SELECT_OPTION(<<"option1">>, <<"选项一"/utf8>>),
					?SELECT_OPTION(<<"option2">>, <<"选项二"/utf8>>),
					?SELECT_OPTION(<<"option3">>, <<"选项三"/utf8>>)
				]
			})
		])
]).

%% 游戏世界管理菜单宏定义
-define(GAME_WORLD_MENUS, [
	?MenuBar(<<"menu_game_params">>, <<"游戏参数设置"/utf8>>, <<"设置游戏经验倍率、掉落率等参数"/utf8>>, <<"fa-sliders-h">>,
		<<"POST">>, <<"/game/params">>, [
			?IParam(<<"exp_rate">>, <<"经验倍率"/utf8>>, <<"number">>, false, #{
				placeholder => <<"请输入经验倍率"/utf8>>,
				min => 1,
				max => 100,
				defaultValue => 1
			}),
			?IParam(<<"drop_rate">>, <<"掉落倍率"/utf8>>, <<"number">>, false, #{
				placeholder => <<"请输入掉落倍率"/utf8>>,
				min => 1,
				max => 100,
				defaultValue => 1
			}),
			?IParam(<<"gold_rate">>, <<"金币倍率"/utf8>>, <<"number">>, false, #{
				placeholder => <<"请输入金币倍率"/utf8>>,
				min => 1,
				max => 100,
				defaultValue => 1
			})
		]),
	?MenuBar(<<"menu_announcement">>, <<"公告管理"/utf8>>, <<"发送全服公告和邮件"/utf8>>, <<"fa-bullhorn">>,
		<<"POST">>, <<"/game/announcement">>, [
			?IParam(<<"title">>, <<"公告标题"/utf8>>, <<"text">>, true, #{placeholder => <<"请输入公告标题"/utf8>>}),
			?IParam(<<"content">>, <<"公告内容"/utf8>>, <<"textarea">>, true, #{
				placeholder => <<"请输入公告内容"/utf8>>,
				rows => 4,
				maxLength => 500
			}),
			?IParam(<<"type">>, <<"公告类型"/utf8>>, <<"select">>, true, #{
				placeholder => <<"请选择公告类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"normal">>, <<"普通公告"/utf8>>),
					?SELECT_OPTION(<<"important">>, <<"重要公告"/utf8>>),
					?SELECT_OPTION(<<"urgent">>, <<"紧急公告"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_activity_control">>, <<"活动控制"/utf8>>, <<"开启/关闭游戏活动"/utf8>>, <<"fa-calendar-alt">>,
		<<"POST">>, <<"/game/activity">>, [
			?IParam(<<"activity_id">>, <<"活动ID"/utf8>>, <<"select">>, true, #{
				placeholder => <<"请选择活动"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"double_exp">>, <<"双倍经验"/utf8>>),
					?SELECT_OPTION(<<"double_drop">>, <<"双倍掉落"/utf8>>),
					?SELECT_OPTION(<<"pvp_event">>, <<"PVP活动"/utf8>>),
					?SELECT_OPTION(<<"guild_war">>, <<"公会战"/utf8>>)
				]
			}),
			?IParam(<<"action">>, <<"操作类型"/utf8>>, <<"radio">>, true, #{
				placeholder => <<"请选择操作"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"start">>, <<"开启活动"/utf8>>),
					?SELECT_OPTION(<<"stop">>, <<"关闭活动"/utf8>>)
				]
			})
		])
]).

%% 数据统计与分析菜单宏定义
-define(STATISTICS_MENUS, [
	?MenuBar(<<"menu_player_stats">>, <<"玩家数据统计"/utf8>>, <<"查看玩家注册、在线、消费等数据"/utf8>>, <<"fa-chart-bar">>,
		<<"GET">>, <<"/stats/players">>, [
			?IParam(<<"start_date">>, <<"开始日期"/utf8>>, <<"date">>, false, #{placeholder => <<"请选择开始日期"/utf8>>}),
			?IParam(<<"end_date">>, <<"结束日期"/utf8>>, <<"date">>, false, #{placeholder => <<"请选择结束日期"/utf8>>}),
			?IParam(<<"stat_type">>, <<"统计类型"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择统计类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"register">>, <<"注册统计"/utf8>>),
					?SELECT_OPTION(<<"online">>, <<"在线统计"/utf8>>),
					?SELECT_OPTION(<<"payment">>, <<"消费统计"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_game_stats">>, <<"游戏数据统计"/utf8>>, <<"查看任务完成率、副本通关率等数据"/utf8>>, <<"fa-chart-line">>,
		<<"GET">>, <<"/stats/game">>, [
			?IParam(<<"metric">>, <<"指标类型"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择指标"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"quest_completion">>, <<"任务完成率"/utf8>>),
					?SELECT_OPTION(<<"dungeon_clear">>, <<"副本通关率"/utf8>>),
					?SELECT_OPTION(<<"pvp_win_rate">>, <<"PVP胜率"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_economy_stats">>, <<"经济数据统计"/utf8>>, <<"查看货币流通、物价监控等数据"/utf8>>, <<"fa-coins">>,
		<<"GET">>, <<"/stats/economy">>, [
			?IParam(<<"currency_type">>, <<"货币类型"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择货币类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"gold">>, <<"金币"/utf8>>),
					?SELECT_OPTION(<<"diamond">>, <<"钻石"/utf8>>),
					?SELECT_OPTION(<<"silver">>, <<"银币"/utf8>>)
				]
			})
		])
]).

%% 权限管理菜单宏定义
-define(PERMISSION_MENUS, [
	?MenuBar(<<"menu_role_permission">>, <<"角色权限管理"/utf8>>, <<"设置不同级别GM的权限分配"/utf8>>, <<"fa-user-shield">>,
		<<"POST">>, <<"/permissions/roles">>, [
			?IParam(<<"role_name">>, <<"角色名称"/utf8>>, <<"text">>, true, #{placeholder => <<"请输入角色名称"/utf8>>}),
			?IParam(<<"permissions">>, <<"权限列表"/utf8>>, <<"checkbox">>, true, #{
				placeholder => <<"请选择权限"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"player_manage">>, <<"玩家管理"/utf8>>),
					?SELECT_OPTION(<<"item_manage">>, <<"物品管理"/utf8>>),
					?SELECT_OPTION(<<"server_manage">>, <<"服务器管理"/utf8>>),
					?SELECT_OPTION(<<"system_manage">>, <<"系统管理"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_audit_logs">>, <<"操作审计日志"/utf8>>, <<"查看权限使用记录"/utf8>>, <<"fa-clipboard-list">>,
		<<"GET">>, <<"/permissions/audit">>, [
			?IParam(<<"operator">>, <<"操作人"/utf8>>, <<"text">>, false, #{placeholder => <<"请输入操作人名称"/utf8>>}),
			?IParam(<<"start_time">>, <<"开始时间"/utf8>>, <<"datetime">>, false, #{placeholder => <<"请选择开始时间"/utf8>>}),
			?IParam(<<"end_time">>, <<"结束时间"/utf8>>, <<"datetime">>, false, #{placeholder => <<"请选择结束时间"/utf8>>})
		]),
	?MenuBar(<<"menu_security_settings">>, <<"安全设置"/utf8>>, <<"设置登录IP限制、操作频率限制"/utf8>>, <<"fa-lock">>,
		<<"POST">>, <<"/permissions/security">>, [
			?IParam(<<"ip_restriction">>, <<"IP限制"/utf8>>, <<"textarea">>, false, #{
				placeholder => <<"请输入允许的IP地址，每行一个"/utf8>>,
				rows => 3
			}),
			?IParam(<<"operation_limit">>, <<"操作频率限制"/utf8>>, <<"number">>, false, #{
				placeholder => <<"请输入每分钟最大操作次数"/utf8>>,
				min => 1,
				max => 1000
			})
		])
]).

%% 客服支持菜单宏定义
-define(SUPPORT_MENUS, [
	?MenuBar(<<"menu_ticket_system">>, <<"工单系统"/utf8>>, <<"处理玩家问题工单"/utf8>>, <<"fa-ticket-alt">>,
		<<"GET">>, <<"/support/tickets">>, [
			?IParam(<<"status">>, <<"工单状态"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择工单状态"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"open">>, <<"待处理"/utf8>>),
					?SELECT_OPTION(<<"in_progress">>, <<"处理中"/utf8>>),
					?SELECT_OPTION(<<"resolved">>, <<"已解决"/utf8>>),
					?SELECT_OPTION(<<"closed">>, <<"已关闭"/utf8>>)
				]
			}),
			?IParam(<<"priority">>, <<"优先级"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择优先级"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"low">>, <<"低"/utf8>>),
					?SELECT_OPTION(<<"medium">>, <<"中"/utf8>>),
					?SELECT_OPTION(<<"high">>, <<"高"/utf8>>),
					?SELECT_OPTION(<<"urgent">>, <<"紧急"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_complaint_handling">>, <<"投诉处理"/utf8>>, <<"处理玩家投诉记录"/utf8>>, <<"fa-exclamation-triangle">>,
		<<"GET">>, <<"/support/complaints">>, [
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, false, #{placeholder => <<"请输入玩家ID"/utf8>>}),
			?IParam(<<"complaint_type">>, <<"投诉类型"/utf8>>, <<"select">>, false, #{
				placeholder => <<"请选择投诉类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"cheating">>, <<"作弊投诉"/utf8>>),
					?SELECT_OPTION(<<"harassment">>, <<"骚扰投诉"/utf8>>),
					?SELECT_OPTION(<<"bug_report">>, <<"BUG报告"/utf8>>),
					?SELECT_OPTION(<<"service_issue">>, <<"服务问题"/utf8>>)
				]
			})
		]),
	?MenuBar(<<"menu_compensation">>, <<"补偿发放"/utf8>>, <<"管理玩家补偿发放"/utf8>>, <<"fa-gift">>,
		<<"POST">>, <<"/support/compensation">>, [
			?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true, #{placeholder => <<"请输入玩家ID"/utf8>>}),
			?IParam(<<"compensation_type">>, <<"补偿类型"/utf8>>, <<"select">>, true, #{
				placeholder => <<"请选择补偿类型"/utf8>>,
				selectOptions => [
					?SELECT_OPTION(<<"item">>, <<"物品补偿"/utf8>>),
					?SELECT_OPTION(<<"currency">>, <<"货币补偿"/utf8>>),
					?SELECT_OPTION(<<"vip">>, <<"VIP补偿"/utf8>>)
				]
			}),
			?IParam(<<"reason">>, <<"补偿原因"/utf8>>, <<"textarea">>, true, #{
				placeholder => <<"请输入补偿原因"/utf8>>,
				rows => 3,
				maxLength => 200
			})
		])
]).


handle(<<"/menus">>, _WsReq) ->
	{ok, [{<<"Content-Type">>, <<"application/json">>}], ?menusJson:json()};

handle(_Path, _WsReq) ->
	validator:reply_json(404, #{error => <<"Not Found">>}).


loadMenus() ->
	Menus = menus(),
	JsonBin = iolist_to_binary(json:encode(Menus)),
	ModName = ?menusJson,
	Forms = [
		{attribute, 1, module, ModName},
		{attribute, 2, export, [{json, 0}]},
		{function, 3, json, 0, [{clause, 3, [], [], [erl_parse:abstract(JsonBin)]}]}
	],
	{ok, ModName, BeamBin} = compile:forms(Forms, [binary]),
	{module, ModName} = code:load_binary(ModName, "nofile", BeamBin),
	gmKvsToBeam:load(?gmHerTable, allHer()),
	ok.

allHer() ->
	Menus = menus(),
	AllBPath = [
		begin
			Path = maps:get(path, maps:get(apiConfig, OneMenus, #{}), <<>>),
			<<_:8, LPath/binary>> = Path,
			[HerStr | _] = binary:split(LPath, <<"/">>),
			HerStr
		end || OneMenusGroups <- maps:get(menuGroups, Menus, []), OneMenus <- maps:get(menus, OneMenusGroups, [])
	],
	AllMods = [{OneMod, binary_to_atom(<<OneMod/binary, "GHer">>)} || OneMod <- lists:usort(AllBPath), OneMod /= <<>>],
	% 手动添加服务器管理相关的模块注册
	ManualMods = [
		{<<"server">>, serverGHer},        % 服务器状态和列表
		{<<"servers">>, serverManagerGHer} % 服务器管理（添加、删除等）
	],
	[{<<>>, comGHer}, {<<"menus">>, menusGHer}, {<<"auth">>, authGHer}, {<<"assets">>, comGHer}] ++ AllMods ++ ManualMods.


menus() ->
	% 获取GM配置信息 - 返回前端期望的menuGroups格式，包含完整的参数配置
	MenuGroups = [
		?MenuGroup(<<"mgPlayer">>, <<"玩家管理"/utf8>>, <<"fa-users">>, ?PlayerMenus()),
		?MenuGroup(<<"mgItem">>, <<"物品管理"/utf8>>, <<"fa-gift">>, ?ItemMenus()),
		?MenuGroup(<<"mgMail">>, <<"邮件管理"/utf8>>, <<"fa-gift">>, ?MailMenus()),
		?MenuGroup(<<"mgServer">>, <<"服务器设置"/utf8>>, <<"fa-gift">>, ?ServerMenus()),
		?MenuGroup(<<"mgSystem">>, <<"系统监控与日志"/utf8>>, <<"fa-gift">>, ?SystemMenus()),
		?MenuGroup(<<"mgTools">>, <<"工具面板"/utf8>>, <<"fa-gift">>, ?ToolsMenus()),

		#{
			id => <<"menu_player">>, name => <<"活动管理"/utf8>>, icon => <<"fa-users">>,
			menus => [
				#{
					id => <<"menu_kick_player">>, name => <<"踢出玩家"/utf8>>, description => <<"将指定玩家踢出游戏"/utf8>>, icon => <<"fa-user-times">>,
					apiConfig => #{method => <<"POST">>, path => <<"/players/kick/{player_id}">>},
					params => [
						#{
							name => <<"player_id">>, label => <<"玩家ID"/utf8>>,
							type => <<"number">>,
							required => true,
							placeholder => <<"请输入玩家ID"/utf8>>
						},
						#{
							name => <<"reason">>, label => <<"踢出原因"/utf8>>,
							type => <<"textarea">>,
							required => false,
							placeholder => <<"请输入踢出原因"/utf8>>,
							rows => 3,
							maxLength => 200
						}
					]
				},
				#{
					id => <<"menu_ban_player">>,
					name => <<"封禁玩家"/utf8>>,
					description => <<"封禁指定玩家"/utf8>>,
					icon => <<"fa-user-lock">>,
					apiConfig => #{
						method => <<"POST">>,
						path => <<"/players/{player_id}/ban">>
					},
					params => [
						#{
							name => <<"player_id">>,
							label => <<"玩家ID"/utf8>>,
							type => <<"number">>,
							required => true,
							placeholder => <<"请输入玩家ID"/utf8>>,
							options => #{
								min => 1,
								max => 999999
							}
						},
						#{
							name => <<"duration">>,
							label => <<"封禁时长"/utf8>>,
							type => <<"select">>,
							required => true,
							placeholder => <<"请选择封禁时长"/utf8>>,
							options => #{
								selectOptions => [
									#{value => <<"1h">>, label => <<"1小时"/utf8>>},
									#{value => <<"6h">>, label => <<"6小时"/utf8>>},
									#{value => <<"24h">>, label => <<"24小时"/utf8>>},
									#{value => <<"7d">>, label => <<"7天"/utf8>>},
									#{value => <<"30d">>, label => <<"30天"/utf8>>},
									#{value => <<"permanent">>, label => <<"永久封禁"/utf8>>}
								]
							}
						},
						#{
							name => <<"reason">>,
							label => <<"封禁原因"/utf8>>,
							type => <<"textarea">>,
							required => true,
							placeholder => <<"请输入封禁原因"/utf8>>,
							rows => 3,
							maxLength => 500
						}
					]
				},
				#{
					id => <<"menu_query_players">>,
					name => <<"查询玩家列表"/utf8>>,
					description => <<"查询玩家列表，支持分页和关键词搜索"/utf8>>,
					icon => <<"fa-search">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/player">>
					},
					params => [
						#{
							name => <<"keyword">>,
							label => <<"搜索关键词"/utf8>>,
							type => <<"text">>,
							required => false,
							placeholder => <<"请输入玩家ID或玩家名"/utf8>>
						},
						#{
							name => <<"page">>,
							label => <<"页码"/utf8>>,
							type => <<"number">>,
							required => false,
							placeholder => <<"请输入页码"/utf8>>,
							options => #{
								defaultValue => 1,
								min => 1,
								max => 1000
							}
						},
						#{
							name => <<"pageSize">>,
							label => <<"每页条数"/utf8>>,
							type => <<"select">>,
							required => false,
							placeholder => <<"请选择每页条数"/utf8>>,
							options => #{
								defaultValue => <<"10">>,
								selectOptions => [
									#{value => <<"5">>, label => <<"5条"/utf8>>},
									#{value => <<"11">>, label => <<"11条"/utf8>>},
									#{value => <<"20">>, label => <<"20条"/utf8>>},
									#{value => <<"50">>, label => <<"50条"/utf8>>},
									#{value => <<"88">>, label => <<"88条"/utf8>>}
								]
							}
						}
					]
				}
			]
		},

		#{
			id => <<"menu_item">>,
			name => <<"物品管理"/utf8>>,
			icon => <<"fa-gift">>,
			menus => [
				#{
					id => <<"menu_add_item">>,
					name => <<"添加物品"/utf8>>,
					description => <<"给指定玩家添加物品"/utf8>>,
					icon => <<"fa-plus-circle">>,
					apiConfig => #{
						method => <<"POST">>,
						path => <<"/items/add">>
					},
					params => [
						#{
							name => <<"player_id">>,
							label => <<"玩家ID"/utf8>>,
							type => <<"number">>,
							required => true,
							placeholder => <<"请输入玩家ID"/utf8>>,
							options => #{
								min => 1,
								max => 999999
							}
						},
						#{
							name => <<"item_id">>,
							label => <<"物品ID"/utf8>>,
							type => <<"number">>,
							required => true,
							placeholder => <<"请输入物品ID"/utf8>>,
							options => #{
								min => 1
							}
						},
						#{
							name => <<"quantity">>,
							label => <<"数量"/utf8>>,
							type => <<"number">>,
							required => true,
							placeholder => <<"请输入数量"/utf8>>,
							options => #{
								defaultValue => 1,
								min => 1,
								max => 9999
							}
						},
						#{
							name => <<"bind">>,
							label => <<"是否绑定"/utf8>>,
							type => <<"radio">>,
							required => true,
							placeholder => <<"请选择绑定状态"/utf8>>,
							options => #{
								defaultValue => <<"false">>,
								selectOptions => [
									#{value => <<"true">>, label => <<"绑定"/utf8>>},
									#{value => <<"false">>, label => <<"不绑定"/utf8>>}
								]
							}
						}
					]
				}
			]
		},

		#{
			id => <<"menu_monitor">>,
			name => <<"监控面板"/utf8>>,
			icon => <<"fa-chart-line">>,
			menus => [
				#{
					id => <<"menu_server_status">>,
					name => <<"服务器状态22"/utf8>>,
					description => <<"查看服务器运行状态和性能指标"/utf8>>,
					icon => <<"fa-server">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/server/status">>
					},
					params => []
				},
				#{
					id => <<"menu_realtime_monitor">>,
					name => <<"实时监控"/utf8>>,
					description => <<"实时监控服务器性能指标"/utf8>>,
					icon => <<"fa-heartbeat">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/monitor/real-time">>
					},
					params => []
				},
				#{
					id => <<"menu_log_viewer">>,
					name => <<"日志查看"/utf8>>,
					description => <<"查看系统日志和操作记录"/utf8>>,
					icon => <<"fa-file-alt">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/logs">>
					},
					params => [
						#{
							name => <<"page">>,
							label => <<"页码"/utf8>>,
							type => <<"number">>,
							required => false,
							placeholder => <<"请输入页码"/utf8>>,
							options => #{
								defaultValue => 1,
								min => 1,
								max => 1000
							}
						},
						#{
							name => <<"pageSize">>,
							label => <<"每页条数"/utf8>>,
							type => <<"select">>,
							required => false,
							placeholder => <<"请选择每页条数"/utf8>>,
							options => #{
								defaultValue => <<"20">>,
								selectOptions => [
									#{value => <<"10">>, label => <<"10条"/utf8>>},
									#{value => <<"20">>, label => <<"20条"/utf8>>},
									#{value => <<"50">>, label => <<"50条"/utf8>>},
									#{value => <<"100">>, label => <<"100条"/utf8>>}
								]
							}
						},
						#{
							name => <<"logType">>,
							label => <<"日志类型"/utf8>>,
							type => <<"checkbox">>,
							required => false,
							placeholder => <<"请选择日志类型"/utf8>>,
							options => #{
								defaultValue => [<<"system">>],
								selectOptions => [
									#{value => <<"system">>, label => <<"系统日志"/utf8>>},
									#{value => <<"player">>, label => <<"玩家日志"/utf8>>},
									#{value => <<"error">>, label => <<"错误日志"/utf8>>}
								]
							}
						}
					]
				}
			]
		},


		#{
			id => <<"menu_server">>,
			name => <<"服务器管理"/utf8>>,
			icon => <<"fa-server">>,
			menus => [
				#{
					id => <<"menu_server_list">>,
					name => <<"服务器列表"/utf8>>,
					description => <<"查看和管理游戏服务器列表"/utf8>>,
					icon => <<"fa-list">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/servers">>,
						sendToGMSrv => true
					},
					params => []
				},
				#{
					id => <<"menu_add_server">>,
					name => <<"增加服务器"/utf8>>,
					description => <<"添加新的游戏服务器配置"/utf8>>,
					icon => <<"fa-plus-circle">>,
					apiConfig => #{
						method => <<"POST">>,
						path => <<"/servers">>,
						sendToGMSrv => true
					},
					params => [
						#{
							name => <<"server_name">>,
							label => <<"服务器名称"/utf8>>,
							type => <<"text">>,
							required => true,
							placeholder => <<"请输入服务器名称"/utf8>>
						},
						#{
							name => <<"server_ip">>,
							label => <<"服务器IP地址"/utf8>>,
							type => <<"text">>,
							required => true,
							placeholder => <<"请输入服务器IP地址"/utf8>>
						},
						#{
							name => <<"server_port">>,
							label => <<"服务器端口"/utf8>>,
							type => <<"number">>,
							required => true,
							placeholder => <<"请输入服务器端口"/utf8>>,
							options => #{
								min => 1,
								max => 65535
							}
						},
						#{
							name => <<"server_type">>,
							label => <<"服务器类型"/utf8>>,
							type => <<"select">>,
							required => true,
							placeholder => <<"请选择服务器类型"/utf8>>,
							options => #{
								selectOptions => [
									#{value => <<"game">>, label => <<"游戏服务器"/utf8>>},
									#{value => <<"login">>, label => <<"登录服务器"/utf8>>},
									#{value => <<"gateway">>, label => <<"网关服务器"/utf8>>}
								]
							}
						}
					]
				},
				#{
					id => <<"menu_delete_server">>,
					name => <<"删除服务器"/utf8>>,
					description => <<"删除指定的游戏服务器配置"/utf8>>,
					icon => <<"fa-trash">>,
					apiConfig => #{
						method => <<"DELETE">>,
						path => <<"/servers/{server_id}">>,
						sendToGMSrv => true
					},
					params => [
						#{
							name => <<"server_id">>,
							label => <<"服务器ID"/utf8>>,
							type => <<"number">>,
							required => true,
							placeholder => <<"请输入要删除的服务器ID"/utf8>>
						}
					]
				},
				#{
					id => <<"menu_server_status">>,
					name => <<"服务器状态"/utf8>>,
					description => <<"查看服务器运行状态和性能指标"/utf8>>,
					icon => <<"fa-heartbeat">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/server/status">>,
						sendToGMSrv => true
					},
					params => []
				}
			]
		},

		#{
			id => <<"menu_system">>,
			name => <<"系统管理"/utf8>>,
			icon => <<"fa-cogs">>,
			menus => [
				#{
					id => <<"menu_broadcast">>,
					name => <<"广播消息"/utf8>>,
					description => <<"向所有在线玩家发送广播消息"/utf8>>,
					icon => <<"fa-bullhorn">>,
					apiConfig => #{
						method => <<"POST">>,
						path => <<"/system/broadcast">>
					},
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
							placeholder => <<"请选择消息类型"/utf8>>,
							options => #{
								defaultValue => <<"normal">>,
								selectOptions => [
									#{value => <<"normal">>, label => <<"普通消息"/utf8>>},
									#{value => <<"important">>, label => <<"重要消息"/utf8>>},
									#{value => <<"urgent">>, label => <<"紧急消息"/utf8>>}
								]
							}
						},
						#{
							name => <<"channels">>,
							label => <<"广播频道"/utf8>>,
							type => <<"checkbox">>,
							required => false,
							placeholder => <<"请选择广播频道"/utf8>>,
							options => #{
								defaultValue => [<<"world">>],
								selectOptions => [
									#{value => <<"world">>, label => <<"世界频道"/utf8>>},
									#{value => <<"guild">>, label => <<"公会频道"/utf8>>},
									#{value => <<"team">>, label => <<"队伍频道"/utf8>>}
								]
							}
						}
					]
				}
			]
		},
		#{
			id => <<"menu_tools">>,
			name => <<"工具面板"/utf8>>,
			icon => <<"fa-tools">>,
			menus => [
				#{
					id => <<"menu_icon_viewer">>,
					name => <<"查看图标"/utf8>>,
					description => <<"预览和选择Ant Design图标，方便在功能中使用"/utf8>>,
					icon => <<"fa-images">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/icons">>
					},
					params => []
				},
				#{
					id => <<"menu_system_settings">>,
					name => <<"系统设置"/utf8>>,
					description => <<"系统配置和管理"/utf8>>,
					icon => <<"fa-cog">>,
					apiConfig => #{
						method => <<"GET">>,
						path => <<"/settings">>
					},
					params => []
				},
				#{
					id => <<"menu_param_type_tester">>,
					name => <<"参数类型测试"/utf8>>,
					description => <<"测试所有GM参数类型的演示功能"/utf8>>,
					icon => <<"fa-flask">>,
					apiConfig => #{
						method => <<"POST">>,
						path => <<"/utils/param-types">>
					},
					params => [
						#{
							name => <<"basic_text">>,
							label => <<"基础文本"/utf8>>,
							type => <<"text">>,
							required => false,
							placeholder => <<"请输入文本"/utf8>>,
							options => #{}
						},
						#{
							name => <<"limited_number">>,
							label => <<"有限制数字(1-100)"/utf8>>,
							type => <<"number">>,
							required => false,
							placeholder => <<"请输入1-100之间的数字"/utf8>>,
							options => #{
								min => 1,
								max => 100
							}
						},
						#{
							name => <<"unlimited_number">>,
							label => <<"无限制数字"/utf8>>,
							type => <<"number">>,
							required => false,
							placeholder => <<"请输入任意数字"/utf8>>,
							options => #{}
						},
						#{
							name => <<"basic_textarea">>,
							label => <<"多行文本"/utf8>>,
							type => <<"textarea">>,
							required => false,
							placeholder => <<"请输入多行文本"/utf8>>,
							options => #{
								rows => 3
							}
						},
						#{
							name => <<"select_demo">>,
							label => <<"下拉选择"/utf8>>,
							type => <<"select">>,
							required => false,
							placeholder => <<"请下拉选择"/utf8>>,
							options => #{
								selectOptions => [
									#{value => <<"option1">>, label => <<"选项一"/utf8>>},
									#{value => <<"option2">>, label => <<"选项二"/utf8>>},
									#{value => <<"option3">>, label => <<"选项三"/utf8>>}
								]
							}
						},
						#{
							name => <<"radio_demo">>,
							label => <<"单选按钮"/utf8>>,
							type => <<"radio">>,
							required => false,
							placeholder => <<"请选择"/utf8>>,
							options => #{
								selectOptions => [
									#{value => <<"yes">>, label => <<"是"/utf8>>},
									#{value => <<"no">>, label => <<"否"/utf8>>},
									#{value => <<"yes1">>, label => <<"是"/utf8>>},
									#{value => <<"no2">>, label => <<"否"/utf8>>},
									#{value => <<"yes3">>, label => <<"是"/utf8>>},
									#{value => <<"no4">>, label => <<"否"/utf8>>},
									#{value => <<"yes5">>, label => <<"是"/utf8>>},
									#{value => <<"no6">>, label => <<"否"/utf8>>},
									#{value => <<"yes7">>, label => <<"是"/utf8>>},
									#{value => <<"no8">>, label => <<"否"/utf8>>},
									#{value => <<"yes9">>, label => <<"是"/utf8>>},
									#{value => <<"no10">>, label => <<"否"/utf8>>},
									#{value => <<"no11">>, label => <<"否"/utf8>>},
									#{value => <<"no12">>, label => <<"否"/utf8>>},
									#{value => <<"no13">>, label => <<"否"/utf8>>}
								]
							}
						},
						#{
							name => <<"checkbox_demo">>,
							label => <<"多选框"/utf8>>,
							type => <<"checkbox">>,
							required => false,
							placeholder => <<"请选择功能"/utf8>>,
							options => #{
								selectOptions => [
									#{value => <<"feature1">>, label => <<"功能一"/utf8>>},
									#{value => <<"feature2">>, label => <<"功能二"/utf8>>},
									#{value => <<"feature3">>, label => <<"功能三"/utf8>>},
									#{value => <<"feature4">>, label => <<"功能一"/utf8>>},
									#{value => <<"feature5">>, label => <<"功能二"/utf8>>},
									#{value => <<"feature6">>, label => <<"功能三"/utf8>>},
									#{value => <<"feature7">>, label => <<"功能一"/utf8>>},
									#{value => <<"feature8">>, label => <<"功能二"/utf8>>},
									#{value => <<"feature9">>, label => <<"功能三"/utf8>>},
									#{value => <<"feature10">>, label => <<"功能一"/utf8>>},
									#{value => <<"feature11">>, label => <<"功能二"/utf8>>},
									#{value => <<"feature12">>, label => <<"功能三"/utf8>>},
									#{value => <<"feature13">>, label => <<"功能一"/utf8>>},
									#{value => <<"feature14">>, label => <<"功能二"/utf8>>},
									#{value => <<"feature15">>, label => <<"功能三"/utf8>>}

								]
							}
						},
						#{
							name => <<"switch_demo">>,
							label => <<"开关切换"/utf8>>,
							type => <<"switch">>,
							required => false,
							placeholder => <<"请切换开关状态"/utf8>>,
							options => #{
								defaultValue => true
							}
						},
						#{
							name => <<"rate_demo">>,
							label => <<"评分组件"/utf8>>,
							type => <<"rate">>,
							required => false,
							placeholder => <<"请评分"/utf8>>,
							options => #{
								defaultValue => 3,
								max => 5
							}
						},
						#{
							name => <<"date_demo">>,
							label => <<"日期选择"/utf8>>,
							type => <<"date">>,
							required => false,
							placeholder => <<"请选择日期"/utf8>>,
							options => #{}
						},
						#{
							name => <<"datetime_demo">>,
							label => <<"日期时间"/utf8>>,
							type => <<"datetime">>,
							required => false,
							placeholder => <<"请选择日期时间"/utf8>>,
							options => #{}
						},
						#{
							name => <<"time_demo">>,
							label => <<"时间选择"/utf8>>,
							type => <<"time">>,
							required => false,
							placeholder => <<"请选择时间"/utf8>>,
							options => #{}
						},
						#{
							name => <<"date_range_demo">>,
							label => <<"日期范围"/utf8>>,
							type => <<"date-range">>,
							required => false,
							placeholder => <<"请选择日期范围"/utf8>>,
							options => #{}
						},
						#{
							name => <<"datetime_range_demo">>,
							label => <<"日期时间范围"/utf8>>,
							type => <<"datetime-range">>,
							required => false,
							placeholder => <<"请选择日期时间范围"/utf8>>,
							options => #{}
						},
						#{
							name => <<"slider_demo">>,
							label => <<"滑块选择"/utf8>>,
							type => <<"slider">>,
							required => false,
							placeholder => <<"请滑块选择"/utf8>>,
							options => #{
								min => 0,
								max => 100,
								defaultValue => 50
							}
						},
						#{
							name => <<"color_demo">>,
							label => <<"颜色选择"/utf8>>,
							type => <<"color">>,
							required => false,
							placeholder => <<"请选择颜色"/utf8>>,
							options => #{
								defaultValue => <<"#1890ff">>
							}
						},
						#{
							name => <<"email_demo">>,
							label => <<"邮箱输入"/utf8>>,
							type => <<"email">>,
							required => false,
							placeholder => <<"请输入邮箱地址"/utf8>>,
							options => #{}
						},
						#{
							name => <<"url_demo">>,
							label => <<"URL输入"/utf8>>,
							type => <<"url">>,
							required => false,
							placeholder => <<"请输入URL地址"/utf8>>,
							options => #{}
						},
						#{
							name => <<"password_demo">>,
							label => <<"密码输入"/utf8>>,
							type => <<"password">>,
							required => false,
							placeholder => <<"请输入密码"/utf8>>,
							options => #{}
						},
						#{
							name => <<"number_range_demo">>,
							label => <<"数字范围"/utf8>>,
							type => <<"number-range">>,
							required => false,
							placeholder => <<"请输入数字范围"/utf8>>,
							options => #{
								min => 0,
								max => 100,
								step => 5
							}
						}
					]
				}
			]
		}
	],
	#{menuGroups => MenuGroups}.