-- 002 · Home: the wallet figure, the slider and the ticker.
--
-- The slider and the ticker are content, not code: Crown Solar adds a row
-- with a picture or a line of text and a window it runs for, and Home shows
-- it. Nothing here needs a release.
--
-- Idempotent, like 001.

BEGIN;


-- ---------------------------------------------------------------------------
-- The wallet
-- ---------------------------------------------------------------------------

-- Every movement of money. The balance is never stored — it is derived from
-- these rows, so the figure on Home and the lines in the ledger can never
-- disagree.
CREATE TABLE IF NOT EXISTS wallet_entries (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id    uuid NOT NULL REFERENCES accounts (id),

  -- Human-readable, e.g. 'TX-0004'. What a partner quotes to CRM.
  reference     text NOT NULL,
  title         text NOT NULL,

  direction     text NOT NULL CHECK (direction IN ('credit', 'debit')),

  type          text NOT NULL CHECK (type IN (
                  'send_cash', 'cash_request', 'scan_prize',
                  'spin_prize', 'returned', 'crm_adjustment'
                )),

  -- 'held' is money that has left the available balance but settled nowhere:
  -- the receiver has not accepted it yet. 'rejected' never moved at all.
  state         text NOT NULL DEFAULT 'cleared'
                  CHECK (state IN ('cleared', 'held', 'rejected')),

  -- Paisa, never rupees. Money is counted in whole units of the smallest
  -- denomination so no balance is ever a rounded float.
  amount_paisa  bigint NOT NULL CHECK (amount_paisa >= 0),

  counterparty_account_id uuid REFERENCES accounts (id),

  posted_at     timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now(),

  UNIQUE (account_id, reference)
);

CREATE INDEX IF NOT EXISTS wallet_entries_by_account
  ON wallet_entries (account_id, posted_at DESC);


-- ---------------------------------------------------------------------------
-- Home's slider
-- ---------------------------------------------------------------------------

-- One slide. A slide is a picture with a window it runs for; the eyebrow and
-- headline are optional text laid over it, so a picture-only slide and a
-- text-only card are both just rows here.
CREATE TABLE IF NOT EXISTS promo_slides (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Where the picture is. Null for a text-only slide, which renders on the
  -- brand gradient exactly as it does today.
  image_url   text,

  eyebrow     text,
  headline    text,

  -- Who sees it. 'all' is every partner; the rest target one role.
  audience    text NOT NULL DEFAULT 'all'
                CHECK (audience IN ('all', 'installer', 'retailer',
                                    'wholesaler', 'distributor')),

  -- The window the slide runs for. A null end never expires.
  starts_at   timestamptz NOT NULL DEFAULT now(),
  ends_at     timestamptz,

  -- Order within the slider, lowest first.
  position    integer NOT NULL DEFAULT 0,

  active      boolean NOT NULL DEFAULT true,
  created_at  timestamptz NOT NULL DEFAULT now(),

  -- A slide has to show something.
  CHECK (image_url IS NOT NULL OR headline IS NOT NULL),
  CHECK (ends_at IS NULL OR ends_at > starts_at)
);

CREATE INDEX IF NOT EXISTS promo_slides_live
  ON promo_slides (audience, position)
  WHERE active;


-- ---------------------------------------------------------------------------
-- Home's ticker
-- ---------------------------------------------------------------------------

-- One announcement in the running line. Its two colours are carried with it,
-- so a scheme can run in its own colours without a release.
CREATE TABLE IF NOT EXISTS ticker_messages (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  message           text NOT NULL,

  -- '#RRGGBB'. Null means the app's own ticker colours, which is what every
  -- message uses unless someone deliberately overrides them.
  text_colour       text CHECK (text_colour IS NULL OR text_colour ~ '^#[0-9A-Fa-f]{6}$'),
  background_colour text CHECK (background_colour IS NULL OR background_colour ~ '^#[0-9A-Fa-f]{6}$'),

  audience          text NOT NULL DEFAULT 'all'
                      CHECK (audience IN ('all', 'installer', 'retailer',
                                          'wholesaler', 'distributor')),

  starts_at         timestamptz NOT NULL DEFAULT now(),
  ends_at           timestamptz,

  position          integer NOT NULL DEFAULT 0,

  active            boolean NOT NULL DEFAULT true,
  created_at        timestamptz NOT NULL DEFAULT now(),

  CHECK (ends_at IS NULL OR ends_at > starts_at)
);

CREATE INDEX IF NOT EXISTS ticker_messages_live
  ON ticker_messages (audience, position)
  WHERE active;

COMMIT;
