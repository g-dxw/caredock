export interface R0ProbeReport {
  sqliteVersion: string;
  foreignKeysEnabled: boolean;
  walEnabled: boolean;
  jsonSupported: boolean;
  strictSupported: boolean;
  migrationCount: number;
  migrationIdempotent: boolean;
  transactionRollbackVerified: boolean;
  writeContentionVerified: boolean;
  backupRestoreVerified: boolean;
  attachmentTwoPhaseVerified: boolean;
  databasePathLabel: string;
}

export interface Completed<T> {
  kind: "completed";
  data: T;
}

export interface CommandError {
  code: string;
  message: string;
}
