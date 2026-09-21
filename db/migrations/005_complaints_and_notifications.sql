-- 005 · Complaints and Notifications.
--
-- Idempotent, like 001–004.

BEGIN;


-- ---------------------------------------------------------------------------
-- What a complaint can be about
-- ---------------------------------------------------------------------------

-- The chips on step 1 of the wizard. Rows, not an enum, because Crown Solar
-- adds a category without a release.
CREATE TABLE IF NOT EXISTS complaint_types (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Stable across renames: the app maps this to the design's icon.
  code      text NOT NULL UNIQUE,

  -- What the chip on the wizard says.
  label     text NOT NULL,

  -- What the ticket list and the detail header say, where the line already
  -- carries a date or a priority beside it and the chip's wording would read
  -- oddly ("QR and prizes · raised Today" vs "QR prize dispute · raised
  -- Today"). Null means the chip's label does for both.
  short_label text,

  position  integer NOT NULL DEFAULT 0,
  active    boolean NOT NULL DEFAULT true
);

-- "Which part?" — the second, narrower choice.
CREATE TABLE IF NOT EXISTS complaint_subtypes (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type_id   uuid NOT NULL REFERENCES complaint_types (id) ON DELETE CASCADE,

  label     text NOT NULL,
  position  integer NOT NULL DEFAULT 0,
  active    boolean NOT NULL DEFAULT true,

  UNIQUE (type_id, label)
);

CREATE INDEX IF NOT EXISTS complaint_subtypes_live
  ON complaint_subtypes (type_id, position)
  WHERE active;


-- ---------------------------------------------------------------------------
-- What Crown Solar promises
-- ---------------------------------------------------------------------------

-- The response and resolution targets the wizard states before submitting.
-- They depend on the sub-type AND the priority, which is why this is its own
-- table rather than two columns on complaint_subtypes.
CREATE TABLE IF NOT EXISTS complaint_targets (
  subtype_id                uuid NOT NULL
                              REFERENCES complaint_subtypes (id)
                              ON DELETE CASCADE,
  priority                  text NOT NULL
                              CHECK (priority IN ('low', 'medium', 'high')),

  response_minutes          integer NOT NULL CHECK (response_minutes > 0),
  resolution_working_days   integer NOT NULL
                              CHECK (resolution_working_days > 0),

  PRIMARY KEY (subtype_id, priority)
);


-- ---------------------------------------------------------------------------
-- The tickets
-- ---------------------------------------------------------------------------

-- Human-facing references (CMP-2026-5514). Partners read these out on the
-- phone, so they are short and per-year rather than a uuid.
CREATE SEQUENCE IF NOT EXISTS complaint_reference_seq START WITH 5515;

CREATE OR REPLACE FUNCTION next_complaint_reference() RETURNS text
  LANGUAGE sql AS $$
    SELECT 'CMP-' || to_char(now(), 'YYYY') || '-'
           || nextval('complaint_reference_seq')::text
  $$;

CREATE TABLE IF NOT EXISTS complaints (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reference   text NOT NULL UNIQUE DEFAULT next_complaint_reference(),

  account_id  uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  subtype_id  uuid NOT NULL REFERENCES complaint_subtypes (id),

  priority    text NOT NULL CHECK (priority IN ('low', 'medium', 'high')),
  title       text NOT NULL,
  detail      text NOT NULL,

  status      text NOT NULL DEFAULT 'in_progress'
                CHECK (status IN ('in_progress', 'resolved')),

  -- What the app attached by itself: the scan, the other claimant, the
  -- timestamps. Free text, because it describes evidence held elsewhere
  -- rather than storing a second copy of it.
  evidence_note           text,

  -- Copied from complaint_targets when the ticket is raised, NOT read back
  -- through the join. A target that changes next month must not silently
  -- rewrite what a partner was promised last month.
  response_target_minutes         integer NOT NULL,
  resolution_target_working_days  integer NOT NULL,

  raised_at         timestamptz NOT NULL DEFAULT now(),

  -- Null until they happen; the detail screen compares them to the targets.
  first_response_at timestamptz,
  resolved_at       timestamptz,

  updated_at        timestamptz NOT NULL DEFAULT now()
);

-- The list screen: this partner's tickets, newest first, split by tab.
CREATE INDEX IF NOT EXISTS complaints_for_account
  ON complaints (account_id, status, raised_at DESC);

DROP TRIGGER IF EXISTS complaints_set_updated_at ON complaints;
CREATE TRIGGER complaints_set_updated_at
  BEFORE UPDATE ON complaints
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- The history on the detail screen. One row per thing that happened, written
-- by whoever made it happen — the app on submission, CRM thereafter.
CREATE TABLE IF NOT EXISTS complaint_events (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  complaint_id  uuid NOT NULL REFERENCES complaints (id) ON DELETE CASCADE,

  title         text NOT NULL,

  -- The narrative only — never a date. The time is `occurred_at`, formatted
  -- by the app when it draws the line, so a history written in September
  -- does not still say "Today" in October.
  meta          text,

  -- A trailing clause after the time ("response target met"). Its own column
  -- because it is a verdict on the event rather than part of the story.
  note          text,

  -- 'done' is behind us, 'active' is what is being waited on now, 'pending'
  -- has not started. The timeline draws each differently.
  state         text NOT NULL DEFAULT 'done'
                  CHECK (state IN ('done', 'active', 'pending')),

  -- Null for a step that has not happened: there is no time to show.
  occurred_at   timestamptz,
  position      integer NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS complaint_events_in_order
  ON complaint_events (complaint_id, position, occurred_at);


-- ---------------------------------------------------------------------------
-- Notifications
-- ---------------------------------------------------------------------------

-- What the bell on Home opens.
--
-- A row is the record of something that already happened elsewhere — a prize
-- credited, a complaint answered. This table never decides anything; it only
-- says what the partner should be told and where tapping it lands.
CREATE TABLE IF NOT EXISTS notifications (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id  uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,

  -- How the row is drawn, not what it is about.
  level       text NOT NULL DEFAULT 'info'
                CHECK (level IN ('info', 'success', 'warning', 'critical')),

  title       text NOT NULL,
  body        text NOT NULL,

  -- The deep link, in two halves: what to tell the partner tapping does
  -- ("opens Ledger entry") and where it actually goes. Either may be null —
  -- a notification that leads nowhere is still worth showing.
  destination_label  text,
  destination_route  text,

  created_at  timestamptz NOT NULL DEFAULT now(),

  -- Null while unread. A timestamp rather than a boolean, because "when did
  -- they see it" is worth more than "did they".
  read_at     timestamptz
);

-- The list, newest first, and the unread badge.
CREATE INDEX IF NOT EXISTS notifications_for_account
  ON notifications (account_id, created_at DESC);

CREATE INDEX IF NOT EXISTS notifications_unread
  ON notifications (account_id)
  WHERE read_at IS NULL;

COMMIT;
