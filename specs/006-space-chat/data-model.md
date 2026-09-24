# Data Model: Space and Chat

- **SpacePost**: title, body, optional image URL, audience (`all`/`installer`/`retailer`/`trade`), published flag, posted time; hearts and "hearted by me" derived from heart rows.
- **PostComment/PostReply**: author name, body, official flag, timestamp; one table with an optional parent, limited to one level by a database trigger.
- **ChatParty**: partner (ten national digits, name, role, market) or department (`dept:<name>`; title and purpose held in the app).
- **ChatThread/ChatMessage**: one thread per sorted party pair, messages with sender address and status (`sending`/`sent`/`delivered`/`read`), unread derived from each participant's read mark.
