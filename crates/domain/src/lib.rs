use serde::Serialize;

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct R0ProbeReport {
    pub sqlite_version: String,
    pub foreign_keys_enabled: bool,
    pub wal_enabled: bool,
    pub json_supported: bool,
    pub strict_supported: bool,
    pub migration_count: usize,
    pub migration_idempotent: bool,
    pub transaction_rollback_verified: bool,
    pub write_contention_verified: bool,
    pub backup_restore_verified: bool,
    pub attachment_two_phase_verified: bool,
    pub database_path_label: String,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MoneyCents(i64);

impl MoneyCents {
    pub fn new(value: i64) -> Option<Self> {
        (value >= 0).then_some(Self(value))
    }

    pub fn value(self) -> i64 {
        self.0
    }

    pub fn multiply_quantity_milli(self, quantity_milli: i64) -> Option<Self> {
        if quantity_milli < 0 {
            return None;
        }

        let numerator = i128::from(self.0).checked_mul(i128::from(quantity_milli))?;
        let rounded = numerator.checked_add(500)?.checked_div(1000)?;
        i64::try_from(rounded).ok().and_then(Self::new)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn money_uses_integer_half_up_rounding() {
        let unit_price = MoneyCents::new(8_001).expect("valid positive money");
        let amount = unit_price
            .multiply_quantity_milli(500)
            .expect("valid quantity");

        assert_eq!(amount.value(), 4_001);
    }

    #[test]
    fn money_rejects_negative_inputs() {
        assert_eq!(MoneyCents::new(-1), None);
        assert_eq!(
            MoneyCents::new(10).unwrap().multiply_quantity_milli(-1),
            None
        );
    }
}
