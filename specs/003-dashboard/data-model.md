# Data Model: Role-Based Dashboard

- **Dashboard**: available balance, held note, slides, tickers, scan subtitle.
- **WalletEntry** (`wallet_entries`): direction, type, state (cleared/held/rejected), amount in paisa; available and held totals are derived, never stored.
- **PromoSlide** (`promo_slides`): id, audience, active flag, active window, position, optional image, eyebrow, headline (image or headline required).
- **TickerMessage** (`ticker_messages`): message, optional `#RRGGBB` text/background colours, audience, active flag, active window, position.
- **HomeTile**: label, icon, role-visible action, and optional pending count badge.
