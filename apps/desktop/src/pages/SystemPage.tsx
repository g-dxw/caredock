import { useState } from "react";
import { Check, Database, HardDriveDownload, Play, ShieldCheck, WifiOff } from "lucide-react";
import { DesktopGateway, toSafeCommandError } from "@anyangtai/client-application";
import type { R0ProbeReport } from "@anyangtai/contracts";
import { Badge, Button, PageHeader, SectionCard, StatCard } from "../components/Ui";

const gateway = new DesktopGateway();
type ProbeState = { status: "idle" } | { status: "running" } | { status: "success"; report: R0ProbeReport } | { status: "error"; code: string; message: string };
const checks: Array<{ key: keyof R0ProbeReport; label: string }> = [
  { key: "foreignKeysEnabled", label: "SQLite 外键" }, { key: "walEnabled", label: "WAL 模式" }, { key: "jsonSupported", label: "JSON 校验" }, { key: "strictSupported", label: "STRICT 表" }, { key: "migrationIdempotent", label: "Migration 幂等" }, { key: "transactionRollbackVerified", label: "事务失败回滚" }, { key: "writeContentionVerified", label: "双连接写竞争" }, { key: "backupRestoreVerified", label: "在线备份与恢复" }, { key: "attachmentTwoPhaseVerified", label: "附件两阶段处理" },
];

export function SystemPage() {
  const [state, setState] = useState<ProbeState>({ status: "idle" });
  async function runProbe() {
    setState({ status: "running" });
    try { const result = await gateway.runR0Probe(); setState({ status: "success", report: result.data }); }
    catch (error) { setState({ status: "error", ...toSafeCommandError(error) }); }
  }
  return <><PageHeader eyebrow="系统 / 本地状态" title="本地数据与系统状态" description="正式业务数据保存在本机。当前网页展示只使用匿名演示数据。" actions={<Button onClick={runProbe} disabled={state.status === "running"}><Play size={16} />{state.status === "running" ? "正在检查…" : "运行技术检查"}</Button>} />
    <div className="stats-grid stats-grid--4"><StatCard label="运行方式" value="本地优先" helper="无需注册和联网" icon={<WifiOff size={19} />} /><StatCard label="正式Migration" value="0001—0007" helper="51张业务表" icon={<Database size={19} />} tone="blue" /><StatCard label="数据备份" value="可用" helper="升级前自动在线备份" icon={<HardDriveDownload size={19} />} tone="violet" /><StatCard label="数据状态" value="匿名演示" helper="不含真实个人信息" icon={<ShieldCheck size={19} />} tone="green" /></div>
    <SectionCard title="技术链路检查" description="验证 React → Gateway → Tauri Command → Rust Application → bundled SQLite。" action={<Badge tone={state.status === "success" ? "green" : state.status === "error" ? "red" : "gray"}>{state.status === "success" ? "全部通过" : state.status === "error" ? "检查失败" : "尚未运行"}</Badge>}>
      {state.status === "idle" && <div className="system-empty"><Database size={26} /><strong>尚未运行本地技术检查</strong><span>网页预览环境无法调用Tauri命令；请在Mac应用中执行。</span></div>}
      {state.status === "error" && <div className="system-error"><strong>{state.code}</strong><span>{state.message}</span><small>如果当前在普通浏览器中预览，这是预期结果，不影响静态原型。</small></div>}
      {state.status === "success" && <><div className="probe-summary"><div><span>bundled SQLite</span><strong>{state.report.sqliteVersion}</strong></div><div><span>Probe migrations</span><strong>{state.report.migrationCount}</strong></div><div><span>数据库标识</span><strong>{state.report.databasePathLabel}</strong></div></div><div className="probe-grid">{checks.map(({ key, label }) => <div key={key} className={state.report[key] === true ? "is-passed" : "is-failed"}><span><Check size={14} /></span><div><strong>{label}</strong><small>{state.report[key] === true ? "通过" : "未通过"}</small></div></div>)}</div></>}
    </SectionCard>
  </>;
}
