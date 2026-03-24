Brand Name: (Schoolify)

Detailed component and interaction specs: see [design.md](design.md).

Design Principles:
- Clean, minimal, modern SaaS UI
- Focus on clarity over decoration
- Designed for low-tech users (simple UX)
- Editorial, tonal-depth UI (no divider lines; use background tiers instead)

Colors:
- Primary: #003ea8
- Primary Container (Primary surfaces / active nav backgrounds): #0053db
- Secondary Container (secondary buttons / chips): #dae2fd
- On Surface (light text): #1a1c1c
- On Surface Variant (labels / metadata, light): #434655
- Surface (main background, light): #f9f9f9
- Surface Container Low (page sections / sidebar tier, light): #f3f3f4
- Surface Container Lowest (elevated cards, light): #ffffff
- Accent (curated highlights, e.g. emphasis tags): #ffb786
- Success (light): #15803d
- Success (dark): #22c55e
- Warning: #f59e0b
- Error: #ef4444
- Outline Variant (ghost borders, light): #c3c6d7

- Dark Background (surface): #0b1326
- Dark Secondary Layout (surface_container_low): #131b2e
- Dark Card Surface (surface_container): #171f33
- Dark High-Elevation Surface (surface_container_highest): #2d3449
- On Surface (dark text): #dae2fd
- On Surface Variant (labels / metadata, dark): #c2c6d6
- Outline Variant (ghost borders, dark): #424754
- Dark Primary (high-priority action color): #a4c9ff

Typography:
- Fonts:
  - Headings / editorial scale / numbers: Manrope
  - Body / labels: Inter
- Base sizing: 16px (1rem)
- Type Scale (Manrope):
  - Display-LG: 3.5rem, weight 800 (hero stats / large numbers)
  - Headline-MD: 1.75rem, weight 700 (page titles / section headers)
  - Title-LG: 1.375rem, weight 600 (card headers / modal headers)
  - Body-LG: 1.0rem, weight 400 (main reading text)
  - Label-MD: 0.75rem, weight 700 (form labels + all-caps utilities)
- Rules:
  - Pair `Headline-MD` with `Body-LG` using ~1.4rem spacing for a clean editorial lockup
  - Avoid tiny text; keep labels at `Label-MD` minimum
  - For lists and tables, prioritize readability over dense typography

UI Rules:
- Use card-based layouts
- Rounded corners (8–12px)
- Consistent padding (16px standard)
- Buttons must be large and clear
- Avoid clutter
- No-line rule: avoid 1px divider borders for sectioning; use background tier shifts instead
- Elevation rule: avoid shadow + border on the same card; prefer tonal layering (surface tiers)
- Mobile action sizing: primary buttons min 48px height (56px preferred)
- Inputs: large touch targets (56px height); labels external (not placeholder-only)

Components:
- Standard button style
- Standard input fields
- Reusable cards
- Consistent icons

Do not deviate from this design system unless explicitly told.