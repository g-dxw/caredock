use std::path::PathBuf;

use anyangtai_application::TechnicalProbePort;
use anyangtai_storage::SqliteTechnicalProbe;

fn main() {
    let root = std::env::args_os()
        .nth(1)
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from(".r0-data"));
    let probe = SqliteTechnicalProbe::new(root);
    let report = probe.run_probe().expect("R0 probe should pass");

    println!("{report:#?}");
}
