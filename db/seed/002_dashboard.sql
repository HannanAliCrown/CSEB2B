-- Seed for Home: the wallet movements, the slider and the ticker.
--
-- The wallet rows are the same five movements the mock has been showing, so
-- the DB-backed dashboard opens on figures everyone recognises: 16,000
-- available with 1,500 held, for a partner who earns from scanning.
--
-- Re-runnable.

BEGIN;


-- ---------------------------------------------------------------------------
-- Wallet movements, for every seeded account
-- ---------------------------------------------------------------------------

INSERT INTO wallet_entries (
  account_id, reference, title, direction, type, state, amount_paisa, posted_at
)
SELECT a.id, v.reference, v.title, v.direction, v.type, v.state,
       -- Installers and retailers carry a smaller opening balance than the
       -- trade roles, exactly as the mock did.
       CASE WHEN v.reference = 'TX-0001' AND a.user_type IN ('wholesaler', 'distributor')
            THEN 14200000
            ELSE v.amount_paisa
       END,
       now() - (v.days_ago || ' days')::interval
FROM accounts a
CROSS JOIN (VALUES
  ('TX-0001', 'Opening balance',                  'credit', 'crm_adjustment', 'cleared', 1850000, 18),
  ('TX-0002', 'Scan reward · inverter',           'credit', 'scan_prize',     'cleared',  120000, 11),
  ('TX-0003', 'Sent to Al-Noor Electric Store',   'debit',  'send_cash',      'cleared',  300000,  6),
  ('TX-0004', 'Sent to Bilal Traders',            'debit',  'send_cash',      'held',     150000,  2),
  ('TX-0005', 'Scan reward · panel',              'credit', 'scan_prize',     'cleared',   80000,  1)
) AS v (reference, title, direction, type, state, amount_paisa, days_ago)
ON CONFLICT (account_id, reference) DO NOTHING;


-- ---------------------------------------------------------------------------
-- The slider
-- ---------------------------------------------------------------------------

-- Text-only slides: no picture yet, so they render on the brand gradient the
-- way they always have. Adding `image_url` to a row is all it takes to turn
-- one into a picture.
INSERT INTO promo_slides (eyebrow, headline, audience, position, ends_at)
SELECT v.eyebrow, v.headline, v.audience, v.position, v.ends_at
FROM (VALUES
  ('CROWN SOLAR',     'Scan 10 products today to earn a spin',            'installer',  0, NULL::timestamptz),
  ('EID SCHEME',      'Double prizes on every inverter until 30 September','installer',  1, NULL),
  ('TRAINING',        'Free installer certification in Lahore this month', 'installer',  2, NULL),
  ('CROWN SOLAR',     'Earn 2x points on every panel this week',           'retailer',   0, NULL),
  ('SHOP BRANDING',   'Frontlit board requests are open until 30 September','retailer',  1, NULL),
  ('QUARTERLY TARGET','Hit 80% by 30 September to unlock the annual bonus','wholesaler', 0, NULL),
  ('QUARTERLY TARGET','Hit 80% by 30 September to unlock the annual bonus','distributor',0, NULL)
) AS v (eyebrow, headline, audience, position, ends_at)
WHERE NOT EXISTS (
  SELECT 1 FROM promo_slides p
   WHERE p.headline = v.headline AND p.audience = v.audience
);


-- ---------------------------------------------------------------------------
-- The ticker
-- ---------------------------------------------------------------------------

-- Colours left null, so these use the app's own ticker colours. A scheme that
-- wants its own sets them per row.
INSERT INTO ticker_messages (message, audience, position)
SELECT v.message, v.audience, v.position
FROM (VALUES
  ('Eid scheme live until 30 September',              'installer',  0),
  ('Scan any Crown Solar box to check it is genuine', 'installer',  1),
  ('Cash sent before 4pm is settled the same day',    'installer',  2),
  ('Eid scheme live until 30 September',              'retailer',   0),
  ('Frontlit board requests open',                    'retailer',   1),
  ('Points expire 90 days after they are earned',     'retailer',   2),
  ('Quarterly targets close 30 September',            'wholesaler', 0),
  ('New partner profiles need CRM approval',          'wholesaler', 1),
  ('Quarterly targets close 30 September',            'distributor',0),
  ('New partner profiles need CRM approval',          'distributor',1)
) AS v (message, audience, position)
WHERE NOT EXISTS (
  SELECT 1 FROM ticker_messages t
   WHERE t.message = v.message AND t.audience = v.audience
);

COMMIT;
