#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            anyangtai_desktop_commands::commands::system_run_r0_probe
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
