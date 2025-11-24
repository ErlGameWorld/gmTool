-ifndef(menus_h_).
-define(menus_h_, true).

%%% @doc GM工具参数类型定义
%%% 定义所有支持的参数类型常量，用于菜单配置和参数验证

%% 基础输入类型
-define(PARAM_TYPE_TEXT, <<"text">>).           % 基础文本输入
-define(PARAM_TYPE_TEXTAREA, <<"textarea">>).     % 多行文本输入
-define(PARAM_TYPE_NUMBER, <<"number">>).         % 数字输入
-define(PARAM_TYPE_PASSWORD, <<"password">>).     % 密码输入
-define(PARAM_TYPE_EMAIL, <<"email">>).          % 邮箱格式验证
-define(PARAM_TYPE_URL, <<"url">>).              % URL格式验证

%% 选择器类型
-define(PARAM_TYPE_SELECT, <<"select">>).         % 下拉选择
-define(PARAM_TYPE_RADIO, <<"radio">>).          % 单选按钮
-define(PARAM_TYPE_CHECKBOX, <<"checkbox">>).     % 多选框
-define(PARAM_TYPE_SWITCH, <<"switch">>).         % 开关切换
-define(PARAM_TYPE_RATE, <<"rate">>).             % 评分组件

%% 日期时间类型
-define(PARAM_TYPE_DATE, <<"date">>).             % 日期选择
-define(PARAM_TYPE_DATETIME, <<"datetime">>).     % 日期时间选择
-define(PARAM_TYPE_TIME, <<"time">>).             % 时间选择
-define(PARAM_TYPE_DATE_RANGE, <<"date-range">>).           % 日期范围选择
-define(PARAM_TYPE_DATETIME_RANGE, <<"datetime-range">>).   % 日期时间范围选择


%% 特殊输入类型
-define(PARAM_TYPE_SLIDER, <<"slider">>).         % 滑块选择
-define(PARAM_TYPE_COLOR, <<"color">>).           % 颜色选择
-define(PARAM_TYPE_NUMBER_RANGE, <<"number-range">>). % 数字范围选择器

%% 参数验证规则定义
-define(VALIDATION_MIN, min).                      % 最小值验证
-define(VALIDATION_MAX, max).                      % 最大值验证
-define(VALIDATION_REQUIRED, required).            % 必填验证
-define(VALIDATION_PATTERN, pattern).              % 正则表达式验证

%% 参数配置选项
-define(PARAM_OPTION_VALUE, value).                 % 选项值
-define(PARAM_OPTION_LABEL, label).                 % 选项标签
-define(PARAM_OPTION_DEFAULT, defaultValue).       % 默认值
-define(PARAM_OPTION_PLACEHOLDER, placeholder).    % 占位符文本
-define(PARAM_OPTION_ROWS, rows).                   % 文本域行数

%% 菜单配置相关
-define(MENU_GROUP_ID, id).                         % 菜单组ID
-define(MENU_GROUP_NAME, name).                     % 菜单组名称
-define(MENU_GROUP_ICON, icon).                     % 菜单组图标
-define(MENU_GROUP_MENUS, menus).                   % 菜单组下的菜单列表

-define(MENU_ID, id).                               % 菜单ID
-define(MENU_NAME, name).                           % 菜单名称
-define(MENU_DESCRIPTION, description).             % 菜单描述
-define(MENU_ICON, icon).                           % 菜单图标
-define(MENU_PARAMS, params).                       % 菜单参数列表
-define(MENU_API_CONFIG, apiConfig).                % API配置

%% API配置相关
-define(API_METHOD, method).                        % HTTP方法
-define(API_PATH, path).                            % API路径

%% 常用HTTP方法
-define(HTTP_GET, <<"GET">>).                       % GET请求
-define(HTTP_POST, <<"POST">>).                     % POST请求
-define(HTTP_PUT, <<"PUT">>).                       % PUT请求
-define(HTTP_DELETE, <<"DELETE">>).                 % DELETE请求

%% 响应状态码
-define(STATUS_OK, 200).                            % 成功
-define(STATUS_CREATED, 201).                       % 创建成功
-define(STATUS_BAD_REQUEST, 400).                  % 请求错误
-define(STATUS_UNAUTHORIZED, 401).                  % 未授权
-define(STATUS_FORBIDDEN, 403).                     % 禁止访问
-define(STATUS_NOT_FOUND, 404).                     % 未找到
-define(STATUS_INTERNAL_ERROR, 500).                % 服务器错误

%% 错误消息
-define(ERROR_NOT_FOUND, <<"Not Found">>).         % 未找到错误
-define(ERROR_UNAUTHORIZED, <<"Unauthorized">>).    % 未授权错误
-define(ERROR_INVALID_PARAMS, <<"Invalid Parameters">>). % 参数错误

%% 成功消息
-define(SUCCESS_OPERATION, <<"Operation Successful">>). % 操作成功

%% @doc 获取所有支持的参数类型列表
%% @returns 参数类型列表
-spec get_supported_param_types() -> [binary()].
get_supported_param_types() ->
    [
        ?PARAM_TYPE_TEXT,
        ?PARAM_TYPE_TEXTAREA,
        ?PARAM_TYPE_NUMBER,
        ?PARAM_TYPE_PASSWORD,
        ?PARAM_TYPE_EMAIL,
        ?PARAM_TYPE_URL,
        ?PARAM_TYPE_SELECT,
        ?PARAM_TYPE_RADIO,
        ?PARAM_TYPE_CHECKBOX,
        ?PARAM_TYPE_SWITCH,
        ?PARAM_TYPE_RATE,
        ?PARAM_TYPE_DATE,
        ?PARAM_TYPE_DATETIME,
        ?PARAM_TYPE_TIME,
        ?PARAM_TYPE_DATE_RANGE,
        ?PARAM_TYPE_DATETIME_RANGE,
        ?PARAM_TYPE_SLIDER,
        ?PARAM_TYPE_COLOR,
        ?PARAM_TYPE_NUMBER_RANGE
    ].

%% @doc 验证参数类型是否支持
%% @param Type 参数类型
%% @returns true | false
-spec is_param_type_supported(binary()) -> boolean().
is_param_type_supported(Type) ->
    lists:member(Type, get_supported_param_types()).

%% @doc 获取参数类型的描述
%% @param Type 参数类型
%% @returns 类型描述
-spec get_param_type_description(binary()) -> binary().
get_param_type_description(Type) ->
    case Type of
        ?PARAM_TYPE_TEXT -> <<"基础文本输入框">>;
        ?PARAM_TYPE_TEXTAREA -> <<"多行文本输入框">>;
        ?PARAM_TYPE_NUMBER -> <<"数字输入框">>;
        ?PARAM_TYPE_PASSWORD -> <<"密码输入框">>;
        ?PARAM_TYPE_EMAIL -> <<"邮箱格式输入框">>;
        ?PARAM_TYPE_URL -> <<"URL格式输入框">>;
        ?PARAM_TYPE_SELECT -> <<"下拉选择框">>;
        ?PARAM_TYPE_RADIO -> <<"单选按钮组">>;
        ?PARAM_TYPE_CHECKBOX -> <<"多选框组">>;
        ?PARAM_TYPE_SWITCH -> <<"开关切换组件">>;
        ?PARAM_TYPE_RATE -> <<"评分组件">>;
        ?PARAM_TYPE_DATE -> <<"日期选择器">>;
        ?PARAM_TYPE_DATETIME -> <<"日期时间选择器">>;
        ?PARAM_TYPE_TIME -> <<"时间选择器">>;
        ?PARAM_TYPE_DATE_RANGE -> <<"日期范围选择器">>;
        ?PARAM_TYPE_DATETIME_RANGE -> <<"日期时间范围选择器">>;
        ?PARAM_TYPE_SLIDER -> <<"滑块选择器">>;
        ?PARAM_TYPE_COLOR -> <<"颜色选择器">>;
        ?PARAM_TYPE_NUMBER_RANGE -> <<"数字范围选择器">>;
        _ -> <<"未知参数类型">>
    end.

%% @doc 获取需要选项的参数类型列表
%% @returns 需要选项的参数类型列表
-spec get_option_required_types() -> [binary()].
get_option_required_types() ->
    [
        ?PARAM_TYPE_SELECT,
        ?PARAM_TYPE_RADIO,
        ?PARAM_TYPE_CHECKBOX
    ].

%% @doc 检查参数类型是否需要选项配置
%% @param Type 参数类型
%% @returns true | false
-spec is_option_required(binary()) -> boolean().
is_option_required(Type) ->
    lists:member(Type, get_option_required_types()).

-endif.