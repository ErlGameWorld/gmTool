-module(gmSrv).

-include("common.hrl").

-export([
	start/0
	, start/1
	, stop/0
	, reloadAssets/0
]).

-on_load(loadInit/0).

loadInit() ->
	menusGHer:module_info(),
	ok.
reloadAssets() ->
	ets:delete_all_objects(?assetsCache).

start() ->
	start(3000).

start(Port) ->
	application:ensure_all_started(gmSrv),
	eWSrv:openSrv(Port, [{wsMod, gmRouter}]).

stop() ->
	application:stop(gmSrv).