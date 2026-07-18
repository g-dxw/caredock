# 安养台一期桌面工程

这是全新的一期技术骨架。R0已经验证Tauri、Gateway/Command、Rust分层、bundled SQLite、事务和备份能力；M0—M4已经加入正式数据库连接、migration runner、升级前备份及A/B/C/D上下文正式表；网页高保真原型V0.1已复用桌面端React/Vite入口。

- 当前业务页面使用匿名演示数据，只用于产品与交互确认，尚未连接Repository或正式数据库。
- 正式数据库文件为`anyangtai.sqlite`，与`r0-probe.sqlite`完全隔离。
- 当前已实现`schema_migrations`和`0001—0007`，共51张业务表；`0008—0012`尚未开始。
- 不读取或迁移上级目录废弃`app/`的数据。
- 不向正式SQLite安装演示数据，也不执行机构初始化业务用例。

## 本地命令

```bash
corepack pnpm install
corepack pnpm check
corepack pnpm --filter @anyangtai/desktop dev
corepack pnpm tauri build --debug --no-bundle
```

浏览器打开`http://127.0.0.1:1420/`即可查看网页高保真原型；同一套组件也由Tauri桌面窗口加载。

Windows与Mac持续集成入口见`.github/workflows/r0-ci.yml`。CI编译不能替代发布前的真实Windows 10/11安装验证。
