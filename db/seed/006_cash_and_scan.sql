-- Seed for Send Cash, the ledger, and Scan.
--
-- The products are the sample codes the scan screen already lists, so every
-- verdict can still be demonstrated without a printed box. The prize bands
-- are Crown Solar's, not the app's.
--
-- Re-runnable.

BEGIN;


-- ---------------------------------------------------------------------------
-- What a winning code pays
-- ---------------------------------------------------------------------------

-- No row for wholesaler or distributor: they scan to check a product, never
-- to win, and leaving them out is what says so.
INSERT INTO scan_prize_rules (role, amount_paisa)
VALUES
  ('installer', 50000),
  ('retailer',  30000)
ON CONFLICT (role) DO NOTHING;


-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------

INSERT INTO products (code, name, batch, plant, made_on, state, wins_prize)
SELECT v.code, v.name, v.batch, v.plant, v.made_on::date, v.state, v.wins_prize
FROM (VALUES
  ('CS-INV-8841', 'Crown Solar 8kW Hybrid Inverter', 'INV-2026-08',
   'Lahore plant', '2026-08-14', 'active',  true),
  ('CS-PNL-2207', 'Crown Solar 560W Panel',          'PNL-2026-07',
   'Lahore plant', '2026-07-22', 'active',  false),
  ('CS-INV-0001', 'Crown Solar 8kW Hybrid Inverter', 'INV-2026-05',
   'Lahore plant', '2026-05-30', 'active',  true),
  ('CS-BAT-7788', 'Crown Solar 200Ah Battery',       'BAT-2026-03',
   'Lahore plant', '2026-03-11', 'blocked', false),
  ('CS-INV-6301', 'Crown Solar 6kW Hybrid Inverter', 'INV-2026-09',
   'Lahore plant', '2026-09-02', 'active',  true),
  ('CS-PNL-5540', 'Crown Solar 540W Panel',          'PNL-2026-09',
   'Lahore plant', '2026-09-09', 'active',  true)
) AS v (code, name, batch, plant, made_on, state, wins_prize)
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.code = v.code);


-- CS-INV-0001 is already spent in both claimable roles, so the
-- already-scanned result can be seen without scanning twice. The accounts
-- are whichever partner holds each role — the point is that the claim is
-- taken, not who by.
INSERT INTO scan_claims (product_id, account_id, role, claimed_at)
SELECT p.id, a.id, a.user_type, now() - v.ago
FROM products p
CROSS JOIN (VALUES
  ('installer', interval '2 days'),
  ('retailer',  interval '4 days')
) AS v (role, ago)
JOIN LATERAL (
  SELECT id, user_type FROM accounts
   WHERE user_type = v.role AND mobile_number <> '3004821190'
   ORDER BY created_at LIMIT 1
) AS a ON true
WHERE p.code = 'CS-INV-0001'
  AND NOT EXISTS (
    SELECT 1 FROM scan_claims c
     WHERE c.product_id = p.id AND c.role = v.role
  );

COMMIT;


-- ---------------------------------------------------------------------------
-- A registration waiting on its buying source
-- ---------------------------------------------------------------------------

BEGIN;

-- So New Profile is not empty on first sight. This stands in for what the
-- registration wizard writes: an applicant who named Al-Noor Electric Store
-- as where they buy, with all three approvals still outstanding.
WITH applicant AS (
  INSERT INTO registration_applications (
    reference, mobile_number, role, full_name, business_name,
    business_address, cnic_number, market_id, submitted_at
  )
  SELECT 'CSE-5560071', '3339912004', 'installer', 'Kamran Abbas',
         'Kamran Solar Services', 'Shop 14, Bilal Market, Shahdara',
         '3520212345671', m.id, now() - interval '19 hours'
    FROM markets m
   WHERE m.name = 'Ravi Road, Lahore'
     AND NOT EXISTS (
       SELECT 1 FROM registration_applications r
        WHERE r.reference = 'CSE-5560071'
     )
  RETURNING id
), source AS (
  INSERT INTO registration_buying_sources (
    application_id, position, mobile_number, matched_account_id,
    matched_name, matched_role, matched_market
  )
  SELECT applicant.id, 0, a.mobile_number, a.id, a.display_name,
         a.user_type, 'Ravi Road, Lahore'
    FROM applicant
    JOIN accounts a ON a.mobile_number = '3007781204'
  RETURNING application_id
)
INSERT INTO registration_approvals (application_id, approver, state)
SELECT source.application_id, v.approver, 'outstanding'
FROM source
CROSS JOIN (VALUES ('buying_source'), ('marketing_officer'), ('crm'))
  AS v (approver);

COMMIT;
