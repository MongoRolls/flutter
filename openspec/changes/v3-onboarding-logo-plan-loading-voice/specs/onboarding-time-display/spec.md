## ADDED Requirements

### Requirement: 引导作息时间展示与保存一致

在首次引导流程中，用户通过时间选择器设置的起床、就寝等时间 MUST 在界面上以正确格式显示，且保存到用户档案后的值与选择一致；MUST NOT 出现截断、空白、或与所选时间相差整小时等错误。

#### Scenario: 时间选择后展示正确

- **WHEN** 用户在引导页选择起床或就寝时间并确认
- **THEN** 同一页面及后续步骤中展示的时间文本与所选 `TimeOfDay` 一致（按应用当前 locale 格式化）

#### Scenario: 完成引导后档案一致

- **WHEN** 用户完成引导并完成 onboarding
- **THEN** `UserProfile` 中对应字段与引导中最终选择一致，且首页或设置中读取的展示与档案一致
