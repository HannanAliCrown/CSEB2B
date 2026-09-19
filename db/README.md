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
| `seed/001_reference_and_partners.sql` | Markets and the six demo partners, matching what the mocks used. |
| `seed/002_dashboard.sql` | The wallet movements, slides and ticker lines Home has been showing. |
| `seed/003_space_and_chat.sql` | Opening Space posts and the two department conversations. |

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

`image_url` may be left null for a text-only slide, which renders on the brand
gradient exactly as it does today. Colours may be left null, which keeps the
app's own ticker colours — nothing invents a colour on the app's behalf.
Expired rows and rows aimed at another role are filtered on the server, so
they never reach the phone.

Everything else — Send Cash, the ledger, Scan and Profile — is still on its
in-memory repository.

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
