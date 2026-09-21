-- 008 · What a buying source has to decide.
--
-- Two inboxes, both for the roles that sell on:
--
--   New Profile   — a registration naming this partner as its buying source.
--   Cash Requests — money already out of someone's wallet, waiting on them.
--
-- The cash side needs no new table: `cash_transfers` (006) already holds the
-- state both parties act on. What is added here is the two rules a buying
-- source's verdict has to obey, put in the database rather than only in the
-- app — so an approval without an expected purchase, or a rejection without
-- a reason, cannot be written at all.
--
-- Idempotent, like 001–007.

BEGIN;


-- ---------------------------------------------------------------------------
-- Expected purchasing
-- ---------------------------------------------------------------------------

-- The bands a buying source picks from before approving someone.
--
-- Rows rather than an enum: what Crown Solar considers a meaningful monthly
-- volume changes with prices, and changing it should not need a release.
CREATE TABLE IF NOT EXISTS expected_purchase_bands (
  id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- As the buying source reads it, e.g. 'PKR 100,000 — 300,000 a month'.
  label     text NOT NULL UNIQUE,

  position  integer NOT NULL DEFAULT 0,
  active    boolean NOT NULL DEFAULT true,

  created_at timestamptz NOT NULL DEFAULT now()
);


-- What the buying source expects this applicant to buy from them. Set only
-- on the buying source's own approval; the marketing officer and CRM have no
-- opinion to record here.
ALTER TABLE registration_approvals
  ADD COLUMN IF NOT EXISTS expected_purchase_band_id uuid
    REFERENCES expected_purchase_bands (id);


-- A buying source cannot approve without saying what they expect the
-- applicant to buy. The constraint is here, not only on the screen, because
-- the figure is the point of asking them at all.
ALTER TABLE registration_approvals
  DROP CONSTRAINT IF EXISTS registration_approvals_approval_needs_expectation;
ALTER TABLE registration_approvals
  ADD CONSTRAINT registration_approvals_approval_needs_expectation CHECK (
    approver <> 'buying_source'
    OR state <> 'approved'
    OR expected_purchase_band_id IS NOT NULL
  );


-- And cannot reject without saying why. A refusal that ends someone's
-- registration owes them a reason.
ALTER TABLE registration_approvals
  DROP CONSTRAINT IF EXISTS registration_approvals_rejection_needs_reason;
ALTER TABLE registration_approvals
  ADD CONSTRAINT registration_approvals_rejection_needs_reason CHECK (
    approver <> 'buying_source'
    OR state <> 'rejected'
    OR (note IS NOT NULL AND btrim(note) <> '')
  );


-- ---------------------------------------------------------------------------
-- Cash requests
-- ---------------------------------------------------------------------------

-- The receiver's inbox reads `cash_transfers` by `to_account_id`, which
-- already has its index (006). This one is for the two decided tabs, which
-- read by decision time rather than by when the money was sent.
CREATE INDEX IF NOT EXISTS cash_transfers_decided
  ON cash_transfers (to_account_id, decided_at DESC)
  WHERE state <> 'held';

COMMIT;
