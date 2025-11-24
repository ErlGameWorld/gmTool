-module(itemGHer).
-export([handle/2]).

-include_lib("eWSrv/include/wsCom.hrl").

handle(<<"/items">>, WsReq) ->
	% 获取物品列表 - 从comGHer.erl迁移
	#wsReq{args = Args} = WsReq,
	Params = maps:from_list(Args),
	
	Page = case maps:get(<<"page">>, Params, <<"1">>) of
		<<"">> -> 1;
		P -> binary_to_integer(P)
	end,
	PageSize = case maps:get(<<"pageSize">>, Params, <<"10">>) of
		<<"">> -> 10;
		PS -> binary_to_integer(PS)
	end,
	Search = maps:get(<<"search">>, Params, <<"">>),
	Type = maps:get(<<"type">>, Params, <<"all">>),
	Rarity = maps:get(<<"rarity">>, Params, <<"all">>),
	
	% 获取物品数据
	Items = get_items(),
	FilteredItems = filter_items(Items, Search, Type, Rarity),
	PagedItems = paginate_list(FilteredItems, Page, PageSize),
	Total = length(FilteredItems),
	
	Response = #{
		success => true,
		data => PagedItems,
		total => Total,
		page => Page,
		pageSize => PageSize
	},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};

handle(<<"/item">>, _WsReq) ->
	% 获取物品列表
	Items = [
		#{id => 1001, name => <<"金币"/utf8>>, type => <<"currency">>, maxStack => 999999},
		#{id => 1002, name => <<"钻石"/utf8>>, type => <<"currency">>, maxStack => 999999},
		#{id => 2001, name => <<"生命药水"/utf8>>, type => <<"consumable">>, effect => <<"恢复生命值"/utf8>>},
		#{id => 2002, name => <<"魔法药水"/utf8>>, type => <<"consumable">>, effect => <<"恢复魔法值"/utf8>>},
		#{id => 3001, name => <<"铁剑"/utf8>>, type => <<"weapon">>, attack => 15, durability => 100}
	],
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Items)};

handle(<<"/item/", ItemId/binary>>, _WsReq) ->
	% 获取单个物品信息
	Item = #{id => binary_to_integer(ItemId), name => <<"物品详情">>, type => <<"item">>, description => <<"这是一个物品">>},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Item)};

handle(<<"/item/update/", ItemId/binary>>, WsReq) ->
	% 更新物品信息
	Body = eWSrv:get_body(WsReq),
	case json:decode(Body, [return_maps]) of
		#{<<"name">> := Name, <<"type">> := Type, <<"description">> := Description} ->
			Response = #{
				<<"success">> => true,
				<<"message">> => <<"物品信息更新成功">>,
				<<"itemId">> => binary_to_integer(ItemId),
				<<"updatedFields">> => #{<<"name">> => Name, <<"type">> => Type, <<"description">> => Description}
			},
			{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
		_ ->
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid request format">>})}
	end;

handle(<<"/item/delete/", ItemId/binary>>, _WsReq) ->
	% 删除物品
	Response = #{
		<<"success">> => true,
		<<"message">> => <<"物品删除成功">>,
		<<"itemId">> => binary_to_integer(ItemId)
	},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};

handle(<<"/item/add">>, WsReq) ->
	% 添加物品
	Body = eWSrv:get_body(WsReq),
	case json:decode(Body, [return_maps]) of
		#{<<"playerId">> := PlayerId, <<"itemId">> := ItemId, <<"quantity">> := Quantity} ->
			Response = #{
				<<"success">> => true,
				<<"message">> => <<"物品添加成功">>,
				<<"playerId">> => PlayerId,
				<<"itemId">> => ItemId,
				<<"quantity">> => Quantity
			},
			{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
		_ ->
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid request format">>})}
	end;

handle(<<"/items">>, WsReq) when WsReq#wsReq.method =:= 'POST' ->
	% 创建物品 - 从comGHer.erl迁移
	case eWSrv:get_body(WsReq) of
		{ok, Body} ->
			case json:decode(Body) of
				ItemData when is_map(ItemData) ->
					% 模拟创建物品
					NewItem = #{
						id => erlang:system_time(millisecond),
						name => maps:get(<<"name">>, ItemData, <<"新物品">>),
						type => maps:get(<<"type">>, ItemData, <<"equipment">>),
						rarity => maps:get(<<"rarity">>, ItemData, <<"common">>),
						level => maps:get(<<"level">>, ItemData, 1),
						description => maps:get(<<"description">>, ItemData, <<"">>)
					},
					Response = #{
						success => true,
						data => NewItem,
						message => <<"物品创建成功">>
					},
					{201, [{<<"content-type">>, <<"application/json">>}], json:encode(Response)};
				_ ->
					{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid item data">>})}
			end;
		_ ->
			{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid request body">>})}
	end;

handle(Path, WsReq) when WsReq#wsReq.method =:= 'PUT' ->
	case binary:split(Path, <<"/">>, [global]) of
		[<<>>, <<"items">>, ItemIdStr] ->
			case string:to_integer(binary_to_list(ItemIdStr)) of
				{ItemId, []} ->
					case eWSrv:get_body(WsReq) of
						{ok, Body} ->
							case json:decode(Body) of
								Updates when is_map(Updates) ->
									% 模拟更新物品
									Response = #{
										success => true,
										message => list_to_binary(io_lib:format("Item ~p updated successfully", [ItemId]))
									},
									{200, [{<<"content-type">>, <<"application/json">>}], json:encode(Response)};
								_ ->
									{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid update data">>})}
							end;
						_ ->
							{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid request body">>})}
					end;
				_ ->
					{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid item ID">>})}
			end;
		_ ->
			{404, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Not Found">>})}
	end;

handle(<<"/items/batch">>, WsReq) when WsReq#wsReq.method =:= 'POST' ->
	% 批量删除物品 - 从comGHer.erl迁移
	case eWSrv:get_body(WsReq) of
		{ok, Body} ->
			case json:decode(Body) of
				#{ids := Ids} when is_list(Ids) ->
					% 模拟批量删除
					Response = #{
						success => true,
						message => list_to_binary(io_lib:format("Deleted ~p items successfully", [length(Ids)]))
					},
					{200, [{<<"content-type">>, <<"application/json">>}], json:encode(Response)};
				_ ->
					{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid request format">>})}
			end;
		_ ->
			{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid request body">>})}
	end;

handle(_Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.

% 辅助函数 - 从comGHer.erl迁移
get_items() ->
	[
		{1, <<"屠龙宝刀">>, <<"weapon">>, <<"legendary">>, 80, <<"传说中的神器，威力无穷">>},
		{2, <<"黄金战甲">>, <<"armor">>, <<"epic">>, 70, <<"黄金打造的坚固战甲">>},
		{3, <<"治疗药水">>, <<"consumable">>, <<"common">>, 1, <<"恢复少量生命值">>},
		{4, <<"魔法戒指">>, <<"accessory">>, <<"rare">>, 50, <<"增加魔法攻击力">>},
		{5, <<"火焰法杖">>, <<"weapon">>, <<"epic">>, 75, <<"蕴含火焰魔法的法杖">>},
		{6, <<"隐身斗篷">>, <<"armor">>, <<"legendary">>, 85, <<"可以让使用者隐身的斗篷">>},
		{7, <<"经验药水">>, <<"consumable">>, <<"uncommon">>, 5, <<"增加角色经验值">>},
		{8, <<"守护项链">>, <<"accessory">>, <<"rare">>, 55, <<"提供额外的防御力">>},
		{9, <<"冰霜之剑">>, <<"weapon">>, <<"epic">>, 78, <<"蕴含冰霜魔法的长剑">>},
		{10, <<"龙鳞盾牌">>, <<"armor">>, <<"legendary">>, 88, <<"用龙鳞打造的坚固盾牌">>}
	].

filter_items(Items, Search, Type, Rarity) ->
	lists:filter(fun({Id, Name, ItemType, ItemRarity, _Level, _Description}) ->
		MatchesSearch = Search =:= <<"">> orelse 
			string:str(integer_to_list(Id), binary_to_list(Search)) > 0 orelse
			string:str(binary_to_list(Name), binary_to_list(Search)) > 0,
		MatchesType = Type =:= <<"all">> orelse ItemType =:= Type,
		MatchesRarity = Rarity =:= <<"all">> orelse ItemRarity =:= Rarity,
		MatchesSearch andalso MatchesType andalso MatchesRarity
	end, Items).

paginate_list(List, Page, PageSize) ->
	StartIndex = (Page - 1) * PageSize + 1,
	EndIndex = Page * PageSize,
	lists:sublist(List, StartIndex, EndIndex - StartIndex + 1).