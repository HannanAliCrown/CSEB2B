-- 001 · First app launch and the registration wizard.
--
-- Applied on top of the login/device-binding schema that already exists in
-- this database (prototype_server/lib/db/schema.sql), which owns `accounts`,
-- `devices`, `account_device_bindings`, `otp_challenges` and
-- `rebinding_authorizations`. This migration extends two of those and adds
-- the registration domain beside them.
--
-- Idempotent: every statement is IF NOT EXISTS or guarded, so it can be run
-- against a database that has had part of it applied already.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ---------------------------------------------------------------------------
-- Reference data
-- ---------------------------------------------------------------------------

-- The markets a partner can be placed in. Reference data, not user input:
-- the details step offers this list and nothing else.
CREATE TABLE IF NOT EXISTS markets (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text UNIQUE NOT NULL,
  city        text NOT NULL,
  active      boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS markets_active_name ON markets (name) WHERE active;


-- ---------------------------------------------------------------------------
-- Devices — what first launch establishes
-- ---------------------------------------------------------------------------

-- First launch settles three things about the phone before anyone signs in:
-- the language, the two permission answers, and where the phone was. They
-- belong to the device, not to an account — there is no account yet, and a
-- reinstall is a new first launch.
--
-- The device's own copy of these (shared_preferences) stays authoritative for
-- deciding whether to show first launch again; these columns are the record
-- Crown Solar can see.
ALTER TABLE devices ADD COLUMN IF NOT EXISTS app_version text;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS language_code text
  CHECK (language_code IS NULL OR language_code IN ('en', 'ur', 'ur-Latn'));
ALTER TABLE devices ADD COLUMN IF NOT EXISTS language_remembered boolean;
ALTER TABLE devices ADD COLUMN IF NOT EXISTS notification_permission text
  CHECK (notification_permission IS NULL
         OR notification_permission IN ('granted', 'denied', 'permanently_denied', 'restricted'));
ALTER TABLE devices ADD COLUMN IF NOT EXISTS location_permission text
  CHECK (location_permission IS NULL
         OR location_permission IN ('granted', 'denied', 'permanently_denied', 'restricted'));

-- Where the phone was at first launch. Never the shop's pin — the shop is
-- placed separately in the wizard, and the design allows them to differ.
ALTER TABLE devices ADD COLUMN IF NOT EXISTS launch_latitude numeric(9, 6);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS launch_longitude numeric(9, 6);
ALTER TABLE devices ADD COLUMN IF NOT EXISTS launch_located_at timestamptz;

ALTER TABLE devices ADD COLUMN IF NOT EXISTS first_launch_completed_at timestamptz;


-- ---------------------------------------------------------------------------
-- Accounts — what a registration becomes
-- ---------------------------------------------------------------------------

-- `accounts` already carries id, mobile_number, user_type, status. The
-- registration wizard needs the rest of what it captured, and the lookups it
-- performs (is this number taken, who holds this CNIC, who is this buying
-- source) read these columns.
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS display_name text;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS contact_name text;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS business_address text;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS alternate_number text;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS market_id uuid REFERENCES markets (id);
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS cnic_number text;
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS shop_latitude numeric(9, 6);
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS shop_longitude numeric(9, 6);

-- One identity registers once. Enforced here rather than only in code, so a
-- duplicate cannot be created by a second path later.
CREATE UNIQUE INDEX IF NOT EXISTS accounts_one_per_cnic
  ON accounts (cnic_number)
  WHERE cnic_number IS NOT NULL;

-- `mobile_number` is stored as the ten national digits with no country code,
-- leading zero or spacing, so 0300…, 300… and +92 300… are one subscriber.
-- The UNIQUE constraint on it is inherited from the base schema.


-- ---------------------------------------------------------------------------
-- Registration applications
-- ---------------------------------------------------------------------------

-- A submitted application. The half-finished wizard draft is NOT here: it is
-- unsubmitted state on one phone, kept in shared_preferences so a partner can
-- close the app mid-wizard and resume. A row appears the moment they submit.
CREATE TABLE IF NOT EXISTS registration_applications (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- What the applicant is shown and quotes back to CRM, e.g. 'CSE-4821190'.
  reference         text UNIQUE NOT NULL,

  device_id         uuid REFERENCES devices (id),

  -- Ten national digits, matching accounts.mobile_number.
  mobile_number     text NOT NULL,
  country_code      text NOT NULL DEFAULT '+92',
  mobile_verified   boolean NOT NULL DEFAULT false,

  -- Only these two are self-selected. Wholesaler and Distributor are
  -- assigned by CRM and can never arrive through this table.
  role              text NOT NULL CHECK (role IN ('installer', 'retailer')),

  full_name         text NOT NULL,
  alternate_number  text,
  business_name     text NOT NULL,
  business_address  text NOT NULL,
  market_id         uuid REFERENCES markets (id),

  shop_latitude     numeric(9, 6),
  shop_longitude    numeric(9, 6),

  cnic_number       text NOT NULL,

  status            text NOT NULL DEFAULT 'submitted'
                      CHECK (status IN ('submitted', 'approved', 'rejected', 'withdrawn')),

  -- Set when all three approvals land and the account is opened.
  account_id        uuid REFERENCES accounts (id),

  submitted_at      timestamptz NOT NULL DEFAULT now(),
  decided_at        timestamptz,
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

-- One application at a time per number. A rejected or withdrawn one does not
-- block a fresh attempt.
CREATE UNIQUE INDEX IF NOT EXISTS registration_applications_one_open_per_number
  ON registration_applications (mobile_number)
  WHERE status = 'submitted';

CREATE INDEX IF NOT EXISTS registration_applications_by_cnic
  ON registration_applications (cnic_number);


-- The buying sources the applicant named. The first is the one asked to
-- verify the application; the rest are recorded with it. Order matters, so it
-- is stored rather than inferred.
CREATE TABLE IF NOT EXISTS registration_buying_sources (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  uuid NOT NULL REFERENCES registration_applications (id) ON DELETE CASCADE,
  position        integer NOT NULL CHECK (position >= 0),

  mobile_number   text NOT NULL,

  -- The account the number resolved to at the time of submission, if any.
  -- Kept alongside the id so the application still reads correctly if that
  -- account is later renamed.
  matched_account_id uuid REFERENCES accounts (id),
  matched_name    text,
  matched_role    text,
  matched_market  text,

  created_at      timestamptz NOT NULL DEFAULT now(),

  UNIQUE (application_id, position)
);


-- Everything captured with a camera or typed as a link. One row per item, so
-- the wizard's three video slots and three shop-image slots do not need six
-- columns on the application.
--
-- `storage_path` is where the file is today: a path on the phone. When file
-- upload arrives it becomes a remote key, and nothing else here changes.
CREATE TABLE IF NOT EXISTS registration_media (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  uuid NOT NULL REFERENCES registration_applications (id) ON DELETE CASCADE,

  kind            text NOT NULL CHECK (kind IN (
                    'video_link',     -- installer: a link they typed
                    'shop_image',     -- retailer: a photo of the shop
                    'cnic_front',
                    'cnic_back',
                    'selfie'
                  )),

  -- The design's slot name for the multi-slot kinds: 'Shop Board',
  -- 'Shop Stock', 'Shop Image', or '1'/'2'/'3' for video links.
  slot            text,

  -- Exactly one of these is set: a link for video_link, a path for the rest.
  link_url        text,
  storage_path    text,

  created_at      timestamptz NOT NULL DEFAULT now(),

  UNIQUE (application_id, kind, slot),
  CHECK (
    (kind = 'video_link' AND link_url IS NOT NULL AND storage_path IS NULL)
    OR (kind <> 'video_link' AND storage_path IS NOT NULL AND link_url IS NULL)
  )
);


-- The three approvals every application waits on. Three rows are written at
-- submission, all outstanding — nothing is approved on arrival.
CREATE TABLE IF NOT EXISTS registration_approvals (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  uuid NOT NULL REFERENCES registration_applications (id) ON DELETE CASCADE,

  approver        text NOT NULL CHECK (approver IN ('buying_source', 'marketing_officer', 'crm')),
  state           text NOT NULL DEFAULT 'outstanding'
                    CHECK (state IN ('outstanding', 'approved', 'rejected')),

  -- Who acted, when they are a Crown Solar partner rather than staff.
  decided_by_account_id uuid REFERENCES accounts (id),
  decided_by_name text,
  decided_at      timestamptz,
  note            text,

  created_at      timestamptz NOT NULL DEFAULT now(),

  UNIQUE (application_id, approver)
);

CREATE INDEX IF NOT EXISTS registration_approvals_outstanding
  ON registration_approvals (application_id)
  WHERE state = 'outstanding';


-- ---------------------------------------------------------------------------
-- Registration OTP
-- ---------------------------------------------------------------------------

-- The base schema's otp_challenges requires an account and a device, because
-- it was written for signing in. A registration OTP is issued before either
-- exists, so the account becomes optional and the number is carried directly.
ALTER TABLE otp_challenges ALTER COLUMN account_id DROP NOT NULL;
ALTER TABLE otp_challenges ALTER COLUMN device_id DROP NOT NULL;
ALTER TABLE otp_challenges ADD COLUMN IF NOT EXISTS mobile_number text;

-- Widen the context check to admit the registration case.
ALTER TABLE otp_challenges DROP CONSTRAINT IF EXISTS otp_challenges_context_check;
ALTER TABLE otp_challenges ADD CONSTRAINT otp_challenges_context_check
  CHECK (context IN ('registration', 'new_device_login', 'registration_wizard'));

-- A challenge always identifies a subscriber, one way or the other.
ALTER TABLE otp_challenges DROP CONSTRAINT IF EXISTS otp_challenges_has_subject;
ALTER TABLE otp_challenges ADD CONSTRAINT otp_challenges_has_subject
  CHECK (account_id IS NOT NULL OR mobile_number IS NOT NULL);

CREATE INDEX IF NOT EXISTS otp_challenges_open_by_number
  ON otp_challenges (mobile_number, created_at DESC)
  WHERE verified = false;


-- ---------------------------------------------------------------------------
-- updated_at upkeep
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS registration_applications_set_updated_at
  ON registration_applications;
CREATE TRIGGER registration_applications_set_updated_at
  BEFORE UPDATE ON registration_applications
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS devices_set_updated_at ON devices;
CREATE TRIGGER devices_set_updated_at
  BEFORE UPDATE ON devices
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMIT;
