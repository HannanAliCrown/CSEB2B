# Data Model: Wallet, Cash Requests, and Ledger

- **WalletEntry**: reference, account, direction, type, state (cleared/held/rejected), amount in paisa, timestamp, counterparty, transfer.
- **CashTransfer**: reference, sender, receiver, amount, note, held/accepted/rejected/expired state, sent time, expiry time, decision time.
- **LedgerRow**: wallet entry plus derived settled balance-after value.

Held debits reduce available balance but are not settled credits for the receiver. The receiver's credit entry exists only once a transfer is accepted; a rejected debit is excluded from the sender's balance.
