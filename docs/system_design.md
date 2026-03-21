System Architecture (LOCKED)

Frontend:
- Flutter
- Feature-based structure
- Riverpod for state management

Backend:
- Supabase
- Multi-tenant (school_id required in all tables)

Rules:
- No agent can modify architecture without approval
- Shared components must be reused
- No duplication of logic

Data Flow:
UI → Provider → Repository → Supabase

Roles:
- Admin
- Teacher
- Parent