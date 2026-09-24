# Data Model: Complaints and Notifications

- **ComplaintCategory** (`complaint_types`): code, label, optional short label, position, active; no sub-types.
- **ComplaintTarget**: response minutes and resolution working days per category and priority.
- **Complaint**: account, reference, category, title, detail, priority, copied SLA targets, status (`in_progress`/`resolved`), optional evidence note, raised/first-response/resolved timestamps.
- **ComplaintEvent**: ordered history with title, narrative, note, state (`done`/`active`/`pending`), and occurred time.
- **AppNotification**: level (`info`/`success`/`warning`/`critical`), title, body, destination label and optional route, created time, read time.
