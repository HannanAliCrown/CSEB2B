-- Baseline seed accounts for specs/001-login-auth-device-binding/quickstart.md.
-- One account per user type, no device binding yet.
-- Apply after lib/db/schema.sql, e.g.:
--   psql -h localhost -U <local-dev-user> -d cse_b2b_prototype -f lib/db/schema.sql
--   psql -h localhost -U <local-dev-user> -d cse_b2b_prototype -f seed/seed.sql

INSERT INTO accounts (mobile_number, user_type) VALUES
  ('+923000000001', 'installer'),
  ('+923000000002', 'retailer'),
  ('+923000000003', 'wholesaler'),
  ('+923000000004', 'distributor')
ON CONFLICT (mobile_number) DO NOTHING;
