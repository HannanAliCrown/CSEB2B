-- 004 · Profile: language, theme, the app PIN, support numbers and About.
--
-- Idempotent, like 001–003.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;


-- ---------------------------------------------------------------------------
-- Per-partner settings
-- ---------------------------------------------------------------------------

-- First launch records the language against the device, before any account
-- exists. Once a partner signs in the choice belongs to them, so it is kept
-- here too and follows the account.
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS language_code text
  CHECK (language_code IS NULL OR language_code IN ('en', 'ur', 'ur-Latn'));
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS language_remembered boolean;

-- 'system' follows the phone, which is what a fresh install does.
ALTER TABLE accounts ADD COLUMN IF NOT EXISTS theme text
  CHECK (theme IS NULL OR theme IN ('system', 'light', 'dark'));


-- ---------------------------------------------------------------------------
-- The app PIN
-- ---------------------------------------------------------------------------

-- A four-digit lock on opening the app.
--
-- One row per account rather than per device, because an account is bound to
-- one handset anyway (account_device_bindings) — so per-account already means
-- per-handset, without a second thing to keep in step.
--
-- The PIN itself is NEVER stored. `pin_hash` holds a bcrypt digest written by
-- pgcrypto's crypt(); verification re-hashes the attempt with the stored salt
-- and compares. Note what this is and is not: four digits is ten thousand
-- combinations, so the hash slows an attacker with a database dump — it is a
-- convenience lock over the phone's own screen lock, not a secret worth much
-- on its own.
CREATE TABLE IF NOT EXISTS app_pins (
  account_id  uuid PRIMARY KEY REFERENCES accounts (id) ON DELETE CASCADE,

  pin_hash    text NOT NULL,

  -- Turning the PIN off keeps the row, so turning it back on does not force
  -- the partner to choose a new one.
  enabled     boolean NOT NULL DEFAULT true,

  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS app_pins_set_updated_at ON app_pins;
CREATE TRIGGER app_pins_set_updated_at
  BEFORE UPDATE ON app_pins
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ---------------------------------------------------------------------------
-- Support numbers
-- ---------------------------------------------------------------------------

-- The numbers Call Support offers. Tapping one opens the phone's dialler with
-- it filled in; the app never places the call itself.
CREATE TABLE IF NOT EXISTS support_contacts (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  label         text NOT NULL,
  phone_number  text NOT NULL,

  -- What this number is for, so a partner picks the right one.
  description   text,

  -- Null reaches every partner; otherwise one role only.
  audience      text NOT NULL DEFAULT 'all'
                  CHECK (audience IN ('all', 'installer', 'retailer',
                                      'wholesaler', 'distributor')),

  position      integer NOT NULL DEFAULT 0,
  active        boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS support_contacts_live
  ON support_contacts (audience, position)
  WHERE active;


-- ---------------------------------------------------------------------------
-- About the app
-- ---------------------------------------------------------------------------

-- Copy that About App shows, as key/value so it can change without a release.
--
-- Deliberately NOT the version number: the installed binary knows its own
-- version, and a row here could disagree with what is actually running.
CREATE TABLE IF NOT EXISTS app_info (
  key         text PRIMARY KEY,
  value       text NOT NULL,
  position    integer NOT NULL DEFAULT 0,
  updated_at  timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS app_info_set_updated_at ON app_info;
CREATE TRIGGER app_info_set_updated_at
  BEFORE UPDATE ON app_info
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMIT;
