# Research: Role-Based Dashboard

- **Decision**: Keep dashboard data behind `DashboardRepository` and role/window filtering in the server SQL.
- **Rationale**: Home already combines wallet, content, and role-specific actions.
- **Alternatives considered**: Duplicated role-specific screens were rejected; the existing role tile composition is simpler.
- **Branding**: Shop Branding is reached from Home's tile; its module is specified separately.
