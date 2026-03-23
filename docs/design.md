# Schoolify Design System

> Synthesized from all Stitch UI screens: `stitch_school_management_mvp` (12 screens) and `stitch_login_page` (30+ screens), including three named theme variants — **Scholar Contrast** (light), **Scholar Contrast Dark** (dark), and **Academic Atelier** (light).

---

## 1. Creative North Star

**"The Architectural Academic"**

School management software is typically cluttered and clinical. This design system rejects that. The UI is treated as a **high-end editorial experience** — authoritative, breathable, and intentionally calm. We achieve this through:

- **Intentional Asymmetry** — varying column widths and offset layouts instead of rigid grids
- **Tonal Depth** — background color shifts define structure, not borders
- **Thumb-First Mobile** — all interactive surfaces are large, tactile, and reachable
- **Data as Statement** — numbers and stats are hero elements, not just cells

---

## 2. Color System

### Light Theme (Scholar Contrast / Academic Atelier)

| Token | Value | Purpose |
|-------|-------|---------|
| `primary` | `#003ea8` / `#0053db` | Action anchor — buttons, CTAs, active states |
| `primary-container` | `#0053db` | High-visibility mobile actions |
| `surface` | `#f9f9f9` / `#f7f9fb` | App base background |
| `surface-container-low` | `#f3f3f4` / `#f0f4f7` | Sidebars, grouping sections |
| `surface-container-lowest` | `#ffffff` | Cards, lifted content, active workspace |
| `surface-container` | `#eeeeee` / `#e8eff3` | Recessed/nested child elements |
| `surface-container-high` | `#e8e8e8` | Table headers, contextual grouping |
| `on-surface` | `#1a1c1c` / `#2a3439` | Primary text (never pure black) |
| `on-surface-variant` | `#434655` | Form labels, metadata, secondary text |
| `outline-variant` | `#c3c6d7` | Ghost borders (max 20% opacity) |

### Dark Theme (Scholar Contrast Dark / Nocturnal Intellectual)

| Token | Value | Purpose |
|-------|-------|---------|
| `background` | `#0b1326` | Deep navy-slate canvas |
| `surface` | `#0b1326` | Base layer |
| `surface-container-low` | `#131b2e` | Secondary layout sections |
| `surface-container` | `#171f33` | Component/card surfaces |
| `surface-container-highest` | `#2d3449` | Interactive/high-elevation surfaces |
| `primary` | `#a4c9ff` | Lighthouse color — high-priority actions only |
| `tertiary` | `#ffb786` | Accent for highlighted/curated content |
| `on-surface` | `#dae2fd` | Primary text (not pure white) |
| `on-surface-variant` | `#c2c6d6` | Metadata, secondary labels |
| `outline-variant` | `#424754` | Ghost borders (max 20% opacity) |

### Semantic / Status Colors

| Purpose | Light | Dark | Background |
|---------|-------|------|------------|
| Success/Present | `#15803d` | `#22c55e` | `#dcfce7` |
| Error/Absent | `#ef4444` | `#ef4444` | Red-100 |
| Warning/Late | `#f59e0b` | `#f59e0b` | Orange-100 |
| Info | Blue-600 | Blue-400 | Blue-100 |

### The "No-Line" Rule

> **1px solid borders for sectioning content are strictly prohibited.**

Structure is created by background color transitions, not drawn lines. To separate a sidebar from content, shift from `surface` to `surface-container-low`. The human eye perceives value difference as a boundary.

---

## 3. Typography

### Font Stack

| Role | Family | Use |
|------|--------|-----|
| Display / Headlines | **Manrope** | All headings, stats, numbers |
| Body / Labels | **Inter** | Reading text, form labels, metadata |
| Icons | **Material Symbols Outlined** | All UI icons |

### Type Scale

| Token | Size | Weight | Use Case |
|-------|------|--------|----------|
| `display-lg` | 3.5rem | 800 ExtraBold | Hero stats, large data (Total Students) |
| `headline-md` | 1.75rem | 700 Bold | Section headers, page titles |
| `title-lg` | 1.375rem | 600 SemiBold | Card titles, modal headers |
| `body-lg` | 1.0rem | 400 Regular | Primary reading text, descriptions |
| `label-md` | 0.75rem | 700 Bold | Form labels, all-caps utility text |

**Key rules:**
- Never go below `body-md` (0.875rem) for instructional text
- Pair `headline-md` with `body-lg` using `1.4rem` spacing for editorial lockups
- Use Manrope ExtraBold for all numbers and statistics
- Never use 100% black — always use `on-surface` token

---

## 4. Elevation & Depth

Depth is expressed through **tonal layering**, never heavy drop shadows.

### Surface Stack (Light)
```
surface-container-lowest (#fff)   ← cards, lifted elements
surface-container-low  (#f0f4f7)  ← sidebars, groupings
surface              (#f7f9fb)    ← page base
```

### Surface Stack (Dark)
```
surface-container-highest (#2d3449) ← top/interactive
surface-container         (#171f33) ← cards
surface-container-low     (#131b2e) ← sections
surface                   (#0b1326) ← canvas
```

### Shadow Rules

- **Standard cards:** No shadow. Background color difference is enough.
- **Floating elements** (modals, dropdowns, FABs): `0 20px 40px rgba(42, 52, 57, 0.06)` — tinted with `on-surface`, never pure black
- **Colored shadows** on CTAs: `shadow-primary/20` (20% opacity primary tint)

### The "Ghost Border" Fallback

When WCAG requires a visible boundary: `1px solid outline-variant at 10–20% opacity`. It should feel like a suggestion, not a hard stop.

---

## 5. Spacing

All spacing follows a **base-4 (1rem) linear scale**.

| Token | Value | Use |
|-------|-------|-----|
| `spacing-1` | 0.25rem | Micro gaps, icon padding |
| `spacing-2` | 0.5rem | Item separation within groups |
| `spacing-3` | 0.75rem | Compact list gutters |
| `spacing-4` | 1rem | Base unit — internal padding, list items |
| `spacing-6` | 1.5rem | Card internal sections |
| `spacing-8` | 2rem | Section dividers (replaces `<hr>`) |
| `spacing-10` | 2.5rem | Major section breathing room |
| `spacing-12` | 3rem | Section margins |
| `spacing-24` | 8.5rem | Bottom-of-page padding (clears mobile nav) |

---

## 6. Components

### Buttons

| Type | Background | Text | Border Radius | Min Height |
|------|-----------|------|---------------|------------|
| Primary | Gradient `primary` → `primary-dim` at 135° | `on-primary` (#fff) | `xl` (0.75rem) | **56px** (48px minimum) |
| Secondary | Transparent | `on-surface` | `xl` | 48px |
| Ghost/Tertiary | None | `primary` color | — | 44px |
| Icon | Transparent | `on-surface-variant` | `full` | 40px |

**Primary button gradient (light):** `linear-gradient(135deg, #0053db, #003ea8)`
**Primary button gradient (dark):** `linear-gradient(135deg, primary, primary-container)`

### Input Fields

- **Height:** 56px (large touch target)
- **Label:** Always external, never placeholder-only. Use `label-md` in `on-surface-variant`. Sits `0.5rem` above the field.
- **Resting:** `surface-container-lowest` background, ghost border at 10% opacity
- **Focus (light):** `2px solid primary` — no glow, clean lines
- **Focus (dark):** `outline-variant` ghost border at 40% opacity + `primary` 2px glow at 10% opacity
- **Error:** `error` (#ffb4ab) text, `error-container` background shift

### Cards & Containers

```
Standard Card:
  background: surface-container-lowest
  border-radius: xl (0.75rem) or lg (0.5rem)
  padding: spacing-6 (1.5rem)
  shadow: none (use bg shift)
  border: ghost border at 10–15% opacity (optional)

Stat Card:
  flex justify-between
  Icon: p-2 bg-primary/10 rounded-lg + Material Symbol at 24px
  Value: display-lg Manrope ExtraBold
  Label: label-md on-surface-variant

Schedule/Event Card:
  border-l-4 [category color] for visual categorization
  flex items-center justify-between
  padding: spacing-4
```

### Lists & Tables

**The No-Divider Rule:** Never use `<hr>` or `1px` lines between items. Use `spacing-4` vertical whitespace. If more separation is needed, increase to `spacing-6`.

**Tables:**
- Header row: `surface-container-high` background, `label-md` uppercase text
- Body rows: `surface-container-lowest` for all rows (no alternating colors)
- Row separation: ghost border at 10% opacity or `spacing-2` air
- Data cells: `body-md`, wrapped in `overflow-x-auto` container

### Status Chips / Attendance Badges

```
border-radius: full (9999px)
padding: px-2.5 py-0.5
font: label-md (text-xs font-bold)
```
Use high-contrast background+text combinations, not just color alone (color-blind accessibility):
- Present: `#dcfce7` bg / `#15803d` text
- Absent: Red-100 bg / Red-700 text
- Late: Orange-100 bg / Orange-600 text

### Navigation

**Sidebar (Desktop):**
- Width: `w-64` (256px), fixed height, flex-col
- Active item: `bg-primary/10 text-primary` with `md` roundedness (0.375rem)
- Hover: `bg-slate-100` / `dark:bg-slate-800`
- No item borders or dividers — spacing only

**Bottom Nav (Mobile):**
- `fixed bottom-0 left-0 right-0`
- Glassmorphism: `surface-container-lowest` at 80% opacity + `backdrop-blur: 20px`
- Labels: `text-[10px] font-bold uppercase tracking-widest`
- Item: `flex flex-col items-center gap-1`
- Padding bottom: `spacing-24` on last page element to clear this bar

**Header:**
- Height: 56–64px, `sticky top-0 z-10`
- Search bar with left icon, `pl-10 pr-4 py-1.5`
- Breadcrumbs: `flex items-center gap-2` with `chevron_right` dividers

### Icons

- Font: **Material Symbols Outlined**
- Sizes: 20px (inline), 22px (list), 24px (standard), 28px (stat cards)
- Filled variant activated with `font-variation-settings: 'FILL' 1` for active states
- Icon containers for stat cards: `p-2 bg-primary/10 rounded-lg`

---

## 7. Layout Patterns

### Full App Shell
```
flex h-screen overflow-hidden
├── Sidebar: w-64 flex-shrink-0 (desktop only)
└── Main: flex-1 flex-col overflow-y-auto
    ├── Header: h-14 sticky top-0
    └── Content: flex-1 p-6
```

### Dashboard Grid
```
grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6
```

### Responsive Content Split
```
grid grid-cols-1 xl:grid-cols-3 gap-8
```

### Timetable Grid (Custom)
```css
grid-template-columns: 80px repeat(5, 1fr);
```

### Mobile-First Card Scroll
```
flex gap-4 overflow-x-auto pb-4
  Card: min-w-[280px] shrink-0
```

---

## 8. Screen Inventory

| Screen | Role | Key Features |
|--------|------|--------------|
| `login_page` | All users | Auth entry, school branding |
| `admin_dashboard` / `school_admin_dashboard_1/2` | Admin | Stat cards, quick actions, recent activity |
| `dashboard_home` | Admin | Full overview, announcements, schedule |
| `teacher_home_dashboard` / `_v2` | Teacher | Class summary, today's schedule, quick mark |
| `teacher_attendance_flow` / `_v2` | Teacher | Mark attendance per class, P/A/L chips |
| `teacher_grading_interface` / `_v2` | Teacher | Grade entry table, subject filter |
| `teacher_student_list` / `_v2` | Teacher | Student roster for their classes |
| `teacher_announcements_view` / `_v2` | Teacher | Read/post announcements |
| `parent_home_dashboard` / `_v2` | Parent | Child overview, fees, recent grades |
| `parent_attendance_view` / `_v2` | Parent | Child's attendance history |
| `parent_grades_view` / `_v2` | Parent | Child's grade breakdown |
| `parent_fees_view` / `_v2` | Parent | Fee status, payment history |
| `parent_announcements_view` / `_v2` | Parent | School announcements |
| `student_management_list` / `student_directory` | Admin | Searchable student list, filters |
| `classes_timetable_management` / `class_detail_view` | Admin | Timetable grid, class detail |
| `mark_attendance` | Teacher/Admin | Bulk attendance marking |
| `add_student_form` | Admin | New student onboarding |
| `finance_fee_tracking_dashboard` | Admin | Fee collection stats, outstanding |
| `announcements_page` | Admin | Create/manage announcements |
| `classes_page` | Admin | Class management overview |

---

## 9. Do's and Don'ts

### Do
- Use `on-surface` instead of `#000000` for all text
- Set **56px minimum** for primary action buttons; **48px** absolute minimum for any tap target
- Use Manrope ExtraBold for all numerical data — make it look like a statement
- Add `spacing-24` bottom padding on all mobile screens to clear the nav bar
- Use `primary/10` background tints for icon containers and active nav items
- Use background color shifts to define regions — never lines
- Pair headlines with `body-lg` at `1.4rem` spacing for editorial lockups

### Don't
- Don't use `#000000` — always use `on-surface` token
- Don't use `1px` borders to divide table rows, sidebar items, or list entries
- Don't put shadows on static cards — reserve shadows for floating elements only
- Don't use alternating table row colors
- Don't use placeholder-only form labels
- Don't use sharp corners (`rounded-none`) — minimum is `rounded` (0.25rem), prefer `rounded-lg` or `rounded-xl`
- Don't crowd screens — if it feels full, switch to a surface tier or a new tab
- Don't use `on-surface` off-white as pure white on dark themes (causes halation)
- Don't overuse the primary blue — if everything is blue, nothing is an action

---

## 10. Theme Variants Summary

| Variant | Mode | Personality | Primary Color |
|---------|------|-------------|---------------|
| Scholar Contrast | Light | Architectural, editorial, white-space driven | `#003ea8` |
| Academic Atelier | Light | Atelier, premium workspace, breathable | `#0053db` |
| Scholar Contrast Dark | Dark | Nocturnal intellectual, library calm | `#a4c9ff` |
