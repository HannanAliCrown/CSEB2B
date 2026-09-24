# Data Model: Shop Branding

- **BrandingConfig** (`branding_config`, single row): scan window days (default 10), replacement months (default 6).
- **BoardType** (`branding_board_types`): stable code, name, description, unit price (paisa), company percent (default 60), optional `replaces_code` for replacement options, position.
- **BoardTypeRole** (`branding_board_type_roles`): board type × role with min points, requires scheme, requires recent scan. No row means never shown to that role.
- **Installation** (`branding_installations`): account, board type, installed-on date; newest row drives replacement detection.
- **BrandingRequest** (`branding_requests`): reference `BRD-YYYY-NNNN`, account, shop/card photo paths, height/width ft, board count, optional address/contact/person, status (`in_progress` | `completed` | `rejected`), stage (1 approved · 2 installed · 3 call confirmed), rejection reason (required when rejected), created at.
- **RequestBoard** (`branding_request_boards`): request, 1-based position, board type, snapshotted unit price and company percent.
- **Eligibility** (derived): role, scheme signed, points balance, days since last scan claim, existing board name and age in months.
