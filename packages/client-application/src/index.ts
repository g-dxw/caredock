import { invoke } from "@tauri-apps/api/core";
import type { CommandError, Completed, R0ProbeReport } from "@anyangtai/contracts";

export interface AppGateway {
  runR0Probe(): Promise<Completed<R0ProbeReport>>;
}

export class DesktopGateway implements AppGateway {
  runR0Probe(): Promise<Completed<R0ProbeReport>> {
    return invoke<Completed<R0ProbeReport>>("system_run_r0_probe");
  }
}

export function toSafeCommandError(error: unknown): CommandError {
  if (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    "message" in error
  ) {
    return {
      code: String(error.code),
      message: String(error.message),
    };
  }

  return {
    code: "UNKNOWN",
    message: "技术探针执行失败，请查看脱敏日志。",
  };
}
