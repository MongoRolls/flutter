## ADDED Requirements

### Requirement: Separate notification channel for peer care reminders

The Flutter app SHALL register and use a dedicated notification channel (and equivalent iOS presentation options) for peer-initiated care reminders, distinct from scheduled daily water reminders and other channels.

#### Scenario: Channel separation on Android

- **WHEN** the app initializes `NotificationService` Android channels
- **THEN** peer care reminders SHALL use a channel id dedicated to care/peer reminders and SHALL NOT reuse the channel id used for recurring hydration schedule reminders

#### Scenario: Recipient sees peer reminder with template summary

- **WHEN** a peer care reminder is displayed on the recipient device
- **THEN** the title SHALL identify the sender (e.g. sender nickname or a fixed「好友提醒」pattern per product copy) and the body SHALL reflect the selected template summary text

## MODIFIED Requirements

### Requirement: REQ-NOTIF-04：关怀通知

The app SHALL support care notifications for peer reminders using the dedicated care channel when showing incoming reminders; local debug calls MAY still use `showCareNotification` but MUST route presentation through the care channel where the platform allows.

#### Scenario: Incoming peer reminder on recipient device

- **WHEN** a peer care reminder must be shown to the recipient after backend acceptance or equivalent delivery
- **THEN** the notification SHALL use the peer/care channel and SHALL NOT reuse the recurring schedule reminder channel

#### Scenario: Local showCareNotification for debugging

- **WHEN** `NotificationService.showCareNotification(title, body)` is invoked for development or offline testing
- **THEN** the notification SHALL still use the peer/care channel configuration when the platform supports per-notification channel selection

---

### Requirement: REQ-NOTIF-05：通知 ID 分配规则

The system SHALL reserve notification id ranges as follows; peer care reminders SHALL use ids in the care range.

#### Scenario: Care range used for peer reminders

- **WHEN** scheduling or showing peer-initiated care reminders that need stable ids
- **THEN** implementations SHALL allocate ids from the 9000+ care range and SHALL document any sub-ranges if coexisting with legacy care ids

| 范围        | 用途               |
|-------------|--------------------|
| 0 - 999     | 定期水提醒（7天 × N个/天）|
| 1000 - 1019 | 计划 Slot 提醒      |
| 2000+       | AI 自定义提醒       |
| 9000+       | 关怀通知（含好友模板提醒；若需与旧 ID 并存，实现时在该范围内划分子段并文档化） |
