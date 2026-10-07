%%%-------------------------------------------------------------------
%%% @doc 宿主项目嵌入 gmTool 的引导模块（复制到自己的项目即可）。
%%%
%%% 用法:
%%%   1. rebar3 escriptize 得到 _build/default/bin/gmTool
%%%   2. 把该文件拷到宿主项目（如 priv/gmTool）
%%%   3. 把本文件拷到宿主 src/，编译进宿主应用
%%%   4. 实现自己的菜单模块（参考 gmExampleMenus.erl）和 *GHer
%%%   5. 把「GM接入参数返回值说明.md」一起复制给业务同事（接入+参数+返回值）
%%%   6. 启动:
%%%
%%%        {ok, _} = gmToolBootstrap:start("priv/gmTool", #{
%%%            port => 3000,
%%%            menuModule => myGameMenus
%%%        }).
%%%
%%% 说明:
%%%   - 本模块不依赖 gmTool 源码，只依赖 OTP 标准库
%%%   - 纯内存加载 escript，不写磁盘
%%% @end
%%%-------------------------------------------------------------------
-module(gmToolBootstrap).

-export([
	load/1
	, start/1
	, start/2
	, start/3
	, stop/0
]).

-define(DEFAULT_PORT, 3000).
-define(defMenusMod, gmExampleMenus).
-define(APP, gmTool).

%% @doc 仅把 escript 中的 beam/app 加载进当前节点（纯内存），不启动服务。
-spec load(file:filename_all()) -> ok | {error, term()}.
load(EscriptPath0) ->
	EscriptPath = filename:absname(unicodePath(EscriptPath0)),
	case filelib:is_file(EscriptPath) of
		false ->
			{error, {escript_not_found, EscriptPath}};
		true ->
			case escript:extract(EscriptPath, []) of
				{ok, Sections} ->
					case lists:keyfind(archive, 1, Sections) of
						{archive, ZipBin} when is_binary(ZipBin) ->
							loadArchiveMemory(ZipBin);
						false ->
							{error, no_archive_in_escript};
						Other ->
							{error, {bad_archive, Other}}
					end;
				{error, Reason} ->
					{error, Reason}
			end
	end.

%% @doc 加载并启动（默认端口 + gmExampleMenus）。
-spec start(file:filename_all()) -> {ok, term()} | {error, term()}.
start(EscriptPath) ->
	start(EscriptPath, #{port => ?DEFAULT_PORT, menuModule => ?defMenusMod}).

%% @doc 加载并启动。
%% start(Path, Port) | start(Path, #{port => N, menuModule => Mod})
-spec start(file:filename_all(), pos_integer() | map()) -> {ok, term()} | {error, term()}.
start(EscriptPath, Port) when is_integer(Port), Port > 0 ->
	start(EscriptPath, #{port => Port, menuModule => ?defMenusMod});
start(EscriptPath, Opts) when is_map(Opts) ->
	case load(EscriptPath) of
		ok ->
			case code:ensure_loaded(?APP) of
				{module, ?APP} ->
					?APP:start(Opts);
				{error, Reason} ->
					{error, {cannot_load_gmTool, Reason}}
			end;
		{error, _} = Err ->
			Err
	end.

%% @doc 加载并启动，显式指定端口与菜单模块。
-spec start(file:filename_all(), pos_integer(), atom()) -> {ok, term()} | {error, term()}.
start(EscriptPath, Port, MenuMod) when is_integer(Port), Port > 0, is_atom(MenuMod) ->
	start(EscriptPath, #{port => Port, menuModule => MenuMod}).

%% @doc 停止 gmTool 应用（若已启动）。
-spec stop() -> ok | {error, term()}.
stop() ->
	case erlang:function_exported(?APP, stop, 0) of
		true ->
			?APP:stop();
		false ->
			application:stop(?APP)
	end.

%% ========== internal ==========
loadArchiveMemory(ZipBin) ->
	case zip:extract(ZipBin, [memory]) of
		{ok, Files} ->
			Beams = [{N, B} || {N, B} <- Files, isBeam(N)],
			Apps = [{N, B} || {N, B} <- Files, isApp(N)],
			case Beams of
				[] ->
					{error, no_beam_in_archive};
				_ ->
					case loadBeams(orderBeams(Beams)) of
						ok ->
							loadApps(Apps);
						{error, _} = Err ->
							Err
					end
			end;
		{error, Reason} ->
			{error, {zip_extract_failed, Reason}}
	end.

loadBeams(Beams) ->
	loadBeamsPass(Beams, length(Beams) + 2).

%% gmExampleMenus → gmMenus → gmTool（照顾 -on_load 依赖）
orderBeams(Beams) ->
	lists:sort(
		fun({A, _}, {B, _}) ->
			beamPrio(A) =< beamPrio(B)
		end,
		Beams
	).

beamPrio(Name) ->
	case filename:basename(Name, ".beam") of
		"gmTool" -> 3;
		"gmMenus" -> 2;
		"gmExampleMenus" -> 1;
		_ -> 0
	end.

loadBeamsPass([], _Left) ->
	ok;
loadBeamsPass(Pending, 0) ->
	Reasons = [
		begin
			Mod = list_to_atom(filename:basename(Name, ".beam")),
			_ = code:soft_purge(Mod),
			{Mod, element(2, code:load_binary(Mod, Name, Bin))}
		end || {Name, Bin} <- Pending
	],
	{error, {load_beam_failed, Reasons}};
loadBeamsPass(Pending, Left) ->
	{Done, Remain} = lists:foldl(
		fun({Name, Bin}, {Ok, Fail}) ->
			Mod = list_to_atom(filename:basename(Name, ".beam")),
			_ = code:soft_purge(Mod),
			case code:load_binary(Mod, Name, Bin) of
				{module, Mod} ->
					{[{Name, Bin} | Ok], Fail};
				{error, _Reason} ->
					{Ok, [{Name, Bin} | Fail]}
			end
		end,
		{[], []},
		Pending
	),
	case Done of
		[] ->
			loadBeamsPass(Remain, 0);
		_ ->
			loadBeamsPass(Remain, Left - 1)
	end.

loadApps([]) ->
	ok;
loadApps([{Name, Bin} | Rest]) ->
	case parseApp(Bin) of
		{ok, AppSpec} ->
			case application:load(AppSpec) of
				ok ->
					loadApps(Rest);
				{error, {already_loaded, _}} ->
					loadApps(Rest);
				{error, Reason} ->
					{error, {load_app_failed, Name, Reason}}
			end;
		{error, Reason} ->
			{error, {parseAppFailed, Name, Reason}}
	end.

parseApp(Bin) ->
	Str = unicode:characters_to_list(Bin),
	case erl_scan:string(Str) of
		{ok, Tokens, _} ->
			case erl_parse:parse_term(Tokens) of
				{ok, {application, _, _} = Spec} ->
					{ok, Spec};
				{ok, Other} ->
					{error, {bad_app_term, Other}};
				{error, Reason} ->
					{error, Reason}
			end;
		{error, Reason, _} ->
			{error, Reason}
	end.

isBeam(Name) ->
	filename:extension(Name) =:= ".beam".

isApp(Name) ->
	filename:extension(Name) =:= ".app".

unicodePath(Path) when is_list(Path) -> Path;
unicodePath(Path) when is_binary(Path) -> unicode:characters_to_list(Path).
