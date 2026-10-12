# Theme & Icon Specification

## Visual Identity Architecture

### App Icon & Logo Replacement
- **Source Asset:** [assets/icon/applogo.jpeg](file:///e:/Abdulrahman/imagineX/assets/icon/applogo.jpeg)
- **High-Resolution PNG Artifact:** [assets/icon/app_logo.png](file:///e:/Abdulrahman/imagineX/assets/icon/app_logo.png)
- **Legacy Removal:** Deprecated and deleted legacy `assets/icon/app_icon.png`.
- **Platform Coverage Generated via `flutter_launcher_icons`:**
  - Android (`mipmap-mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`)
  - iOS (`Assets.xcassets/AppIcon.appiconset`)
  - Web (`favicon.png`, `Icon-192.png`, `Icon-512.png`, `Icon-maskable`)
  - Windows (`runner/resources/app_icon.ico`)
  - macOS (`AppIcon.appiconset`)

### Intentional Color System ([lib/theme/app_theme.dart](file:///e:/Abdulrahman/imagineX/lib/theme/app_theme.dart))
Replaced clichéd AI dark blue (`#0B1326` / neon cyan) with true deep neutrals and authentic warm sunset orange:

| Token | Hex Value | Role |
| :--- | :--- | :--- |
| `AppColors.primary` | `#FF5722` | Dominant Brand Orange (Buttons, Selected Badges, Titles) |
| `AppColors.primaryLight` | `#FF7A47` | Hover & Active Secondary Accent |
| `AppColors.primaryDark` | `#E64A19` | Gradient Secondary Accent |
| `AppColors.primaryContainer` | `rgba(255, 87, 34, 0.15)` | Subtle Translucent Fill |
| `AppColors.background` | `#0E1015` | Deep Charcoal Base (Scaffold) |
| `AppColors.surface` | `#151821` | Elevated Card Surface |
| `AppColors.surfaceElevated` | `#1D212E` | Modals & Bottom Navigation Bar |
| `AppColors.surfaceBorder` | `rgba(255, 255, 255, 0.10)` | Clean Spatial Delimiters |
| `AppColors.textPrimary` | `#F8FAFC` | Crisp High-Contrast Typography |
| `AppColors.textSecondary` | `#94A3B8` | Slate 400 Muted Typography |
| `AppColors.textMuted` | `#64748B` | Slate 500 Subtle Captions |

### UI Integration Points
1. **[lib/screens/home_screen.dart](file:///e:/Abdulrahman/imagineX/lib/screens/home_screen.dart):**
   - AppBar features the new logo badge beside "SlideAI".
   - Brand orange ambient leaks, slide count slider, and primary template CTA button.
2. **[lib/screens/settings_screen.dart](file:///e:/Abdulrahman/imagineX/lib/screens/settings_screen.dart):**
   - App Brand Showcase card at top highlighting new logo icon, version badge, and metadata.
3. **[lib/screens/editor_screen.dart](file:///e:/Abdulrahman/imagineX/lib/screens/editor_screen.dart):**
   - App logo badge in AppBar, active slide rail highlight in orange, and refined text edit cursor.
4. **[lib/screens/template_screen.dart](file:///e:/Abdulrahman/imagineX/lib/screens/template_screen.dart):**
   - Selection state cards, indicators, and dialog loaders themed to `AppColors.primary`.
5. **[lib/screens/export_screen.dart](file:///e:/Abdulrahman/imagineX/lib/screens/export_screen.dart):**
   - Export deck CTA, slideshow icons, and dialog loaders themed with `AppColors`.
6. **[lib/widgets/floating_bottom_bar.dart](file:///e:/Abdulrahman/imagineX/lib/widgets/floating_bottom_bar.dart):**
   - Elevated dark floating capsule with vibrant orange active tab indicator.
