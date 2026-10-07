%%%-------------------------------------------------------------------
%%% @doc gmTool — 基础 GM 框架公共 API + escript 入口。
%%%
%%% 本仓库提供前后端交互、界面展示、Web 服务与菜单合并能力。
%%% 业务菜单由「菜单模块」提供：独立运行默认 gmExampleMenus；
%%% A/B/C 等宿主项目启动时传入自己的菜单模块即可。
%%%
%%% 独立运行:
%%%   rebar3 escriptize
%%%   _build/default/bin/gmTool [--port N] [--menu-module Mod]
%%%
%%% 嵌入宿主节点:
%%%   gmToolBootstrap:start("priv/gmTool", #{
%%%       port => 3000,
%%%       menuModule => myGameMenus
%%%   }),
%%%   %% myGameMenus:menus/0  +  自己的 *GHer 即可
%%% @end
%%%-------------------------------------------------------------------
-module(gmTool).

-include("common.hrl").

-export([
	main/1
	, start/0
	, start/1
	, start/2
	, stop/0
	, stop/1
	, open/1
	, open/2
	, close/0
	, close/1
	, reloadMenus/0
	, menuModule/0
]).

-define(DEFAULT_PORT, 3000).
-define(defMenusMod, gmExampleMenus).
-define(APP, gmTool).
-define(usePort, '$gmUsePort').

-on_load(loadInit/0).

loadInit() ->
	%% 触发 gmMenus:-on_load（此时菜单模块可能尚未设置，用默认）
	gmMenus:module_info(),
	ok.

%% ========== escript ==========
%% Usage:
%%   gmTool [--port N] [--menu-module Mod]
%%   gmTool [PORT]
main(Args) ->
	{Port, MenuMod} = parseArgs(Args, ?DEFAULT_PORT, ?defMenusMod),
	case start(Port, MenuMod) of
		{ok, _} ->
			io:format("gmTool listening on http://0.0.0.0:~p/ (menuModule=~p)~n", [Port, MenuMod]),
			receive after infinity -> ok end;
		{error, {already_started, _}} ->
			io:format("gmTool already running on this node~n"),
			erlang:halt(0);
		{error, Reason} ->
			io:format("failed to start gmTool: ~p~n", [Reason]),
			erlang:halt(1)
	end.

%% ========== OTP helpers ==========
%% start() / start(Port) 默认使用 gmExampleMenus
start() ->
	start(#{port => ?DEFAULT_PORT, menuModule => ?defMenusMod}).

start(Port) when is_integer(Port) ->
	start(#{port => Port, menuModule => ?defMenusMod});
start(Opts) when is_map(Opts) ->
	Port = maps:get(port, Opts, ?DEFAULT_PORT),
	MenuMod = maps:get(menuModule, Opts, ?defMenusMod),
	doStart(Port, MenuMod).

start(Port, MenuMod) when is_integer(Port), is_atom(MenuMod) ->
	doStart(Port, MenuMod).

doStart(Port, MenuMod) ->
	ok = gmMenus:setMenuModule(MenuMod),
	persistent_term:put(?usePort, Port),
	case application:ensure_all_started(?APP) of
		{ok, _} ->
			reloadMenus(),
			open(Port);
		{error, {already_started, ?APP}} ->
			reloadMenus(),
			open(Port);
		{error, _} = Err ->
			Err
	end.

stop() ->
	close(),
	application:stop(?APP).

stop(Port) when is_integer(Port) ->
	close(Port),
	application:stop(?APP).

open(Port) ->
	open(Port, []).

open(Port, ExtraOpts) when is_integer(Port) ->
	Opts = [{wsMod, gmRouter} | ExtraOpts],
	try eWSrv:openSrv(Port, Opts) of
		{ok, _} = Ok ->
			Ok;
		Other ->
			Other
	catch
		error:{badmatch, {error, {already_started, Pid}}} ->
			{ok, Pid};
		error:{badmatch, {error, Reason}} ->
			{error, Reason};
		error:{badmatch, Reason} ->
			{error, Reason}
	end.

close() ->
	case persistent_term:get(?usePort, undefined) of
		Port when is_integer(Port) -> close(Port);
		_ -> ok
	end.

close(Port) when is_integer(Port) ->
	try eWSrv:closeSrv(Port) of
		_ -> ok
	catch
		_:_ -> ok
	end.

-spec menuModule() -> module().
menuModule() ->
	gmMenus:menuModule().

-spec reloadMenus() -> ok.
reloadMenus() ->
	gmMenus:reloadMenus().

%% ========== internal ==========
parseArgs([], Port, MenuMod) ->
	{Port, MenuMod};
parseArgs(["--port", PortStr | Rest], _Port, MenuMod) ->
	parseArgs(Rest, parsePort(PortStr), MenuMod);
parseArgs(["--menu-module", ModStr | Rest], Port, _MenuMod) ->
	parseArgs(Rest, Port, list_to_atom(ModStr));
parseArgs([[$- | _] = Flag | _], _Port, _MenuMod) ->
	io:format("unknown flag: ~s~n", [Flag]),
	usage(),
	erlang:halt(2);
parseArgs([PortStr | Rest], _Port, MenuMod) ->
	parseArgs(Rest, parsePort(PortStr), MenuMod).

parsePort(PortStr) ->
	case string:to_integer(PortStr) of
		{Port, ""} when Port >= 1, Port =< 65535 ->
			Port;
		_ ->
			usage(),
			erlang:halt(2)
	end.

usage() ->
	io:format(
		"Usage:~n"
		"  gmTool [--port N] [--menu-module Mod]~n"
		"  gmTool [PORT]~n"
		"~n"
		"  --port          listen port (default ~p)~n"
		"  --menu-module   host menu module (default ~p)~n",
		[?DEFAULT_PORT, ?defMenusMod]
	).
