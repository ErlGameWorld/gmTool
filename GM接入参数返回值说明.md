# gmTool 完整说明文档（接入 + 参数 + 返回值）

> **宿主项目请只复制 / 只看这一份文档。**  
> 嵌入时连同 escript、`gmToolBootstrap.erl` 一起带过去即可；不必再翻 README 或其它说明。
>
> **推荐阅读顺序：** `0.1–0.6` 接入 → **`0.7` 场景选型表** → 中间「参数类型」按需查 → 文末「返回值」→ `0.10` 自检 / 附录 FAQ。

---

## 零、接入说明（嵌入其它 Erlang 项目）

### 0.1 复制什么

| 物品 | 作用 |
|------|------|
| `_build/default/bin/gmTool`（escript） | 运行时本体（已内嵌前端），放到宿主如 `priv/gmTool` |
| `src/utils/gmToolBootstrap.erl` | 宿主引导模块：内存加载 escript 并启动 |
| **本文档** | 菜单 / 参数类型 / 返回值约定 |

**不需要**复制：`gmCli/`、`scripts/`、前端源码（那些只用于维护 gmTool 本仓库时重新打包 UI）。

### 0.2 启动

```erlang
{ok, _} = gmToolBootstrap:start("priv/gmTool", #{
    port => 3000,
    menuModule => myGameMenus   %% 你自己的菜单模块
}).
```

或：`gmToolBootstrap:start("priv/gmTool", 3000, myGameMenus).`

演示登录账号：`admin` / `admin123`（生产请替换鉴权）。

### 0.3 最小菜单模块

```erlang
-module(myGameMenus).
-export([menus/0, handlers/0]).

menus() ->
    [
        #{
            id => <<"mgPlayer">>,
            name => <<"玩家管理"/utf8>>,
            icon => <<"fa-users">>,
            menus => [
                #{
                    id => <<"menu_query_players">>,
                    name => <<"查询玩家"/utf8>>,
                    description => <<"分页查询"/utf8>>,
                    icon => <<"fa-search">>,
                    apiConfig => #{
                        method => <<"GET">>,
                        path => <<"/player">>,
                        sendToGMSrv => true
                    },
                    params => [],          %% 参数写法见下文「参数类型」章节
                    autoRun => true        %% 可选：打开即请求
                }
            ]
        }
    ].

%% 路径第一段 → 处理模块（务必显式登记）
handlers() ->
    [
        {<<"player">>, myPlayerGHer},
        {<<"servers">>, myServerGHer}   %% 顶部选服栏需要 GET /servers
    ].
```

GHer：`handle/2` 里返回约定数据即可（见文末「返回值格式」），**不要**自己拼 HTTP/JSON。

```erlang
-module(myPlayerGHer).
-export([handle/2]).
handle(<<"/player">>, _WsReq) -> {table, Columns, Rows, #{total => N}};
handle(_, _) -> not_found.
```

框架与示例模块用 `gm*` / `gmEx*` 前缀；宿主模块名可自定，在 `handlers/0` 登记即可。

### 0.4 菜单项字段 / sendToGMSrv / autoRun

| 字段 | 必选 | 说明 |
|------|------|------|
| `id` | 是 | 全局唯一 |
| `name` | 是 | 侧栏显示名 |
| `description` | 否 | 打开后说明 |
| `icon` | 否 | 如 `<<"fa-search">>` |
| `apiConfig` | 是 | `#{method, path, sendToGMSrv}` |
| `params` | 否 | 见下文参数类型章节；无参 `[]` |
| `autoRun` | 否 | `true` = 打开即自动执行一次 |

| `sendToGMSrv` | 行为 |
|---------------|------|
| 缺省 / `true` | 请求打到 **GM 本机** GHer |
| `false` | 浏览器直连顶部选中区服（需先选服；注意 CORS） |

`autoRun => true`：打开菜单用默认参数自动请求；写操作不要开。`sendToGMSrv => false` 时会等选服就绪再跑。

侧栏顺序：`宿主 menus() ++ 框架工具面板（置底）`。

### 0.5 顶部服务器列表 `GET /servers`

前端顶栏会请求该接口。行数据至少含：`id`、`name`、`serverAddress`、`port`（`group` 可选）。建议用 `{table, Cols, Rows, Meta}` 返回（见文末返回值章节）。

### 0.6 独立运行（调试）

```bash
rebar3 compile && rebar3 escriptize
_build/default/bin/gmTool --port 3000 --menu-module gmExampleMenus
```

侧栏「返回格式演示」「参数输入演示」可对照本文逐项点开。

### 0.7 场景选型（先看这张表）

| 你想在界面上看到什么 | 菜单怎么配 | GHer 返回什么 |
|----------------------|------------|---------------|
| 列表 / 可排序表格 / 分页 | `params` 可选 page/pageSize；列表可 `autoRun` | `{table, Cols, Rows}` 或带 Meta |
| 点单元格跳到详情 | 列 Extra 里配 `link`；目标菜单 `id` 已存在 | 同上 table |
| 行右侧「详情/删除」按钮 | Meta.`actions`（跳菜单或调 api） | 同上 table |
| 详情页键值对 | 详情菜单带 `player_id` 等参数 | `{kv, Pairs}` |
| 几个指标卡片 | 无参或少参；可 `autoRun` | `{cards, Cards}` |
| 操作成功一句话 | 写操作菜单，**不要** autoRun | `{msg, <<"...">>}` 或 `ok` |
| 任意结构 JSON | — | `{json, Map}` / `{json, Map, Msg}` |
| 结果区再出可提交表单 | 少用；菜单本身通常已有表单 | `{form, Params, Meta}` |
| 成功后自动打开另一菜单 | — | `{redirect, #{menu => ...}}` |
| 业务失败提示 | — | `{error, Reason}` / `{error, Code, Reason}` |
| 资源不存在 | — | `not_found` |
| 打本机 GM | `sendToGMSrv => true`（或缺省） | 任意上表 |
| 打顶部选中的游戏服 | `sendToGMSrv => false`，且先选服 | 区服自己的 HTTP 约定（非本手册打包） |

### 0.8 GHer 里怎么读前端传来的参数

路由：菜单 `apiConfig.path` 的**第一段**决定模块（如 `<<"/players/kick">>` → `handlers` 里 `<<"players">>`），`handle/2` 的第一个参数是**完整 path**。

| 菜单 method | 参数在哪 | 典型读法（eWSrv） |
|-------------|----------|-------------------|
| `GET` | Query | `Q = eWSrv:mapargs(WsReq), maps:get(<<"page">>, Q, <<"1">>)` |
| `POST` / `PUT` | JSON Body | `Body = eWSrv:body(WsReq)` 再 `json:decode(Body)`（注意空 body） |

字段名 = 菜单 `params` 里的 `name`（binary）。  
路径里若写了 `<<"/players/{id}">>`，前端会用表单同名字段替换 `{id}`。

字符串请用 `<<"中文"/utf8>>`，避免编码问题。

```erlang
handle(<<"/players/kick">>, WsReq) ->
    Raw = eWSrv:body(WsReq),
    Body = case Raw of
        Bin when is_binary(Bin), Bin =/= <<>> ->
            case catch json:decode(Bin) of M when is_map(M) -> M; _ -> #{} end;
        _ -> #{}
    end,
    PlayerId = maps:get(<<"player_id">>, Body, undefined),
    Reason = maps:get(<<"reason">>, Body, <<>>),
    %% ... 业务 ...
    {msg, <<"已踢出"/utf8>>}.
```

### 0.9 配置时不要做的事

- 不要在 GHer 里自己 `json:encode` 再返回 HTTP 三元组（除非你很清楚在做透传）。
- 不要调用 `gmReply:*`；只返回约定元组 / atom。
- 不要依赖「路径自动推导模块名」；**必须**写 `handlers/0`。
- 写操作菜单不要开 `autoRun`。
- 菜单 `id` 必须全局唯一（跳转 / actions 都靠它）。
- 宿主模块尽量不要用无前缀的 `playerGHer` 这类名，以免和别的依赖冲突（示例用 `gmEx*`）。

### 0.10 接入自检清单

- [ ] 已复制 escript + `gmToolBootstrap.erl` + **本文档**
- [ ] `menuModule` 指向已编译的菜单模块
- [ ] `menus/0` 每项有 `id/name/apiConfig/params`
- [ ] `handlers/0` 覆盖所有 path 第一段（含 `servers`）
- [ ] 本机接口 `sendToGMSrv` 为 true 或缺省
- [ ] 列表类需要时开了 `autoRun` 并配了 `defaultValue`
- [ ] `handle/2` 返回的是约定格式，且能在侧栏演示里找到同类效果

---

# GM工具参数类型完整说明

## 📋 文档概述

本文档基于GM工具前后端完整实现，详细说明18种参数类型的配置方法。文档结合前端`FunctionPanel.jsx`的实际渲染逻辑和后端`menus.hrl`的类型定义，提供Erlang格式的配置示例，确保配置的准确性和实用性。

## 🔧 参数配置结构标准

### 通用参数结构
所有参数配置必须包含以下核心字段：

```erlang
#{
    name => <<"参数名">>,           % 必选 - API字段名
    label => <<"显示标签">>,        % 必选 - 用户界面显示文本
    type => <<"参数类型">>,         % 必选 - 参数类型标识
    required => true | false,       % 可选 - 是否必填，默认false
    placeholder => <<"占位文本">>,   % 可选 - 输入框占位文本
    description => <<"参数说明">>,   % 可选 - 参数详细说明，前端显示问号提示
    options => #{...}               % 可选 - 类型特定选项配置
}
```

### 配置优先级说明
前端处理逻辑遵循以下优先级：
- **优先使用options字段**中的配置
- **其次兼容原有validation字段**（向后兼容）
- **默认值优先级**：优先使用`options.defaultValue`

## 📊 参数类型详细说明

### 1. text - 基础文本输入框

**使用场景**：单行文本输入，如用户名、标题、描述等
**前端组件**：`<Input />`
**后端类型**：`"text"`

**Erlang配置示例**：
```erlang
#{
    name => <<"username">>,
    label => <<"用户名">>,
    type => <<"text">>,
    required => true,
    placeholder => <<"请输入用户名">>,
    options => #{
        defaultValue => <<"默认用户名">>  % 可选 - 默认值
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options`

---

### 2. textarea - 多行文本输入框

**使用场景**：多行文本输入，如描述、备注、详细说明等
**前端组件**：`<Input.TextArea />`
**后端类型**：`"textarea"`

**Erlang配置示例**：
```erlang
#{
    name => <<"description">>,
    label => <<"描述信息">>,
    type => <<"textarea">>,
    required => false,
    placeholder => <<"请输入详细描述">>,
    options => #{
        defaultValue => <<"默认描述">>,
        rows => 4,                    % 可选 - 文本域行数
        maxLength => 500              % 可选 - 最大字符数
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options`

---

### 3. number - 数字输入框

**使用场景**：数字输入，如年龄、数量、金额等
**前端组件**：`<InputNumber />`
**后端类型**：`"number"`

**Erlang配置示例**：
```erlang
#{
    name => <<"age">>,
    label => <<"年龄">>,
    type => <<"number">>,
    required => true,
    placeholder => <<"请输入年龄">>,
    options => #{
        defaultValue => 18,            % 可选 - 默认值
        min => 0,                      % 可选 - 最小值
        max => 150,                    % 可选 - 最大值
        step => 1                      % 可选 - 步长
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options`

---

### 4. password - 密码输入框

**使用场景**：密码输入，如用户密码、安全密钥等
**前端组件**：`<Input.Password />`
**后端类型**：`"password"`

**Erlang配置示例**：
```erlang
#{
    name => <<"password">>,
    label => <<"密码">>,
    type => <<"password">>,
    required => true,
    placeholder => <<"请输入密码">>,
    options => #{
        defaultValue => <<"默认密码">>  % 可选 - 默认值
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options`

---

### 5. email - 邮箱输入框

**使用场景**：邮箱地址输入，带格式验证
**前端组件**：`<Input type="email" />`
**后端类型**：`"email"`

**Erlang配置示例**：
```erlang
#{
    name => <<"email">>,
    label => <<"邮箱地址">>,
    type => <<"email">>,
    required => true,
    placeholder => <<"请输入邮箱地址">>,
    options => #{
        defaultValue => <<"example@domain.com">>  % 可选 - 默认值
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options`

---

### 6. url - URL输入框

**使用场景**：网址输入，带URL格式验证
**前端组件**：`<Input type="url" />`
**后端类型**：`"url"`

**Erlang配置示例**：
```erlang
#{
    name => <<"website">>,
    label => <<"网站地址">>,
    type => <<"url">>,
    required => false,
    placeholder => <<"请输入网址">>,
    options => #{
        defaultValue => <<"https://example.com">>  % 可选 - 默认值
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options`

---

### 7. select - 下拉选择框

**使用场景**：从多个选项中选择一个，如状态、分类等
**前端组件**：`<Select />`
**后端类型**：`"select"`

**Erlang配置示例**：
```erlang
#{
    name => <<"gender">>,
    label => <<"性别">>,
    type => <<"select">>,
    required => true,
    placeholder => <<"请选择性别">>,
    options => #{
        defaultValue => <<"male">>,               % 可选 - 默认选中值
        selectOptions => [                       % 必选 - 选项数组
            #{value => <<"male">>, label => <<"男">>},
            #{value => <<"female">>, label => <<"女">>},
            #{value => <<"other">>, label => <<"其他">>}
        ]
    }
}
```

**必选参数**：`name`, `label`, `type`, `options.selectOptions`
**可选参数**：`required`, `placeholder`, `description`, `options.defaultValue`

---

### 8. radio - 单选按钮组

**使用场景**：单选按钮选择，如是否、状态等
**前端组件**：`<Radio.Group />`
**后端类型**：`"radio"`

**Erlang配置示例**：
```erlang
#{
    name => <<"status">>,
    label => <<"状态">>,
    type => <<"radio">>,
    required => true,
    placeholder => <<"请选择状态">>,
    options => #{
        defaultValue => <<"active">>,             % 可选 - 默认选中值
        selectOptions => [                       % 必选 - 选项数组
            #{value => <<"active">>, label => <<"激活">>},
            #{value => <<"inactive">>, label => <<"未激活">>}
        ]
    }
}
```

**必选参数**：`name`, `label`, `type`, `options.selectOptions`
**可选参数**：`required`, `placeholder`, `description`, `options.defaultValue`

---

### 9. checkbox - 多选框组

**使用场景**：多选场景，如兴趣爱好、权限设置等
**前端组件**：`<Checkbox.Group />`
**后端类型**：`"checkbox"`

**Erlang配置示例**：
```erlang
#{
    name => <<"hobbies">>,
    label => <<"兴趣爱好">>,
    type => <<"checkbox">>,
    required => false,
    placeholder => <<"请选择兴趣爱好">>,
    options => #{
        defaultValue => [<<"reading">>, <<"sports">>], % 可选 - 默认选中值（数组）
        selectOptions => [                       % 必选 - 选项数组
            #{value => <<"reading">>, label => <<"阅读">>},
            #{value => <<"sports">>, label => <<"运动">>},
            #{value => <<"music">>, label => <<"音乐">>}
        ]
    }
}
```

**必选参数**：`name`, `label`, `type`, `options.selectOptions`
**可选参数**：`required`, `placeholder`, `description`, `options.defaultValue`

---

### 10. switch - 开关切换

**使用场景**：开关状态切换，如启用/禁用、是/否等
**前端组件**：`<Switch />`
**后端类型**：`"switch"`

**Erlang配置示例**：
```erlang
#{
    name => <<"enabled">>,
    label => <<"启用状态">>,
    type => <<"switch">>,
    required => false,
    placeholder => <<"请切换开关状态">>,
    options => #{
        defaultValue => true                     % 可选 - 默认值（true/false）
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options.defaultValue`

---

### 11. rate - 评分组件

**使用场景**：评分、星级评价等
**前端组件**：`<Rate />`
**后端类型**：`"rate"`

**Erlang配置示例**：
```erlang
#{
    name => <<"rating">>,
    label => <<"评分">>,
    type => <<"rate">>,
    required => false,
    placeholder => <<"请评分">>,
    options => #{
        defaultValue => 3,                       % 可选 - 默认分值
        max => 5                                  % 可选 - 最大分值
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options`

---

### 12. date - 日期选择器

**使用场景**：日期选择，如生日、事件日期等
**前端组件**：`<DatePicker />`
**后端类型**：`"date"`

**Erlang配置示例**：
```erlang
#{
    name => <<"birthday">>,
    label => <<"生日">>,
    type => <<"date">>,
    required => true,
    placeholder => <<"请选择生日">>,
    options => #{
        defaultValue => <<"1990-01-01">>          % 可选 - 默认日期
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options.defaultValue`

---

### 13. datetime - 日期时间选择器

**使用场景**：日期时间选择，如会议时间、操作时间等
**前端组件**：`<DatePicker showTime />`
**后端类型**：`"datetime"`

**Erlang配置示例**：
```erlang
#{
    name => <<"meeting_time">>,
    label => <<"会议时间">>,
    type => <<"datetime">>,
    required => true,
    placeholder => <<"请选择日期时间">>,
    options => #{
        defaultValue => <<"2024-01-01 10:00:00">> % 可选 - 默认日期时间
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options.defaultValue`

---

### 14. time - 时间选择器

**使用场景**：时间选择，如开始时间、结束时间等
**前端组件**：`<DatePicker picker="time" />`
**后端类型**：`"time"`

**Erlang配置示例**：
```erlang
#{
    name => <<"start_time">>,
    label => <<"开始时间">>,
    type => <<"time">>,
    required => true,
    placeholder => <<"请选择时间">>,
    options => #{
        defaultValue => <<"09:00:00">>           % 可选 - 默认时间
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options.defaultValue`

---

### 15. date-range - 日期范围选择器

**使用场景**：日期范围选择，如统计日期范围、活动期间等
**前端组件**：`<RangePicker />`
**后端类型**：`"date-range"`

**Erlang配置示例**：
```erlang
#{
    name => <<"date_range">>,
    label => <<"日期范围">>,
    type => <<"date-range">>,
    required => false,
    placeholder => <<"请选择日期范围">>,
    options => #{
        defaultValue => [                        % 可选 - 默认范围（数组格式）
            <<"2024-01-01">>,
            <<"2024-12-31">>
        ]
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options.defaultValue`

---

### 16. datetime-range - 日期时间范围选择器

**使用场景**：日期时间范围选择，如操作时间范围、监控期间等
**前端组件**：`<RangePicker showTime />`
**后端类型**：`"datetime-range"`

**Erlang配置示例**：
```erlang
#{
    name => <<"datetime_range">>,
    label => <<"日期时间范围">>,
    type => <<"datetime-range">>,
    required => false,
    placeholder => <<"请选择日期时间范围">>,
    options => #{
        defaultValue => [                        % 可选 - 默认范围（数组格式）
            <<"2024-01-01 00:00:00">>,
            <<"2024-12-31 23:59:59">>
        ]
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options.defaultValue`

---

### 17. slider - 滑块选择器

**使用场景**：滑块数值选择，如音量、亮度、进度等
**前端组件**：`<Slider />`
**后端类型**：`"slider"`

**Erlang配置示例**：
```erlang
#{
    name => <<"volume">>,
    label => <<"音量">>,
    type => <<"slider">>,
    required => false,
    placeholder => <<"请调节音量">>,
    options => #{
        defaultValue => 50,                      % 可选 - 默认值
        min => 0,                                % 可选 - 最小值
        max => 100,                              % 可选 - 最大值
        marks => #{
            0 => <<"静音">>,
            50 => <<"适中">>,
            100 => <<"最大">>
        }
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options`

---

### 18. color - 颜色选择器

**使用场景**：颜色选择，如主题色、背景色等
**前端组件**：`<ColorPicker />`
**后端类型**：`"color"`

**Erlang配置示例**：
```erlang
#{
    name => <<"theme_color">>,
    label => <<"主题颜色">>,
    type => <<"color">>,
    required => false,
    placeholder => <<"请选择颜色">>,
    options => #{
        defaultValue => <<"#1890ff">>            % 可选 - 默认颜色值
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options.defaultValue`

---

### 19. number-range - 数字范围选择器

**使用场景**：数字范围选择，如年龄范围、价格区间等
**前端组件**：双`<InputNumber />`组件（min/max）
**后端类型**：`"number-range"`

**Erlang配置示例**：
```erlang
#{
    name => <<"age_range">>,
    label => <<"年龄范围">>,
    type => <<"number-range">>,
    required => false,
    placeholder => <<"请输入年龄范围">>,
    options => #{
        defaultValue => [10, 90],                % 可选 - 默认范围（数组格式）
        min => 0,                                % 可选 - 最小值
        max => 100,                              % 可选 - 最大值
        step => 5                                % 可选 - 步长
    }
}
```

**必选参数**：`name`, `label`, `type`
**可选参数**：`required`, `placeholder`, `description`, `options`

## 🔄 参数格式转换说明

### 前端处理逻辑

1. **日期时间类型**（date/datetime/time）：
   - 调用`formatDateValue`函数转换为对应格式字符串
   - date: "YYYY-MM-DD"
   - datetime: "YYYY-MM-DD HH:mm:ss"
   - time: "HH:mm:ss"

2. **范围类型**（date-range/datetime-range）：
   - 数组格式`[start, end]` → 对象格式`{min: start, max: end}`

3. **number-range类型**：
   - `_min`和`_max`字段 → 对象格式`{min: value, max: value}`

4. **其他类型**：保持原值不进行格式转换

### 后端接收格式

- **日期类型**：字符串格式（"2024-01-01"）
- **日期时间类型**：字符串格式（"2024-01-01 10:00:00"）
- **范围类型**：对象格式`#{min => Start, max => End}`
- **选择类型**：字符串或数组格式

## 📊 参数类型总结表

| 类型 | 使用场景 | 前端组件 | 通用参数 | options参数 | 默认值格式 |
|------|----------|----------|----------|-------------|------------|
| text | 单行文本 | Input | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue | 字符串 |
| textarea | 多行文本 | TextArea | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue, rows, maxLength | 字符串 |
| number | 数字输入 | InputNumber | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue, min, max, step | 数字 |
| password | 密码输入 | Input.Password | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue | 字符串 |
| select | 下拉选择 | Select | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **必选**: selectOptions<br>**可选**: defaultValue | 字符串 |
| radio | 单选按钮 | Radio.Group | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **必选**: selectOptions<br>**可选**: defaultValue | 字符串 |
| checkbox | 多选框 | Checkbox.Group | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **必选**: selectOptions<br>**可选**: defaultValue | 数组 |
| switch | 开关切换 | Switch | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue | 布尔值 |
| rate | 评分 | Rate | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue, max | 数字 |
| date | 日期选择 | DatePicker | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue | 字符串 |
| datetime | 日期时间 | DatePicker(showTime) | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue | 字符串 |
| time | 时间选择 | DatePicker(time) | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue | 字符串 |
| date-range | 日期范围 | RangePicker | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue | 数组 |
| datetime-range | 日期时间范围 | RangePicker(showTime) | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue | 数组 |
| slider | 滑块选择 | Slider | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue, min, max, marks | 数字 |
| color | 颜色选择 | ColorPicker | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue | 字符串 |
| number-range | 数字范围 | 双InputNumber | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue, min, max, step | 数组 |
| email | 邮箱输入 | Input | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue | 字符串 |
| url | URL输入 | Input | **必选**: name, label, type<br>**可选**: required, placeholder, description, options | **可选**: defaultValue | 字符串 |

## 🎯 使用建议

1. **必填参数**：根据业务需求合理设置`required`字段
2. **默认值**：为常用选项设置合理的默认值提升用户体验
3. **验证规则**：利用`options`中的验证规则确保数据有效性
4. **占位文本**：提供清晰的提示信息帮助用户理解参数用途
5. **参数说明**：为复杂参数添加`description`字段，前端将显示问号按钮提供详细说明
6. **选项配置**：选择类型必须提供`selectOptions`选项数组
7. **打开即查**：浏览类菜单可设菜单级 `autoRun => true`（见下文），并给查询参数配好 `defaultValue`

## 📌 菜单项字段与 autoRun

参数配在菜单的 `params` 里；菜单本身还有这些字段（常量见 `include/menus.hrl`）：

| 字段 | 常量 | 说明 |
|------|------|------|
| `id` | `MENU_ID` | 菜单唯一 ID |
| `name` | `MENU_NAME` | 侧栏名称 |
| `description` | `MENU_DESCRIPTION` | 打开后说明文字 |
| `icon` | `MENU_ICON` | 图标 |
| `apiConfig` | `MENU_API_CONFIG` | `#{method, path}` |
| `params` | `MENU_PARAMS` | 参数列表（本文档主体） |
| `autoRun` | `MENU_AUTO_RUN` | `true` = 打开菜单即自动执行一次 |

### autoRun 行为

| 情况 | 行为 |
|------|------|
| 未设置 / `false` | 打开后只展示表单，需手动点「执行」 |
| `autoRun => true` | 打开后用默认参数（或空参）自动请求一次 |
| 从结果「跳转菜单」带预填 | 无论是否 `autoRun`，都会自动执行一次 |
| 再次点进同一菜单 | 再自动请求一次（**不缓存**上次结果） |
| 停在当前页不切换 | 不会反复请求 |
| 有参但必填缺默认值 | 校验失败，本次不发请求；用户补全后可手动执行 |

适合：按表名生成的库表菜单、列表预览、监控只读页。  
不适合：踢人、封禁、发奖等需确认后再提交的写操作（不要开 `autoRun`）。

```erlang
%% 库表：点进即拉数据
#{
    id => <<"db_user">>,
    name => <<"user 表"/utf8>>,
    description => <<"打开即展示前 1000 条"/utf8>>,
    icon => <<"fa-database">>,
    apiConfig => #{method => <<"GET">>, path => <<"/db/table/user">>},
    params => [],
    autoRun => true
}

%% 带默认查询条件：打开即按默认值查，之后可改条件再点执行
#{
    id => <<"menu_item_list">>,
    name => <<"物品列表"/utf8>>,
    apiConfig => #{method => <<"GET">>, path => <<"/items">>},
    autoRun => true,
    params => [
        #{
            name => <<"page">>,
            label => <<"页码"/utf8>>,
            type => <<"number">>,
            required => false,
            options => #{defaultValue => 1, min => 1}
        }
    ]
}
```

宏叠加写法：

```erlang
(?MenuBar(<<"db_user">>, <<"user 表"/utf8>>, <<"..."/utf8>>, <<"fa-database">>,
          <<"GET">>, <<"/db/table/user">>, []))#{autoRun => true}
```

（`sendToGMSrv` / 嵌入步骤见本文开头「接入说明」。）

## 🔧 完整配置示例

### 玩家管理功能示例（需手动执行）
```erlang
#{
    id => <<"kick_player">>,
    name => <<"踢出玩家">>,
    description => <<"将指定玩家踢出游戏">>,
    icon => <<"fa-user-times">>,
    apiConfig => #{
        method => <<"POST">>,
        path => <<"/players/kick">>
    },
    %% 写操作不要加 autoRun
    params => [
        #{
            name => <<"player_id">>,
            label => <<"玩家ID">>,
            type => <<"number">>,
            required => true,
            placeholder => <<"请输入玩家ID">>,
            options => #{
                min => 1,
                max => 999999
            }
        },
        #{
            name => <<"reason">>,
            label => <<"踢出原因">>,
            type => <<"textarea">>,
            required => true,
            placeholder => <<"请输入踢出原因">>,
            options => #{
                rows => 3,
                maxLength => 500
            }
        }
    ]
}
```

这份文档提供了完整的参数类型配置指南，结合前后端实现确保配置的准确性和实用性。


---

## 返回值格式说明（GHer handle/2）

业务接口 **不要** 自己拼 HTTP / JSON，也不要调用 `gmReply`。  
在 `handle/2` 返回下列约定项即可，框架自动打包成前端认识的 JSON。

独立运行侧栏「返回格式演示」可逐项对照。

### R0. 一眼选型

| 需求 | 返回 |
|------|------|
| 成功无正文 | `ok` |
| 成功一句话 | `{msg, Bin}` |
| 结构化数据 / 调试 | `{json, Data}` 或 `{json, Data, Msg}` |
| 列表表格 | `{table, Cols, Rows}` / `{table, Cols, Rows, Meta}` |
| 详情键值 | `{kv, Pairs}` / `{kv, Pairs, Meta}` |
| 多块指标 | `{cards, Cards}` / `{cards, Cards, Meta}` |
| 结果区再出表单 | `{form, Params}` / `{form, Params, Meta}` |
| 成功后跳转别的菜单 | `{redirect, Spec}` |
| 客户端错误 | `{error, Reason}`（HTTP 400） |
| 指定状态码错误 | `{error, Code, Reason}` |
| 不存在 | `not_found`（HTTP 404） |
| 已是 HTTP 三元组 | `{Status, Headers, Body}`（透传，少用） |
| map / list 裸返回 | 当作 `{json, Data}` 成功包装（可用，但建议显式 `{json, ...}`） |

无法识别的返回值会变成 `500 bad_reply`（带 detail），请改用上表。

### R1. 成功 / 失败

```erlang
handle(<<"/players/kick">>, _WsReq) ->
    {msg, <<"已踢出玩家"/utf8>>};
handle(<<"/players/x">>, _WsReq) ->
    not_found;
handle(<<"/players/forbidden">>, _WsReq) ->
    {error, 403, <<"无权限"/utf8>>}.
```

| 你返回 | HTTP | 前端效果 |
|--------|------|----------|
| `ok` | 200 | 成功提示，无正文 |
| `{msg, <<"...">>}` | 200 | 成功 + 一句话（结果区 msg） |
| `{json, Data}` | 200 | JSON / 结构展示 |
| `{json, Data, <<"说明">>}` | 200 | 同上 + 顶部说明 |
| `not_found` | 404 | 未找到 |
| `{error, <<"原因">>}` | 400 | 错误提示 |
| `{error, Code, <<"原因">>}` | Code | 错误提示 |

### R2. 表格 `{table, Columns, Rows}` / `{table, Columns, Rows, Meta}`

**Columns（列）**

| 写法 | 含义 |
|------|------|
| `{Key, Title}` | 字段名 + 表头；默认可排序 |
| `{Key, Title, Extra}` | Extra 见下表 |
| 已是前端列 map（含 `title`/`dataIndex`） | 高级用法，一般不必 |

`Key` 可用 atom 或 binary（如 `id` / `<<"id">>`）。`Title` 建议 `<<"中文"/utf8>>`。

**Extra（列第三项）**

| 字段 | 含义 |
|------|------|
| `sortable => false` | 本列禁止排序（默认 true） |
| `width => 120` | 列宽 |
| `link => #{menu => MenuId, params => #{FormField => RowField}}` | 单元格可点，跳到菜单并预填 |

**Rows（行）二选一**

```erlang
%% A. 按列顺序的二维列表（简单）
Columns = [{id, <<"ID">>}, {name, <<"名称"/utf8>>}, {level, <<"等级"/utf8>>}],
Rows = [
    [1001, <<"张三"/utf8>>, 50],
    [1002, <<"李四"/utf8>>, 45]
],
{table, Columns, Rows}.

%% B. map 列表（字段多、可读性好；键名与列 Key 对应）
Rows = [
    #{id => 1001, name => <<"张三"/utf8>>, level => 50},
    #{id => 1002, name => <<"李四"/utf8>>, level => 45}
],
{table, Columns, Rows, #{total => 2}}.
```

**Meta（第 4 个参数）**

| 字段 | 含义 |
|------|------|
| `total` | 总条数（分页展示） |
| `page` / `pageSize` | 当前页信息（若你做了服务端分页，应与请求参数一致） |
| `pagination => true\|false` | 是否显示分页控件（默认 true） |
| `sortable => false` | 整表关闭**前端列头本地排序**（默认开；只排当前结果，不请求接口） |
| `truncatedCols` / `totalCols` | 列过多被截断时：未展示列数 / 总列数；前端会出警告条（可选） |
| `actions => [Action]` | 每行最右「操作」列 |
| `title` 等其它键 | 会合并进前端 data（慎用，避免覆盖 `type/columns/dataSource`） |

**单元格 link（跳菜单）**

```erlang
{name, <<"玩家名"/utf8>>, #{
    link => #{
        menu => <<"menu_player_details">>,  %% 目标菜单的 id
        params => #{
            player_id => id                 %% 目标表单字段 := 本行字段名
        }
    }
}}
```

含义：`params` 里**左边**是目标菜单 `params.name`，**右边**是本行字段名（atom/binary，与列 Key 一致）。

**行 actions**

```erlang
%% 1) 跳转菜单并预填（与 link 类似，但是按钮）
#{
    key => <<"detail">>,
    label => <<"详情"/utf8>>,
    menu => <<"menu_player_details">>,
    params => #{player_id => id}
}

%% 2) 直接调 HTTP（可确认框；成功可刷新当前表）
#{
    key => <<"delete">>,
    label => <<"删除"/utf8>>,
    confirm => <<"确认删除？"/utf8>>,
    api => #{
        method => <<"DELETE">>,
        path => <<"/players/{id}">>,   %% {字段名} 替换成该行对应字段
        refresh => true                %% 成功后重新执行当前菜单
    }
}
```

注意：结果区 `actions.api` / `form` 提交默认打 **GM 本机**（同源），与菜单项 `sendToGMSrv => false` 的「执行」按钮行为可能不同。

**分页怎么配合菜单**

1. 菜单 `params` 提供 `page`、`pageSize`（带 `defaultValue`）。
2. GHer 从 query/body 读出 `page` / `pageSize`，切片或查库。
3. 返回 `{table, Cols, Rows, #{total => Total, page => Page, pageSize => PageSize, pagination => true}}`。
4. 前端**翻页/改每页条数**会再次请求同一菜单接口。
5. **列头排序**：只对当前表格内的数据做本地排序，**不会请求接口**。gmTool **不约定** `sort`/`order` 等服务端排序参数。
6. 若宿主要「全库排序」：自己在菜单 `params` 加字段并由自己的 GHer 实现即可。独立运行可参考示例菜单「分页+表单排序示例」`GET /demo/table-sort`（下拉选字段 / 复合 `score,level`，点「执行」才带参）。

空表：`Rows = []`，`total => 0` 即可。

列过多时可在 Meta 写 `truncatedCols` / `totalCols`（例如只返回前 40 列），前端会提示用「精确 Key / 行详情」看完整字段。

### R2.1 结构化 JSON（表结构 / 行详情增强）

`{json, Data}` / `{json, Data, Msg}` 在 Data 满足下列约定时，前端会用结构化面板展示（否则仍是普通 JSON pre）：

| 约定 | 说明 |
|------|------|
| 推荐显式标记 | `view => <<"schema">>` 或 `<<"row">>` / `<<"row_detail">>`（也可用 `type` 同值） |
| `summary` | `[{label, value}, ...]` 概要 Descriptions |
| `fields` | `#{columns, rows}` 字段表，或 `[%{field, comment, value}, ...]` |
| `key_slots` | `#{columns, rows}` Key 槽位表 |
| `raw_term` / `kv_term` | Erlang term 文本（可复制） |
| `json` | 完整 JSON 文本或对象 |
| `table` / `key_text` / `display` / `record` / `table_comment` | 顶部 Tag / 说明（可选） |

无上述强结构时不要指望自动美化；普通调试数据继续用 `{json, Map}` 即可。

独立运行侧栏「返回格式演示」可点开对照：

| 菜单 | 路径 | 演示内容 |
|------|------|----------|
| 分页+表单排序示例 | `GET /demo/table-sort` | 宿主自实现参考：表单 sort/order + 执行；列头仍本地排序 |
| 列截断提示 | `GET /demo/table-trunc` | Meta.`truncatedCols` / `totalCols` |
| JSON schema 面板 | `GET /demo/schema` | `view=schema` |
| JSON 行详情 | `GET /demo/row` | `view=row` + `raw_term` / `kv_term` |

实现见 `gmExDemoGHer` / `gmExampleMenus`。

### R3. 键值 `{kv, Pairs}` / `{kv, Pairs, Meta}`

适合详情页。

```erlang
{kv, [
    {<<"玩家ID"/utf8>>, 1001},
    {<<"玩家名"/utf8>>, <<"张三"/utf8>>},
    {<<"等级"/utf8>>, 50}
], #{title => <<"玩家详情"/utf8>>}}.

{kv, #{id => 1001, name => <<"张三"/utf8>>}}.   %% map 也可
```

### R4. 卡片 `{cards, Cards}` / `{cards, Cards, Meta}`

```erlang
{cards, [
    #{title => <<"在线"/utf8>>, content => 1250, footer => <<"人"/utf8>>},
    #{title => <<"CPU"/utf8>>, content => <<"45%">>, description => <<"负载"/utf8>>},
    {<<"内存"/utf8>>, <<"67%">>}    %% {Title, Content} 简写
], #{title => <<"概览"/utf8>>}}.
```

单卡 map 常用键：`title`、`content`、`description`、`footer`、`extra`（有则展示）。

### R5. 结果区表单 `{form, Params}` / `{form, Params, Meta}`

`Params` **形状与菜单 params 完全相同**（见上文参数类型章节）。

```erlang
{form,
    [
        #{name => <<"player_id">>, label => <<"玩家ID"/utf8>>,
          type => <<"number">>, required => true,
          options => #{min => 1}}
    ],
    #{
        title => <<"补单"/utf8>>,
        submit => #{method => <<"POST">>, path => <<"/orders/fix">>}
    }
}.
```

`Meta.submit`：`method`（默认 POST）、`path`（可含 `{字段名}` 占位）。提交成功后前端可刷新。

### R6. 跳转 `{redirect, Spec}`

执行成功后自动打开另一菜单（可预填，并自动执行一次）：

```erlang
{redirect, #{
    menu => <<"menu_query_players">>,           %% 必填：目标菜单 id
    params => #{keyword => <<"张三"/utf8>>},    %% 可选：预填
    message => <<"正在打开玩家列表..."/utf8>>  %% 可选：提示文案
}}.
```

### R7. 透传（一般不用）

```erlang
{200, [{<<"Content-Type">>, <<"application/json">>}], JsonBin}.
```

### R8. 特殊能力对照（菜单 × 返回）

| 能力 | 菜单侧 | 返回侧 |
|------|--------|--------|
| 打开即查 | `autoRun => true` + 默认参数 | 通常 `table` / `kv` / `cards` / `json` |
| 本机处理 | `sendToGMSrv => true` | 任意约定返回 |
| 直连区服 | `sendToGMSrv => false` | 区服响应需前端能解析；要走约定 UI 建议仍打本机再由本机转发 |
| 点名字进详情 | 列 `link` | 当前接口仍返回 `table`；详情接口返回 `kv` 或结构化 `{json, #{view => <<"row">>, ...}}` |
| 行内删除并刷新 | `actions` + `api.refresh => true` | 删除接口返回 `{msg, _}` / `ok` |
| 操作完跳列表 | — | `{redirect, #{menu => ...}}` |
| 二次确认 | `actions` 里 `confirm => <<"...">>` | — |
| 仅提示成功 | — | `{msg, _}` 或 `ok` |
| 校验失败 | — | `{error, <<"缺参数"/utf8>>}` |
| 列过多截断提示 | — | Meta.`truncatedCols` / `totalCols` |

### R9. 完整最小示例（菜单 + handle）

```erlang
%% ===== 菜单 =====
#{
    id => <<"menu_kick">>,
    name => <<"踢出玩家"/utf8>>,
    apiConfig => #{method => <<"POST">>, path => <<"/players/kick">>, sendToGMSrv => true},
    %% 不要 autoRun
    params => [
        #{name => <<"player_id">>, label => <<"玩家ID"/utf8>>, type => <<"number">>,
          required => true, options => #{min => 1}},
        #{name => <<"reason">>, label => <<"原因"/utf8>>, type => <<"textarea">>,
          required => false, options => #{rows => 3}}
    ]
}

%% ===== handle =====
handle(<<"/players/kick">>, WsReq) ->
    %% 读 body 中的 player_id / reason ...
    {msg, <<"已踢出"/utf8>>}.
```

列表 + 链接 + 操作可参考本仓库示例模块 `gmExPlayerGHer`；格式全集见 `gmExDemoGHer`。

---

## 附录：常见问题

| 现象 | 排查 |
|------|------|
| 点执行打到错误主机 / CORS | `sendToGMSrv` 是否该为 true；区服是否允许浏览器跨域 |
| 顶栏没有服务器 | 是否实现并 `handlers` 登记了 `GET /servers` |
| 打开即报未选服 | `sendToGMSrv => false` 且尚未选服；或改回本机 |
| undef / handler not loaded | `handlers/0` 模块名、是否已编译进节点 |
| 401 | 先登录；前端会自动带 Bearer |
| 空表单点执行没请求 | 必填项缺 `defaultValue`，`autoRun` 校验失败 |
| 跳转菜单没反应 | 目标 `menu` id 是否存在且唯一 |
| 500 bad_reply | 返回值不在约定表内，检查拼写 / 元组 arity |
| 中文乱码 | 二进制是否写了 `/utf8` |
| 表格列对不上 | 二维 Rows 顺序是否与 Columns 一致；map 键是否与列 Key 一致 |
| 分页点列头后翻页又回第 1 页 | 列头排序不打接口；翻页只带 page/pageSize |
| JSON 被当成表结构面板 | Data 是否误带 `fields`/`summary`；可去掉或显式 `view => <<"schema">>` |
| 点列头没有请求 / 只排当前页 | 属预期：gmTool 仅做表格本地排序，不约定服务端 sort 参数 |

---

## 附录：给 AI / 同事的一句话目标

1. **配菜单**：`menus/0` 里写清 `id、apiConfig、params、autoRun、sendToGMSrv`；`handlers/0` 登记 path 第一段。  
2. **读参数**：GET 用 `eWSrv:mapargs`，POST 用 `eWSrv:body` + `json:decode`；字段名 = `params.name`。  
3. **返回数据**：只返回本文「返回值格式」表里的约定项，用场景选型表选 table/kv/cards/msg/…。  
4. **特殊交互**：跳转靠 `link` / `actions.menu` / `redirect`；行内调接口靠 `actions.api`；打开即查靠 `autoRun`。
