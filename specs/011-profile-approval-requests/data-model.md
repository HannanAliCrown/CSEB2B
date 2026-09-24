# Data Model: Profile Approval Requests

- **ProfileRequest**: application id, reference, applicant contact/mobile/alternate number, business name, role (`installer`/`retailer`), address, market, shop pin, other buying sources named, submitted time. No CNIC number.
- **BuyingSource** (`registration_buying_sources`): `position` (0 = the verifying source), mobile number, matched account/name/role/market.
- **ProfileRequestMedia**: `video_link`, `shop_image`, or `selfie` with slot and link; `cnic_front`/`cnic_back` are never selected.
- **ExpectedPurchaseBand** (`expected_purchase_bands`): label, position, active.
- **ProfileDecision**: the `registration_approvals` row with `approver = 'buying_source'`: state, deciding account and name, decision time, note (reason), expected-purchase band. Migration 008 constraints require a band on approval and a non-blank note on rejection.
