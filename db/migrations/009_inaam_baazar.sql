-- 009 · Inaam Baazar: Spin and Win, Item Schemes, and the Reward Program.
--
-- Three ways Crown Solar rewards an installer for scanning, all configured
-- from the Teams app and none of them decided by this application. What the
-- app does is count scans, show what that earns, and pay what is won.
--
-- Every prize here is paid into the cash wallet, which already exists
-- (002) — Inaam has no balance of its own.
--
-- Idempotent, like 001–008.

BEGIN;


-- A scheme prize is its own kind of wallet movement. Without this it would
-- have to masquerade as a CRM adjustment, which would be a lie in the one
-- place a partner goes to check what they were paid.
ALTER TABLE wallet_entries DROP CONSTRAINT IF EXISTS wallet_entries_type_check;
ALTER TABLE wallet_entries ADD CONSTRAINT wallet_entries_type_check CHECK (
  type IN ('send_cash', 'cash_request', 'scan_prize', 'spin_prize',
           'scheme_prize', 'returned', 'crm_adjustment')
);


-- ---------------------------------------------------------------------------
-- Spin and Win
-- ---------------------------------------------------------------------------

-- How the wheel is set up. Versioned rather than edited in place, because
-- every spin records the configuration that was in force when it happened —
-- a prize paid last month must stay explicable after the odds change.
CREATE TABLE IF NOT EXISTS spin_configs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  version         integer NOT NULL UNIQUE,

  -- Scans in one day that earn one spin. Ten today; the Teams app moves it.
  scans_per_spin  integer NOT NULL CHECK (scans_per_spin > 0),

  active          boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Only one configuration is in force at a time.
CREATE UNIQUE INDEX IF NOT EXISTS spin_configs_one_active
  ON spin_configs ((true)) WHERE active;


-- One segment of the wheel: what it pays and how likely it is.
--
-- The weight is never sent to the phone. A partner cannot influence the odds,
-- so showing them would only invite the belief that they can.
CREATE TABLE IF NOT EXISTS spin_prizes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  config_id     uuid NOT NULL REFERENCES spin_configs (id) ON DELETE CASCADE,

  amount_paisa  bigint NOT NULL CHECK (amount_paisa > 0),

  -- Relative likelihood. A prize with weight 0 is on the wheel but never won,
  -- which is not a thing Crown Solar should be able to do by accident.
  weight        integer NOT NULL CHECK (weight > 0),

  -- Where it sits on the wheel, clockwise from the top.
  position      integer NOT NULL,

  UNIQUE (config_id, position)
);


-- Every spin that has happened. The entitlement to spin is never stored: it
-- is today's scans divided by `scans_per_spin`, less the spins already taken
-- today, so it cannot drift from the scans that earned it.
CREATE TABLE IF NOT EXISTS spins (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reference       text NOT NULL UNIQUE,

  account_id      uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,

  -- What was in force. Kept so an old prize stays explicable.
  config_id       uuid NOT NULL REFERENCES spin_configs (id),
  prize_id        uuid REFERENCES spin_prizes (id),

  amount_paisa    bigint NOT NULL CHECK (amount_paisa > 0),

  -- The credit this spin produced, so the prize and the ledger line can
  -- never disagree about each other.
  wallet_entry_id uuid REFERENCES wallet_entries (id) ON DELETE SET NULL,

  spun_at         timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS spins_by_account
  ON spins (account_id, spun_at DESC);


-- ---------------------------------------------------------------------------
-- Item Schemes
-- ---------------------------------------------------------------------------

-- A scheme over particular products, measured one way or the other.
CREATE TABLE IF NOT EXISTS item_schemes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,

  -- 'scans' counts boxes; 'amount' counts rupees purchased. Never both: a
  -- scheme that mixed them would have two progress bars and one prize.
  measure     text NOT NULL CHECK (measure IN ('scans', 'amount')),

  starts_on   date NOT NULL,

  -- The target has to be reached AND the prize claimed before this.
  ends_on     date NOT NULL,

  active      boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),

  CHECK (ends_on > starts_on),
  UNIQUE (name, starts_on)
);

-- Which products count toward it. A scheme with no products counts nothing,
-- which is why seeding one without them is a mistake worth noticing.
CREATE TABLE IF NOT EXISTS item_scheme_products (
  scheme_id   uuid NOT NULL REFERENCES item_schemes (id) ON DELETE CASCADE,
  product_id  uuid NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  PRIMARY KEY (scheme_id, product_id)
);

-- The tiers inside it: what each takes and what each pays.
CREATE TABLE IF NOT EXISTS item_scheme_tiers (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scheme_id     uuid NOT NULL REFERENCES item_schemes (id) ON DELETE CASCADE,

  name          text NOT NULL,

  -- Scans, or paisa, depending on the scheme's measure.
  threshold     bigint NOT NULL CHECK (threshold > 0),

  reward_paisa  bigint NOT NULL CHECK (reward_paisa > 0),
  position      integer NOT NULL DEFAULT 0,

  UNIQUE (scheme_id, name)
);

-- Progress on an amount-measured scheme.
--
-- Scans this app can count for itself; rupees purchased it cannot — that
-- figure comes from SAP through the Teams app, the same way points accruals
-- do. A scheme with no row here shows zero rather than a number nobody
-- posted.
CREATE TABLE IF NOT EXISTS item_scheme_progress (
  scheme_id     uuid NOT NULL REFERENCES item_schemes (id) ON DELETE CASCADE,
  account_id    uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  amount_paisa  bigint NOT NULL DEFAULT 0 CHECK (amount_paisa >= 0),
  updated_at    timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (scheme_id, account_id)
);


-- The one tier a partner took.
--
-- The primary key is (scheme, account) and that single fact is the whole
-- one-claim rule: taking Silver closes Gold and Platinum because there is
-- nowhere to write a second claim, whatever the app does next.
CREATE TABLE IF NOT EXISTS item_scheme_claims (
  scheme_id       uuid NOT NULL REFERENCES item_schemes (id) ON DELETE CASCADE,
  account_id      uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,

  tier_id         uuid NOT NULL REFERENCES item_scheme_tiers (id),
  reference       text NOT NULL UNIQUE,
  amount_paisa    bigint NOT NULL CHECK (amount_paisa > 0),
  wallet_entry_id uuid REFERENCES wallet_entries (id) ON DELETE SET NULL,
  claimed_at      timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (scheme_id, account_id)
);


-- ---------------------------------------------------------------------------
-- Reward Program
-- ---------------------------------------------------------------------------

-- One month's programme. A background job closes each month, awards the
-- highest tier every partner reached, and creates the next one — so these
-- rows arrive without anyone opening the app.
CREATE TABLE IF NOT EXISTS reward_programs (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- 'July 2026', as the screen prints it.
  label       text NOT NULL,

  starts_on   date NOT NULL,
  ends_on     date NOT NULL,

  created_at  timestamptz NOT NULL DEFAULT now(),

  CHECK (ends_on > starts_on),
  UNIQUE (starts_on)
);

CREATE TABLE IF NOT EXISTS reward_program_products (
  program_id  uuid NOT NULL REFERENCES reward_programs (id) ON DELETE CASCADE,
  product_id  uuid NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  PRIMARY KEY (program_id, product_id)
);

-- What each tier takes, and the extra it adds to next month's scan prizes.
CREATE TABLE IF NOT EXISTS reward_program_tiers (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  program_id     uuid NOT NULL
                   REFERENCES reward_programs (id) ON DELETE CASCADE,

  name           text NOT NULL,
  scan_target    integer NOT NULL CHECK (scan_target > 0),

  -- The percentage added to every scheme-product scan prize next month.
  bonus_percent  integer NOT NULL CHECK (bonus_percent > 0),

  position       integer NOT NULL DEFAULT 0,

  UNIQUE (program_id, name)
);


-- What the month-end job decided.
--
-- The award is written against the programme that was *earned*, and applies
-- during the programme that follows it — which is what "you get the bonus on
-- next month's scans" means.
CREATE TABLE IF NOT EXISTS reward_program_awards (
  program_id   uuid NOT NULL REFERENCES reward_programs (id) ON DELETE CASCADE,
  account_id   uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,

  tier_id      uuid NOT NULL REFERENCES reward_program_tiers (id),

  -- Copied from the tier, so a tier renamed or re-rated later does not
  -- rewrite what somebody already earned.
  bonus_percent integer NOT NULL CHECK (bonus_percent > 0),

  -- The window the bonus is live for: the month after the one it was earned
  -- in. Stored so the scanner can answer "is a bonus running?" with a date
  -- comparison rather than a calendar calculation.
  applies_from  date NOT NULL,
  applies_until date NOT NULL,

  awarded_at    timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (program_id, account_id),
  CHECK (applies_until > applies_from)
);

CREATE INDEX IF NOT EXISTS reward_program_awards_live
  ON reward_program_awards (account_id, applies_from, applies_until);

COMMIT;
