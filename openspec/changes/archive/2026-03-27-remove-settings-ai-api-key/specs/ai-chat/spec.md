## ADDED Requirements

### Requirement: Personal settings must not expose custom AI API key UI

The Flutter client SHALL NOT present on the personal Settings screen (`SettingsScreen`, `flutter/lib/features/settings/screens/settings_screen.dart`) any section for entering, displaying, or saving a user-supplied DeepSeek or other third-party LLM API key (including but not limited to titles such as「AI 助手配置」, explanatory copy, text fields, and primary actions such as「保存 API Key」).

Runtime configuration via `AiConfig.load()` and persistence APIs (e.g. `AiConfig.saveApiKey`) MAY remain for non-settings code paths; this requirement only restricts the Settings **user interface**.

#### Scenario: User opens personal settings

- **WHEN** the user navigates to the personal Settings screen
- **THEN** the page MUST NOT show an「AI 助手配置」block (or equivalent) for API key input or save actions

#### Scenario: Other settings unchanged

- **WHEN** the user uses basic profile, reminder, notification, or health-archive entry sections on the same screen
- **THEN** those sections MUST continue to behave as before this change (excluding the removed API key block)
