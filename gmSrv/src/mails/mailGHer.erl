-module(mailGHer).
-export([handle/2]).

-include_lib("eWSrv/include/eWSrv.hrl").

handle(<<"/mails">>, WsReq) ->
	% 获取邮件列表 - 从comGHer.erl迁移
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
	
	% 获取邮件数据
	Mails = get_mails(),
	FilteredMails = filter_mails(Mails, Search, Type),
	PagedMails = paginate_list(FilteredMails, Page, PageSize),
	Total = length(FilteredMails),
	
	Response = #{
		success => true,
		data => PagedMails,
		total => Total,
		page => Page,
		pageSize => PageSize
	},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};

handle(<<"/mail">>, _WsReq) ->
	% 获取邮件列表
	Mails = [
		#{id => 1, title => <<"系统公告"/utf8>>, content => <<"服务器维护通知"/utf8>>, sender => <<"系统"/utf8>>, timestamp => <<"2024-01-01 10:00:00">>, status => <<"unread">>},
		#{id => 2, title => <<"活动奖励"/utf8>>, content => <<"恭喜获得活动奖励"/utf8>>, sender => <<"活动中心"/utf8>>, timestamp => <<"2024-01-01 09:30:00">>, status => <<"read">>},
		#{id => 3, title => <<"GM通知"/utf8>>, content => <<"违规行为警告"/utf8>>, sender => <<"GM"/utf8>>, timestamp => <<"2024-01-01 09:00:00">>, status => <<"unread">>}
	],
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Mails)};

handle(<<"/mail/send">>, WsReq) ->
	% 发送邮件
	Body = eWSrv:get_body(WsReq),
	case json:decode(Body) of
		{ok, #{<<"title">> := _Title, <<"content">> := _Content, <<"recipients">> := _Recipients}} ->
			% 发送邮件逻辑
			Response = #{<<"success">> => true, <<"message">> => <<"邮件发送成功"/utf8>>},
			{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
		_ ->
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid request body">>})}
	end;

handle(<<"/mail/delete/", MailId/binary>>, _WsReq) ->
	% 删除邮件
	Response = #{<<"success">> => true, <<"message">> => <<"邮件删除成功"/utf8>>, <<"mailId">> => binary_to_integer(MailId)},
	{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};

% 批量删除邮件
handle(<<"/mail/batch">>, WsReq) ->
	Body = eWSrv:get_body(WsReq),
	case json:decode(Body) of
		{ok, #{<<"ids">> := Ids}} when is_list(Ids) ->
			Response = #{<<"success">> => true, <<"deleted">> => Ids},
			{200, [{<<"Content-Type">>, <<"application/json">>}], json:encode(Response)};
		_ ->
			{400, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Invalid request body">>})}
	end;

handle(<<"/mails/send">>, WsReq) when WsReq#wsReq.method =:= 'POST' ->
	% 发送邮件 - 从comGHer.erl迁移
	case eWSrv:get_body(WsReq) of
		{ok, Body} ->
			case json:decode(Body) of
				MailData when is_map(MailData) ->
					% 模拟发送邮件
					NewMail = #{
						id => erlang:system_time(millisecond),
						title => maps:get(<<"title">>, MailData, <<"新邮件">>),
						sender => <<"GM">>,
						recipient => maps:get(<<"recipient">>, MailData, <<"全体玩家">>),
						recipientType => maps:get(<<"recipientType">>, MailData, <<"all">>),
						type => maps:get(<<"type">>, MailData, <<"system">>),
						status => <<"unread">>,
						content => maps:get(<<"content">>, MailData, <<"">>),
						sendTime => list_to_binary(calendar:local_time_to_string(calendar:local_time())),
						expireTime => list_to_binary(calendar:local_time_to_string(calendar:local_time())),
						hasAttachments => false
					},
					Response = #{
						success => true,
						data => NewMail,
						message => <<"邮件发送成功">>
					},
					{201, [{<<"content-type">>, <<"application/json">>}], json:encode(Response)};
				_ ->
					{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid mail data">>})}
			end;
		_ ->
			{400, [{<<"content-type">>, <<"application/json">>}], json:encode(#{error => <<"Invalid request body">>})}
	end;

handle(_Path, _WsReq) ->
	{404, [{<<"Content-Type">>, <<"application/json">>}], json:encode(#{<<"error">> => <<"Not Found">>})}.

% 辅助函数 - 从comGHer.erl迁移
get_mails() ->
	[
		#{
			id => 1,
			title => <<"系统公告">>,
			sender => <<"系统管理员">>,
			recipient => <<"全体玩家">>,
			recipientType => <<"all">>,
			type => <<"system">>,
			status => <<"unread">>,
			content => <<"欢迎来到游戏世界！祝您游戏愉快！">>,
			sendTime => <<"2023-08-15 10:00:00">>,
			expireTime => <<"2023-08-22 10:00:00">>,
			hasAttachments => false
		},
		#{
			id => 2,
			title => <<"活动奖励">>,
			sender => <<"活动管理员">>,
			recipient => <<"张三">>,
			recipientType => <<"player">>,
			type => <<"reward">>,
			status => <<"read">>,
			content => <<"恭喜您在活动中获得奖励！">>,
			sendTime => <<"2023-08-14 15:30:00">>,
			expireTime => <<"2023-08-21 15:30:00">>,
			hasAttachments => true
		},
		#{
			id => 3,
			title => <<"维护通知">>,
			sender => <<"技术团队">>,
			recipient => <<"全体玩家">>,
			recipientType => <<"all">>,
			type => <<"maintenance">>,
			status => <<"unread">>,
			content => <<"服务器将于今晚进行维护，请提前下线。">>,
			sendTime => <<"2023-08-13 20:00:00">>,
			expireTime => <<"2023-08-14 20:00:00">>,
			hasAttachments => false
		}
	].

filter_mails(Mails, Search, Type) ->
	lists:filter(fun(Mail) ->
		Title = maps:get(title, Mail, <<"">>),
		Content = maps:get(content, Mail, <<"">>),
		MailType = maps:get(type, Mail, <<"">>),
		
		MatchesSearch = Search =:= <<"">> orelse 
			string:str(binary_to_list(Title), binary_to_list(Search)) > 0 orelse
			string:str(binary_to_list(Content), binary_to_list(Search)) > 0,
		MatchesType = Type =:= <<"all">> orelse MailType =:= Type,
		MatchesSearch andalso MatchesType
	end, Mails).

paginate_list(List, Page, PageSize) ->
	StartIndex = (Page - 1) * PageSize + 1,
	EndIndex = Page * PageSize,
	lists:sublist(List, StartIndex, EndIndex - StartIndex + 1).