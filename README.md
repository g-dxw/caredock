# 安养台一期桌面工程

这是全新的一期技术骨架。R0已经验证Tauri、Gateway/Command、Rust分层、bundled SQLite、事务和备份能力；M0—M3已经加入正式数据库连接、migration runner、升级前备份及A/B/C上下文正式表。

- 不包含正式业务页面。
- 正式数据库文件为`anyangtai.sqlite`，与`r0-probe.sqlite`完全隔离。
- 当前已实现`schema_migrations`和`0001—0006`，共34张业务表；`0007—0012`尚未开始。
- 不读取或迁移上级目录废弃`app/`的数据。
- 不安装机构演示数据，也不执行机构初始化业务用例。

## 本地命令

```bash
corepack pnpm install
corepack pnpm check
corepack pnpm tauri build --debug --no-bundle
```

Windows与Mac持续集成入口见`.github/workflows/r0-ci.yml`。CI编译不能替代发布前的真实Windows 10/11安装验证。
