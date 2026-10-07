%%%-------------------------------------------------------------------
%%% @doc 默认示例菜单模块（独立运行时使用）。
%%%
%%% 接入约定请只看「GM接入参数返回值说明.md」（接入 + 参数 + 返回值）。
%%% 模块一律 gm* / gmEx* 前缀，嵌入宿主时不会与业务模块撞名。
%%%
%%% 契约: menus/0  +  handlers/0
%%% @end
%%%-------------------------------------------------------------------
-module(gmExampleMenus).

-export([menus/0, handlers/0]).

-define(MenuGroup(Id, Name, Icon, Menus), #{id => Id, name => Name, icon => Icon, menus => Menus}).
-define(MenuBar(Id, Name, Desc, Icon, Method, Path, Params),
	#{id => Id, name => Name, description => Desc, icon => Icon,
		apiConfig => #{method => Method, path => Path, sendToGMSrv => true}, params => Params}).
-define(MenuBarDirect(Id, Name, Desc, Icon, Method, Path, Params),
	#{id => Id, name => Name, description => Desc, icon => Icon,
		apiConfig => #{method => Method, path => Path, sendToGMSrv => false}, params => Params}).
-define(IParam(Name, Label, Type, Required, Options),
	#{name => Name, label => Label, type => Type, required => Required, options => Options}).
-define(IParam(Name, Label, Type, Required, Options, Desc),
	#{name => Name, label => Label, type => Type, required => Required, options => Options, description => Desc}).
-define(SELECT_OPTION(Value, Label), #{value => Value, label => Label}).
-define(WithAuto(Menu), maps:merge(Menu, #{autoRun => true})).

menus() ->
	[
		?MenuGroup(<<"mgDemoReply">>, <<"返回格式演示"/utf8>>, <<"fa-shapes">>, replyMenus()),
		?MenuGroup(<<"mgDemoParams">>, <<"参数输入演示"/utf8>>, <<"fa-sliders-h">>, paramMenus()),
		?MenuGroup(<<"mgPlayer">>, <<"玩家管理"/utf8>>, <<"fa-users">>, playerMenus()),
		?MenuGroup(<<"mgItem">>, <<"物品管理"/utf8>>, <<"fa-gift">>, itemMenus()),
		?MenuGroup(<<"mgServer">>, <<"服务器管理"/utf8>>, <<"fa-server">>, serverMenus()),
		?MenuGroup(<<"mgMonitor">>, <<"监控与日志"/utf8>>, <<"fa-chart-line">>, monitorMenus())
	].

handlers() ->
	[
		{<<"demo">>, gmExDemoGHer},
		{<<"player">>, gmExPlayerGHer},
		{<<"players">>, gmExPlayerGHer},
		{<<"items">>, gmExItemGHer},
		{<<"server">>, gmExServerGHer},
		{<<"servers">>, gmExServerMgrGHer},
		{<<"monitor">>, gmExMonitorGHer},
		{<<"logs">>, gmExLogsGHer}
	].

%% ========== 返回格式 ==========
replyMenus() ->
	[
		?WithAuto(?MenuBar(<<"menu_demo_table">>, <<"表格 table"/utf8>>,
			<<"列链接 + 行操作 + 列头本地排序"/utf8>>, <<"fa-table">>,
			<<"GET">>, <<"/demo/table">>, [])),
		?WithAuto(?MenuBar(<<"menu_demo_table_sort">>, <<"分页+表单排序示例"/utf8>>,
			<<"演示宿主自实现：表单 sort/order 点「执行」才请求；列头仍是本地排序"/utf8>>, <<"fa-sort">>,
			<<"GET">>, <<"/demo/table-sort">>,
			[
				?IParam(<<"page">>, <<"页码"/utf8>>, <<"number">>, false,
					#{defaultValue => 1, min => 1}),
				?IParam(<<"pageSize">>, <<"每页条数"/utf8>>, <<"select">>, false,
					#{defaultValue => <<"5">>, selectOptions => [
						?SELECT_OPTION(<<"5">>, <<"5 条"/utf8>>),
						?SELECT_OPTION(<<"10">>, <<"10 条"/utf8>>),
						?SELECT_OPTION(<<"20">>, <<"20 条"/utf8>>)
					]}),
				?IParam(<<"sort">>, <<"排序字段"/utf8>>, <<"select">>, false,
					#{defaultValue => <<>>, selectOptions => [
						?SELECT_OPTION(<<>>, <<"不指定"/utf8>>),
						?SELECT_OPTION(<<"id">>, <<"id（编号）"/utf8>>),
						?SELECT_OPTION(<<"name">>, <<"name（名称）"/utf8>>),
						?SELECT_OPTION(<<"score">>, <<"score（分数）"/utf8>>),
						?SELECT_OPTION(<<"level">>, <<"level（等级）"/utf8>>),
						?SELECT_OPTION(<<"status">>, <<"status（状态）"/utf8>>),
						?SELECT_OPTION(<<"score,level">>, <<"score,level（复合）"/utf8>>),
						?SELECT_OPTION(<<"level,id">>, <<"level,id（复合）"/utf8>>)
					]},
					<<"非框架约定：示例里自行读参排序；点列头不会带此参数"/utf8>>),
				?IParam(<<"order">>, <<"排序方向"/utf8>>, <<"select">>, false,
					#{defaultValue => <<"asc">>, selectOptions => [
						?SELECT_OPTION(<<"asc">>, <<"升序"/utf8>>),
						?SELECT_OPTION(<<"desc">>, <<"降序"/utf8>>)
					]})
			])),
		?WithAuto(?MenuBar(<<"menu_demo_table_trunc">>, <<"列截断提示"/utf8>>,
			<<"Meta.truncatedCols / totalCols 触发警告条"/utf8>>, <<"fa-columns">>,
			<<"GET">>, <<"/demo/table-trunc">>, [])),
		?MenuBar(<<"menu_demo_kv">>, <<"键值 KV"/utf8>>,
			<<"详情页常用键值对"/utf8>>, <<"fa-list">>,
			<<"GET">>, <<"/demo/kv">>,
			[?IParam(<<"id">>, <<"编号"/utf8>>, <<"number">>, false,
				#{defaultValue => 1, min => 1}, <<"可选，默认 1"/utf8>>)]),
		?WithAuto(?MenuBar(<<"menu_demo_cards">>, <<"卡片 cards"/utf8>>,
			<<"指标卡片组"/utf8>>, <<"fa-th-large">>,
			<<"GET">>, <<"/demo/cards">>, [])),
		?MenuBar(<<"menu_demo_form">>, <<"动态表单 form"/utf8>>,
			<<"结果区内嵌可提交表单"/utf8>>, <<"fa-wpforms">>,
			<<"GET">>, <<"/demo/form">>, []),
		?MenuBar(<<"menu_demo_json">>, <<"JSON"/utf8>>,
			<<"{json, Map} 结构化展示"/utf8>>, <<"fa-code">>,
			<<"GET">>, <<"/demo/json">>, []),
		?WithAuto(?MenuBar(<<"menu_demo_schema">>, <<"JSON schema 面板"/utf8>>,
			<<"view=schema：概要 + Key 槽位 + 字段清单"/utf8>>, <<"fa-database">>,
			<<"GET">>, <<"/demo/schema">>, [])),
		?MenuBar(<<"menu_demo_row">>, <<"JSON 行详情"/utf8>>,
			<<"view=row：字段明细 + raw_term 可复制"/utf8>>, <<"fa-file-alt">>,
			<<"GET">>, <<"/demo/row">>,
			[?IParam(<<"id">>, <<"Key"/utf8>>, <<"number">>, false,
				#{defaultValue => 1001, min => 1})]),
		?MenuBar(<<"menu_demo_msg">>, <<"消息 msg"/utf8>>,
			<<"一句话成功提示"/utf8>>, <<"fa-comment">>,
			<<"GET">>, <<"/demo/msg">>, []),
		?MenuBar(<<"menu_demo_redirect">>, <<"跳转 redirect"/utf8>>,
			<<"打开后跳到表格演示菜单"/utf8>>, <<"fa-share">>,
			<<"GET">>, <<"/demo/redirect">>, []),
		?MenuBar(<<"menu_demo_error">>, <<"错误 error"/utf8>>,
			<<"业务失败提示"/utf8>>, <<"fa-exclamation-triangle">>,
			<<"GET">>, <<"/demo/error">>, []),
		?MenuBar(<<"menu_demo_404">>, <<"not_found"/utf8>>,
			<<"资源不存在"/utf8>>, <<"fa-unlink">>,
			<<"GET">>, <<"/demo/not-found">>, []),
		?MenuBarDirect(<<"menu_direct_demo_msg">>, <<"直连区服演示"/utf8>>,
			<<"sendToGMSrv=false，请求发到顶部所选服务器（选 127.0.0.1:8080 可打回本机）"/utf8>>,
			<<"fa-share">>, <<"GET">>, <<"/demo/msg">>, [])
	].

%% ========== 参数类型（常用控件） ==========
paramMenus() ->
	[
		?MenuBar(<<"menu_demo_params">>, <<"综合参数回显"/utf8>>,
			<<"覆盖常用输入类型，提交后 JSON 回显"/utf8>>, <<"fa-keyboard">>,
			<<"POST">>, <<"/demo/params">>,
			[
				?IParam(<<"text">>, <<"单行文本"/utf8>>, <<"text">>, true,
					#{placeholder => <<"请输入"/utf8>>, defaultValue => <<"hello">>},
					<<"必填文本"/utf8>>),
				?IParam(<<"textarea">>, <<"多行文本"/utf8>>, <<"textarea">>, false,
					#{rows => 3, defaultValue => <<"多行内容"/utf8>>}),
				?IParam(<<"number">>, <<"数字"/utf8>>, <<"number">>, true,
					#{defaultValue => 42, min => 0, max => 100, step => 1}),
				?IParam(<<"select">>, <<"下拉"/utf8>>, <<"select">>, true,
					#{defaultValue => <<"b">>, selectOptions => [
						?SELECT_OPTION(<<"a">>, <<"选项 A"/utf8>>),
						?SELECT_OPTION(<<"b">>, <<"选项 B"/utf8>>),
						?SELECT_OPTION(<<"c">>, <<"选项 C"/utf8>>)
					]}),
				?IParam(<<"radio">>, <<"单选"/utf8>>, <<"radio">>, true,
					#{defaultValue => <<"yes">>, selectOptions => [
						?SELECT_OPTION(<<"yes">>, <<"是"/utf8>>),
						?SELECT_OPTION(<<"no">>, <<"否"/utf8>>)
					]}),
				?IParam(<<"checkbox">>, <<"多选"/utf8>>, <<"checkbox">>, false,
					#{defaultValue => [<<"x">>, <<"y">>], selectOptions => [
						?SELECT_OPTION(<<"x">>, <<"X"/utf8>>),
						?SELECT_OPTION(<<"y">>, <<"Y"/utf8>>),
						?SELECT_OPTION(<<"z">>, <<"Z"/utf8>>)
					]}),
				?IParam(<<"switch">>, <<"开关"/utf8>>, <<"switch">>, false,
					#{defaultValue => true}),
				?IParam(<<"rate">>, <<"评分"/utf8>>, <<"rate">>, false,
					#{defaultValue => 3, max => 5}),
				?IParam(<<"slider">>, <<"滑块"/utf8>>, <<"slider">>, false,
					#{defaultValue => 50, min => 0, max => 100}),
				?IParam(<<"date">>, <<"日期"/utf8>>, <<"date">>, false,
					#{defaultValue => <<"2026-01-01">>}),
				?IParam(<<"datetime">>, <<"日期时间"/utf8>>, <<"datetime">>, false,
					#{defaultValue => <<"2026-01-01 12:00:00">>}),
				?IParam(<<"color">>, <<"颜色"/utf8>>, <<"color">>, false,
					#{defaultValue => <<"#1890ff">>}),
				?IParam(<<"email">>, <<"邮箱"/utf8>>, <<"email">>, false,
					#{placeholder => <<"a@b.com"/utf8>>}),
				?IParam(<<"url">>, <<"URL"/utf8>>, <<"url">>, false,
					#{placeholder => <<"https://example.com"/utf8>>}),
				?IParam(<<"password">>, <<"密码"/utf8>>, <<"password">>, false,
					#{placeholder => <<"不会回显明文存储"/utf8>>}),
				?IParam(<<"number_range">>, <<"数字范围"/utf8>>, <<"number-range">>, false,
					#{defaultValue => [10, 90], min => 0, max => 100})
			])
	].

%% ========== 玩家 ==========
playerMenus() ->
	[
		?WithAuto(?MenuBar(<<"menu_query_players">>, <<"查询玩家列表"/utf8>>,
			<<"表格 + 列链接 + 行操作 + 分页"/utf8>>, <<"fa-search">>,
			<<"GET">>, <<"/player">>,
			[
				?IParam(<<"keyword">>, <<"搜索关键词"/utf8>>, <<"text">>, false,
					#{placeholder => <<"玩家ID或玩家名"/utf8>>},
					<<"支持模糊匹配"/utf8>>),
				?IParam(<<"page">>, <<"页码"/utf8>>, <<"number">>, false,
					#{defaultValue => 1, min => 1}, <<"从1开始"/utf8>>),
				?IParam(<<"pageSize">>, <<"每页条数"/utf8>>, <<"select">>, false,
					#{defaultValue => <<"10">>, selectOptions => [
						?SELECT_OPTION(<<"5">>, <<"5条"/utf8>>),
						?SELECT_OPTION(<<"10">>, <<"10条"/utf8>>),
						?SELECT_OPTION(<<"20">>, <<"20条"/utf8>>),
						?SELECT_OPTION(<<"50">>, <<"50条"/utf8>>)
					]}, <<"分页大小"/utf8>>)
			])),
		?MenuBar(<<"menu_player_details">>, <<"玩家详情"/utf8>>,
			<<"KV 详情演示"/utf8>>, <<"fa-user-circle">>,
			<<"GET">>, <<"/players/details">>,
			[
				?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true,
					#{placeholder => <<"请输入玩家ID"/utf8>>, min => 1, defaultValue => 1001},
					<<"有效玩家ID"/utf8>>)
			]),
		?WithAuto(?MenuBar(<<"menu_player_by_id">>, <<"玩家路径详情"/utf8>>,
			<<"GET /player/{id} 路径参数演示"/utf8>>, <<"fa-user-circle">>,
			<<"GET">>, <<"/player/1001">>, [])),
		?MenuBar(<<"menu_kick_player">>, <<"踢出玩家"/utf8>>,
			<<"{msg, Text} 写操作演示"/utf8>>, <<"fa-user-times">>,
			<<"POST">>, <<"/players/kick">>,
			[
				?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true,
					#{placeholder => <<"请输入玩家ID"/utf8>>},
					<<"要踢出的玩家"/utf8>>),
				?IParam(<<"reason">>, <<"踢出原因"/utf8>>, <<"textarea">>, false,
					#{placeholder => <<"请输入原因"/utf8>>, rows => 3, maxLength => 200},
					<<"便于追溯"/utf8>>)
			]),
		?MenuBar(<<"menu_ban_player">>, <<"封禁玩家"/utf8>>,
			<<"select + textarea"/utf8>>, <<"fa-user-lock">>,
			<<"POST">>, <<"/players/ban">>,
			[
				?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true,
					#{placeholder => <<"请输入玩家ID"/utf8>>, min => 1},
					<<"要封禁的玩家"/utf8>>),
				?IParam(<<"duration">>, <<"封禁时长"/utf8>>, <<"select">>, true,
					#{placeholder => <<"请选择"/utf8>>, selectOptions => [
						?SELECT_OPTION(<<"1h">>, <<"1小时"/utf8>>),
						?SELECT_OPTION(<<"24h">>, <<"24小时"/utf8>>),
						?SELECT_OPTION(<<"7d">>, <<"7天"/utf8>>),
						?SELECT_OPTION(<<"permanent">>, <<"永久"/utf8>>)
					]}, <<"按违规程度选择"/utf8>>),
				?IParam(<<"reason">>, <<"封禁原因"/utf8>>, <<"textarea">>, true,
					#{placeholder => <<"请输入原因"/utf8>>, rows => 3, maxLength => 500},
					<<"必填"/utf8>>)
			]),
		?MenuBar(<<"menu_unban_player">>, <<"解封玩家"/utf8>>,
			<<"解除玩家封禁"/utf8>>, <<"fa-user-check">>,
			<<"POST">>, <<"/players/unban">>,
			[
				?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true,
					#{placeholder => <<"请输入玩家ID"/utf8>>}, <<"要解封的玩家"/utf8>>),
				?IParam(<<"reason">>, <<"解封原因"/utf8>>, <<"textarea">>, false,
					#{placeholder => <<"请输入原因"/utf8>>, rows => 3}, <<"可选"/utf8>>)
			])
	].

%% ========== 物品 ==========
itemMenus() ->
	[
		?WithAuto(?MenuBar(<<"menu_item_list">>, <<"物品列表"/utf8>>,
			<<"二维列表行 → 表格"/utf8>>, <<"fa-list">>,
			<<"GET">>, <<"/items">>, [])),
		?MenuBar(<<"menu_add_item">>, <<"添加物品"/utf8>>,
			<<"JSON 回显写操作"/utf8>>, <<"fa-plus-circle">>,
			<<"POST">>, <<"/items/add">>,
			[
				?IParam(<<"player_id">>, <<"玩家ID"/utf8>>, <<"number">>, true,
					#{placeholder => <<"玩家ID"/utf8>>, min => 1}, <<"目标玩家"/utf8>>),
				?IParam(<<"item_id">>, <<"物品ID"/utf8>>, <<"number">>, true,
					#{placeholder => <<"物品ID"/utf8>>, min => 1}, <<"物品配置ID"/utf8>>),
				?IParam(<<"quantity">>, <<"数量"/utf8>>, <<"number">>, true,
					#{defaultValue => 1, min => 1, max => 9999}, <<"1-9999"/utf8>>),
				?IParam(<<"bind">>, <<"是否绑定"/utf8>>, <<"radio">>, false,
					#{defaultValue => <<"false">>, selectOptions => [
						?SELECT_OPTION(<<"true">>, <<"绑定"/utf8>>),
						?SELECT_OPTION(<<"false">>, <<"不绑定"/utf8>>)
					]}, <<"绑定状态"/utf8>>)
			])
	].

%% ========== 服务器 ==========
serverMenus() ->
	[
		?WithAuto(?MenuBar(<<"menu_server_list">>, <<"服务器列表"/utf8>>,
			<<"顶部选服栏数据源 GET /servers"/utf8>>, <<"fa-list">>,
			<<"GET">>, <<"/servers">>,
			[
				?IParam(<<"page">>, <<"页码"/utf8>>, <<"number">>, false,
					#{defaultValue => 1, min => 1}, <<"从1开始"/utf8>>),
				?IParam(<<"pageSize">>, <<"每页条数"/utf8>>, <<"select">>, false,
					#{defaultValue => <<"10">>, selectOptions => [
						?SELECT_OPTION(<<"5">>, <<"5条"/utf8>>),
						?SELECT_OPTION(<<"10">>, <<"10条"/utf8>>),
						?SELECT_OPTION(<<"20">>, <<"20条"/utf8>>)
					]}, <<"分页大小"/utf8>>)
			])),
		?WithAuto(?MenuBar(<<"menu_server_status">>, <<"服务器状态"/utf8>>,
			<<"运行状态表格"/utf8>>, <<"fa-heartbeat">>,
			<<"GET">>, <<"/server/status">>, [])),
		?WithAuto(?MenuBar(<<"menu_server_statistics">>, <<"服务器统计"/utf8>>,
			<<"GET /server/statistics"/utf8>>, <<"fa-chart-bar">>,
			<<"GET">>, <<"/server/statistics">>, [])),
		?WithAuto(?MenuBar(<<"menu_server_groups">>, <<"服务器分组"/utf8>>,
			<<"GET /servers/groups"/utf8>>, <<"fa-layer-group">>,
			<<"GET">>, <<"/servers/groups">>, []))
	].

%% ========== 监控 ==========
monitorMenus() ->
	[
		?WithAuto(?MenuBar(<<"menu_monitor">>, <<"实时监控"/utf8>>,
			<<"JSON 指标"/utf8>>, <<"fa-tachometer-alt">>,
			<<"GET">>, <<"/monitor">>, [])),
		?WithAuto(?MenuBar(<<"menu_monitor_realtime">>, <<"实时监控 JSON"/utf8>>,
			<<"GET /monitor/real-time"/utf8>>, <<"fa-bolt">>,
			<<"GET">>, <<"/monitor/real-time">>, [])),
		?WithAuto(?MenuBar(<<"menu_monitor_alerts">>, <<"监控告警"/utf8>>,
			<<"GET /monitor/alerts"/utf8>>, <<"fa-bell">>,
			<<"GET">>, <<"/monitor/alerts">>, [])),
		?WithAuto(?MenuBar(<<"menu_monitor_cards">>, <<"监控卡片"/utf8>>,
			<<"复用 cards 演示路径"/utf8>>, <<"fa-th">>,
			<<"GET">>, <<"/demo/cards">>, [])),
		?MenuBar(<<"menu_logs">>, <<"系统日志"/utf8>>,
			<<"分页表格"/utf8>>, <<"fa-file-alt">>,
			<<"GET">>, <<"/logs">>,
			[
				?IParam(<<"page">>, <<"页码"/utf8>>, <<"number">>, false,
					#{defaultValue => 1, min => 1}, <<"页码"/utf8>>),
				?IParam(<<"pageSize">>, <<"每页条数"/utf8>>, <<"select">>, false,
					#{defaultValue => <<"20">>, selectOptions => [
						?SELECT_OPTION(<<"10">>, <<"10条"/utf8>>),
						?SELECT_OPTION(<<"20">>, <<"20条"/utf8>>),
						?SELECT_OPTION(<<"50">>, <<"50条"/utf8>>)
					]}, <<"分页"/utf8>>)
			])
	].
