# Data Model: Product Scanning and Prizes

- **Product**: product code, name, batch, active/blocked state.
- **ScanClaim**: product, account, role, claimed time, prize amount.
- **ScanPrizeRule**: role and configured prize amount.
- **ScanOutcome**: mode, verdict, product details, existing claim, optional prize.
