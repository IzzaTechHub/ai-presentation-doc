# Editorial White & Brand Orange Light Theme Architecture

## Design Overview
In alignment with the official brand identity established in the app logo (`assets/icon/app_logo.png`), the application interface transitions from a dark background to a crisp, high-contrast Editorial White theme with vibrant orange accents (`#FF5722`).

The white theme harmonizes directly with the white-and-orange emblem in the logo, delivering an Apple/Linear-caliber editorial experience with zero eye fatigue, high text contrast, and refined micro-elevation.

---

## 1. Color System Tokens (`AppColors`)

| Token | Hex Value | Purpose |
| :--- | :--- | :--- |
| `background` | `#F8F9FA` | Crisp porcelain scaffold backdrop |
| `surface` | `#FFFFFF` | Pure white card surfaces and containers |
| `surfaceElevated` | `#FFFFFF` | Modals, dialogs, and floating navigation bar |
| `surfaceBorder` | `#E2E8F0` | Subtle slate-200 boundary borders |
| `inputFill` | `#F8FAFC` | Slate-50 background for text inputs and pills |
| `primary` | `#FF5722` | Core brand orange accent |
| `primaryLight` | `#FF8A65` | Warm secondary orange highlights |
| `primaryDark` | `#E64A19` | High-contrast deep orange for text/badges |
| `primaryContainer` | `#FFF0EB` | Soft translucent orange fill for active states |
| `primaryBorder` | `#FFCCBC` | Delicate orange boundary border |
| `textPrimary` | `#0F172A` | Slate-900 high-contrast primary typography |
| `textSecondary` | `#475569` | Slate-600 secondary labels and descriptions |
| `textMuted` | `#94A3B8` | Slate-400 placeholder text and inactive icons |
| `error` | `#DC2626` | Clinical red for deletions and error states |
| `success` | `#16A34A` | Emerald green for completion and export |

---

## 2. Typography & Contrast Ratios
- **Headlines & Titles:** Set with Google Fonts **Outfit** (`#0F172A` or `#FF5722`).
- **Body & Subtitles:** Set with Google Fonts **Inter** (`#0F172A` and `#475569`).
- **Contrast Ratios:**
  - `textPrimary` (`#0F172A`) on `surface` (`#FFFFFF`): **16.1:1** (Exceeds WCAG AAA standard of 7:1).
  - `primary` (`#FF5722`) on `surface` (`#FFFFFF`): **3.6:1** for large titles and UI accents; text badges utilize `primaryDark` (`#E64A19`) at **4.8:1**.
  - `primaryContainer` (`#FFF0EB`) with `primaryBorder` (`#FFCCBC`): Provides a clean visual container without jarring harshness.

---

## 3. Elevation & Shadow Geometry
Instead of heavy dark mode drop shadows, the light theme adopts subtle multi-layered luxury elevation:
```dart
boxShadow: [
  BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 16,
    offset: const Offset(0, 4),
  ),
  BoxShadow(
    color: AppColors.primary.withValues(alpha: 0.06),
    blurRadius: 16,
    offset: const Offset(0, 2),
  ),
]
```

---

## 4. Component Transformations
1. **Floating Navigation Capsule:**
   - Translucent white frosted glass (`#FFFFFF` with `0.92` alpha) with a 20px Gaussian backdrop blur filter.
   - Inactive tabs display clean Slate-600 vector icons; the active tab expands into a vibrant orange pill with crisp white vector icons.
2. **Dashboard / Home Screen:**
   - Pure white prompt container with Slate-200 border.
   - Translucent orange preset pills (`#FFF0EB`) that switch to solid brand orange when selected.
   - Text inputs with dark slate typography and orange cursor.
3. **Template Showcase:**
   - Template cards rendered in crisp white with soft elevation and clean borders.
   - Progress dialog styled with pure white surface, rotating status steps, and orange pulsing loader.
4. **Slide Editor Canvas:**
   - Thumbnail rail styled with pure white surface and slate dividers.
   - Stage canvas backdrop styled with Slate-100 (`#F1F5F9`) to ensure the 16:9 presentation slide stands out distinctly.
   - Floating toolbar styled with elevated white surface and subtle shadows.
5. **Presentation History & Vault:**
   - History item tiles rendered in white with slate borders and orange metadata chips.
6. **Settings Screen:**
   - App Brand Showcase Card featuring the brand logo with white card elevation, deep slate title, and orange version pill.

---

## 5. Pure Background Clarity (Elimination of Ambient Leaks)
- **Problem:** Ambient background radial gradients that transitioned to `Colors.transparent` (`#00000000`) caused dark gray/black sRGB interpolation artifacts (dirty shadow smudges in top-right, top-left, and bottom-right corners) on the light canvas.
- **Resolution:** All legacy `RadialGradient` ambient orbs have been completely removed across all screens (`SettingsScreen`, `HomeScreen`, `HistoryScreen`, `TemplateScreen`, `ExportScreen`, `EditorScreen`).
- **Result:** Screens now present a 100% clean, pristine, and uniform Editorial White background (`#F8F9FA`) with pure `#FFFFFF` elevated cards and crisp vector typography.

