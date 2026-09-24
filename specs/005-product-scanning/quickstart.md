# Quickstart: Product Scanning and Prizes

1. Start `prototype_server` against a database with `db/migrations` and `db/seed` applied, and run the app with `DATA_SOURCE=server`.
2. Test an unknown and blocked code (`CS-BAT-7788`) in Authenticity Check.
3. Test a genuine code in Authenticity Check and confirm no claim/wallet entry.
4. Claim a winning code (`CS-INV-8841`) as Installer and Retailer and verify wallet credits.
5. Open the scanner as Wholesaler and Distributor and confirm only Authenticity Check is offered.
6. Scan the same code again for the same role and confirm the already scanned refusal.
7. Stop the server and confirm a scan reports "Could not check this code".
