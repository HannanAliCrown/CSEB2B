-- Seed for Inaam Baazar.
--
-- Everything here is configuration the Teams app owns: the wheel's segments
-- and odds, the schemes and their tiers, and the monthly programme. The app
-- reads it and never writes it.
--
-- Re-runnable.

BEGIN;


-- ---------------------------------------------------------------------------
-- Codes to scan
-- ---------------------------------------------------------------------------

-- A spin is earned by ten scans in a day, and the scan seed prints six boxes
-- in total. These exist so a day's scanning can actually reach a spin, and
-- so the schemes and the monthly programme — which join products by their
-- code prefix — have more than a handful to count.
INSERT INTO products (code, name, batch, plant, made_on, state, wins_prize)
SELECT v.code, v.name, v.batch, v.plant, v.made_on::date, 'active', v.wins
FROM (VALUES
  ('CS-INV-6302', 'Crown Solar 6kW Hybrid Inverter', 'INV-2026-09',
   'Lahore plant',  '2026-09-02', true),
  ('CS-INV-6303', 'Crown Solar 6kW Hybrid Inverter', 'INV-2026-09',
   'Lahore plant',  '2026-09-03', false),
  ('CS-INV-8842', 'Crown Solar 8kW Hybrid Inverter', 'INV-2026-08',
   'Lahore plant',  '2026-08-15', true),
  ('CS-INV-8843', 'Crown Solar 8kW Hybrid Inverter', 'INV-2026-08',
   'Karachi plant', '2026-08-16', false),
  ('CS-INV-8844', 'Crown Solar 8kW Hybrid Inverter', 'INV-2026-08',
   'Karachi plant', '2026-08-17', true),
  ('CS-PNL-5541', 'Crown Solar 540W Panel',          'PNL-2026-09',
   'Lahore plant',  '2026-09-09', false),
  ('CS-PNL-5542', 'Crown Solar 540W Panel',          'PNL-2026-09',
   'Lahore plant',  '2026-09-10', true),
  ('CS-PNL-2208', 'Crown Solar 560W Panel',          'PNL-2026-07',
   'Karachi plant', '2026-07-23', false),
  ('CS-PNL-2209', 'Crown Solar 560W Panel',          'PNL-2026-07',
   'Karachi plant', '2026-07-24', true),
  ('CS-BAT-7789', 'Crown Solar 200Ah Battery',       'BAT-2026-08',
   'Lahore plant',  '2026-08-05', false),
  ('CS-BAT-7790', 'Crown Solar 200Ah Battery',       'BAT-2026-08',
   'Lahore plant',  '2026-08-06', true),
  ('CS-INV-6304', 'Crown Solar 6kW Hybrid Inverter', 'INV-2026-09',
   'Karachi plant', '2026-09-04', true)
) AS v (code, name, batch, plant, made_on, wins)
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.code = v.code);


-- ---------------------------------------------------------------------------
-- The wheel
-- ---------------------------------------------------------------------------

INSERT INTO spin_configs (version, scans_per_spin, active)
VALUES (1, 10, true)
ON CONFLICT (version) DO NOTHING;


-- Eight segments, as the design draws them. The weights are what make the
-- smallest prize the usual outcome: Rs. 50 lands 93.6 times in a hundred,
-- Rs. 50,000 four times in a thousand.
INSERT INTO spin_prizes (config_id, amount_paisa, weight, position)
SELECT c.id, v.amount_paisa, v.weight, v.position
FROM (VALUES
  (   5000, 156, 0),
  (   5000, 156, 1),
  (   5000, 156, 2),
  (  50000,  60, 3),
  (   5000, 156, 4),
  (   5000, 156, 5),
  (   5000, 156, 6),
  (5000000,   4, 7)
) AS v (amount_paisa, weight, position)
CROSS JOIN (SELECT id FROM spin_configs WHERE version = 1) AS c
WHERE NOT EXISTS (
  SELECT 1 FROM spin_prizes p
   WHERE p.config_id = c.id AND p.position = v.position
);


-- ---------------------------------------------------------------------------
-- Item Schemes
-- ---------------------------------------------------------------------------

INSERT INTO item_schemes (name, measure, starts_on, ends_on)
VALUES
  ('Inverter Scan Scheme', 'scans',  '2026-07-01', '2026-12-31'),
  ('Panel Purchase Scheme', 'amount', '2026-07-01', '2026-12-31')
ON CONFLICT (name, starts_on) DO NOTHING;


-- Which products count. The scan scheme is on inverters; the amount scheme
-- on panels.
INSERT INTO item_scheme_products (scheme_id, product_id)
SELECT s.id, p.id
FROM item_schemes s
JOIN products p
  ON (s.name = 'Inverter Scan Scheme'  AND p.code LIKE 'CS-INV-%')
  OR (s.name = 'Panel Purchase Scheme' AND p.code LIKE 'CS-PNL-%')
WHERE NOT EXISTS (
  SELECT 1 FROM item_scheme_products x
   WHERE x.scheme_id = s.id AND x.product_id = p.id
);


INSERT INTO item_scheme_tiers (scheme_id, name, threshold, reward_paisa,
                               position)
SELECT s.id, v.name, v.threshold, v.reward_paisa, v.position
FROM (VALUES
  ('Inverter Scan Scheme',  'Silver',   150,  1400000, 0),
  ('Inverter Scan Scheme',  'Gold',     300,  2500000, 1),
  ('Inverter Scan Scheme',  'Platinum', 500,  4000000, 2),
  ('Panel Purchase Scheme', 'Silver',   120000000, 1400000, 0),
  ('Panel Purchase Scheme', 'Gold',     250000000, 2500000, 1),
  ('Panel Purchase Scheme', 'Platinum', 400000000, 4000000, 2)
) AS v (scheme, name, threshold, reward_paisa, position)
JOIN item_schemes s ON s.name = v.scheme
WHERE NOT EXISTS (
  SELECT 1 FROM item_scheme_tiers t
   WHERE t.scheme_id = s.id AND t.name = v.name
);


-- What SAP has posted against the amount-measured scheme, so board 09 · B2
-- has a figure. Scans the app counts itself; rupees it does not.
--
-- PKR 1,310,400 is past Silver and short of Gold, so the claim — and the
-- one-claim-only choice it forces — can be seen without waiting on SAP.
INSERT INTO item_scheme_progress (scheme_id, account_id, amount_paisa)
SELECT s.id, a.id, 131040000
FROM item_schemes s
CROSS JOIN (
  SELECT id FROM accounts WHERE mobile_number = '3004821190'
) AS a
WHERE s.name = 'Panel Purchase Scheme'
  AND NOT EXISTS (
    SELECT 1 FROM item_scheme_progress p
     WHERE p.scheme_id = s.id AND p.account_id = a.id
  );


-- ---------------------------------------------------------------------------
-- Reward Program
-- ---------------------------------------------------------------------------

-- Last month's programme and this one. The background job creates each new
-- month; these two stand in for what it has already done.
INSERT INTO reward_programs (label, starts_on, ends_on)
VALUES
  ('August 2026',    '2026-08-01', '2026-08-31'),
  ('September 2026', '2026-09-01', '2026-09-30')
ON CONFLICT (starts_on) DO NOTHING;


INSERT INTO reward_program_products (program_id, product_id)
SELECT r.id, p.id
FROM reward_programs r
JOIN products p ON p.code LIKE 'CS-INV-%'
WHERE NOT EXISTS (
  SELECT 1 FROM reward_program_products x
   WHERE x.program_id = r.id AND x.product_id = p.id
);


INSERT INTO reward_program_tiers (program_id, name, scan_target,
                                  bonus_percent, position)
SELECT r.id, v.name, v.scan_target, v.bonus_percent, v.position
FROM (VALUES
  ('SILVER',   10,  25, 0),
  ('GOLD',     25,  50, 1),
  ('PLATINUM', 40, 100, 2)
) AS v (name, scan_target, bonus_percent, position)
CROSS JOIN reward_programs r
WHERE NOT EXISTS (
  SELECT 1 FROM reward_program_tiers t
   WHERE t.program_id = r.id AND t.name = v.name
);


-- What the month-end job decided for August: Silver, so a +25% bonus runs
-- through September. This is the line the hub shows at the top.
INSERT INTO reward_program_awards (program_id, account_id, tier_id,
                                   bonus_percent, applies_from, applies_until)
SELECT august.id, a.id, t.id, t.bonus_percent, '2026-09-01', '2026-09-30'
FROM (
  SELECT id FROM reward_programs WHERE starts_on = '2026-08-01'
) AS august
JOIN reward_program_tiers t
  ON t.program_id = august.id AND t.name = 'SILVER'
CROSS JOIN (
  SELECT id FROM accounts WHERE mobile_number = '3004821190'
) AS a
WHERE NOT EXISTS (
  SELECT 1 FROM reward_program_awards w
   WHERE w.program_id = august.id AND w.account_id = a.id
);

COMMIT;
