-module(gmExItemGHer).
-export([handle/2]).

-include_lib("eWSrv/include/eWSrv.hrl").

handle(<<"/items">>, _WsReq) ->
	Cols = [
		{id, <<"物品ID"/utf8>>},
		{name, <<"名称"/utf8>>},
		{type, <<"类型"/utf8>>},
		{rarity, <<"稀有度"/utf8>>},
		{count, <<"数量"/utf8>>}
	],
	Rows = [
		[10001, <<"生命药水"/utf8>>, <<"消耗品"/utf8>>, <<"普通"/utf8>>, 99],
		[10002, <<"铁剑"/utf8>>, <<"武器"/utf8>>, <<"优秀"/utf8>>, 1],
		[10003, <<"龙鳞甲"/utf8>>, <<"防具"/utf8>>, <<"史诗"/utf8>>, 1],
		[10004, <<"传送卷轴"/utf8>>, <<"消耗品"/utf8>>, <<"稀有"/utf8>>, 10]
	],
	{table, Cols, Rows, #{total => length(Rows)}};

handle(<<"/items/add">>, WsReq) ->
	case bodyMap(WsReq) of
		{ok, #{<<"player_id">> := Pid, <<"item_id">> := Iid} = Body} ->
			Qty = maps:get(<<"quantity">>, Body, 1),
			Bind = maps:get(<<"bind">>, Body, <<"false">>),
			{json, #{
				playerId => Pid,
				itemId => Iid,
				quantity => Qty,
				bind => Bind
			}, <<"添加物品成功"/utf8>>};
		{ok, _} ->
			{error, <<"缺少 player_id 或 item_id"/utf8>>};
		{error, Reason} ->
			{error, Reason}
	end;

handle(_Path, _WsReq) ->
	not_found.

bodyMap(WsReq) ->
	Raw = try eWSrv:body(WsReq) of
		Bin when is_binary(Bin) -> Bin;
		List when is_list(List) -> iolist_to_binary(List);
		_ -> <<>>
	catch
		_:_ -> <<>>
	end,
	case Raw of
		<<>> -> {error, <<"Empty request body">>};
		JsonBin ->
			try {ok, json:decode(JsonBin)}
			catch _:_ -> {error, <<"Invalid JSON">>}
			end
	end.
