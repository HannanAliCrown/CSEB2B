# Research: Wallet, Cash Requests, and Ledger

- **Decision**: Use integer paisa and derive balances from wallet entries.
- **Rationale**: One ledger prevents Home, wallet, and ledger totals from drifting.
- **Alternatives considered**: A stored mutable balance was rejected because it could diverge under transfer decisions.
- **Deferred**: PDF export and product/equipment settlement are not in this feature.
