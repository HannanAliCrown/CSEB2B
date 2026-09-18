-- Schema for the Login, Authentication, and Device Binding prototype.
-- Prototype-only persistence (FR-045) — see specs/001-login-auth-device-binding/data-model.md.
-- Owned exclusively by prototype_server; the Flutter app never issues SQL.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  mobile_number text UNIQUE NOT NULL,
  user_type text NOT NULL
    CHECK (user_type IN ('installer', 'retailer', 'wholesaler', 'distributor')),
  status text NOT NULL DEFAULT 'active'
    CHECK (status = 'active'),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  installation_uuid text UNIQUE NOT NULL,
  platform text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS account_device_bindings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES accounts (id),
  device_id uuid NOT NULL REFERENCES devices (id),
  status text NOT NULL
    CHECK (status IN ('active', 'revoked')),
  created_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  context text NOT NULL
    CHECK (context IN ('initial_registration', 'rebinding'))
);

-- Structural enforcement of FR-009/FR-038 (at most one Active device per
-- account) and the device-conflict invariant (at most one account may have
-- a device Active). See plan.md "Prototype Business-Rule Enforcement".
CREATE UNIQUE INDEX IF NOT EXISTS account_device_bindings_one_active_per_account
  ON account_device_bindings (account_id)
  WHERE status = 'active';

CREATE UNIQUE INDEX IF NOT EXISTS account_device_bindings_one_active_per_device
  ON account_device_bindings (device_id)
  WHERE status = 'active';

CREATE TABLE IF NOT EXISTS otp_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES accounts (id),
  device_id uuid NOT NULL REFERENCES devices (id),
  context text NOT NULL
    CHECK (context IN ('registration', 'new_device_login')),
  code text NOT NULL,
  verified boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  verified_at timestamptz
  -- Deliberately no expires_at / attempt-count / lockout column: OTP expiry
  -- duration is an open business-rule question (spec.md Open Questions),
  -- and retry/lockout limits are explicitly out of scope. A failed
  -- verification attempt is represented solely by `verified` remaining
  -- false; no separate per-attempt audit row is created (FR-017).
);

CREATE TABLE IF NOT EXISTS rebinding_authorizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES accounts (id),
  device_id uuid NOT NULL REFERENCES devices (id),
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'authorized', 'not_authorized')),
  requested_at timestamptz NOT NULL DEFAULT now(),
  resolved_at timestamptz,
  source text NOT NULL DEFAULT 'prototype_simulated_crm'
);
