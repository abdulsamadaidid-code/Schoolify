# Design system (Flutter)

**Authority:** [branding.md](branding.md) for implementation tokens + [design.md](design.md) for detailed component and interaction specs — Stitch exports under `Stitch UI/` are **visual reference only** (see [.cursor/rules/stitch-ui.mdc](../.cursor/rules/stitch-ui.mdc)).

**Code location:** [`schoolify_app/lib/core/theme/`](../schoolify_app/lib/core/theme/), [`schoolify_app/lib/core/design_system/`](../schoolify_app/lib/core/design_system/), [`schoolify_app/lib/core/ui/`](../schoolify_app/lib/core/ui/) (canonical Flutter package root is **`schoolify_app/`** only).

---

## Component inventory

| Widget / API | Role |
|--------------|------|
| `AppTheme.light()` / `AppTheme.dark()` | `ThemeData` + component themes (inputs, cards, nav, dialogs). |
| `SchoolifyColors` (`ThemeExtension`) | Accent, success, warning, surface tiers, ghost border, primary gradient stops. |
| `AppColors` | Raw palette constants — prefer theme in UI code. |
| `AppSpacing`, `AppRadii`, `AppTypography` | Spacing, radii (8–12px), type scale (Manrope + Inter via `google_fonts`). |
| `AppSurface` + `AppSurfaceTier` | Tonal page backgrounds (no 1px section dividers). |
| `SchoolifyCard` | Elevated panel on tonal base; optional ghost border. |
| `SchoolifyButton` + `SchoolifyButtonVariant` | Primary (gradient), secondary, tertiary, danger. |
| `SchoolifyTextField` | External label + 56px field. |
| `SchoolifyChip` | Filter-style chip on `secondaryContainer`. |
| `SchoolifyDataTable` | `DataTable` with row spacing bias (thin/no dividers). |
| `SchoolifyNavigationBar` | Thin wrapper over M3 `NavigationBar`. |
| `EmptyState` | Icon, title, body, optional CTA. |
| `EditorialLockup` | Headline + body with branded gap. |
| `AppBreakpoints`, `ConstrainedContent` | Responsive buckets + max content width on large screens. |

**Preview:** [`schoolify_app/lib/core/ui/dev/design_system_gallery.dart`](../schoolify_app/lib/core/ui/dev/design_system_gallery.dart) (dev-only; wire behind a route or flag when needed).

---

## Assumptions for other agents

1. **`onSecondaryContainer` text** — [branding.md](branding.md) specifies the secondary container fill (`#dae2fd`) but not label ink. Stitch DESIGN uses `#5c647a`; we encoded that as `AppColors.onSecondaryContainer` for readable contrast on chips/secondary buttons.
2. **Primary gradient** — Stitch calls for a subtle top→bottom gradient on primary CTAs; `SchoolifyColors` exposes `primaryGradientTop/Bottom` (aligned with primary / primary container). Dark theme reuses the same stops for now; revisit if product wants a dark-specific gradient.
3. **Ghost border** — Implemented as ~20% alpha of `outlineVariant` (light/dark), not a separate token in branding.
4. **Platform / entrypoint** — Production entry is `schoolify_app/lib/main.dart` → `bootstrap()` → `SchoolifyApp` + router. Use the gallery only for local QA (optional route), not as `home`.
5. **Riverpod** — Not wired in the design package; features should obtain `school_id` and async state in providers, not in these primitives.
6. **Accessibility** — Large tap targets (56px fields, 56px default primary button), external labels, semantic empty state. Prefer `SelectableText` for dense read-only data on web/desktop in feature screens (see theming skill).
7. **Glass nav / blur** — Stitch specifies glassmorphism for mobile bottom nav/FAB, but `SchoolifyNavigationBar` is currently a standard M3 bar. Track this as a **Wave 8 UI/UX improvement task**: add bottom-nav blur + opacity treatment in shell-level mobile navigation.

---

## File size

Per [docs/rules.md](rules.md), keep files under ~300 lines; split new widgets if they grow beyond that.
