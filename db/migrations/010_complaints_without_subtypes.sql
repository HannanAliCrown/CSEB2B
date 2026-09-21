-- Complaints: the sub-type goes, the partner's own words take its place.
--
-- "Which part?" was a second dropdown that only ever narrowed the category.
-- A partner describes their problem better than a list of thirteen labels
-- can, so the wizard now asks them to write it. What stays is the category,
-- because CRM routes on it, and the priority, because the promise depends
-- on it.
--
-- Targets were keyed on the sub-type. They are now keyed on the type, which
-- is lossless: every sub-type carried the same band per priority.
--
-- Idempotent.

BEGIN;


-- ---------------------------------------------------------------------------
-- Targets move from the sub-type to the type
-- ---------------------------------------------------------------------------

ALTER TABLE complaint_targets
  ADD COLUMN IF NOT EXISTS type_id uuid REFERENCES complaint_types (id)
    ON DELETE CASCADE;

-- Only while the sub-types are still here to read the type from.
DO $$
BEGIN
  IF to_regclass('public.complaint_subtypes') IS NOT NULL THEN
    UPDATE complaint_targets g
       SET type_id = s.type_id
      FROM complaint_subtypes s
     WHERE s.id = g.subtype_id AND g.type_id IS NULL;
  END IF;
END $$;

-- Every sub-type of a type carried the same band, so collapsing them leaves
-- one row per (type, priority) and no promise is changed.
DELETE FROM complaint_targets g
 WHERE g.ctid NOT IN (
   SELECT min(k.ctid) FROM complaint_targets k
    WHERE k.type_id IS NOT NULL
    GROUP BY k.type_id, k.priority
 )
   AND g.type_id IS NOT NULL;

DELETE FROM complaint_targets WHERE type_id IS NULL;

ALTER TABLE complaint_targets ALTER COLUMN type_id SET NOT NULL;

ALTER TABLE complaint_targets DROP CONSTRAINT IF EXISTS complaint_targets_pkey;
ALTER TABLE complaint_targets DROP COLUMN IF EXISTS subtype_id;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'complaint_targets_pkey'
  ) THEN
    ALTER TABLE complaint_targets
      ADD CONSTRAINT complaint_targets_pkey PRIMARY KEY (type_id, priority);
  END IF;
END $$;


-- ---------------------------------------------------------------------------
-- Tickets point at the type
-- ---------------------------------------------------------------------------

ALTER TABLE complaints
  ADD COLUMN IF NOT EXISTS type_id uuid REFERENCES complaint_types (id);

DO $$
BEGIN
  IF to_regclass('public.complaint_subtypes') IS NOT NULL THEN
    UPDATE complaints c
       SET type_id = s.type_id
      FROM complaint_subtypes s
     WHERE s.id = c.subtype_id AND c.type_id IS NULL;
  END IF;
END $$;

-- A ticket with no category cannot be routed, so the column is required —
-- but only once every existing row has one.
ALTER TABLE complaints ALTER COLUMN type_id SET NOT NULL;

ALTER TABLE complaints DROP COLUMN IF EXISTS subtype_id;


-- ---------------------------------------------------------------------------
-- The sub-types themselves
-- ---------------------------------------------------------------------------

-- Nothing references them now. The targets a ticket was promised were copied
-- onto the ticket when it was raised, so dropping this rewrites no history.
DROP INDEX IF EXISTS complaint_subtypes_live;
DROP TABLE IF EXISTS complaint_subtypes;

COMMIT;
