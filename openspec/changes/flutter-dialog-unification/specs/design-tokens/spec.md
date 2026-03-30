# design-tokens Specification Delta

## ADDED Requirements

### Requirement: Modal layer tokens are documented and aligned with Flutter implementation

The design token documentation SHALL include modal-specific tokens for solid card surfaces used in dialogs and bottom sheets, including: dialog max width rule (`min(400, viewport width − 48)` logical pixels), dialog corner radius choice (fixed to either `AppRadius.xl` or `AppRadius.x2l` for centered dialogs as implemented), bottom sheet top corner radius range (`AppRadius.x2l` through `AppRadius.x3l`), solid surface color (`AppColors.bgCard`), optional divider border (`AppColors.divider`), card shadow (`AppShadows.card`), destructive primary button colors for destructive confirms, and drag handle colors (e.g. `AppColors.grey` / `divider`). The Flutter implementation SHALL match these documented values.

#### Scenario: Reviewer verifies modal tokens

- **WHEN** a reviewer compares `flutter/doc/design-tokens.md` and `openspec/specs/design-tokens/spec.md` with the modal wrapper widgets and theme
- **THEN** modal backgrounds, radii, shadows, and destructive primary styling SHALL not contradict the documented modal token table

### Requirement: Modal documentation distinguishes solid modals from page GlassCard

The documentation SHALL state that modal content surfaces are solid cards (`bgCard`) and SHALL NOT use the glass/blur treatment used by page-level `GlassCard`, so that modal and page decoration strategies are not confused.

#### Scenario: Glass vs modal distinction is explicit

- **WHEN** a contributor reads the design-token documentation for modals
- **THEN** they SHALL find an explicit statement that modal content uses solid surfaces, distinct from glass card surfaces on non-modal pages
