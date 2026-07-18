use anyangtai_domain::R0ProbeReport;

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProbePortError {
    pub code: &'static str,
    pub safe_message: String,
}

impl ProbePortError {
    pub fn storage_failure() -> Self {
        Self {
            code: "STORAGE_FAILURE",
            safe_message: "本地技术探针执行失败，详细信息已限制在开发日志中。".to_owned(),
        }
    }
}

pub trait TechnicalProbePort {
    fn run_probe(&self) -> Result<R0ProbeReport, ProbePortError>;
}

pub struct RunTechnicalProbe<'a> {
    port: &'a dyn TechnicalProbePort,
}

impl<'a> RunTechnicalProbe<'a> {
    pub fn new(port: &'a dyn TechnicalProbePort) -> Self {
        Self { port }
    }

    pub fn execute(&self) -> Result<R0ProbeReport, ProbePortError> {
        self.port.run_probe()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    struct FakeProbePort;

    impl TechnicalProbePort for FakeProbePort {
        fn run_probe(&self) -> Result<R0ProbeReport, ProbePortError> {
            Ok(R0ProbeReport {
                sqlite_version: "probe".to_owned(),
                foreign_keys_enabled: true,
                wal_enabled: true,
                json_supported: true,
                strict_supported: true,
                migration_count: 2,
                migration_idempotent: true,
                transaction_rollback_verified: true,
                write_contention_verified: true,
                backup_restore_verified: true,
                attachment_two_phase_verified: true,
                database_path_label: "r0-probe.sqlite".to_owned(),
            })
        }
    }

    #[test]
    fn use_case_delegates_to_port() {
        let port = FakeProbePort;
        let report = RunTechnicalProbe::new(&port).execute().unwrap();

        assert_eq!(report.sqlite_version, "probe");
        assert!(report.transaction_rollback_verified);
    }
}
