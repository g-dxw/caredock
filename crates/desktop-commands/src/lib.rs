use anyangtai_application::{ProbePortError, RunTechnicalProbe};
use anyangtai_domain::R0ProbeReport;
use anyangtai_storage::SqliteTechnicalProbe;
use serde::Serialize;
use tauri::Manager;

#[derive(Debug, Serialize)]
#[serde(tag = "kind", rename_all = "camelCase")]
pub enum CommandOutcome<T> {
    Completed { data: T },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct CommandErrorDto {
    pub code: String,
    pub message: String,
}

impl From<ProbePortError> for CommandErrorDto {
    fn from(value: ProbePortError) -> Self {
        Self {
            code: value.code.to_owned(),
            message: value.safe_message,
        }
    }
}

pub mod commands {
    use super::*;

    #[tauri::command]
    pub fn system_run_r0_probe(
        app: tauri::AppHandle,
    ) -> Result<CommandOutcome<R0ProbeReport>, CommandErrorDto> {
        let app_data_dir = app.path().app_data_dir().map_err(|_| CommandErrorDto {
            code: "STORAGE_FAILURE".to_owned(),
            message: "无法初始化本地技术验证目录。".to_owned(),
        })?;
        let probe = SqliteTechnicalProbe::new(app_data_dir.join("r0-technical-probe"));
        let data = RunTechnicalProbe::new(&probe).execute()?;

        Ok(CommandOutcome::Completed { data })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn port_error_maps_to_stable_safe_command_error() {
        let error = CommandErrorDto::from(ProbePortError::storage_failure());

        assert_eq!(error.code, "STORAGE_FAILURE");
        assert!(!error.message.contains("SELECT"));
        assert!(!error.message.contains('/'));
    }
}
