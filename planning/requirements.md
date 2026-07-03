# Requirements

This file is owned by the user. Add planned features here before asking the AI to implement them.

Use one requirement section per feature or meaningful work item.

## R001 - Prowlarr M-Team 搜索结果增强媒体语言信息

Status: Draft
Priority: High

### Goal

调整 Prowlarr 的 M-Team 搜索器，让它调用 M-Team API 获取更完整的媒体信息，并在返回的搜索结果中显示影片的多语言音轨、字幕语言，以及每种语言音轨对应的规格。

### User Story

作为使用 Prowlarr 搜索 M-Team 资源的用户，我希望搜索结果能展示影片包含哪些音轨语言、字幕语言，以及不同语言音轨各自的规格，这样我可以更准确地判断资源是否符合下载需求。

### Expected Behavior

- M-Team 搜索结果可以显示影片包含的多个音轨语言。
- M-Team 搜索结果可以显示影片包含的字幕语言。
- 当不同语言音轨规格不同时，搜索结果可以分别展示每种语言的音轨规格。
- 示例：English: TrueHD；Chinese: DDP 5.1。
- 这些信息后续应尽量能被 Sonarr/Radarr 的匹配和排序逻辑使用。

### Repositories Involved

- Prowlarr: 主要修改 M-Team indexer/API 解析和搜索结果字段。
- Sonarr: 暂不确定，取决于 Prowlarr 是否能同步这些字段。
- Radarr: 暂不确定，取决于 Prowlarr 是否能同步这些字段。

### Acceptance Criteria

- M-Team 搜索结果中能看到音轨语言列表。
- M-Team 搜索结果中能看到字幕语言列表。
- 每个音轨语言能关联自己的规格，而不是只显示一个全局音频规格。
- 至少能覆盖 English TrueHD、Chinese DDP 5.1 这类同片不同语言不同规格的情况。

### Notes

- 需要先确认 M-Team API 返回的字段结构，以及 Prowlarr 当前搜索结果模型能否承载这些信息。

## R002 - Sonarr/Radarr 搜索结果自定义排序

Status: Draft
Priority: High

### Goal

在 Sonarr/Radarr 的搜索结果匹配和排序机制中，加入类似 Excel 自定义排序的能力，让用户可以按多个字段组合决定候选资源优先级。

### User Story

作为 Sonarr/Radarr 用户，我希望能配置搜索结果的主排序列和次排序列，并针对不同字段类型选择合适排序方式，这样自动选择资源时能更贴近我的偏好。

### Expected Behavior

- 用户可以选择主排序列和次排序列。
- 数值列支持升序和降序。
- 语言、字幕等枚举或集合类型字段支持：
  - 有某项优先。
  - 没有某项优先。
  - 用户自定义语言/字幕排序顺序。
- 排序规则可以影响搜索结果展示和自动选择候选项的优先级。
- 排序逻辑应能利用 Prowlarr 传来的音轨语言、字幕语言、音轨规格等字段。

### Repositories Involved

- Prowlarr: 可能需要配合提供更完整字段。
- Sonarr: 主要修改搜索结果排序、匹配逻辑和相关配置界面。
- Radarr: 主要修改搜索结果排序、匹配逻辑和相关配置界面。

### Acceptance Criteria

- 用户可以配置至少一个主排序字段。
- 用户可以配置至少一个次排序字段。
- 数值字段可以选择升序或降序。
- 语言和字幕字段可以按“有/没有/自定义次序”进行排序。
- 排序结果稳定、可解释，并能在多个候选 release 之间体现优先级差异。

### Notes

- 需要先确认哪些字段已经存在，哪些字段需要从 Prowlarr 或 release 解析链路新增。

## R003 - 质量配置支持 Custom Format 分数优先策略

Status: Draft
Priority: High

### Goal

在 Sonarr/Radarr 的质量配置中增加可选策略，允许用户设置某个质量配置使用 Custom Format 分数优先，而不是始终优先选择最高质量档位。

### User Story

作为 Sonarr/Radarr 用户，我希望可以在特定质量配置里启用 Custom Format 分数优先，这样自动追踪不会只因为质量档位更高就选择不符合我偏好的资源。

### Expected Behavior

- 每个质量配置可以独立设置是否启用 Custom Format 分数优先。
- 默认行为保持现状，不影响已有用户配置。
- 启用后，自动追踪和候选 release 排序时优先考虑 Custom Format 分数。
- 质量档位仍然参与判断，但不再在该质量配置中绝对优先。
- 不同质量配置可以使用不同策略。

### Repositories Involved

- Prowlarr: 暂不涉及。
- Sonarr: 主要修改质量配置、自动追踪和候选 release 排序逻辑。
- Radarr: 主要修改质量配置、自动追踪和候选 release 排序逻辑。

### Acceptance Criteria

- 用户可以在质量配置中开启或关闭 Custom Format 分数优先。
- 未开启该选项的质量配置保持原有匹配逻辑。
- 开启后，Custom Format 分数更高的候选项可以优先于质量档位更高但分数较低的候选项。
- 自动追踪日志或拒绝原因能说明排序/选择受该策略影响。

### Notes

- 这是配置级别的可选行为，不是全局改写 Sonarr/Radarr 的所有匹配规则。

## R004 - Sonarr 支持整季包搜索和追踪

Status: Draft
Priority: Medium

### Goal

让 Sonarr 支持搜索和追踪整季包，而不是只能围绕单集进行追踪。

### User Story

作为 Sonarr 用户，我希望可以搜索、识别并追踪整季包，这样在整季资源更合适时，不需要只能依赖单集资源。

### Expected Behavior

- 用户可以针对某一季搜索整季包。
- 自动追踪时可以识别并选择合适的 season pack。
- 整季包需要能正确映射到对应季和集数。
- 需要避免整季包覆盖、重复下载、漏集等问题。

### Repositories Involved

- Prowlarr: 可能需要确认搜索结果是否能明确标识 season pack。
- Sonarr: 主要修改整季搜索、追踪、匹配和导入逻辑。
- Radarr: 不涉及。

### Acceptance Criteria

- Sonarr 可以找到并展示整季包搜索结果。
- 整季包可以参与自动追踪决策。
- 下载后能正确关联到对应剧集季和集数。
- 追踪逻辑能避免明显的重复下载或漏集问题。

### Notes

- 需要先探索 Sonarr 当前 season pack 支持范围，确认是缺少搜索入口、自动追踪策略，还是后续导入映射能力。
