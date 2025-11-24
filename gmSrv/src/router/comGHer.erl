-module(comGHer).
-include_lib("eWSrv/include/wsCom.hrl").
-include("common.hrl").
-export([handle/2]).

% 静态文件处理函数
handle(<<"/">>, _WsReq) ->
	% 构建静态文件路径
	FilePath = filename:join([code:priv_dir(gmSrv), <<"static">>, <<"index.html">>]),
	% 检查文件是否存在
	case readAssets(FilePath) of
		{ok, FileContent} ->
			ContentType = contentType(FilePath),
			Headers = [{<<"Content-Type">>, ContentType}],
			{200, Headers, FileContent};
		{error, Error} ->
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => Error})}
	end;
handle(<<"/login">>, _WsReq) ->
	% 处理前端路由：返回index.html让前端路由处理
	FilePath = filename:join([code:priv_dir(gmSrv), <<"static">>, <<"index.html">>]),
	case readAssets(FilePath) of
		{ok, FileContent} ->
			ContentType = contentType(FilePath),
			Headers = [{<<"Content-Type">>, ContentType}],
			{200, Headers, FileContent};
		{error, Error} ->
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => Error})}
	end;
handle(<<"/assets/", LBin/binary>>, _WsReq) ->
	% 检查是否为静态文件路径（支持/assets/路径和常见静态文件扩展名）
	FilePath = filename:join([code:priv_dir(gmSrv), <<"static/assets">>, LBin]),
	io:format("IMY****** ~p ~p ~n", [FilePath, filename:extension(FilePath)]),
	% 检查文件是否存在
	case readAssets(FilePath) of
		{ok, FileContent} ->
			ContentType = contentType(FilePath),
			Headers = [{<<"Content-Type">>, ContentType}],
			{200, Headers, FileContent};
		{error, Error} ->
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => Error})}
	end;
handle(Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"undefined path:", Path/binary>>})}.

readAssets(FilePath) ->
	case ets:lookup(?assetsCache, FilePath) of
		[] ->
			case file:read_file(FilePath, [raw]) of
				{ok, FileContent} ->
					ets:insert(?assetsCache, {FilePath, FileContent}),
					{ok, FileContent};
				{error, Error} ->
					{error, Error}
			end;
		[{_FilePath, FileContent}] ->
			{ok, FileContent}
	end.

% 获取文件Content-Type
contentType(FilePath) ->
	case filename:extension(FilePath) of
		<<".html">> -> <<"text/html">>;
		<<".css">> -> <<"text/css">>;
		<<".js">> -> <<"text/javascript">>;
		<<".mjs">> -> <<"text/javascript">>;
		<<".png">> -> <<"image/png">>;
		<<".jpg">> -> <<"image/jpeg">>;
		<<".jpeg">> -> <<"image/jpeg">>;
		<<".gif">> -> <<"image/gif">>;
		<<".ico">> -> <<"image/x-icon">>;
		<<".json">> -> <<"application/json">>;
		<<".svg">> -> <<"image/svg+xml">>;
		<<".wasm">> -> <<"application/wasm">>;
		_ -> <<"application/octet-stream">>
	end.