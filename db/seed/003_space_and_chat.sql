-- Seed for Space and Chat.
--
-- The Space posts stand in for what the publishing application would have
-- written; the partner app never creates one. The chat threads are the same
-- opening conversations the mock had, so the list is not empty on first
-- sight.
--
-- Re-runnable.

BEGIN;


-- ---------------------------------------------------------------------------
-- Space posts
-- ---------------------------------------------------------------------------

-- Every post carries a picture. `image_url` is what the publishing
-- application writes; these stand-ins are placeholders until Crown Solar's
-- own photographs are in place, and a post with no picture still renders —
-- the card simply leaves the panel out.
INSERT INTO space_posts (title, body, image_url, audience, posted_at)
SELECT v.title, v.body, v.image_url, v.audience, now() - (v.hours_ago || ' hours')::interval
FROM (VALUES
  ('Dealer meet-up in Lahore on 20 September',
   'Doors open at 10 am at Pearl Continental. Bring your profile QR for attendance. Lunch and the new product briefing are included.',
   'https://picsum.photos/seed/crown-meetup/900/400', 'all', 4),
  ('New 8kW hybrid inverter is now shipping',
   'The CS-8K hybrid ships from the Lahore plant this week. It carries a five-year warranty and works with the existing mounting kit.',
   'https://picsum.photos/seed/crown-inverter/900/400', 'all', 24),
  ('Installer certification, free this month',
   'Two-day certification at the Lahore training centre. Certified installers appear first when a customer searches their area.',
   'https://picsum.photos/seed/crown-training/900/400', 'installer', 48),
  ('Frontlit shop boards: requests open until 30 September',
   'Retailers can request a new frontlit board through Shop Branding. The supplier calls within three working days.',
   'https://picsum.photos/seed/crown-branding/900/400', 'retailer', 72),
  ('Quarterly targets close on 30 September',
   'Hit 80% of your quarterly target to unlock the annual bonus band. Your progress is on the Points screen.',
   'https://picsum.photos/seed/crown-targets/900/400', 'trade', 96)
) AS v (title, body, image_url, audience, hours_ago)
WHERE NOT EXISTS (SELECT 1 FROM space_posts p WHERE p.title = v.title);


-- The insert above does nothing on a database seeded before the pictures
-- existed, so they are filled in here too. Only where there is none: a
-- picture the publishing application has since set is never overwritten.
UPDATE space_posts p SET image_url = v.image_url
FROM (VALUES
  ('Dealer meet-up in Lahore on 20 September',
   'https://picsum.photos/seed/crown-meetup/900/400'),
  ('New 8kW hybrid inverter is now shipping',
   'https://picsum.photos/seed/crown-inverter/900/400'),
  ('Installer certification, free this month',
   'https://picsum.photos/seed/crown-training/900/400'),
  ('Frontlit shop boards: requests open until 30 September',
   'https://picsum.photos/seed/crown-branding/900/400'),
  ('Quarterly targets close on 30 September',
   'https://picsum.photos/seed/crown-targets/900/400')
) AS v (title, image_url)
WHERE p.title = v.title AND p.image_url IS NULL;


-- Comments on the meet-up post, with one official reply under the first.
WITH post AS (
  SELECT id FROM space_posts
   WHERE title = 'Dealer meet-up in Lahore on 20 September'
), first_comment AS (
  INSERT INTO space_comments (post_id, account_id, author_name, body, posted_at)
  SELECT post.id, a.id, a.display_name,
         'Kya installers bhi aa sakte hain?', now() - interval '1 hour'
    FROM post
    JOIN accounts a ON a.mobile_number = '3335560071'
   WHERE NOT EXISTS (
     SELECT 1 FROM space_comments c
      WHERE c.post_id = post.id AND c.body = 'Kya installers bhi aa sakte hain?'
   )
  RETURNING id, post_id
)
INSERT INTO space_comments (post_id, parent_comment_id, author_name, body, official, posted_at)
SELECT post_id, id, 'Crown Solar · CRM',
       'Yes, installers are welcome. Bring your profile QR.', true,
       now() - interval '45 minutes'
  FROM first_comment;

INSERT INTO space_comments (post_id, account_id, author_name, body, posted_at)
SELECT p.id, a.id, a.display_name, 'Parking available hai?', now() - interval '20 minutes'
  FROM space_posts p
  JOIN accounts a ON a.mobile_number = '3217745002'
 WHERE p.title = 'Dealer meet-up in Lahore on 20 September'
   AND NOT EXISTS (
     SELECT 1 FROM space_comments c
      WHERE c.post_id = p.id AND c.body = 'Parking available hai?'
   );

INSERT INTO space_comments (post_id, account_id, author_name, body, posted_at)
SELECT p.id, a.id, a.display_name, 'Stock kab tak aayega Badami Bagh mein?',
       now() - interval '20 hours'
  FROM space_posts p
  JOIN accounts a ON a.mobile_number = '3014429911'
 WHERE p.title = 'New 8kW hybrid inverter is now shipping'
   AND NOT EXISTS (
     SELECT 1 FROM space_comments c
      WHERE c.post_id = p.id AND c.body = 'Stock kab tak aayega Badami Bagh mein?'
   );


-- Opening hearts, so the counts are not all zero. Every partner hearts the
-- two posts aimed at everyone.
INSERT INTO space_post_hearts (post_id, account_id)
SELECT p.id, a.id
  FROM space_posts p
 CROSS JOIN accounts a
 WHERE p.audience = 'all'
ON CONFLICT DO NOTHING;


-- ---------------------------------------------------------------------------
-- Chat
-- ---------------------------------------------------------------------------

-- Every partner starts with a CRM and a Branding conversation. The thread's
-- two parties are stored in sorted order, which is what the CHECK enforces.
INSERT INTO chat_threads (party_low, party_high)
SELECT LEAST(a.mobile_number, d.address), GREATEST(a.mobile_number, d.address)
  FROM accounts a
 CROSS JOIN (VALUES ('dept:crm'), ('dept:branding')) AS d (address)
ON CONFLICT (party_low, party_high) DO NOTHING;


-- CRM: the partner asked, CRM answered twice. The two answers stay unread,
-- because nothing has marked the thread read yet.
INSERT INTO chat_messages (thread_id, sender_address, body, status, sent_at)
SELECT t.id, v.sender, v.body, v.status, now() - (v.hours_ago || ' hours')::interval
  FROM accounts a
  JOIN chat_threads t
    ON t.party_low = LEAST(a.mobile_number, 'dept:crm')
   AND t.party_high = GREATEST(a.mobile_number, 'dept:crm')
 CROSS JOIN LATERAL (VALUES
   (a.mobile_number, 'I scanned the same code twice by mistake.', 'read', 3),
   ('dept:crm', 'We are checking both scans against the record.', 'delivered', 2),
   ('dept:crm', 'Nothing has been deducted from you.', 'delivered', 2)
 ) AS v (sender, body, status, hours_ago)
 WHERE NOT EXISTS (SELECT 1 FROM chat_messages m WHERE m.thread_id = t.id);

INSERT INTO chat_messages (thread_id, sender_address, body, status, sent_at)
SELECT t.id, 'dept:branding',
       'Your frontlit board request is approved. The supplier will call you before 30 September.',
       'delivered', now() - interval '1 day'
  FROM accounts a
  JOIN chat_threads t
    ON t.party_low = LEAST(a.mobile_number, 'dept:branding')
   AND t.party_high = GREATEST(a.mobile_number, 'dept:branding')
 WHERE NOT EXISTS (SELECT 1 FROM chat_messages m WHERE m.thread_id = t.id);

COMMIT;
