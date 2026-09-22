-- Seed for Shop Branding.
--
-- The board types Crown Solar offers, what each costs, and what each role
-- must satisfy to be offered it. All of it is configuration the Teams app
-- owns; the app reads it and never writes it.
--
-- Plus enough history on the demo partners to walk every state: a retailer
-- with a live request and a rejected one, and an installer whose shop
-- already carries a board new enough to force a skin change.
--
-- Re-runnable.

BEGIN;


-- ---------------------------------------------------------------------------
-- The board types
-- ---------------------------------------------------------------------------

INSERT INTO branding_board_types
  (code, name, description, unit_price_paisa, company_percent,
   replaces_code, position)
VALUES
  ('frontlit', 'Frontlit Board',
   'Printed flex face lit from the front', 4500000, 60, NULL, 1),
  ('backlit', 'Backlit Board',
   'Translucent face lit from inside the frame', 8000000, 60, NULL, 2),
  ('inverter_wall', 'Inverter Wall Branding',
   'Crown Solar inverter wall on your shopfront', 3000000, 60, NULL, 3),
  ('panel_wall', 'Panel Wall Branding',
   'Crown Solar panel wall on your shopfront', 3000000, 60, NULL, 4),
  ('vinyl', 'Vinyl Pasting',
   'Printed vinyl applied to glass or wall', 2500000, 60, NULL, 5),
  ('one_way_vision', 'One Way Vision',
   'Perforated film — branding outside, daylight inside', 2500000, 60,
   NULL, 6),
  ('customer_care', 'Customer Care Branding',
   'Full customer-care counter and signage', 15000000, 60, NULL, 7),
  ('three_d', '3D Board',
   'Raised lettering with its own lighting', 25000000, 60, NULL, 8)
ON CONFLICT (code) DO UPDATE SET
  name             = EXCLUDED.name,
  description      = EXCLUDED.description,
  unit_price_paisa = EXCLUDED.unit_price_paisa,
  company_percent  = EXCLUDED.company_percent,
  position         = EXCLUDED.position;


-- The two replacement options. Inserted after the boards they replace, so
-- `replaces_code` has something to point at.
INSERT INTO branding_board_types
  (code, name, description, unit_price_paisa, company_percent,
   replaces_code, position)
VALUES
  ('backlit_skin', 'Backlit Skin Change',
   'New printed skin on your existing frame', 2000000, 60, 'backlit', 9),
  ('frontlit_flex', 'Frontlit Flex Change',
   'New printed flex on your existing frame', 1500000, 60, 'frontlit', 10)
ON CONFLICT (code) DO UPDATE SET
  name             = EXCLUDED.name,
  description      = EXCLUDED.description,
  unit_price_paisa = EXCLUDED.unit_price_paisa,
  replaces_code    = EXCLUDED.replaces_code,
  position         = EXCLUDED.position;


-- ---------------------------------------------------------------------------
-- Who may ask for what
-- ---------------------------------------------------------------------------

-- Installer: the Frontlit Board alone, and only while scanning is current.
-- No scheme and no points threshold — an installer's one condition is that
-- they are still working.
INSERT INTO branding_board_type_roles
  (board_type_id, role, min_points, requires_scheme, requires_recent_scan)
SELECT id, 'installer', 0, false, true
  FROM branding_board_types WHERE code = 'frontlit'
ON CONFLICT (board_type_id, role) DO UPDATE SET
  min_points           = EXCLUDED.min_points,
  requires_scheme      = EXCLUDED.requires_scheme,
  requires_recent_scan = EXCLUDED.requires_recent_scan;


-- Retailer, Wholesaler and Distributor: both boards on a signed scheme,
-- with no points floor.
INSERT INTO branding_board_type_roles
  (board_type_id, role, min_points, requires_scheme, requires_recent_scan)
SELECT t.id, r.role, 0, true, false
  FROM branding_board_types t
  CROSS JOIN (VALUES ('retailer'), ('wholesaler'), ('distributor')) AS r(role)
 WHERE t.code IN ('frontlit', 'backlit')
ON CONFLICT (board_type_id, role) DO UPDATE SET
  min_points           = EXCLUDED.min_points,
  requires_scheme      = EXCLUDED.requires_scheme,
  requires_recent_scan = EXCLUDED.requires_recent_scan;


-- The four wall and film options, at 15,000 points on a signed scheme.
INSERT INTO branding_board_type_roles
  (board_type_id, role, min_points, requires_scheme, requires_recent_scan)
SELECT t.id, r.role, 15000, true, false
  FROM branding_board_types t
  CROSS JOIN (VALUES ('retailer'), ('wholesaler'), ('distributor')) AS r(role)
 WHERE t.code IN ('inverter_wall', 'panel_wall', 'vinyl', 'one_way_vision')
ON CONFLICT (board_type_id, role) DO UPDATE SET
  min_points           = EXCLUDED.min_points,
  requires_scheme      = EXCLUDED.requires_scheme,
  requires_recent_scan = EXCLUDED.requires_recent_scan;


-- Customer Care Branding at 100,000 points, for Wholesaler and Distributor.
INSERT INTO branding_board_type_roles
  (board_type_id, role, min_points, requires_scheme, requires_recent_scan)
SELECT t.id, r.role, 100000, false, false
  FROM branding_board_types t
  CROSS JOIN (VALUES ('wholesaler'), ('distributor')) AS r(role)
 WHERE t.code = 'customer_care'
ON CONFLICT (board_type_id, role) DO UPDATE SET
  min_points           = EXCLUDED.min_points,
  requires_scheme      = EXCLUDED.requires_scheme,
  requires_recent_scan = EXCLUDED.requires_recent_scan;


-- The 3D Board at 100,000 points, for Distributors only.
INSERT INTO branding_board_type_roles
  (board_type_id, role, min_points, requires_scheme, requires_recent_scan)
SELECT id, 'distributor', 100000, false, false
  FROM branding_board_types WHERE code = 'three_d'
ON CONFLICT (board_type_id, role) DO UPDATE SET
  min_points           = EXCLUDED.min_points,
  requires_scheme      = EXCLUDED.requires_scheme,
  requires_recent_scan = EXCLUDED.requires_recent_scan;


-- The replacement options are open to every role that can have a board on
-- its shop. Their condition is not points or a scheme but the installation
-- itself, which is why they carry none of the three flags.
INSERT INTO branding_board_type_roles
  (board_type_id, role, min_points, requires_scheme, requires_recent_scan)
SELECT t.id, r.role, 0, false, false
  FROM branding_board_types t
  CROSS JOIN (VALUES ('installer'), ('retailer'),
                     ('wholesaler'), ('distributor')) AS r(role)
 WHERE t.code IN ('backlit_skin', 'frontlit_flex')
ON CONFLICT (board_type_id, role) DO UPDATE SET
  min_points           = EXCLUDED.min_points,
  requires_scheme      = EXCLUDED.requires_scheme,
  requires_recent_scan = EXCLUDED.requires_recent_scan;


-- ---------------------------------------------------------------------------
-- Al-Noor Electric Store · a retailer mid-request, with history behind it
-- ---------------------------------------------------------------------------

INSERT INTO branding_requests
  (reference, account_id, shop_photo_path, card_photo_path,
   height_ft, width_ft, board_count, status, stage, created_at)
SELECT 'BRD-2026-3391', a.id,
       '/seed/al-noor-shop.jpg', '/seed/al-noor-card.jpg',
       4, 12, 2, 'in_progress', 2, now() - interval '9 days'
  FROM accounts a WHERE a.mobile_number = '3007781204'
ON CONFLICT (reference) DO NOTHING;

INSERT INTO branding_request_boards
  (request_id, position, board_type_id, unit_price_paisa, company_percent)
SELECT r.id, 1, t.id, t.unit_price_paisa, t.company_percent
  FROM branding_requests r, branding_board_types t
 WHERE r.reference = 'BRD-2026-3391' AND t.code = 'backlit'
ON CONFLICT (request_id, position) DO NOTHING;

INSERT INTO branding_request_boards
  (request_id, position, board_type_id, unit_price_paisa, company_percent)
SELECT r.id, 2, t.id, t.unit_price_paisa, t.company_percent
  FROM branding_requests r, branding_board_types t
 WHERE r.reference = 'BRD-2026-3391' AND t.code = 'inverter_wall'
ON CONFLICT (request_id, position) DO NOTHING;


-- A finished one, which is what put a board on their shop.
INSERT INTO branding_requests
  (reference, account_id, shop_photo_path, card_photo_path,
   height_ft, width_ft, board_count, status, stage, created_at)
SELECT 'BRD-2026-2988', a.id,
       '/seed/al-noor-shop.jpg', '/seed/al-noor-card.jpg',
       4, 10, 1, 'completed', 3, now() - interval '5 months'
  FROM accounts a WHERE a.mobile_number = '3007781204'
ON CONFLICT (reference) DO NOTHING;

INSERT INTO branding_request_boards
  (request_id, position, board_type_id, unit_price_paisa, company_percent)
SELECT r.id, 1, t.id, t.unit_price_paisa, t.company_percent
  FROM branding_requests r, branding_board_types t
 WHERE r.reference = 'BRD-2026-2988' AND t.code = 'frontlit'
ON CONFLICT (request_id, position) DO NOTHING;


-- And one Crown Solar turned down, with the reason they gave.
INSERT INTO branding_requests
  (reference, account_id, shop_photo_path, card_photo_path,
   height_ft, width_ft, board_count, status, stage,
   rejection_reason, created_at)
SELECT 'BRD-2025-6602', a.id,
       '/seed/al-noor-shop.jpg', '/seed/al-noor-card.jpg',
       3, 8, 1, 'rejected', 1,
       'Wall surface is not suitable for vinyl pasting — too much surface '
       'damage to hold the material.',
       now() - interval '14 months'
  FROM accounts a WHERE a.mobile_number = '3007781204'
ON CONFLICT (reference) DO NOTHING;

INSERT INTO branding_request_boards
  (request_id, position, board_type_id, unit_price_paisa, company_percent)
SELECT r.id, 1, t.id, t.unit_price_paisa, t.company_percent
  FROM branding_requests r, branding_board_types t
 WHERE r.reference = 'BRD-2025-6602' AND t.code = 'vinyl'
ON CONFLICT (request_id, position) DO NOTHING;


-- ---------------------------------------------------------------------------
-- What is already on the shopfronts
-- ---------------------------------------------------------------------------

-- Adnan Solar Works carries a Backlit board put up two months ago. Too new
-- to replace, so every other option disappears and only the skin change is
-- offered — the state board 07 · A5 draws.
INSERT INTO branding_installations (account_id, board_type_id, installed_on)
SELECT a.id, t.id, (current_date - interval '2 months')::date
  FROM accounts a, branding_board_types t
 WHERE a.mobile_number = '3004821190' AND t.code = 'backlit'
   AND NOT EXISTS (
     SELECT 1 FROM branding_installations existing
      WHERE existing.account_id = a.id AND existing.board_type_id = t.id
   );

-- Al-Noor's Frontlit board went up with BRD-2026-2988, five months ago —
-- also inside the window, so they see Frontlit Flex Change only.
INSERT INTO branding_installations (account_id, board_type_id, installed_on)
SELECT a.id, t.id, (current_date - interval '5 months')::date
  FROM accounts a, branding_board_types t
 WHERE a.mobile_number = '3007781204' AND t.code = 'frontlit'
   AND NOT EXISTS (
     SELECT 1 FROM branding_installations existing
      WHERE existing.account_id = a.id AND existing.board_type_id = t.id
   );

-- Shahdara Solar Services has a bare shopfront, so an installer's ordinary
-- path — Frontlit, gated on recent scanning — is walkable too.

COMMIT;
