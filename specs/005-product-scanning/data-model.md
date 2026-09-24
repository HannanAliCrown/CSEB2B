# Data Model: Product Scanning and Prizes

- **Product** (`products`): code (unique, upper case), name, batch, plant, made-on date, state (active/blocked), wins-prize flag.
- **ScanClaim** (`scan_claims`): product, account, role at claim time, claimed time, prize amount (null when nothing paid), wallet entry; unique per product and role.
- **ScanPrizeRule** (`scan_prize_rules`): role and configured prize amount; a role without a row cannot win.
- **ScanOutcome**: mode, verdict, product details, existing claim, optional prize.
