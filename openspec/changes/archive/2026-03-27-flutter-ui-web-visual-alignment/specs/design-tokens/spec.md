## ADDED Requirements

### Requirement: Design token documentation maps web light reference to Flutter

The Flutter codebase SHALL include a reviewable mapping from the marketing site’s **light** design tokens (as defined in the repository’s read-only reference CSS/components) to Flutter `AppColors` / `ThemeData` fields, including radius steps and shadow strategies; platform rounding within ±1 logical pixel or approximate colors SHALL be documented where applicable.

#### Scenario: Token table is reviewable

- **WHEN** a reviewer opens the documented mapping and compares with browser-computed styles for the light theme
- **THEN** primary background, card surface, primary accent, and main text colors SHALL be consistent with the mapping such that there is no obvious visual clash with the marketing light theme

### Requirement: Global light theme matches documented tokens

The application SHALL use a single light `ThemeData` (no in-app dark theme as part of this capability) such that `Scaffold` background, card surfaces, `ColorScheme`, and text hierarchy align with the documented token mapping.

#### Scenario: Cold start shows aligned surfaces

- **WHEN** the user cold-starts the app and navigates to any screen that uses a `Scaffold`
- **THEN** background and app bar / card surfaces SHALL match the token table and SHALL NOT rely on large areas of legacy hard-coded colors inconsistent with that table

### Requirement: Shared card container matches GlassCard light intent

Reusable card-style containers (e.g. glass / elevated surfaces) SHALL use unified corner radius, shadow, and border treatments derived from the token mapping; repeated per-screen `BoxDecoration` SHALL be reduced in favor of shared widgets or theme helpers.

#### Scenario: Scrolling lists show consistent cards

- **WHEN** the user scrolls through lists or sections that use the shared card component
- **THEN** corner radius and shadows SHALL match the light GlassCard intent and the same screen SHALL NOT mix incompatible card styles for the same role

### Requirement: Typography and spacing use a constrained scale

Title and body text SHALL use a defined `TextTheme` hierarchy aligned with the design; vertical spacing between blocks SHALL use a small fixed set of values (e.g. 8, 12, 16, 24) without restructuring page information architecture.

#### Scenario: Section spacing uses the scale

- **WHEN** a screen applies the updated theme and spacing rules
- **THEN** major vertical gaps between sections SHALL be expressed using values from the allowed set

### Requirement: Manual product acceptance on core tabs

After style refresh, product SHALL manually verify Home, Settings, and Community (or the three primary bottom-navigation tabs in the current build) on a real device or simulator and accept the visual result or record a bounded list of acceptable deviations that do not affect functionality.

#### Scenario: Product sign-off

- **WHEN** implementation of this capability is complete
- **THEN** product SHALL have reviewed the agreed screens on device and SHALL confirm release readiness or listed acceptable deviations

### Requirement: Accessibility baseline is preserved or improved

Contrast and readability SHALL remain at least at current practice; dynamic text scaling SHALL not cause major layout overflow worse than the prior behavior for primary layouts.

#### Scenario: Dynamic text does not break primary layouts

- **WHEN** the user enables larger accessibility text sizes on the platform
- **THEN** primary screens using the updated theme SHALL not exhibit worse overflow than before for the same content
