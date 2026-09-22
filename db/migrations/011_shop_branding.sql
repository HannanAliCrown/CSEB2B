-- 011 · Shop Branding: the request, the board types it may carry, and the
-- eligibility that decides which of them a partner is offered.
--
-- Nothing here is a product rule the app enforces. Which board types exist,
-- what each costs, what each demands in points, scheme or recent scanning,
-- and how the bill is split — all of it is configuration the Teams app owns.
-- The app reads it, measures the partner against it, and records what was
-- asked for.
--
-- Points and scheme signing already exist (007); scan claims already exist
-- (006). Branding reads all three rather than keeping counts of its own.
--
-- Idempotent, like 001–010.

BEGIN;

-- The windows the eligibility rules are measured over. One row.
--
-- A table rather than constants because both numbers are business policy:
-- "recently scanned" and "too new to replace" are the kind of thing that
-- gets retuned after a season, and neither should need a release.
CREATE TABLE IF NOT EXISTS branding_config (
  id                     boolean PRIMARY KEY DEFAULT true CHECK (id),

  -- How recently an installer must have scanned for board types to open.
  scan_window_days       integer NOT NULL DEFAULT 10
                           CHECK (scan_window_days > 0),

  -- How new an installed board must be for replacement detection to take
  -- over and collapse the options to a skin or flex change.
  replacement_months     integer NOT NULL DEFAULT 6
                           CHECK (replacement_months > 0),

  updated_at             timestamptz NOT NULL DEFAULT now()
);

INSERT INTO branding_config (id) VALUES (true) ON CONFLICT (id) DO NOTHING;


-- Every board type Crown Solar offers.
--
-- One row is one option on the board-type step. What it costs and how the
-- bill splits belong here, because they do not change with who is asking.
-- What a partner must do to be offered it does change with who is asking,
-- and lives on the role table below.
CREATE TABLE IF NOT EXISTS branding_board_types (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Stable across renames, so a request keeps meaning what it meant.
  code                 text NOT NULL UNIQUE,

  name                 text NOT NULL,

  -- The one line under the name on the option card.
  description          text NOT NULL,

  -- What the whole job costs, per board. The split below divides it.
  unit_price_paisa     integer NOT NULL CHECK (unit_price_paisa > 0),

  -- Crown Solar's share. The partner pays the rest, so only one is stored
  -- and the two can never disagree.
  company_percent      integer NOT NULL DEFAULT 60
                         CHECK (company_percent BETWEEN 0 AND 100),

  -- Set on the two replacement options. Names the board type whose recent
  -- installation brings this one out — and, while it does, hides every
  -- other option. Null on everything a partner can simply qualify for.
  replaces_code        text REFERENCES branding_board_types (code),

  position             integer NOT NULL DEFAULT 0
);


-- Which roles may see a board type, and what each must satisfy to get it.
--
-- The conditions sit here rather than on the type because the same board
-- carries different terms for different roles: a Frontlit Board opens for
-- an installer who scanned recently, and for a retailer who signed a
-- scheme. Role itself is not a condition a partner can meet — points can be
-- earned and a scheme can be signed, but a retailer does not become a
-- distributor — so an absent row means the option is never shown at all,
-- while a row whose conditions are unmet is shown locked with its reason.
CREATE TABLE IF NOT EXISTS branding_board_type_roles (
  board_type_id        uuid NOT NULL REFERENCES branding_board_types (id)
                         ON DELETE CASCADE,
  role                 text NOT NULL CHECK (
                         role IN ('installer', 'retailer',
                                  'wholesaler', 'distributor')
                       ),

  -- Points the partner must hold. Zero means no points condition.
  min_points           integer NOT NULL DEFAULT 0 CHECK (min_points >= 0),

  -- Whether a signed scheme is required.
  requires_scheme      boolean NOT NULL DEFAULT false,

  -- Whether the partner must have scanned inside the configured window.
  -- The installer's Frontlit board is the only option that uses this.
  requires_recent_scan boolean NOT NULL DEFAULT false,

  PRIMARY KEY (board_type_id, role)
);


-- What is physically on a partner's shop right now.
--
-- Written when a request completes, and read by replacement detection. A
-- partner can have had several over the years, so this is a history and the
-- most recent row wins.
CREATE TABLE IF NOT EXISTS branding_installations (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id    uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  board_type_id uuid NOT NULL REFERENCES branding_board_types (id),
  installed_on  date NOT NULL,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS branding_installations_recent
  ON branding_installations (account_id, installed_on DESC);


-- One branding request.
--
-- The measurements and photos are the partner's; the status and the stage
-- are Crown Solar's. Nothing in the app moves a request forward.
CREATE TABLE IF NOT EXISTS branding_requests (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- What the partner and Crown Solar quote at each other: BRD-2026-3391.
  reference         text NOT NULL UNIQUE,

  account_id        uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,

  -- Device paths, as the registration wizard stores its captures. The
  -- prototype uploads nothing; the real API will replace these with URLs
  -- behind the same two columns.
  shop_photo_path   text NOT NULL,
  card_photo_path   text NOT NULL,

  height_ft         numeric(6, 2) NOT NULL CHECK (height_ft > 0),
  width_ft          numeric(6, 2) NOT NULL CHECK (width_ft > 0),
  board_count       integer NOT NULL CHECK (board_count > 0),

  -- All three optional, and all three fall back to the registered profile.
  shop_address      text,
  contact_number    text,
  person_name       text,

  status            text NOT NULL DEFAULT 'in_progress'
                      CHECK (status IN ('in_progress', 'completed', 'rejected')),

  -- 1 approved · 2 board installed · 3 call confirmed. Held even on a
  -- completed request so its timeline still reads as a history.
  stage             integer NOT NULL DEFAULT 1 CHECK (stage BETWEEN 1 AND 3),

  -- Present only on a rejected request, which shows this instead of a
  -- timeline: no stage past review was ever reached.
  rejection_reason  text,

  created_at        timestamptz NOT NULL DEFAULT now(),

  CHECK (status <> 'rejected' OR rejection_reason IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS branding_requests_by_account
  ON branding_requests (account_id, created_at DESC);


-- One board inside a request.
--
-- A request for two boards is two rows, and each may be a different type —
-- a retailer can mix a Backlit Board with an Inverter Wall Branding as long
-- as each meets its own condition.
CREATE TABLE IF NOT EXISTS branding_request_boards (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id       uuid NOT NULL REFERENCES branding_requests (id)
                     ON DELETE CASCADE,

  -- 1-based, so BOARD 1 on screen is position 1 here.
  position         integer NOT NULL CHECK (position > 0),

  board_type_id    uuid NOT NULL REFERENCES branding_board_types (id),

  -- Copied from the board type when the request is submitted, so a price
  -- or split changed afterwards does not rewrite what was agreed.
  unit_price_paisa integer NOT NULL CHECK (unit_price_paisa > 0),
  company_percent  integer NOT NULL
                     CHECK (company_percent BETWEEN 0 AND 100),

  UNIQUE (request_id, position)
);

COMMIT;
