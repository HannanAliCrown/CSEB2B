# Data Model: Inaam Rewards

- **SpinConfig/SpinPrize**: versioned configuration (one active), scans-per-spin, segments with amount, weight, position.
- **Spin**: reference, account, config, selected prize, amount, timestamp, wallet entry.
- **ItemScheme/SchemeTier/Claim**: product scope, measure (`scans`/`amount`), start/end dates, thresholds, reward, one claim per scheme and account.
- **ItemSchemeProgress**: externally posted purchase amount per scheme and account.
- **RewardProgram/ProgramTier/Award**: period, product scope, scan targets, bonus percent; award with earned programme and applies-from/until window.
