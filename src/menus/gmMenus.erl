%%%-------------------------------------------------------------------
%%% @doc 菜单合并器（非 HTTP Handler）。
%%%
%%% 最终菜单 = 宿主菜单模块 menus/0 ++ 框架固有菜单（工具面板置底）
%%% 最终路由 = 路径推导(仅宿主) < 框架固有 < 宿主 handlers/0
%%%
%%% 宿主菜单模块契约（必须提供）:
%%%   menus/0    -> [MenuGroup] | #{menuGroups => [MenuGroup]}
%%%   handlers/0 -> [{PathSeg :: binary(), module()}]
%%%
%%% 启动时通过 gmTool:start(#{menuModule => Mod}) 指定宿主模块即可。
%%% HTTP 入口（/menus、工具面板等）由 gmComGHer 处理。
%%% @end
%%%-------------------------------------------------------------------
-module(gmMenus).

-include("common.hrl").

-define(menusJson, menusJson).
-define(menusMod, {gmTool, menu_module}).
-define(defMenusMod, gmExampleMenus).

-on_load(loadMenus/0).

-export([
	menus/0
	, allHer/0
	, reloadMenus/0
	, menuModule/0
	, setMenuModule/1
	, builtinMenuGroups/0
	, menusJson/0
]).

%% 合并后的完整菜单（前端 /menus 使用）
menus() ->
	Builtin = builtinMenuGroups(),
	Host = hostMenuGroups(),
	#{menuGroups => Host ++ Builtin}.

allHer() ->
	%% 路径推导只针对宿主菜单；框架路径显式挂到 gmComGHer / gmAuthGHer
	Derived = derivedHandlers(#{menuGroups => hostMenuGroups()}),
	HostHandlers = hostHandlers(),
	Base = [
		{<<>>, gmComGHer},
		{<<"menus">>, gmComGHer},
		{<<"icons">>, gmComGHer},
		{<<"utils">>, gmComGHer},
		{<<"auth">>, gmAuthGHer}
	],
	%% 优先级（低→高）：路径推导 < 框架固有 < 宿主显式
	%% Derived 必须打底，否则会把 menus/icons/utils 覆盖成不存在的 <Seg>GHer
	mergeHandlers(mergeHandlers(Derived, Base), HostHandlers).

%% ========== internal ==========
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
	{module, ModName} = code:load_binary(ModName, [], BeamBin),
	gmKvsToBeam:load(?gmHerTable, allHer()),
	ok.

hostMenuGroups() ->
	normalizeMenus((menuModule()):menus()).

hostHandlers() ->
	(menuModule()):handlers().

normalizeMenus(#{menuGroups := Groups}) when is_list(Groups) ->
	Groups;
normalizeMenus(Groups) when is_list(Groups) ->
	Groups.

derivedHandlers(#{menuGroups := Groups}) ->
	Segs = [
		begin
			Path = maps:get(path, maps:get(apiConfig, OneMenu, #{}), <<>>),
			case Path of
				<<$/, LPath/binary>> ->
					[HerStr | _] = binary:split(LPath, <<"/">>),
					HerStr;
				_ ->
					<<>>
			end
		end
		|| Group <- Groups, OneMenu <- maps:get(menus, Group, [])
	],
	[{Seg, binary_to_atom(<<Seg/binary, "GHer">>)} || Seg <- lists:usort(Segs), Seg =/= <<>>].

%% 注意：路径推导名不含 gm 前缀。示例是 gmEx*，必须靠 handlers/0 覆盖。

mergeHandlers(Base, New) ->
	lists:foldl(fun({K, V}, Acc) -> lists:keystore(K, 1, Acc, {K, V}) end, Base, New).

reloadMenus() ->
	doReloadMenus().

%% 供 HTTP 层取侧栏 JSON（不经本模块 handle）
menusJson() ->
	?menusJson:json().

%% 尽量从磁盘热加载宿主菜单模块及其 handlers，再重建 menusJson / 路由表
doReloadMenus() ->
	Mod = menuModule(),
	reloadBeam(Mod),
	lists:foreach(fun({_, HMod}) when is_atom(HMod) -> reloadBeam(HMod);(_) -> ok end, Mod:handlers()),
	ok = loadMenus().

reloadBeam(Mod) when is_atom(Mod) ->
	_ = code:soft_purge(Mod),
	case code:load_file(Mod) of
		{module, Mod} ->
			ok;
		{error, _} ->
			%% escript / 内存加载模块可能无文件路径，ensure_loaded 即可
			_ = code:ensure_loaded(Mod),
			ok
	end;
reloadBeam(_) ->
	ok.

-spec setMenuModule(module()) -> ok.
setMenuModule(Mod) when is_atom(Mod) ->
	persistent_term:put(?menusMod, Mod),
	ok.

-spec menuModule() -> module().
menuModule() ->
	persistent_term:get(?menusMod, ?defMenusMod).

%% 框架固有路由已写在 allHer/0 的 Base 里（menus/icons/utils → gmComGHer）

%% 框架固有菜单：每个接入项目都会看到的「工具面板」
-spec builtinMenuGroups() -> [map()].
builtinMenuGroups() ->
	[
		#{
			id => <<"mgTools">>,
			name => <<"工具面板"/utf8>>,
			icon => <<"fa-tools">>,
			menus => [
				#{
					id => <<"menu_icon_viewer">>,
					name => <<"查看图标"/utf8>>,
					description => <<"预览和选择 Ant Design 图标"/utf8>>,
					icon => <<"fa-images">>,
					apiConfig => #{method => <<"GET">>, path => <<"/icons">>, sendToGMSrv => true},
					params => []
				},
				#{
					id => <<"menu_param_type_tester">>,
					name => <<"参数类型测试"/utf8>>,
					description => <<"覆盖文档全部 19 种参数类型，提交后 JSON 回显"/utf8>>,
					icon => <<"fa-flask">>,
					apiConfig => #{method => <<"POST">>, path => <<"/utils/param-types">>, sendToGMSrv => true},
					params => paramTypeTesterParams()
				},
				#{
					id => <<"menu_reload_menus">>,
					name => <<"刷新菜单"/utf8>>,
					description => <<"代码改完菜单后点此重新加载侧栏（热加载菜单模块 + handlers）"/utf8>>,
					icon => <<"fa-sync">>,
					apiConfig => #{method => <<"POST">>, path => <<"/menus/reload">>, sendToGMSrv => true},
					params => []
				}
			]
		}
	].

%% 工具面板「参数类型测试」：与文档 / FunctionPanel 支持的类型一一对应（共 19 种）
paramTypeTesterParams() ->
	[
		#{name => <<"basic_text">>, label => <<"基础文本"/utf8>>, type => <<"text">>,
			required => false, placeholder => <<"请输入文本"/utf8>>,
			description => <<"text"/utf8>>,
			options => #{defaultValue => <<"hello">>}},
		#{name => <<"basic_textarea">>, label => <<"多行文本"/utf8>>, type => <<"textarea">>,
			required => false, placeholder => <<"请输入多行文本"/utf8>>,
			description => <<"textarea"/utf8>>,
			options => #{rows => 3, maxLength => 200, defaultValue => <<"多行内容"/utf8>>}},
		#{name => <<"limited_number">>, label => <<"有限制数字(1-100)"/utf8>>, type => <<"number">>,
			required => false, placeholder => <<"请输入1-100之间的数字"/utf8>>,
			description => <<"number + min/max/step"/utf8>>,
			options => #{min => 1, max => 100, step => 1, defaultValue => 50}},
		#{name => <<"unlimited_number">>, label => <<"无限制数字"/utf8>>, type => <<"number">>,
			required => false, placeholder => <<"请输入任意数字"/utf8>>,
			description => <<"number 无范围"/utf8>>,
			options => #{defaultValue => 42}},
		#{name => <<"password_demo">>, label => <<"密码输入"/utf8>>, type => <<"password">>,
			required => false, placeholder => <<"请输入密码"/utf8>>,
			description => <<"password"/utf8>>, options => #{}},
		#{name => <<"email_demo">>, label => <<"邮箱输入"/utf8>>, type => <<"email">>,
			required => false, placeholder => <<"a@b.com"/utf8>>,
			description => <<"email"/utf8>>,
			options => #{defaultValue => <<"demo@example.com">>}},
		#{name => <<"url_demo">>, label => <<"URL输入"/utf8>>, type => <<"url">>,
			required => false, placeholder => <<"https://example.com"/utf8>>,
			description => <<"url"/utf8>>,
			options => #{defaultValue => <<"https://example.com">>}},
		#{name => <<"select_demo">>, label => <<"下拉选择"/utf8>>, type => <<"select">>,
			required => false, placeholder => <<"请下拉选择"/utf8>>,
			description => <<"select"/utf8>>,
			options => #{
				defaultValue => <<"option2">>,
				selectOptions => [
					#{value => <<"option1">>, label => <<"选项一"/utf8>>},
					#{value => <<"option2">>, label => <<"选项二"/utf8>>},
					#{value => <<"option3">>, label => <<"选项三"/utf8>>},
					#{value => <<"option4">>, label => <<"选项四"/utf8>>},
					#{value => <<"option5">>, label => <<"选项五"/utf8>>},
					#{value => <<"option6">>, label => <<"选项六"/utf8>>}
				]
			}},
		#{name => <<"radio_demo">>, label => <<"单选按钮"/utf8>>, type => <<"radio">>,
			required => false, placeholder => <<"请选择"/utf8>>,
			description => <<"radio（多项测换行）"/utf8>>,
			options => #{
				defaultValue => <<"a">>,
				selectOptions => [
					#{value => <<"a">>, label => <<"选项A"/utf8>>},
					#{value => <<"b">>, label => <<"选项B"/utf8>>},
					#{value => <<"c">>, label => <<"选项C"/utf8>>},
					#{value => <<"d">>, label => <<"选项D"/utf8>>},
					#{value => <<"e">>, label => <<"选项E"/utf8>>},
					#{value => <<"f">>, label => <<"选项F"/utf8>>},
					#{value => <<"g">>, label => <<"选项G"/utf8>>},
					#{value => <<"h">>, label => <<"选项H"/utf8>>},
					#{value => <<"i">>, label => <<"选项I"/utf8>>},
					#{value => <<"j">>, label => <<"选项J"/utf8>>}
				]
			}},
		#{name => <<"checkbox_demo">>, label => <<"多选框"/utf8>>, type => <<"checkbox">>,
			required => false, placeholder => <<"请选择功能"/utf8>>,
			description => <<"checkbox（多项测换行）"/utf8>>,
			options => #{
				defaultValue => [<<"f1">>, <<"f3">>],
				selectOptions => [
					#{value => <<"f1">>, label => <<"功能一"/utf8>>},
					#{value => <<"f2">>, label => <<"功能二"/utf8>>},
					#{value => <<"f3">>, label => <<"功能三"/utf8>>},
					#{value => <<"f4">>, label => <<"功能四"/utf8>>},
					#{value => <<"f5">>, label => <<"功能五"/utf8>>},
					#{value => <<"f6">>, label => <<"功能六"/utf8>>},
					#{value => <<"f7">>, label => <<"功能七"/utf8>>},
					#{value => <<"f8">>, label => <<"功能八"/utf8>>},
					#{value => <<"f9">>, label => <<"功能九"/utf8>>},
					#{value => <<"f10">>, label => <<"功能十"/utf8>>},
					#{value => <<"f11">>, label => <<"功能十一"/utf8>>},
					#{value => <<"f12">>, label => <<"功能十二"/utf8>>}
				]
			}},
		#{name => <<"switch_demo">>, label => <<"开关切换"/utf8>>, type => <<"switch">>,
			required => false, description => <<"switch"/utf8>>,
			options => #{defaultValue => true}},
		#{name => <<"rate_demo">>, label => <<"评分组件"/utf8>>, type => <<"rate">>,
			required => false, description => <<"rate"/utf8>>,
			options => #{defaultValue => 3, max => 5}},
		#{name => <<"slider_demo">>, label => <<"滑块选择"/utf8>>, type => <<"slider">>,
			required => false, description => <<"slider"/utf8>>,
			options => #{min => 0, max => 100, defaultValue => 50}},
		#{name => <<"color_demo">>, label => <<"颜色选择"/utf8>>, type => <<"color">>,
			required => false, description => <<"color"/utf8>>,
			options => #{defaultValue => <<"#1890ff">>}},
		#{name => <<"date_demo">>, label => <<"日期选择"/utf8>>, type => <<"date">>,
			required => false, placeholder => <<"请选择日期"/utf8>>,
			description => <<"date"/utf8>>,
			options => #{defaultValue => <<"2026-01-01">>}},
		#{name => <<"datetime_demo">>, label => <<"日期时间"/utf8>>, type => <<"datetime">>,
			required => false, placeholder => <<"请选择日期时间"/utf8>>,
			description => <<"datetime"/utf8>>,
			options => #{defaultValue => <<"2026-01-01 12:00:00">>}},
		#{name => <<"time_demo">>, label => <<"时间选择"/utf8>>, type => <<"time">>,
			required => false, placeholder => <<"请选择时间"/utf8>>,
			description => <<"time"/utf8>>,
			options => #{defaultValue => <<"12:30:00">>}},
		#{name => <<"date_range_demo">>, label => <<"日期范围"/utf8>>, type => <<"date-range">>,
			required => false, placeholder => <<"请选择日期范围"/utf8>>,
			description => <<"date-range"/utf8>>,
			options => #{defaultValue => [<<"2026-01-01">>, <<"2026-01-31">>]}},
		#{name => <<"datetime_range_demo">>, label => <<"日期时间范围"/utf8>>, type => <<"datetime-range">>,
			required => false, placeholder => <<"请选择日期时间范围"/utf8>>,
			description => <<"datetime-range"/utf8>>,
			options => #{defaultValue => [<<"2026-01-01 00:00:00">>, <<"2026-01-01 23:59:59">>]}},
		#{name => <<"number_range_demo">>, label => <<"数字范围"/utf8>>, type => <<"number-range">>,
			required => false, placeholder => <<"请输入数字范围"/utf8>>,
			description => <<"number-range"/utf8>>,
			options => #{min => 0, max => 100, step => 5, defaultValue => [10, 90]}}
	].