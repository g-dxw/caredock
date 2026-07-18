import { useState } from "react";
import { DesktopGateway, toSafeCommandError } from "@anyangtai/client-application";
import type { R0ProbeReport } from "@anyangtai/contracts";
import "./App.css";

const gateway = new DesktopGateway();

type ProbeState =
  | { status: "idle" }
  | { status: "running" }
  | { status: "success"; report: R0ProbeReport }
  | { status: "error"; code: string; message: string };

const checks: Array<{ key: keyof R0ProbeReport; label: string }> = [
  { key: "foreignKeysEnabled", label: "SQLite 外键" },
  { key: "walEnabled", label: "WAL 模式" },
  { key: "jsonSupported", label: "JSON 校验" },
  { key: "strictSupported", label: "STRICT 表" },
  { key: "migrationIdempotent", label: "Migration 幂等" },
  { key: "transactionRollbackVerified", label: "事务失败回滚" },
  { key: "writeContentionVerified", label: "双连接写竞争" },
  { key: "backupRestoreVerified", label: "在线备份与恢复" },
  { key: "attachmentTwoPhaseVerified", label: "附件两阶段处理" },
];

function App() {
  const [state, setState] = useState<ProbeState>({ status: "idle" });

  async function runProbe() {
    setState({ status: "running" });
    try {
      const result = await gateway.runR0Probe();
      setState({ status: "success", report: result.data });
    } catch (error) {
      const safeError = toSafeCommandError(error);
      setState({ status: "error", ...safeError });
    }
  }

  return (
    <main className="shell">
      <header className="hero">
        <p className="eyebrow">安养台 · R0 技术验证</p>
        <h1>本地优先架构探针</h1>
        <p className="intro">
          当前窗口不包含真实老人资料和业务页面，只验证 React → Gateway →
          Tauri Command → Rust Application → bundled SQLite 的完整路径。
        </p>
      </header>

      <section className="panel" aria-live="polite">
        <div className="panel-heading">
          <div>
            <h2>技术状态</h2>
            <p>探针数据仅写入Tauri应用数据目录。</p>
          </div>
          <button type="button" onClick={runProbe} disabled={state.status === "running"}>
            {state.status === "running" ? "正在验证…" : "运行R0探针"}
          </button>
        </div>

        {state.status === "idle" && (
          <p className="empty">点击按钮后执行SQLite、migration、事务、备份和附件验证。</p>
        )}

        {state.status === "error" && (
          <div className="error-card" role="alert">
            <strong>{state.code}</strong>
            <span>{state.message}</span>
          </div>
        )}

        {state.status === "success" && (
          <>
            <div className="summary">
              <div>
                <span>bundled SQLite</span>
                <strong>{state.report.sqliteVersion}</strong>
              </div>
              <div>
                <span>Probe migrations</span>
                <strong>{state.report.migrationCount}</strong>
              </div>
              <div>
                <span>数据库标识</span>
                <strong>{state.report.databasePathLabel}</strong>
              </div>
            </div>

            <ul className="check-grid">
              {checks.map(({ key, label }) => {
                const passed = state.report[key] === true;
                return (
                  <li key={key} className={passed ? "passed" : "failed"}>
                    <span aria-hidden="true">{passed ? "✓" : "!"}</span>
                    <div>
                      <strong>{label}</strong>
                      <small>{passed ? "通过" : "未通过"}</small>
                    </div>
                  </li>
                );
              })}
            </ul>
          </>
        )}
      </section>

      <footer>R0不创建正式业务表 · 不迁移旧app · 不保存真实敏感数据</footer>
    </main>
  );
}

export default App;
