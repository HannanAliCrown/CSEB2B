-- Seed data for local development.
--
-- These are the same six partners and five markets the app has been
-- demonstrating with (lib/core/mock/partner_directory.dart), so the DB-backed
-- app opens on the state everyone already recognises. Re-runnable: every
-- insert is ON CONFLICT DO NOTHING.
--
-- Not fixtures for tests. Tests build their own rows.

BEGIN;

INSERT INTO markets (name, city) VALUES
  ('Ravi Road, Lahore',    'Lahore'),
  ('Hall Road, Lahore',    'Lahore'),
  ('Badami Bagh, Lahore',  'Lahore'),
  ('Shahdara, Lahore',     'Lahore'),
  ('Model Town, Lahore',   'Lahore')
ON CONFLICT (name) DO NOTHING;


-- Mobile numbers are the ten national digits: no +92, no leading zero.
INSERT INTO accounts (
  mobile_number, user_type, status,
  display_name, contact_name, cnic_number, market_id
)
SELECT v.mobile_number, v.user_type, 'active',
       v.display_name, v.contact_name, v.cnic_number, m.id
FROM (VALUES
  ('3217745002', 'retailer',    'Bilal Traders',           'Bilal Ahmed',           '35202-1122334-5', 'Hall Road, Lahore'),
  ('3004821190', 'installer',   'Adnan Solar Works',       'Muhammad Adnan Shahid', '35202-7719480-3', 'Ravi Road, Lahore'),
  ('3007781204', 'retailer',    'Al-Noor Electric Store',  'Noor Hassan',           '35202-4410932-7', 'Ravi Road, Lahore'),
  ('3014429911', 'wholesaler',  'Hamza Solar House',       'Hamza Iqbal',           '35202-9087651-1', 'Badami Bagh, Lahore'),
  ('3335560071', 'installer',   'Shahdara Solar Services', 'Usman Tariq',           '35202-3312098-4', 'Shahdara, Lahore'),
  ('3028890143', 'distributor', 'Ravi Distribution Co.',   'Kamran Sheikh',         '35202-7765431-9', 'Ravi Road, Lahore')
) AS v (mobile_number, user_type, display_name, contact_name, cnic_number, market_name)
JOIN markets m ON m.name = v.market_name
ON CONFLICT (mobile_number) DO NOTHING;

COMMIT;
