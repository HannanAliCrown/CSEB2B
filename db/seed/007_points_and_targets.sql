-- Seed for Points, schemes and targets.
--
-- Every figure below is a movement, never a balance or a score: the hub, the
-- ledger and each target are all derived from `point_entries`, so seeding a
-- balance directly would be seeding a lie.
--
-- The four demo partners are deliberately in different states, so each board
-- on 06 is reachable with real data:
--
--   Al-Noor Electric Store  (retailer)    signed scheme, mid-year  → A1, B1
--   Hamza Solar House       (wholesaler)  annual met, extras set   → B2, B3
--   Bilal Traders           (retailer)    no scheme                → B4
--   Ravi Distribution Co.   (distributor) signed scheme
--
-- Re-runnable.

BEGIN;


-- ---------------------------------------------------------------------------
-- Who may send points to whom
-- ---------------------------------------------------------------------------

-- The three trading roles may exchange points in any direction. Installers
-- appear nowhere: they hold no points, and a pair with no row is refused, so
-- leaving them out is the whole rule.
INSERT INTO point_transfer_rules (from_role, to_role)
SELECT f.role, t.role
FROM (VALUES ('retailer'), ('wholesaler'), ('distributor')) AS f (role)
CROSS JOIN (VALUES ('retailer'), ('wholesaler'), ('distributor')) AS t (role)
ON CONFLICT (from_role, to_role) DO NOTHING;


-- ---------------------------------------------------------------------------
-- Schemes, signed on paper
-- ---------------------------------------------------------------------------

INSERT INTO point_schemes (name, year, annual_target_points, annual_prize,
                           grand_prize)
VALUES
  ('Retailer Scheme',    2026, 1000000, 'Umrah package for two', NULL),
  ('Wholesaler Scheme',  2026, 1000000, 'Umrah package for two',
   'Foreign tour for two, for hitting every four-month target'),
  ('Distributor Scheme', 2026, 5000000, 'Hajj package for two',  NULL)
ON CONFLICT (name, year) DO NOTHING;


INSERT INTO scheme_periods (scheme_id, label, starts_on, ends_on,
                            target_points, prize, position)
SELECT s.id, v.label, v.starts_on::date, v.ends_on::date, v.target_points,
       v.prize, v.position
FROM (VALUES
  ('Retailer Scheme',    'Jan — Apr 2026', '2026-01-01', '2026-04-30',
    280000, '32-inch LED television',    0),
  ('Retailer Scheme',    'May — Aug 2026', '2026-05-01', '2026-08-31',
    320000, 'Haier 1-ton inverter AC',   1),
  ('Retailer Scheme',    'Sep — Dec 2026', '2026-09-01', '2026-12-31',
    400000, 'Honda 125 motorcycle',      2),
  ('Wholesaler Scheme',  'Jan — Apr 2026', '2026-01-01', '2026-04-30',
    280000, '32-inch LED television',    0),
  ('Wholesaler Scheme',  'May — Aug 2026', '2026-05-01', '2026-08-31',
    320000, 'Honda 125 motorcycle',      1),
  ('Wholesaler Scheme',  'Sep — Dec 2026', '2026-09-01', '2026-12-31',
    400000, 'Gold coin, 2 tola',         2),
  ('Distributor Scheme', 'Jan — Apr 2026', '2026-01-01', '2026-04-30',
    1200000, 'Toyota Hilux service package', 0),
  ('Distributor Scheme', 'May — Aug 2026', '2026-05-01', '2026-08-31',
    1400000, 'Foreign tour for two',         1),
  ('Distributor Scheme', 'Sep — Dec 2026', '2026-09-01', '2026-12-31',
    1600000, 'Gold coin, 5 tola',            2)
) AS v (scheme, label, starts_on, ends_on, target_points, prize, position)
JOIN point_schemes s ON s.name = v.scheme AND s.year = 2026
WHERE NOT EXISTS (
  SELECT 1 FROM scheme_periods p
   WHERE p.scheme_id = s.id AND p.label = v.label
);


-- Bilal Traders is deliberately absent: a partner with no scheme is a state
-- the app has to show, not an oversight.
INSERT INTO account_schemes (account_id, scheme_id, signed_on)
SELECT a.id, s.id, v.signed_on::date
FROM (VALUES
  ('3007781204', 'Retailer Scheme',    '2025-12-18'),
  ('3014429911', 'Wholesaler Scheme',  '2025-12-11'),
  ('3028890143', 'Distributor Scheme', '2025-12-04')
) AS v (mobile_number, scheme, signed_on)
JOIN accounts a ON a.mobile_number = v.mobile_number
JOIN point_schemes s ON s.name = v.scheme AND s.year = 2026
ON CONFLICT (account_id) DO NOTHING;


-- ---------------------------------------------------------------------------
-- What SAP has posted
-- ---------------------------------------------------------------------------

-- One percent of each purchase, and the reversal when a purchase is undone.
INSERT INTO point_entries (account_id, direction, type, amount, sap_document,
                           posted_at)
SELECT a.id, v.direction, v.type, v.amount, v.sap_document,
       v.posted_on::timestamptz
FROM (VALUES
  -- Al-Noor: two closed periods and the one now running.
  ('3007781204', 'credit', 'purchase_accrual', 312600, 'INV-71204',
   '2026-02-15 10:20'),
  ('3007781204', 'credit', 'purchase_accrual', 191900, 'INV-74418',
   '2026-06-20 11:05'),
  ('3007781204', 'credit', 'purchase_accrual', 123500, 'INV-76540',
   '2026-09-01 09:30'),
  ('3007781204', 'debit',  'reversal',           4300, 'INV-76980',
   '2026-09-05 14:12'),
  ('3007781204', 'credit', 'purchase_accrual',  18400, 'INV-77213',
   '2026-09-21 06:02'),

  -- Hamza: past the year total already, in August.
  ('3014429911', 'credit', 'purchase_accrual', 470000, 'INV-70880',
   '2026-03-10 09:15'),
  ('3014429911', 'credit', 'purchase_accrual', 332300, 'INV-75012',
   '2026-07-18 15:40'),

  -- Ravi: a distributor's volume.
  ('3028890143', 'credit', 'purchase_accrual', 1850000, 'INV-72330',
   '2026-04-12 08:50')
) AS v (mobile_number, direction, type, amount, sap_document, posted_on)
JOIN accounts a ON a.mobile_number = v.mobile_number
WHERE NOT EXISTS (
  SELECT 1 FROM point_entries e
   WHERE e.account_id = a.id AND e.sap_document = v.sap_document
);


-- A correction Crown Solar made by hand. The reason travels with it: a
-- number with no reason is not an answer.
INSERT INTO point_entries (account_id, direction, type, amount, note,
                           posted_at)
SELECT a.id, 'credit', 'crm_adjustment', 9000,
       'Wrong recipient corrected', '2026-09-08 11:45'::timestamptz
FROM accounts a
WHERE a.mobile_number = '3007781204'
  AND NOT EXISTS (
    SELECT 1 FROM point_entries e
     WHERE e.account_id = a.id AND e.type = 'crm_adjustment'
  );


-- ---------------------------------------------------------------------------
-- Transfers between partners
-- ---------------------------------------------------------------------------

-- Both legs of every transfer, exactly as the app writes them: the sender's
-- debit and the receiver's credit share one reference, so a partner and the
-- person they paid are reading the same event.
WITH transfers AS (
  SELECT
    v.reference,
    sender.id   AS from_id,
    receiver.id AS to_id,
    v.amount,
    v.sent_on::timestamptz AS sent_at
  FROM (VALUES
    ('PT-2026-77002', '3007781204', '3028890143', 180500, '2026-05-10 10:00'),
    ('PT-2026-77118', '3007781204', '3014429911', 200000, '2026-07-02 12:30'),
    ('PT-2026-77260', '3007781204', '3217745002',   6000, '2026-08-14 16:20'),
    ('PT-2026-77304', '3007781204', '3028890143',  75000, '2026-08-21 09:10'),
    ('PT-2026-77351', '3007781204', '3014429911',  40000, '2026-09-02 10:05'),
    ('PT-2026-77366', '3014429911', '3007781204',  19800, '2026-09-03 13:25'),
    ('PT-2026-77389', '3014429911', '3007781204',  25000, '2026-09-07 17:40'),
    ('PT-2026-77405', '3007781204', '3217745002',  12000, '2026-09-20 15:14')
  ) AS v (reference, from_number, to_number, amount, sent_on)
  JOIN accounts sender   ON sender.mobile_number   = v.from_number
  JOIN accounts receiver ON receiver.mobile_number = v.to_number
  WHERE NOT EXISTS (
    SELECT 1 FROM point_entries e WHERE e.reference = v.reference
  )
)
INSERT INTO point_entries (account_id, reference, direction, type, amount,
                           counterparty_account_id, posted_at)
SELECT leg.account_id, t.reference, leg.direction, leg.type, t.amount,
       leg.counterparty_id, t.sent_at
FROM transfers t
CROSS JOIN LATERAL (VALUES
  (t.from_id, 'debit',  'transfer_out', t.to_id),
  (t.to_id,   'credit', 'transfer_in',  t.from_id)
) AS leg (account_id, direction, type, counterparty_id);


-- ---------------------------------------------------------------------------
-- A target Crown Solar set by hand
-- ---------------------------------------------------------------------------

-- Hamza reached the year total in August, so the team set fresh targets after
-- the conversation. These run alongside the signed scheme.
INSERT INTO account_extra_targets (account_id, label, starts_on, ends_on,
                                   target_points, prize, assigned_by)
SELECT a.id, v.label, v.starts_on::date, v.ends_on::date, v.target_points,
       v.prize, 'Crown Solar CRM'
FROM (VALUES
  ('Extra · Jul — Aug 2026',   '2026-07-01', '2026-08-31', 150000,
   'Gold coin, 1 tola'),
  ('Extra · Sep — Dec 2026',   '2026-09-01', '2026-12-31', 300000,
   '32-inch LED television'),
  ('Stretch · Jul — Dec 2026', '2026-07-01', '2026-12-31', 500000,
   'Foreign tour for two')
) AS v (label, starts_on, ends_on, target_points, prize)
CROSS JOIN (
  SELECT id FROM accounts WHERE mobile_number = '3014429911'
) AS a
WHERE NOT EXISTS (
  SELECT 1 FROM account_extra_targets t
   WHERE t.account_id = a.id AND t.label = v.label
);

COMMIT;
