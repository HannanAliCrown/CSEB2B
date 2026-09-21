-- Seed for Profile: the support numbers and the About copy.
--
-- No PINs are seeded. A PIN is something a partner chooses; inventing one
-- would be a lock nobody set.
--
-- Re-runnable.

BEGIN;

INSERT INTO support_contacts (label, phone_number, description, audience, position)
SELECT v.label, v.phone_number, v.description, v.audience, v.position
FROM (VALUES
  ('Crown Solar Helpline', '042 111 276 963',
   'General help, 9 am to 6 pm, Monday to Saturday', 'all', 0),
  ('CRM',                  '042 111 276 964',
   'Accounts, device changes and points adjustments', 'all', 1),
  ('Technical Support',    '042 111 276 965',
   'Product and installation questions', 'all', 2),
  ('Shop Branding',        '042 111 276 966',
   'Frontlit boards and shop branding requests', 'retailer', 3)
) AS v (label, phone_number, description, audience, position)
WHERE NOT EXISTS (
  SELECT 1 FROM support_contacts s WHERE s.phone_number = v.phone_number
);


INSERT INTO app_info (key, value, position)
VALUES
  ('company',  'Crown Solar Energy (Pvt) Ltd', 0),
  ('address',  'Ravi Road, Lahore, Pakistan',  1),
  ('website',  'https://crownsolar.com.pk',    2),
  ('email',    'support@crownsolar.com.pk',    3),
  ('legal',    'This app is for registered Crown Solar partners. Prices, '
               'schemes and prize amounts are set by Crown Solar and may '
               'change.', 4)
ON CONFLICT (key) DO NOTHING;

COMMIT;
