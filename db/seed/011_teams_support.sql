-- Seed for Crown Solar Teams support (specs/013-teams-support).
--
-- One of each thing a Teams officer can leave in this database, so every new
-- state can be seen from the partner's side: a complaint and a branding
-- request an officer raised, an officer in chat, an item scheme shown in one
-- market only, and a code not yet assigned to a product.
--
-- The officer is a demo Marketing Officer. Crown Solar Teams owns staff; the
-- id here is fixed so its seed can use the same one.
--
-- Re-runnable.

BEGIN;

-- ---------------------------------------------------------------------------
-- An officer-raised complaint and branding request (CSE-2, CSE-3)
-- ---------------------------------------------------------------------------

INSERT INTO complaints (
  reference, account_id, type_id, priority, title, detail, status,
  response_target_minutes, resolution_target_working_days, raised_at,
  raised_by_staff_id, raised_by_staff_name, raised_by_staff_role
)
SELECT 'CMP-2026-5520', a.id, t.id, 'medium',
       'Shop board light not working',
       'Raised during a market visit: the backlit board stays dark after sunset.',
       'in_progress', g.response_minutes, g.resolution_working_days,
       now() - interval '5 hours',
       '00000000-0000-4000-8000-000000000101', 'Imran Aslam', 'mo'
  FROM accounts a
  JOIN complaint_types t ON t.code = 'shop_branding'
  JOIN complaint_targets g ON g.type_id = t.id AND g.priority = 'medium'
 WHERE a.mobile_number = '3004821190'
ON CONFLICT (reference) DO NOTHING;

INSERT INTO complaint_events (complaint_id, title, meta, state, occurred_at, position)
SELECT c.id, 'Complaint raised', 'By Imran Aslam · Marketing Officer', 'done',
       c.raised_at, 0
  FROM complaints c
 WHERE c.reference = 'CMP-2026-5520'
   AND NOT EXISTS (SELECT 1 FROM complaint_events e WHERE e.complaint_id = c.id);

INSERT INTO branding_requests
  (reference, account_id, shop_photo_path, card_photo_path,
   height_ft, width_ft, board_count, status, stage, created_at,
   raised_by_staff_id, raised_by_staff_name, raised_by_staff_role)
SELECT 'BRD-2026-3410', a.id,
       '/seed/bilal-shop.jpg', '/seed/bilal-card.jpg',
       3, 10, 1, 'in_progress', 1, now() - interval '2 days',
       '00000000-0000-4000-8000-000000000101', 'Imran Aslam', 'mo'
  FROM accounts a WHERE a.mobile_number = '3217745002'
ON CONFLICT (reference) DO NOTHING;

INSERT INTO branding_request_boards
  (request_id, position, board_type_id, unit_price_paisa, company_percent)
SELECT r.id, 1, t.id, t.unit_price_paisa, t.company_percent
  FROM branding_requests r, branding_board_types t
 WHERE r.reference = 'BRD-2026-3410' AND t.code = 'frontlit'
ON CONFLICT (request_id, position) DO NOTHING;


-- ---------------------------------------------------------------------------
-- The officer in chat (CSE-5)
-- ---------------------------------------------------------------------------

INSERT INTO chat_staff_parties (address, display_name, role)
VALUES ('staff:00000000-0000-4000-8000-000000000101', 'Imran Aslam', 'mo')
ON CONFLICT (address) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  role         = EXCLUDED.role,
  updated_at   = now();

INSERT INTO chat_threads (party_low, party_high)
SELECT LEAST(a.mobile_number, s.address), GREATEST(a.mobile_number, s.address)
  FROM accounts a, chat_staff_parties s
 WHERE a.mobile_number = '3004821190'
   AND s.address = 'staff:00000000-0000-4000-8000-000000000101'
ON CONFLICT (party_low, party_high) DO NOTHING;

INSERT INTO chat_messages (thread_id, sender_address, body, status, sent_at)
SELECT t.id, 'staff:00000000-0000-4000-8000-000000000101',
       'I will visit Ravi Road tomorrow. Please keep the inverter invoices ready.',
       'delivered', now() - interval '1 hour'
  FROM chat_threads t
 WHERE t.party_low = '3004821190'
   AND t.party_high = 'staff:00000000-0000-4000-8000-000000000101'
   AND NOT EXISTS (SELECT 1 FROM chat_messages m WHERE m.thread_id = t.id);


-- ---------------------------------------------------------------------------
-- An item scheme shown in Ravi Road only (CSE-6)
-- ---------------------------------------------------------------------------

INSERT INTO item_schemes (name, measure, starts_on, ends_on)
VALUES ('Ravi Road Inverter Drive', 'scans', '2026-09-01', '2026-12-31')
ON CONFLICT (name, starts_on) DO NOTHING;

INSERT INTO item_scheme_products (scheme_id, product_id)
SELECT s.id, p.id
  FROM item_schemes s JOIN products p ON p.code LIKE 'CS-INV-%'
 WHERE s.name = 'Ravi Road Inverter Drive'
ON CONFLICT (scheme_id, product_id) DO NOTHING;

INSERT INTO item_scheme_tiers (scheme_id, name, threshold, reward_paisa, position)
SELECT s.id, 'Silver', 50, 500000, 0
  FROM item_schemes s WHERE s.name = 'Ravi Road Inverter Drive'
ON CONFLICT (scheme_id, name) DO NOTHING;

INSERT INTO item_scheme_markets (scheme_id, market_id)
SELECT s.id, m.id
  FROM item_schemes s, markets m
 WHERE s.name = 'Ravi Road Inverter Drive' AND m.name = 'Ravi Road, Lahore'
ON CONFLICT (scheme_id, market_id) DO NOTHING;


-- ---------------------------------------------------------------------------
-- A code not yet assigned to a product serial (CSE-7)
-- ---------------------------------------------------------------------------

INSERT INTO products (code, name, state)
VALUES ('CS-NEW-0001', 'Crown Solar 8kW Hybrid Inverter', 'unassigned')
ON CONFLICT (code) DO NOTHING;

COMMIT;
