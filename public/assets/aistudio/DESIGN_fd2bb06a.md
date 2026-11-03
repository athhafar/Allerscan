---
name: Clinical Clarity
colors:
  surface: '#f9f9ff'
  surface-dim: '#d3daef'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3ff'
  surface-container: '#e9edff'
  surface-container-high: '#e1e8fd'
  surface-container-highest: '#dce2f7'
  on-surface: '#141b2b'
  on-surface-variant: '#3e4941'
  inverse-surface: '#293040'
  inverse-on-surface: '#edf0ff'
  outline: '#6e7a71'
  outline-variant: '#bdcabf'
  surface-tint: '#006c44'
  primary: '#006a43'
  on-primary: '#ffffff'
  primary-container: '#008655'
  on-primary-container: '#f6fff6'
  inverse-primary: '#71dba2'
  secondary: '#b61722'
  on-secondary: '#ffffff'
  secondary-container: '#da3437'
  on-secondary-container: '#fffbff'
  tertiary: '#825100'
  on-tertiary: '#ffffff'
  tertiary-container: '#a36700'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#8df8bd'
  primary-fixed-dim: '#71dba2'
  on-primary-fixed: '#002112'
  on-primary-fixed-variant: '#005232'
  secondary-fixed: '#ffdad7'
  secondary-fixed-dim: '#ffb3ad'
  on-secondary-fixed: '#410004'
  on-secondary-fixed-variant: '#930013'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f9f9ff'
  on-background: '#141b2b'
  surface-variant: '#dce2f7'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.005em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-md-medium:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  caption:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes an ultra-clean, reassuring, and functionally minimalist mobile interface tailored for rapid allergen identification in food and consumer products. The target audience includes individuals managing food sensitivities, parents, and caregivers who require immediate, unambiguous verification under varied real-world lighting and stress levels.

The emotional tone balances clinical precision with quiet reassurance:
- **Calm Authority:** Clean white space and neutral framing eliminate visual anxiety while handling potentially life-threatening allergen alerts.
- **Unambiguous Legibility:** High-contrast information hierarchy and standardized safety indicators communicate danger levels in milliseconds.
- **Modern Restraint:** Avoids decorative distractions; every visual element directly serves identification, scan processing, or user profile curation in Bahasa Indonesia.

## Colors

The palette utilizes a clinical off-white canvas with purposeful semantic status indicators to deliver instantaneous risk recognition.

### Palette Architecture
- **Primary Brand (`#2E9E6B`):** Represents focused safety, active navigational states, confirmed selections, and primary CTA actions.
- **Canvas & Elevation Backgrounds:**
  - Base Screen Canvas: `#FAFAFA`
  - Elevated Cards / Modals: `#FFFFFF`
  - Subtle Framing Borders: `#EEEEEE` (hairline) and `#E5E7EB` (interactive controls)
- **Neutral Typography:**
  - Primary Text: `#111827` (headings, high-priority readouts)
  - Secondary Text: `#6B7280` (metadata, ingredient lists, subtitles)
  - Tertiary / Placeholder Text: `#9CA3AF` (field hints, inactive icon strokes)

### Semantic Risk Matrix
- **Tinggi (High Risk):**
  - Solid Accent: `#EF4444`
  - Soft Container: `#FEF2F2`
  - Container Border: `#FEE2E2`
- **Sedang (Medium Risk):**
  - Solid Accent: `#F59E0B`
  - Soft Container: `#FFFBEB`
  - Container Border: `#FEF3C7`
- **Aman (Safe / Low Risk):**
  - Solid Accent: `#22C55E`
  - Soft Container: `#F0FDF4`
  - Container Border: `#DCFCE7`

## Typography

The type scale relies exclusively on `Inter` to deliver systematic clarity, optimal screen hinting, and tall x-height for readability at compact viewports. 

### Usage Guidelines
- **Headings (`headline-lg` / 24px):** Dedicated to screen titles (e.g., "Hasil Pemindaian", "Profil Alergi", "Riwayat Pindai").
- **Section Headers (`headline-sm` / 18px):** Section groupings inside cards or multi-block lists (e.g., "Bahan Terdeteksi", "Pengaturan Akun").
- **Body (`body-lg` / 16px):** Primary scanning output, highlighted ingredient entries, and critical instruction paragraphs.
- **Secondary Body (`body-md` / 14px):** Product brand names, timestamps, and contextual informational notes.
- **Captions & Micro-labels (`label-sm` / 12px, `caption` / 12px):** All badge statuses, bottom navigation indicators, allergen pill titles, and metadata stamps.

## Layout & Spacing

The layout is built for mobile viewports (primarily 390x844pt) using an 8pt layout grid (with a 4pt subgrid for fine alignment of icons and text offsets).

### Screen Geometry & Padding
- **Outer Canvas Margins:** 20px (`1.25rem`) fixed horizontal screen padding across all standard screens to safeguard edge tap targets.
- **Component Padding Scale:**
  - Compact chips and badges: `space-xs` (4px) vertical, `space-sm` (8px) horizontal.
  - Buttons and Inputs: 12px vertical, `space-md` (16px) horizontal.
  - Cards and Panels: `space-md` (16px) internal padding throughout.
- **Vertical Rhythm:** Sections and standalone cards maintain `space-md` (16px) separation; related atomic items stack with `space-sm` (8px) gaps.
- **Viewport Constraints:** Floating buttons and bottom navigation respect mobile safe areas (home indicator bottom padding: 34px).

## Elevation & Depth

Visual hierarchy uses flat physical separation: pure white cards resting on an off-white substrate (`#FAFAFA`), paired with featherlight shadows and hairline borders.

### Surface Elevation Levels
- **Base Surface (`Level 0`):** `#FAFAFA` — Canvas foundation for views.
- **Card Surface (`Level 1`):** `#FFFFFF` — Border: `1px solid #EEEEEE`. Shadow: `0 2px 8px rgba(0, 0, 0, 0.04)`. Used for content cards, allergen breakdowns, and history items.
- **Floating Modals & Sheets (`Level 2`):** `#FFFFFF` — Border: `1px solid #E5E7EB`. Shadow: `0 8px 24px rgba(0, 0, 0, 0.08)`. Applied to bottom sheets displaying detailed ingredient warnings.
- **Fixed Navigation Chrome:** Solid `#FFFFFF` background with a top border hairline (`1px solid #EEEEEE`) without blur or drop shadow, creating a stable touch zone.

## Shapes

Corner radii establish a structured yet friendly tactile feel.

### Corner Radii Architecture
- **Cards & Content Enclosures:** 16px (`1rem`) border radius, matching the curved profile of contemporary mobile viewports.
- **Action Controls & Fields:** 12px (`0.75rem`) border radius for primary action buttons, text input fields, and search inputs.
- **Status Badges, Chips & Tags:** Fully pill-shaped (`9999px`) to immediately communicate categorized status rather than clickable surfaces.

## Components

### Buttons
- **Primary Button:** Background `#2E9E6B`, text `#FFFFFF` (`label-md`), height 48px, radius 12px. Pressed state: `#26855A`.
- **Secondary / Ghost Button:** Background transparent, border `1.5px solid #E5E7EB`, text `#111827`, height 48px, radius 12px.
- **Floating Action / Scanner Shutter:** Circular 64px button, background `#2E9E6B`, with centered white outline camera icon.

### Status Badges & Chips
- **Aman (Safe):** Background `#F0FDF4`, border `1px solid #DCFCE7`, text `#22C55E` (`label-sm`). Icon: `CheckCircle2`.
- **Sedang (Medium):** Background `#FFFBEB`, border `1px solid #FEF3C7`, text `#F59E0B` (`label-sm`). Icon: `AlertTriangle`.
- **Bahaya / Tinggi (High):** Background `#FEF2F2`, border `1px solid #FEE2E2`, text `#EF4444` (`label-sm`). Icon: `AlertOctagon`.
- **Allergen Filter Chips:** Pill shape with `space-sm` (8px) horizontal padding. Selected: background `#2E9E6B`, text `#FFFFFF`. Unselected: background `#FFFFFF`, border `1px solid #E5E7EB`, text `#6B7280`.

### Cards & Result Containers
- **Product Result Card:** Background `#FFFFFF`, radius 16px, padding 16px, border `1px solid #EEEEEE`, elevation `0 2px 8px rgba(0, 0, 0, 0.04)`. Displays scanned product title (`headline-sm`), brand name (`body-md`), and trailing status badge.
- **Ingredient List Row:** Divided by `1px solid #F3F4F6` hairline rules. Text: `#111827`. Matches flagged allergens in bold with colored indicator dots (4px diameter).

### Input Fields
- **Search & Text Input:** Height 48px, background `#FFFFFF`, radius 12px, border `1px solid #E5E7EB`, placeholder `#9CA3AF`, text `#111827`. Focused state: border `1.5px solid #2E9E6B` without drop shadow rings.

### Selection Controls (Checkboxes & Radios)
- **Allergen Checkbox:** Size 20x20px, radius 6px. Unchecked: `1.5px solid #D1D5DB`. Checked: `#2E9E6B` fill with white 2px stroke checkmark.

### Bottom Navigation Bar
- Height 64px (excluding device safe inset), background `#FFFFFF`, top border `1px solid #EEEEEE`.
- 3 Tabs arranged symmetrically:
  1. **Pindai (Scan):** Outline camera/viewfinder icon.
  2. **Riwayat (History):** Outline clock/receipt icon.
  3. **Profil (Profile):** Outline user icon.
- Active state: `#2E9E6B` icon and label (`label-sm`). Inactive state: `#9CA3AF`.

### Iconography Rules
- Lucide-style outline icons with a consistent `2px` stroke width and rounded joins (`stroke-linecap="round"`, `stroke-linejoin="round"`).
- Sizing tokens: Standard 20x20px inside buttons/inputs, 24x24px for navigation tabs and top app bar actions.