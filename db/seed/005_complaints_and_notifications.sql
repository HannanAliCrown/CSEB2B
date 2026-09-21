-- Seed for Complaints and Notifications.
--
-- The categories and their targets are reference data Crown Solar owns.
-- The four tickets and five notifications are the ones drawn on board 08, so
-- the screens are not empty on first sight.
--
-- Every date is relative to now(), never a literal. A seed with 04 Sep
-- written into it reads correctly for one month and wrongly ever after.
--
-- Re-runnable.

BEGIN;


-- ---------------------------------------------------------------------------
-- What a complaint can be about
-- ---------------------------------------------------------------------------

INSERT INTO complaint_types (code, label, short_label, position)
SELECT v.code, v.label, v.short_label, v.position
FROM (VALUES
  ('qr_and_prizes',      'QR and prizes',      'QR prize dispute', 0),
  ('wallet_and_cash',    'Wallet and cash',    NULL,               1),
  ('points',             'Points',             NULL,               2),
  ('shop_branding',      'Shop branding',      NULL,               3),
  ('account_and_access', 'Account and access', NULL,               4),
  ('something_else',     'Something else',     NULL,               5)
) AS v (code, label, short_label, position)
WHERE NOT EXISTS (
  SELECT 1 FROM complaint_types t WHERE t.code = v.code
);


-- ---------------------------------------------------------------------------
-- What Crown Solar promises
-- ---------------------------------------------------------------------------

-- One band per priority, applied to every category. The design's single
-- stated case — a High-priority prize dispute answered within 4 hours and
-- resolved within 2 working days — is the 'high' row.
INSERT INTO complaint_targets (type_id, priority, response_minutes,
                               resolution_working_days)
SELECT t.id, v.priority, v.response_minutes, v.resolution_working_days
FROM complaint_types t
CROSS JOIN (VALUES
  ('high',    240, 2),
  ('medium',  480, 3),
  ('low',    1440, 5)
) AS v (priority, response_minutes, resolution_working_days)
WHERE NOT EXISTS (
  SELECT 1 FROM complaint_targets g
   WHERE g.type_id = t.id AND g.priority = v.priority
);


-- ---------------------------------------------------------------------------
-- Adnan Solar Works' tickets
-- ---------------------------------------------------------------------------

INSERT INTO complaints (
  reference, account_id, type_id, priority, title, detail, status,
  evidence_note, response_target_minutes, resolution_target_working_days,
  raised_at, first_response_at, resolved_at
)
SELECT
  v.reference, a.id, t.id, v.priority, v.title, v.detail, v.status,
  v.evidence_note, g.response_minutes, g.resolution_working_days,
  now() - v.raised_ago,
  CASE WHEN v.responded_ago IS NULL THEN NULL ELSE now() - v.responded_ago END,
  CASE WHEN v.resolved_ago  IS NULL THEN NULL ELSE now() - v.resolved_ago  END
FROM (VALUES
  ('CMP-2026-5514', 'qr_and_prizes', 'high',
   'Prize not credited for inverter scan',
   'I scanned a Crown 8kW inverter on 8 September at about 3 pm. The app '
     'showed the prize screen but nothing came into my wallet.',
   'in_progress',
   'QR code CS-6K-2026-338201 · previous claimant M. Zubair Solar · both '
     'timestamps · your location at the time of the scan.',
   interval '3 hours 12 minutes', interval '2 hours', NULL),

  ('CMP-2026-5390', 'shop_branding', 'medium',
   'Board installed with wrong shop name',
   'The frontlit board that went up yesterday reads "Adnan Solar Work". The '
     'shop name is Adnan Solar Works.',
   'in_progress', NULL,
   interval '17 days', interval '16 days 20 hours', NULL),

  ('CMP-2026-5102', 'points', 'medium',
   'Points missing for August purchase',
   'I bought 12 panels on 18 August through Hamza Solar House. No points '
     'were posted against the invoice.',
   'resolved', NULL,
   interval '30 days', interval '29 days 18 hours', interval '27 days'),

  ('CMP-2026-4977', 'account_and_access', 'low',
   'Cannot sign in on my new phone',
   'My old handset broke. The app says my account is fixed to another '
     'device and will not let me in.',
   'resolved', NULL,
   interval '38 days', interval '37 days', interval '35 days')
) AS v (reference, type_code, priority, title, detail, status,
        evidence_note, raised_ago, responded_ago, resolved_ago)
JOIN complaint_types   t ON t.code = v.type_code
JOIN complaint_targets g ON g.type_id = t.id AND g.priority = v.priority
CROSS JOIN (
  SELECT id FROM accounts WHERE mobile_number = '3004821190'
) AS a
WHERE NOT EXISTS (
  SELECT 1 FROM complaints c WHERE c.reference = v.reference
);


-- The history on CMP-2026-5514's detail screen. The step still being waited
-- on is not a row: the server derives it from the ticket's status and its
-- resolution target, so it can never quote a date that has gone stale.
INSERT INTO complaint_events (complaint_id, title, meta, note, state,
                              occurred_at, position)
SELECT c.id, v.title, v.meta, v.note, 'done', c.raised_at + v.after, v.position
FROM (VALUES
  ('Complaint raised',
   'Submitted by you with attached scan evidence.', NULL,
   interval '0 minutes', 0),
  ('Ticket assigned',
   'Assigned to CRM prize desk.', NULL,
   interval '12 minutes', 1),
  ('First response',
   '"We are checking both scans against the installation record."',
   'response target met',
   interval '1 hour 12 minutes', 2)
) AS v (title, meta, note, after, position)
CROSS JOIN (
  SELECT id, raised_at FROM complaints WHERE reference = 'CMP-2026-5514'
) AS c
WHERE NOT EXISTS (
  SELECT 1 FROM complaint_events e
   WHERE e.complaint_id = c.id AND e.title = v.title
);


-- The two resolved tickets, so their history is not blank either.
INSERT INTO complaint_events (complaint_id, title, meta, note, state,
                              occurred_at, position)
SELECT c.id, v.title, v.meta, NULL, 'done',
       CASE v.position
         WHEN 0 THEN c.raised_at
         WHEN 1 THEN c.first_response_at
         ELSE c.resolved_at
       END,
       v.position
FROM (VALUES
  ('Complaint raised', 'Submitted by you.',                            0),
  ('First response',   'Crown Solar acknowledged the complaint.',      1),
  ('Resolved',         'Closed by CRM. Reopen it by raising a new '
                       'complaint if the problem comes back.',         2)
) AS v (title, meta, position)
CROSS JOIN (
  SELECT id, raised_at, first_response_at, resolved_at
    FROM complaints
   WHERE reference IN ('CMP-2026-5102', 'CMP-2026-4977')
) AS c
WHERE NOT EXISTS (
  SELECT 1 FROM complaint_events e
   WHERE e.complaint_id = c.id AND e.title = v.title
);


-- CMP-2026-5390 has been answered but not resolved.
INSERT INTO complaint_events (complaint_id, title, meta, note, state,
                              occurred_at, position)
SELECT c.id, v.title, v.meta, NULL, 'done',
       CASE v.position WHEN 0 THEN c.raised_at ELSE c.first_response_at END,
       v.position
FROM (VALUES
  ('Complaint raised', 'Submitted by you.',                        0),
  ('First response',   'Rehman Signs has been asked to reprint '
                       'and refit the board.',                     1)
) AS v (title, meta, position)
CROSS JOIN (
  SELECT id, raised_at, first_response_at
    FROM complaints WHERE reference = 'CMP-2026-5390'
) AS c
WHERE NOT EXISTS (
  SELECT 1 FROM complaint_events e
   WHERE e.complaint_id = c.id AND e.title = v.title
);


-- ---------------------------------------------------------------------------
-- Notifications
-- ---------------------------------------------------------------------------

-- These stand in for what the backend would have written when each thing
-- happened. `destination_route` is null where the destination is not built
-- yet — the row still says where it would go, and the app says so plainly
-- rather than pretending to navigate.
INSERT INTO notifications (account_id, level, title, body, destination_label,
                           destination_route, created_at, read_at)
SELECT a.id, v.level, v.title, v.body, v.destination_label,
       v.destination_route, now() - v.ago,
       CASE WHEN v.unread THEN NULL ELSE now() - v.ago + interval '1 hour' END
FROM (VALUES
  ('info',
   'Cash request expired and returned',
   'PKR 4,000 you sent to Sitara Electronics came back to your wallet.',
   'opens Ledger entry', '/wallet/ledger',
   interval '5 hours', true),

  ('info',
   'Prize held for review',
   'Your claim on CS-6K-2026-338201 is with CRM.',
   'opens Claim detail', NULL,
   interval '1 day 6 hours', true),

  ('info',
   'Spin entitlement earned',
   'You scanned 10 products today. One spin is waiting.',
   'opens Inaam Baazar · Spin and Win', NULL,
   interval '1 day 9 hours', false),

  ('success',
   'Complaint CMP-2026-5102 resolved',
   'Points for your August purchase have been posted.',
   'opens Complaint detail', '/complaints/CMP-2026-5102',
   interval '27 days', false),

  ('info',
   'New post in Space',
   'Crown Solar shared: Eid scheme for retailers.',
   'opens Post detail', NULL,
   interval '32 days', false)
) AS v (level, title, body, destination_label, destination_route, ago, unread)
CROSS JOIN (
  SELECT id FROM accounts WHERE mobile_number = '3004821190'
) AS a
WHERE NOT EXISTS (
  SELECT 1 FROM notifications n
   WHERE n.account_id = a.id AND n.title = v.title
);

COMMIT;
