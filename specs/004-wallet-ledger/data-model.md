# Data Model: Wallet, Cash Requests, and Ledger

- **WalletEntry**: reference, account, direction, type, state, amount in paisa, timestamp, counterparty.
- **CashTransfer**: sender, receiver, amount, held/accepted/rejected/expired state, decision time.
- **LedgerRow**: wallet entry plus derived settled balance-after value.

Held debits reduce available balance but are not settled credits for the receiver.
