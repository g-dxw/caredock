# 安养台 R0 技术验证工程

这是全新的一期技术骨架，只验证Tauri、Gateway/Command、Rust分层、bundled SQLite、migration、事务和备份能力。

- 不包含正式业务页面。
- 不包含正式92张业务表。
- 不读取或迁移上级目录废弃`app/`的数据。
- 当前只允许匿名技术探针数据。

## 本地命令

```bash
corepack pnpm install
corepack pnpm check
corepack pnpm tauri build --debug --no-bundle
```

Windows与Mac持续集成入口见`.github/workflows/r0-ci.yml`。CI编译不能替代发布前的真实Windows 10/11安装验证。
