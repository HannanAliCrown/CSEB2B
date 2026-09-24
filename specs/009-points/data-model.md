# Data Model: Points and Targets

- **PointEntry**: reference, account, amount, direction, type (purchase accrual, reversal, transfer in/out, CRM adjustment), counterparty, SAP document, note, posted time, derived balance-after.
- **PointTransferRule**: allowed sender and receiver role pair.
- **PointRestriction**: account can-send/can-receive flags and reason.
- **PointScheme/SchemePeriod/ExtraTarget**: configured targets, four-month windows, prizes (annual, per period, optional grand prize), progress and met date.
