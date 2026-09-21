-- Seed for the two inboxes a buying source works from.
--
-- Re-runnable.

BEGIN;


-- ---------------------------------------------------------------------------
-- Expected purchasing
-- ---------------------------------------------------------------------------

INSERT INTO expected_purchase_bands (label, position)
VALUES
  ('Up to PKR 100,000 a month',        0),
  ('PKR 100,000 — 300,000 a month',    1),
  ('PKR 300,000 — 700,000 a month',    2),
  ('PKR 700,000 — 1,500,000 a month',  3),
  ('Over PKR 1,500,000 a month',       4)
ON CONFLICT (label) DO NOTHING;


-- ---------------------------------------------------------------------------
-- What the applicant submitted
-- ---------------------------------------------------------------------------

-- The media on the seeded registration, so the buying source's screen has
-- something to list. The CNIC front and back are deliberately included here:
-- they are part of the application, and the point is that the screen does
-- not show them to the buying source.
INSERT INTO registration_media (application_id, kind, slot, link_url,
                                storage_path)
SELECT r.id, v.kind, v.slot, v.link_url, v.storage_path
FROM (VALUES
  ('video_link', '1', 'https://youtu.be/cs-install-8841', NULL),
  ('video_link', '2', 'https://youtu.be/cs-install-9120', NULL),
  ('shop_image', 'Shop Board', NULL, '/captures/shop-board.jpg'),
  ('shop_image', 'Shop Stock', NULL, '/captures/shop-stock.jpg'),
  ('selfie',     NULL,         NULL, '/captures/selfie.jpg'),
  ('cnic_front', NULL,         NULL, '/captures/cnic-front.jpg'),
  ('cnic_back',  NULL,         NULL, '/captures/cnic-back.jpg')
) AS v (kind, slot, link_url, storage_path)
CROSS JOIN (
  SELECT id FROM registration_applications WHERE reference = 'CSE-5560071'
) AS r
WHERE NOT EXISTS (
  SELECT 1 FROM registration_media m
   WHERE m.application_id = r.id AND m.kind = v.kind
     AND m.slot IS NOT DISTINCT FROM v.slot
);


-- A second buying source on the same application, so the screen shows that
-- the applicant named more than one place they buy from.
INSERT INTO registration_buying_sources (application_id, position,
                                         mobile_number, matched_account_id,
                                         matched_name, matched_role,
                                         matched_market)
SELECT r.id, 1, a.mobile_number, a.id, a.display_name, a.user_type,
       'Ravi Road, Lahore'
FROM (
  SELECT id FROM registration_applications WHERE reference = 'CSE-5560071'
) AS r
CROSS JOIN (
  SELECT id, mobile_number, display_name, user_type
    FROM accounts WHERE mobile_number = '3014429911'
) AS a
WHERE NOT EXISTS (
  SELECT 1 FROM registration_buying_sources s
   WHERE s.application_id = r.id AND s.position = 1
);


-- ---------------------------------------------------------------------------
-- Cash waiting on a buying source
-- ---------------------------------------------------------------------------

-- Transfers already sent and held, so the Cash Requests inbox is not empty
-- on first sight. Each writes the sender's debit exactly as the app does —
-- the money is out of their wallet and settled nowhere.
--
-- Each amount is inside what that sender's seeded wallet holds. These rows
-- are written directly and so pass no balance check; an amount larger than
-- the sender has would leave their Home screen showing a negative balance.
WITH sent AS (
  INSERT INTO cash_transfers (reference, from_account_id, to_account_id,
                              amount_paisa, note, sent_at, expires_at)
  SELECT v.reference, sender.id, receiver.id, v.amount_paisa, v.note,
         now() - v.ago, now() + v.expires_in
    FROM (VALUES
      ('TX-0101', '3004821190', '3007781204',  850000,
       'Panels invoice 8841',  interval '5 hours',  interval '2 days'),
      ('TX-0102', '3335560071', '3007781204', 1420000,
       'Inverter part payment', interval '1 day 6 hours', interval '1 day'),
      ('TX-0103', '3217745002', '3007781204',  680000,
       NULL, interval '6 days', interval '20 hours')
    ) AS v (reference, from_number, to_number, amount_paisa, note, ago,
            expires_in)
    JOIN accounts sender   ON sender.mobile_number   = v.from_number
    JOIN accounts receiver ON receiver.mobile_number = v.to_number
   WHERE NOT EXISTS (
     SELECT 1 FROM cash_transfers t WHERE t.reference = v.reference
   )
  RETURNING id, reference, from_account_id, to_account_id, amount_paisa,
            sent_at
)
INSERT INTO wallet_entries (account_id, reference, title, direction, type,
                            state, amount_paisa, counterparty_account_id,
                            transfer_id, posted_at)
SELECT sent.from_account_id, sent.reference,
       'Sent to ' || a.display_name, 'debit', 'send_cash', 'held',
       sent.amount_paisa, sent.to_account_id, sent.id, sent.sent_at
FROM sent
JOIN accounts a ON a.id = sent.to_account_id;

COMMIT;
