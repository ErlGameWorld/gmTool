gmTool
======

基础 GM 框架：菜单驱动的 GM 后台（Erlang + 内嵌前端）。  
业务由宿主提供**菜单模块**与 `*GHer`，启动时注入即可。

给宿主开发者（只看这一份）
--------------------------

**[GM接入参数返回值说明.md](GM接入参数返回值说明.md)**

文档结构：

1. **接入说明** — 复制什么、怎么启动、菜单 / handlers、选服、`sendToGMSrv` / `autoRun`
2. **参数类型** — 原文完整保留（控件配置）
3. **返回值格式** — table / kv / cards / form / redirect / msg / json / error

嵌入时请一并复制：

1. `_build/default/bin/gmTool` → 如 `priv/gmTool`
2. `src/utils/gmToolBootstrap.erl`
3. **上述说明文档**

不必复制 `gmCli/` 或 `scripts/`（仅本仓库重新打包前端时用）。

```erlang
{ok, _} = gmToolBootstrap:start("priv/gmTool", #{
    port => 3000,
    menuModule => myGameMenus
}).
```

目录要点
--------

```
src/
  auth/ router/ menus/ utils/ tools/   # 框架（模块名 gm*）
  example/                                      # 示例（gmEx* / gmExampleMenus）
GM接入参数返回值说明.md                            # 宿主唯一约定文档
```

Build / 本仓库维护
------------------

```bash
rebar3 compile
rebar3 escriptize
# 改前端后：
cd gmCli && npm install && npm run build   # embed → src/gmWebShow.erl
```

独立运行：

```bash
_build/default/bin/gmTool --port 3000 --menu-module gmExampleMenus
```

```erlang
%% rebar3 shell
gmTool:start(#{port => 3000, menuModule => gmExampleMenus}).
```

侧栏「返回格式演示」「参数输入演示」可对照文档逐项验证。
