-- 012 · Crown Solar Teams support (specs/013-teams-support, CSE-1 … CSE-7).
--
-- Crown Solar Teams is the field staff's app (MO, ASM, RSM) on this same
-- database. Its staff live in its own tables, created by its migrations after
-- this one, so every staff reference here is an id with the name and role
-- copied beside it — the same way `decided_by_name` already copies a
-- partner's name — rather than a foreign key into Teams.
--
-- Idempotent, like 001–011.

BEGIN;

-- ---------------------------------------------------------------------------
-- CSE-1 · The Marketing Officer's decision on a registration
-- ---------------------------------------------------------------------------

ALTER TABLE registration_approvals
  ADD COLUMN IF NOT EXISTS decided_by_staff_id uuid;
ALTER TABLE registration_approvals
  ADD COLUMN IF NOT EXISTS decided_by_staff_role text;

ALTER TABLE registration_approvals
  DROP CONSTRAINT IF EXISTS registration_approvals_staff_role_check;
ALTER TABLE registration_approvals
  ADD CONSTRAINT registration_approvals_staff_role_check
  CHECK (decided_by_staff_role IS NULL
         OR decided_by_staff_role IN ('mo', 'asm', 'rsm'));

-- A Marketing Officer who turns an applicant down says why. The rejection
-- does not end the application — CRM sees it with the reason and decides.
ALTER TABLE registration_approvals
  DROP CONSTRAINT IF EXISTS registration_approvals_mo_reject_note;
ALTER TABLE registration_approvals
  ADD CONSTRAINT registration_approvals_mo_reject_note
  CHECK (approver <> 'marketing_officer'
         OR state <> 'rejected'
         OR btrim(coalesce(note, '')) <> '');


-- ---------------------------------------------------------------------------
-- CSE-2, CSE-3 · Complaints and branding requests an officer raised
-- ---------------------------------------------------------------------------

-- All three or none: a partner-raised request has no officer at all, and
-- the app shows the "Raised by" row only when there is one.
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS raised_by_staff_id uuid;
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS raised_by_staff_name text;
ALTER TABLE complaints ADD COLUMN IF NOT EXISTS raised_by_staff_role text;

ALTER TABLE complaints DROP CONSTRAINT IF EXISTS complaints_raised_by_staff;
ALTER TABLE complaints ADD CONSTRAINT complaints_raised_by_staff
  CHECK (
    (raised_by_staff_id IS NULL AND raised_by_staff_name IS NULL
       AND raised_by_staff_role IS NULL)
    OR (raised_by_staff_id IS NOT NULL AND raised_by_staff_name IS NOT NULL
       AND raised_by_staff_role IN ('mo', 'asm'))
  );

ALTER TABLE branding_requests ADD COLUMN IF NOT EXISTS raised_by_staff_id uuid;
ALTER TABLE branding_requests ADD COLUMN IF NOT EXISTS raised_by_staff_name text;
ALTER TABLE branding_requests ADD COLUMN IF NOT EXISTS raised_by_staff_role text;

ALTER TABLE branding_requests
  DROP CONSTRAINT IF EXISTS branding_requests_raised_by_staff;
ALTER TABLE branding_requests ADD CONSTRAINT branding_requests_raised_by_staff
  CHECK (
    (raised_by_staff_id IS NULL AND raised_by_staff_name IS NULL
       AND raised_by_staff_role IS NULL)
    OR (raised_by_staff_id IS NOT NULL AND raised_by_staff_name IS NOT NULL
       AND raised_by_staff_role IN ('mo', 'asm'))
  );


-- ---------------------------------------------------------------------------
-- CSE-4 · A closed shop
-- ---------------------------------------------------------------------------

-- Only the value. What a closed account may still do is not decided yet.
ALTER TABLE accounts DROP CONSTRAINT IF EXISTS accounts_status_check;
ALTER TABLE accounts ADD CONSTRAINT accounts_status_check
  CHECK (status IN ('active', 'closed'));


-- ---------------------------------------------------------------------------
-- CSE-5 · Officers in chat
-- ---------------------------------------------------------------------------

-- Who a `staff:<id>` chat address is. Written by Crown Solar Teams when an
-- officer starts a conversation; read here so a partner sees a name, not an
-- address.
CREATE TABLE IF NOT EXISTS chat_staff_parties (
  address       text PRIMARY KEY CHECK (address LIKE 'staff:%'),
  display_name  text NOT NULL,
  role          text NOT NULL CHECK (role IN ('mo', 'asm', 'rsm')),
  updated_at    timestamptz NOT NULL DEFAULT now()
);


-- ---------------------------------------------------------------------------
-- CSE-6 · Schemes and offers shown per market
-- ---------------------------------------------------------------------------

-- Super Admin decides which markets see each one. No rows means every
-- market, which is how everything behaved before this migration.
CREATE TABLE IF NOT EXISTS point_scheme_markets (
  scheme_id  uuid NOT NULL REFERENCES point_schemes (id) ON DELETE CASCADE,
  market_id  uuid NOT NULL REFERENCES markets (id) ON DELETE CASCADE,
  PRIMARY KEY (scheme_id, market_id)
);

CREATE TABLE IF NOT EXISTS item_scheme_markets (
  scheme_id  uuid NOT NULL REFERENCES item_schemes (id) ON DELETE CASCADE,
  market_id  uuid NOT NULL REFERENCES markets (id) ON DELETE CASCADE,
  PRIMARY KEY (scheme_id, market_id)
);

CREATE TABLE IF NOT EXISTS reward_program_markets (
  program_id uuid NOT NULL REFERENCES reward_programs (id) ON DELETE CASCADE,
  market_id  uuid NOT NULL REFERENCES markets (id) ON DELETE CASCADE,
  PRIMARY KEY (program_id, market_id)
);


-- ---------------------------------------------------------------------------
-- CSE-7 · A code not yet assigned to a product serial
-- ---------------------------------------------------------------------------

ALTER TABLE products DROP CONSTRAINT IF EXISTS products_state_check;
ALTER TABLE products ADD CONSTRAINT products_state_check
  CHECK (state IN ('active', 'blocked', 'unassigned'));

COMMIT;
