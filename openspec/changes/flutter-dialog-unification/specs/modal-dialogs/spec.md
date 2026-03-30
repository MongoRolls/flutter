# modal-dialogs Specification

## Purpose

定义 Flutter 客户端标准模态（居中确认、居中告知、底部面板）的视觉、交互与选用规则，以及与 `AppTheme` / `AppColors` 的一致性要求。

## ADDED Requirements

### Requirement: Standard confirm dialog uses solid card surface and destructive primary for destructive actions

The application SHALL provide a centered confirm dialog implementation (e.g. `AppConfirmDialog`) that uses a solid card surface (`AppColors.bgCard`), not glass/blur effects, with geometry and shadow aligned to `AppRadius` / `AppShadows` as documented for modals. For destructive actions (e.g. delete, clear, discard), the primary action button SHALL use destructive colors (`AppColors.red` or `AppColors.redDeep` with white foreground) as the affirmative action. The secondary cancel action SHALL use a text-style or outlined control consistent with the theme. The implementation SHALL return `Future<bool?>` where `true` means confirm, `false` cancel, and `null` when dismissed via barrier if allowed.

#### Scenario: Destructive confirm shows red primary

- **WHEN** the user opens a destructive confirm flow (e.g. delete or clear) using the standard confirm dialog
- **THEN** the primary button on the right (or equivalent layout) SHALL use destructive styling and the card surface SHALL be solid `bgCard` without glass effect

### Requirement: Standard info dialog matches confirm geometry with single primary dismissal

The application SHALL provide a centered info dialog implementation (e.g. `AppInfoDialog`) sharing the same solid card geometry and shadow as the confirm dialog, for scenarios where a single acknowledgment is needed (no cancel/confirm dual path). The primary action SHALL be `ElevatedButton`-style aligned with `AppColors.blue` unless a product-specific exception is documented.

#### Scenario: Info dialog has one primary action

- **WHEN** the user opens a short informational modal that requires acknowledgment only
- **THEN** the dialog SHALL present one primary dismissal control and SHALL NOT require a cancel/confirm pair for the same role

### Requirement: Standard modal sheet for long content and bottom presentation

The application SHALL provide a bottom modal sheet implementation (e.g. `AppModalSheet`) using `showModalBottomSheet`, with top-only corner radius in the `AppRadius.x2l`–`AppRadius.x3l` range as documented, solid `AppColors.bgCard` surface, a drag handle, optional title bar, scrollable content when tall, and bottom safe-area padding. The implementation SHALL use `isScrollControlled: true` when content may exceed half the viewport height.

#### Scenario: Tall sheet scrolls inside

- **WHEN** the user opens a bottom sheet with content taller than the available viewport region
- **THEN** the content area SHALL scroll internally and the bottom inset SHALL respect safe area

### Requirement: Modal stack and barrier behavior use Material defaults unless specified

The application SHALL use `showDialog`/`showModalBottomSheet` with default barrier dismissibility and barrier color unless a product-level exception is recorded in the spec or design tokens. The implementation SHALL avoid stacking multiple modal layers on top of each other within the same flow without clear justification.

#### Scenario: Default barrier behavior

- **WHEN** a standard dialog or bottom sheet is shown with default barrier settings
- **THEN** barrier dismissibility and overlay color SHALL match the framework defaults for that API as documented for this project

### Requirement: Selection guide for developers

Project documentation (design tokens doc and/or developer notes) SHALL document when to use confirm vs info vs bottom sheet (e.g. short yes/no vs acknowledge vs long content or QR).

#### Scenario: Documented selection path

- **WHEN** a developer implements a new modal flow
- **THEN** they SHALL be able to choose among the standard components using the documented selection table
