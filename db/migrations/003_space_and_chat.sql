-- 003 · Space and Chat.
--
-- Space posts are NOT written from this app. Another Crown Solar application
-- publishes them into `space_posts`; the partner app only reads them, and
-- writes nothing but its own hearts and comments. There is deliberately no
-- endpoint here that creates a post.
--
-- Chat is the other way round: every row is written by a partner.
--
-- Idempotent, like 001 and 002.

BEGIN;


-- ---------------------------------------------------------------------------
-- Space
-- ---------------------------------------------------------------------------

-- One broadcast from Crown Solar. Owned by the publishing application.
CREATE TABLE IF NOT EXISTS space_posts (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  title       text NOT NULL,
  body        text NOT NULL,
  image_url   text,

  -- Who it reaches. 'trade' is wholesalers and distributors together, which
  -- is how the app groups them.
  audience    text NOT NULL DEFAULT 'all'
                CHECK (audience IN ('all', 'installer', 'retailer', 'trade')),

  -- Unpublishing hides a post without deleting the conversation under it.
  published   boolean NOT NULL DEFAULT true,

  posted_at   timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS space_posts_live
  ON space_posts (audience, posted_at DESC)
  WHERE published;


-- A heart is a row, not a counter: the count is COUNT(*) and "did I heart
-- this" is whether my row exists. A stored counter would drift.
CREATE TABLE IF NOT EXISTS space_post_hearts (
  post_id     uuid NOT NULL REFERENCES space_posts (id) ON DELETE CASCADE,
  account_id  uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  created_at  timestamptz NOT NULL DEFAULT now(),

  -- One heart per partner per post, enforced here rather than in code.
  PRIMARY KEY (post_id, account_id)
);


-- Comments and the replies under them, in one table.
--
-- `parent_comment_id` null means a top-level comment. The app shows exactly
-- two levels, so a reply's parent must itself be top-level; that is enforced
-- by the trigger below rather than left to whoever writes next.
CREATE TABLE IF NOT EXISTS space_comments (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id           uuid NOT NULL REFERENCES space_posts (id) ON DELETE CASCADE,
  parent_comment_id uuid REFERENCES space_comments (id) ON DELETE CASCADE,

  -- Null when Crown Solar staff wrote it rather than a partner.
  account_id        uuid REFERENCES accounts (id),

  -- Kept alongside the account so a business renaming itself does not rewrite
  -- what it said months ago.
  author_name       text NOT NULL,

  body              text NOT NULL,

  -- True when Crown Solar itself wrote it, which the app tags "Admin".
  official          boolean NOT NULL DEFAULT false,

  posted_at         timestamptz NOT NULL DEFAULT now(),
  created_at        timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS space_comments_by_post
  ON space_comments (post_id, posted_at);

CREATE INDEX IF NOT EXISTS space_comments_by_parent
  ON space_comments (parent_comment_id, posted_at)
  WHERE parent_comment_id IS NOT NULL;

CREATE OR REPLACE FUNCTION space_comments_two_levels() RETURNS trigger AS $$
BEGIN
  IF NEW.parent_comment_id IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM space_comments
       WHERE id = NEW.parent_comment_id
         AND parent_comment_id IS NOT NULL
    ) THEN
      RAISE EXCEPTION 'a reply cannot be made to a reply';
    END IF;
    -- A reply belongs to the same post as the comment it answers.
    IF NOT EXISTS (
      SELECT 1 FROM space_comments
       WHERE id = NEW.parent_comment_id AND post_id = NEW.post_id
    ) THEN
      RAISE EXCEPTION 'a reply must sit under a comment on the same post';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS space_comments_two_levels ON space_comments;
CREATE TRIGGER space_comments_two_levels
  BEFORE INSERT OR UPDATE ON space_comments
  FOR EACH ROW EXECUTE FUNCTION space_comments_two_levels();

DROP TRIGGER IF EXISTS space_posts_set_updated_at ON space_posts;
CREATE TRIGGER space_posts_set_updated_at
  BEFORE UPDATE ON space_posts
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();


-- ---------------------------------------------------------------------------
-- Chat
-- ---------------------------------------------------------------------------

-- One conversation between two parties, stored once rather than once per
-- side — a message sent by one really does appear for the other.
--
-- A party is addressed the way the app already addresses it: a partner by
-- their ten national digits, a Crown Solar team as 'dept:<name>'. The pair is
-- stored in sorted order so (A,B) and (B,A) are the same row.
CREATE TABLE IF NOT EXISTS chat_threads (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  party_low       text NOT NULL,
  party_high      text NOT NULL,

  created_at      timestamptz NOT NULL DEFAULT now(),

  -- Null until someone speaks. Drives the list's ordering.
  last_message_at timestamptz,

  UNIQUE (party_low, party_high),
  CHECK (party_low < party_high)
);

CREATE INDEX IF NOT EXISTS chat_threads_by_party_low
  ON chat_threads (party_low, last_message_at DESC);
CREATE INDEX IF NOT EXISTS chat_threads_by_party_high
  ON chat_threads (party_high, last_message_at DESC);


CREATE TABLE IF NOT EXISTS chat_messages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id       uuid NOT NULL REFERENCES chat_threads (id) ON DELETE CASCADE,

  -- Who said it, in the same address form as the thread's two parties.
  sender_address  text NOT NULL,

  body            text NOT NULL,

  status          text NOT NULL DEFAULT 'sent'
                    CHECK (status IN ('sending', 'sent', 'delivered', 'read')),

  sent_at         timestamptz NOT NULL DEFAULT now(),
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS chat_messages_by_thread
  ON chat_messages (thread_id, sent_at);


-- How far each side has read. Unread is then "messages after my mark that I
-- did not send" — a count that cannot drift out of step with the messages.
CREATE TABLE IF NOT EXISTS chat_thread_reads (
  thread_id         uuid NOT NULL REFERENCES chat_threads (id) ON DELETE CASCADE,
  participant_address text NOT NULL,
  last_read_at      timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (thread_id, participant_address)
);


-- Keeps last_message_at true without anyone remembering to set it.
CREATE OR REPLACE FUNCTION chat_touch_thread() RETURNS trigger AS $$
BEGIN
  UPDATE chat_threads
     SET last_message_at = NEW.sent_at
   WHERE id = NEW.thread_id
     AND (last_message_at IS NULL OR last_message_at < NEW.sent_at);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS chat_messages_touch_thread ON chat_messages;
CREATE TRIGGER chat_messages_touch_thread
  AFTER INSERT ON chat_messages
  FOR EACH ROW EXECUTE FUNCTION chat_touch_thread();

COMMIT;
