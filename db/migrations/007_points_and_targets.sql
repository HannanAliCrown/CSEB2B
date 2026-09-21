-- 007 · Points, schemes and targets.
--
-- Points are not money. They live in their own ledger with their own
-- balance, and nothing here touches `wallet_entries` — the two are never
-- added together, on any screen or in any query.
--
-- Points are whole. There is no fractional point, so the amounts here are
-- plain bigints rather than the paisa trick the wallet uses.
--
-- Idempotent, like 001–006.

BEGIN;


-- ---------------------------------------------------------------------------
-- The points ledger
-- ---------------------------------------------------------------------------

-- Human-facing references, e.g. 'PT-2026-77410'.
CREATE SEQUENCE IF NOT EXISTS point_reference_seq START WITH 77411;

CREATE OR REPLACE FUNCTION next_point_reference() RETURNS text
  LANGUAGE sql AS $$
    SELECT 'PT-' || to_char(now(), 'YYYY') || '-'
           || nextval('point_reference_seq')::text
  $$;

-- Every movement of points. The balance is never stored: it is the sum of
-- these rows, so the hub, the ledger and a target's score can never disagree
-- about each other.
CREATE TABLE IF NOT EXISTS point_entries (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id    uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,

  reference     text NOT NULL DEFAULT next_point_reference(),

  direction     text NOT NULL CHECK (direction IN ('credit', 'debit')),

  -- What put the line there.
  --
  -- 'purchase_accrual' is SAP posting one percent of a purchase.
  -- 'reversal' is SAP taking that back when the purchase is reversed.
  -- 'transfer_in' / 'transfer_out' are partner-to-partner.
  -- 'crm_adjustment' is Crown Solar correcting something by hand.
  type          text NOT NULL CHECK (type IN (
                  'purchase_accrual', 'reversal',
                  'transfer_in', 'transfer_out', 'crm_adjustment'
                )),

  amount        bigint NOT NULL CHECK (amount > 0),

  -- Set on a transfer; null on anything SAP or CRM wrote.
  counterparty_account_id uuid REFERENCES accounts (id),

  -- The SAP document a purchase or reversal came from, e.g. 'INV-77213'.
  -- Points are posted by SAP, so this is what a partner quotes when a figure
  -- looks wrong.
  sap_document  text,

  -- Why, in Crown Solar's words. Shown on a CRM adjustment, where a number
  -- with no reason is not an answer.
  note          text,

  posted_at     timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now(),

  -- A transfer names the other party; nothing else may.
  CHECK ((type IN ('transfer_in', 'transfer_out'))
         = (counterparty_account_id IS NOT NULL))
);

CREATE INDEX IF NOT EXISTS point_entries_by_account
  ON point_entries (account_id, posted_at DESC);

-- What a target counts: points that arrived. Sending points out reduces the
-- balance and is deliberately outside this index's predicate.
CREATE INDEX IF NOT EXISTS point_entries_counting_toward_targets
  ON point_entries (account_id, posted_at)
  WHERE type IN ('purchase_accrual', 'transfer_in', 'reversal');


-- ---------------------------------------------------------------------------
-- Who may send points to whom
-- ---------------------------------------------------------------------------

-- One row per permitted pair. A pair with no row is refused — which is how
-- installers are kept out of points entirely without naming them anywhere,
-- and how the Crown Solar team changes the hierarchy from the Teams app
-- without a release here.
CREATE TABLE IF NOT EXISTS point_transfer_rules (
  from_role   text NOT NULL CHECK (from_role IN ('installer', 'retailer',
                                                 'wholesaler', 'distributor')),
  to_role     text NOT NULL CHECK (to_role IN ('installer', 'retailer',
                                               'wholesaler', 'distributor')),
  updated_at  timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (from_role, to_role)
);


-- A block on one account's points transfers, set by Crown Solar.
--
-- No row means no restriction. Only sending and receiving are affected: the
-- balance and the ledger stay visible either way, because a partner is
-- always entitled to see their own record.
CREATE TABLE IF NOT EXISTS point_restrictions (
  account_id   uuid PRIMARY KEY REFERENCES accounts (id) ON DELETE CASCADE,
  can_send     boolean NOT NULL DEFAULT true,
  can_receive  boolean NOT NULL DEFAULT true,
  reason       text,
  created_at   timestamptz NOT NULL DEFAULT now()
);


-- ---------------------------------------------------------------------------
-- Schemes and targets
-- ---------------------------------------------------------------------------

-- A scheme as printed and signed on paper. Signing is manual: the partner
-- fills a form, it is kept in a spreadsheet, and the rows arrive here later.
-- Nothing in this app signs one.
CREATE TABLE IF NOT EXISTS point_schemes (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name                 text NOT NULL,
  year                 integer NOT NULL,

  -- The year total and what reaching it wins.
  annual_target_points bigint NOT NULL CHECK (annual_target_points > 0),
  annual_prize         text,

  -- The variant that also carries a grand prize for hitting every period.
  -- Null when the scheme has no such prize.
  grand_prize          text,

  created_at           timestamptz NOT NULL DEFAULT now(),

  UNIQUE (name, year)
);

-- The four-month targets inside a scheme, each with its own prize.
CREATE TABLE IF NOT EXISTS scheme_periods (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  scheme_id      uuid NOT NULL REFERENCES point_schemes (id) ON DELETE CASCADE,

  -- 'Jan — Apr 2026'.
  label          text NOT NULL,

  starts_on      date NOT NULL,
  ends_on        date NOT NULL,
  target_points  bigint NOT NULL CHECK (target_points > 0),
  prize          text,
  position       integer NOT NULL DEFAULT 0,

  CHECK (ends_on > starts_on),
  UNIQUE (scheme_id, label)
);


-- Who signed what. The primary key is the account, because only one scheme
-- can be signed by one partner.
CREATE TABLE IF NOT EXISTS account_schemes (
  account_id  uuid PRIMARY KEY REFERENCES accounts (id) ON DELETE CASCADE,
  scheme_id   uuid NOT NULL REFERENCES point_schemes (id),

  -- When the paper was signed, not when the row was typed in.
  signed_on   date NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);


-- A target Crown Solar set for one partner, outside any scheme.
--
-- Assigned from the Teams app after a conversation — normally to someone who
-- reached their annual target before the year ended. It runs alongside the
-- signed scheme and takes nothing away from it, so it is its own table
-- rather than a flag on scheme_periods.
CREATE TABLE IF NOT EXISTS account_extra_targets (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id     uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,

  label          text NOT NULL,
  starts_on      date NOT NULL,
  ends_on        date NOT NULL,
  target_points  bigint NOT NULL CHECK (target_points > 0),
  prize          text,

  -- Who set it, for the "assigned by Crown Solar CRM" line.
  assigned_by    text,
  assigned_at    timestamptz NOT NULL DEFAULT now(),

  CHECK (ends_on > starts_on),
  UNIQUE (account_id, label)
);

CREATE INDEX IF NOT EXISTS account_extra_targets_in_order
  ON account_extra_targets (account_id, starts_on);

COMMIT;
