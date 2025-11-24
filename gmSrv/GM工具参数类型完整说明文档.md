# GM工具参数类型完整说明文档

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

## 🔧 完整配置示例

### 玩家管理功能示例
```erlang
#{
    name => <<"kick_player">>,
    label => <<"踢出玩家">>,
    description => <<"将指定玩家踢出游戏">>,
    icon => <<"fa-user-times">>,
    apiConfig => #{
        method => <<"POST">>,
        path => <<"/players/kick/{player_id}">>
    },
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