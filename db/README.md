# db



The PostgreSQL schema behind the app's features.

The Flutter app never opens a PostgreSQL connection
(`specs/001-login-auth-device-binding/plan.md`, FR-038). It calls
`prototype_server/` over HTTP, and that process owns the connection:

```text
Flutter UI → ViewModel → Repository → Service (HttpRegistrationService)
  → HTTP → prototype_server → PostgreSQL
```

`Service` is the seam the real API slots into later: same interface, same
endpoints, different base URL.

## Layout

| Path | What it is |
| --- | --- |
| `prototype_server/lib/db/schema.sql` | The original login / device-binding tables. Still the base. |
| `migrations/001_first_launch_and_registration.sql` | First launch and the registration wizard, applied on top. |
| `migrations/002_dashboard.sql` | Home: wallet movements, the slider and the ticker. |
| `migrations/003_space_and_chat.sql` | Space posts, hearts and comments; chat threads and messages. |
| `migrations/004_profile_settings.sql` | Language, theme, the app PIN, support numbers and About. |
| `migrations/005_complaints_and_notifications.sql` | Complaint types, targets, tickets, history and notifications. |
| `migrations/006_cash_and_scan.sql` | Cash transfers, products, prize bands and scan claims. |
| `migrations/007_points_and_targets.sql` | The points ledger, transfer rules, schemes, targets and extras. |
| `migrations/008_profile_requests_and_cash_requests.sql` | Expected-purchase bands, and the two rules a buying source's verdict must satisfy. |
| `migrations/009_inaam_baazar.sql` | The spin wheel and its spins, item schemes with their one claim, and the monthly reward programme. |
| `migrations/010_complaints_without_subtypes.sql` | Drops complaint sub-types; targets and tickets key on the category instead. |
| `migrations/011_shop_branding.sql` | Shop branding: board types, eligibility rules, requests and installed boards. |
| `migrations/012_teams_support.sql` | Crown Solar Teams support: officer on approvals, complaints and branding; closed accounts; staff chat parties; market targeting; unassigned codes. |
| `seed/001_reference_and_partners.sql` | Markets and the six demo partners, matching what the mocks used. |
| `seed/002_dashboard.sql` | The wallet movements, slides and ticker lines Home has been showing. |
| `seed/003_space_and_chat.sql` | Opening Space posts and the two department conversations. |
| `seed/004_profile_settings.sql` | Support numbers and the About copy. No PINs — a PIN is something a partner chooses. |
| `seed/005_complaints_and_notifications.sql` | The categories and targets, board 08's four tickets and five notifications. |
| `seed/006_cash_and_scan.sql` | Prize bands, the sample product codes, and one registration waiting on its buying source. |
| `seed/007_points_and_targets.sql` | Transfer rules, three schemes, board 06's ledger, and one partner's extra targets. |
| `seed/008_profile_requests_and_cash_requests.sql` | The expected-purchase bands, and three transfers already held on a retailer's inbox. |
| `seed/009_inaam_baazar.sql` | More codes to scan, the wheel and its odds, two item schemes, and two months of the reward programme. |
| `seed/010_shop_branding.sql` | Board types, their role rules, and branding history on the demo partners. |
| `seed/011_teams_support.sql` | An officer-raised complaint and branding request, an officer chat, a Ravi Road-only item scheme and an unassigned code. |

Migrations are idempotent — every statement is `IF NOT EXISTS` or guarded —
so re-running one is safe.

## Applying

```bash
psql -h localhost -U <user> -d cse_b2b_prototype -f prototype_server/lib/db/schema.sql
psql -h localhost -U <user> -d cse_b2b_prototype -f db/migrations/001_first_launch_and_registration.sql
psql -h localhost -U <user> -d cse_b2b_prototype -f db/seed/001_reference_and_partners.sql
```

## Running the app against it

Start the server with the connection details in its environment — they are
local configuration and are never committed:

```bash
cd prototype_server
dart run bin/server.dart
```

Then build the app with the switch on. Without it the app uses the in-memory
mocks, so a build with no server still opens:

```bash
flutter run --dart-define=DATA_SOURCE=server
```

`API_BASE_URL` defaults to `http://10.0.2.2:8080`, which is the host machine
as the Android emulator sees it. A real device on the same network needs the
machine's LAN address instead.

## Signing in as a demo partner

Any of these numbers signs in without an SMS code, because the account is
already bound to this device. What each one is worth looking at differs, so
one partner cannot exercise the whole app.

| Number | Who | Role | What it is for |
| --- | --- | --- | --- |
| `3004821190` | Adnan Solar Works | Installer | The fullest account. Inaam (spins, schemes, reward programme), scanning, complaints, the wallet and its ledger. |
| `3335560071` | Shahdara Solar Services | Installer | A second installer with nothing on it — the empty states, and the other side of a cash transfer. |
| `3007781204` | Al-Noor Electric Store | Retailer | Cash Requests and New Profile waiting on them, points on a signed scheme. |
| `3217745002` | Bilal Traders | Retailer | A small points balance and a transfer they sent. |
| `3014429911` | Hamza Solar House | Wholesaler | Points with three extra targets set from the Teams app. |
| `3028890143` | Ravi Distribution Co. | Distributor | The largest points balance, on the distributor scheme. |

Installers see Inaam in the bottom bar; retailers, wholesalers and
distributors see Points instead, and only they get the New Profile and Cash
Request tiles on Home.

## What is moved so far

| Feature | Reads from |
| --- | --- |
| First launch | Preferences on the phone, reported to `devices` |
| Registration wizard | `GET /markets`, `/accounts/lookup`, `/accounts/cnic-holder`, `/buying-sources/lookup`, `POST /registration/wizard/otp`, `POST /registration/applications` |
| Sign in | `GET /session/lookup` |
| Approval status | `GET /registration/applications/latest` |
| Home | `GET /dashboard` — wallet figure, slider, ticker |
| Space | `GET /space/feed`, `GET /space/posts/<id>`, and the heart / comment / reply posts |
| Chat | `GET /chat/threads`, `GET /chat/party`, `POST /chat/threads/open`, `/chat/messages`, `/chat/threads/read` |
| Profile settings | `GET`/`PUT /profile/settings`, `/profile/pin`, `/profile/pin/verify`, `/profile/pin/disable`, `GET /support/contacts`, `GET /app/about` |
| Complaints | `GET /complaints`, `/complaints/catalogue`, `/complaints/<reference>`, `POST /complaints` |
| Notifications | `GET /notifications`, `POST /notifications/read` |
| Send Cash | `GET /wallet/recipients`, `/wallet/recipients/lookup`, `POST /wallet/transfers` |
| The ledger | `GET /wallet/ledger` — the lines and the two totals, from one set of rows |
| Scan QR | `GET /scan/intro`, `POST /scan` |
| New Profile | `GET /profile-requests`, `POST /profile-requests/decision` |
| Points | `GET /points/ledger`, `/points/targets`, `/points/recipients`, `/points/recipients/lookup`, `POST /points/transfers` |
| Cash Request | `GET /wallet/cash-requests`, `POST /wallet/cash-requests/decision` |
| Inaam Baazar | `GET`/`POST /inaam/spin`, `GET /inaam/item-schemes`, `POST /inaam/item-schemes/claim`, `GET /inaam/reward-program` |

The partner's own name and role are not fetched for Home. They arrive with
sign-in and Home reads the signed-in partner, rather than asking twice for
something that cannot have changed since.

## Adding a slide or a ticker line

Both are content. A row is all it takes — no release, no build.

```sql
-- A picture that runs for a fortnight, installers only.
INSERT INTO promo_slides (image_url, eyebrow, headline, audience, starts_at, ends_at, position)
VALUES ('https://…/eid-2026.png', 'EID SCHEME', 'Double prizes on every inverter',
        'installer', now(), now() + interval '14 days', 0);

-- A ticker line in its own colours.
INSERT INTO ticker_messages (message, text_colour, background_colour, audience, ends_at)
VALUES ('Eid scheme live until 30 September', '#FFFFFF', '#04037E', 'all',
        timestamptz '2026-10-01');
```

## What a complaint is, and is not

A ticket has a category and the partner's own words. There is no second,
narrower dropdown: `complaint_subtypes` was dropped in migration 010 because
a list of labels can only ever come close to the problem, while a sentence
names it. `complaints.title` is what the partner wrote on step 1 and
`complaints.detail` is what they wrote on step 2 — both free text, neither
chosen from anything.

`complaint_targets` is therefore keyed `(type_id, priority)`. Changing a band
changes what is promised from then on; a ticket already raised keeps the
`response_target_minutes` and `resolution_target_working_days` copied onto it.

```sql
-- Answer Wallet and cash complaints faster from now on.
UPDATE complaint_targets SET response_minutes = 120
 WHERE priority = 'high'
   AND type_id = (SELECT id FROM complaint_types WHERE code = 'wallet_and_cash');
```

## Moving a complaint along

The app raises tickets; everything after that is CRM's. A status change is a
row in `complaint_events` and a row in `notifications` — the app polls for
both and needs no release to show them.

```sql
-- CRM answers CMP-2026-5514.
WITH ticket AS (
  UPDATE complaints SET first_response_at = now()
   WHERE reference = 'CMP-2026-5514' AND first_response_at IS NULL
  RETURNING id, account_id
)
INSERT INTO complaint_events (complaint_id, title, meta, state, occurred_at, position)
SELECT id, 'First response', 'We are checking the scan against the record.',
       'done', now(), 10
  FROM ticket;
```

Note what the `meta` does **not** contain: a date. `occurred_at` carries the
time and the app turns it into "Today, 5:20 PM" when it draws the line, so a
history written today still reads correctly next month.

Targets are copied onto the ticket when it is raised
(`response_target_minutes`, `resolution_target_working_days`). Changing a band
in `complaint_targets` changes what is promised from then on and never
rewrites what an open ticket was already promised.

`image_url` may be left null for a text-only slide, which renders on the brand
gradient exactly as it does today. Colours may be left null, which keeps the
app's own ticker colours — nothing invents a colour on the app's behalf.
Expired rows and rows aimed at another role are filtered on the server, so
they never reach the phone.

Still on an in-memory repository: Cash Request, Shop Branding and Inaam
Baazar.

### Space posts come from somewhere else

Nothing in this app creates a Space post, and there is no endpoint that
does. A separate Crown Solar application publishes into `space_posts`; the
partner app reads the feed and writes only its own hearts and comments. A
test asserts that `POST /space/posts` is a 404.

## What is in the database, and what is not

In: markets, accounts, submitted registration applications with their buying
sources, media and three approvals, registration OTP challenges, and what
first launch settled about each device.

Not in: the half-finished wizard draft. That is unsubmitted state on one
phone, held in `shared_preferences` so "Continue your registration?" works
without a reachable server and mid-wizard typing never hits the network.

## Scanning the same code twice

`scan_claims` has `UNIQUE (product_id, role)`. That single key is the whole
rule: one box is sold on and then installed, so a code is worth one claim to
an installer and one to a retailer, and a second partner in either role is
refused by the database rather than by a check in the app that two phones
could race past.

A role with no row in `scan_prize_rules` cannot win at all, which is how
wholesalers and distributors are kept to authenticity checks — they also take
no claim, so they can never use up a code an installer is owed.

To run a winning journey again in a demonstration, put the claims back:

```sql
-- Everything this partner has claimed.
DELETE FROM scan_claims
 WHERE account_id = (SELECT id FROM accounts WHERE mobile_number = '3004821190');

-- Or one code, in one role.
DELETE FROM scan_claims
 WHERE role = 'installer'
   AND product_id = (SELECT id FROM products WHERE code = 'CS-INV-8841');
```

The prize already paid is left alone on purpose: that money really was won,
and the wallet keeps what it was credited.

## Why a transfer writes one entry, not two

Sending cash writes the sender's debit as `held` and nothing at all to the
receiver. The money is gone from what the sender can spend the moment they
send it — which is what the review sheet promises — but the receiver has not
accepted it, so a line in their ledger would be a promise the app made on
their behalf. Their credit is written when they accept.

`cash_transfers` is the record both sides act on; `wallet_entries.transfer_id`
points back at it.

## Points are not money

`point_entries` is a separate ledger from `wallet_entries`, in a different
unit, and no query joins the two. A points balance and a cash balance are
never added together, on a screen or in SQL.

Points are whole — there is no fraction of a point — so the amounts are plain
bigints rather than the paisa trick the wallet uses.

### What counts toward a target

Points that **arrived**: `purchase_accrual` and `transfer_in`, less
`reversal`. Points sent out reduce the balance and are deliberately outside
that sum, which is why `point_entries_counting_toward_targets` has exactly
that predicate. A partner who sends points to someone with a signed scheme
has given away the credit — it counts for the receiver.

A `crm_adjustment` moves the balance but does not count, because the
"What counts toward your target" breakdown names only three sources and has
to add up to the total.

### Who may send to whom

`point_transfer_rules` holds one row per permitted pair. A pair with no row
is refused — which is the whole reason installers hold no points and appear
in no recipient list without being named anywhere. The Crown Solar team
changes the hierarchy from the Teams app by adding or removing rows:

```sql
-- Stop wholesalers paying retailers.
DELETE FROM point_transfer_rules
 WHERE from_role = 'wholesaler' AND to_role = 'retailer';
```

`point_restrictions` blocks one account's sending or receiving. No row means
no restriction; the balance and the ledger stay visible either way, because a
partner is always entitled to see their own record.

### Schemes

Signing is manual: the partner fills a paper form, the entries live in a
spreadsheet, and the rows arrive here later. Nothing in the app signs one,
and `account_schemes` is keyed on the account because only one scheme can be
signed by one partner.

`account_extra_targets` holds a target Crown Solar set for one partner from
the Teams app, normally after they reached the annual target early. It runs
alongside the scheme and takes nothing away from it.

```sql
-- After the conversation.
INSERT INTO account_extra_targets
  (account_id, label, starts_on, ends_on, target_points, prize, assigned_by)
SELECT id, 'Extra · Sep — Dec 2026', '2026-09-01', '2026-12-31', 300000,
       '32-inch LED television', 'Crown Solar CRM'
  FROM accounts WHERE mobile_number = '3014429911';
```

## Inaam Baazar

Three ways to be rewarded for scanning. All three pay into the cash wallet —
`wallet_entries` — so Inaam holds no balance of its own and none is shown.

### The wheel is never the app's to decide

`spin_configs` holds one active version; `spin_prizes` holds its segments
with an `amount_paisa` and a `weight`. The app receives the amounts and never
the weights: a partner cannot influence the odds, so sending them would only
suggest they can.

```sql
-- Make Rs. 500 twice as likely without touching the app.
UPDATE spin_prizes SET weight = 120
 WHERE amount_paisa = 50000
   AND config_id = (SELECT id FROM spin_configs WHERE active);
```

### Spins are counted, not stored

There is no `spins_available` column. The entitlement is
`scans today ÷ scans_per_spin − spins taken today`, worked out each time it is
asked for, so it cannot drift from the scans that earned it. Raising
`scans_per_spin` never puts a partner into a debt of spins, because the figure
is floored at zero.

The account row is locked for the length of a spin, which is what stops two
taps finding the same entitlement free.

### One claim per scheme, ever

`item_scheme_claims` is keyed `PRIMARY KEY (scheme_id, account_id)`. A second
claim is refused by the database, not by a check in Dart — so a partner who
reaches Platinum after claiming Silver is turned away by the same rule, in the
same place, however they ask.

A scheme is measured on `scans` or on `amount`, never both. Scans the app
counts for itself from `scan_claims`. Rupees it does not: `item_scheme_progress`
is written by SAP or the Teams app, and an amount-measured scheme with no row
reads as zero rather than as unknown.

### A tier reached is not a prize paid

`reward_program_tiers` says what each tier is worth this month.
`reward_program_awards` is what the month-end job decided, with
`bonus_percent` **copied onto the award** and `applies_from` / `applies_until`
carrying the window. Re-rating a tier afterwards therefore changes what future
months pay and never what somebody has already earned.

The bonus is applied where the money is: a scan of a programme product during
the window pays its band plus the award's percentage, and the higher amount is
what lands in `wallet_entries`.

```sql
-- What the month-end job writes for one winner.
INSERT INTO reward_program_awards (program_id, account_id, tier_id,
                                   bonus_percent, applies_from, applies_until)
SELECT p.id, a.id, t.id, t.bonus_percent, '2026-10-01', '2026-10-31'
  FROM reward_programs p
  JOIN reward_program_tiers t ON t.program_id = p.id AND t.name = 'GOLD'
 CROSS JOIN accounts a
 WHERE p.starts_on = '2026-09-01' AND a.mobile_number = '3004821190';
```
