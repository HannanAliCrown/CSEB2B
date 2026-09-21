-- 006 · Send Cash, the ledger, and Scan.
--
-- `wallet_entries` already exists (002) and stays the single record of every
-- movement — the balance is still never stored. What this migration adds is
-- the transfer that produces two of those entries, and the product records a
-- scan is checked against.
--
-- Idempotent, like 001–005.

BEGIN;


-- ---------------------------------------------------------------------------
-- Sending cash
-- ---------------------------------------------------------------------------

-- Human-readable references, e.g. 'TX-0006'. Partners quote these to CRM, so
-- they are short and sequential rather than a uuid. 0001–0005 are the seeded
-- opening history.
CREATE SEQUENCE IF NOT EXISTS wallet_reference_seq START WITH 6;

CREATE OR REPLACE FUNCTION next_wallet_reference() RETURNS text
  LANGUAGE sql AS $$
    SELECT 'TX-' || lpad(nextval('wallet_reference_seq')::text, 4, '0')
  $$;

-- One transfer between two partners.
--
-- This is the thing both sides act on; the money itself is in
-- `wallet_entries`, which carries a `transfer_id` back to here. A transfer
-- writes the sender's debit immediately — the money is gone from what they
-- can spend the moment they send it — and the receiver's credit only when
-- they accept.
CREATE TABLE IF NOT EXISTS cash_transfers (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reference        text NOT NULL UNIQUE DEFAULT next_wallet_reference(),

  from_account_id  uuid NOT NULL REFERENCES accounts (id),
  to_account_id    uuid NOT NULL REFERENCES accounts (id),

  amount_paisa     bigint NOT NULL CHECK (amount_paisa > 0),
  note             text,

  -- 'held' is the only state money is in limbo. 'rejected' and 'expired'
  -- both return it; they are kept apart because the partner is owed
  -- different words for each.
  state            text NOT NULL DEFAULT 'held'
                     CHECK (state IN ('held', 'accepted', 'rejected',
                                      'expired')),

  sent_at          timestamptz NOT NULL DEFAULT now(),
  decided_at       timestamptz,

  -- Nobody's money sits in limbo forever; CRM returns anything past this.
  expires_at       timestamptz,

  -- Sending to yourself is not a transfer.
  CHECK (from_account_id <> to_account_id),

  -- A decided transfer says when it was decided.
  CHECK ((state = 'held') = (decided_at IS NULL))
);

CREATE INDEX IF NOT EXISTS cash_transfers_waiting_on_receiver
  ON cash_transfers (to_account_id, sent_at DESC)
  WHERE state = 'held';

CREATE INDEX IF NOT EXISTS cash_transfers_by_sender
  ON cash_transfers (from_account_id, sent_at DESC);


-- Which transfer, prize or adjustment put a line in the ledger.
ALTER TABLE wallet_entries ADD COLUMN IF NOT EXISTS transfer_id uuid
  REFERENCES cash_transfers (id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS wallet_entries_by_transfer
  ON wallet_entries (transfer_id)
  WHERE transfer_id IS NOT NULL;


-- ---------------------------------------------------------------------------
-- Scanning a product
-- ---------------------------------------------------------------------------

-- What is behind a printed code. Crown Solar's factory records; the app only
-- ever reads them.
CREATE TABLE IF NOT EXISTS products (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- As printed on the box, upper case.
  code        text NOT NULL UNIQUE,

  name        text NOT NULL,
  batch       text,
  plant       text,
  made_on     date,

  -- 'blocked' is a batch Crown Solar has withdrawn. It is still genuine —
  -- which is why this is not simply a missing row.
  state       text NOT NULL DEFAULT 'active'
                CHECK (state IN ('active', 'blocked')),

  -- Whether this particular code pays anything. How much is not here: that
  -- depends on who scans it (scan_prize_rules).
  wins_prize  boolean NOT NULL DEFAULT false,

  created_at  timestamptz NOT NULL DEFAULT now()
);


-- What a winning code pays, by role.
--
-- A role with no row here cannot win at all — which is how wholesalers and
-- distributors are kept to authenticity checks, without that rule living in
-- the app.
CREATE TABLE IF NOT EXISTS scan_prize_rules (
  role          text PRIMARY KEY
                  CHECK (role IN ('installer', 'retailer',
                                  'wholesaler', 'distributor')),
  amount_paisa  bigint NOT NULL CHECK (amount_paisa > 0),
  updated_at    timestamptz NOT NULL DEFAULT now()
);


-- Who has claimed a code.
--
-- One box is sold on and then installed, so the same code is worth one claim
-- to an installer and one to a retailer. The unique key is what enforces
-- that: a second installer on a code an installer already took is refused by
-- the database, not by a check in the app that a second request could race.
CREATE TABLE IF NOT EXISTS scan_claims (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id      uuid NOT NULL REFERENCES products (id) ON DELETE CASCADE,
  account_id      uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,

  -- The role as it was when the claim was taken. Copied, not joined: a
  -- partner promoted from retailer to wholesaler next year must not free up
  -- the retailer claim they already spent.
  role            text NOT NULL
                    CHECK (role IN ('installer', 'retailer',
                                    'wholesaler', 'distributor')),

  -- Null when the code was genuine but paid nothing.
  prize_paisa     bigint CHECK (prize_paisa IS NULL OR prize_paisa > 0),

  -- The credit this claim produced, so the prize and the ledger line can
  -- never disagree about each other.
  wallet_entry_id uuid REFERENCES wallet_entries (id) ON DELETE SET NULL,

  claimed_at      timestamptz NOT NULL DEFAULT now(),

  UNIQUE (product_id, role)
);

CREATE INDEX IF NOT EXISTS scan_claims_by_account
  ON scan_claims (account_id, claimed_at DESC);


-- ---------------------------------------------------------------------------
-- New profile requests
-- ---------------------------------------------------------------------------

-- A retailer, wholesaler or distributor named as someone's buying source has
-- to verify them. Both tables already exist (001); this is the index that
-- makes "the requests waiting on me" a lookup rather than a scan.
CREATE INDEX IF NOT EXISTS registration_buying_sources_by_account
  ON registration_buying_sources (matched_account_id)
  WHERE matched_account_id IS NOT NULL;

COMMIT;
