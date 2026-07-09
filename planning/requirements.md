# Requirements

This file is owned by the user. Add planned features here before asking the AI to implement them.

Use one requirement section per feature or meaningful work item.

## R001 - Prowlarr M-Team 搜索结果增强媒体语言信息

Status: Draft
Priority: High

### Goal

调整 Prowlarr 的 M-Team 搜索器，让它调用 M-Team API 获取更完整的媒体信息，并在返回的搜索结果中显示影片的多语言音轨、字幕语言，以及每种语言音轨对应的规格。Radarr 也需要接收 Prowlarr 返回的这些 R001 字段和附加数据搜索状态，并在交互式搜索与自动追踪决策中正确使用。

### User Story

作为使用 Prowlarr 搜索 M-Team 资源的用户，我希望搜索结果能展示影片包含哪些音轨语言、字幕语言，以及不同语言音轨各自的规格，这样我可以更准确地判断资源是否符合下载需求。

### Expected Behavior

- M-Team 搜索结果可以显示影片包含的多个音轨语言。
- M-Team 搜索结果可以显示影片包含的字幕语言。
- 当不同语言音轨规格不同时，搜索结果可以分别展示每种语言的音轨规格。
- 示例：English: TrueHD；Chinese: DDP 5.1。
- 这些信息后续应尽量能被 Sonarr/Radarr 的匹配和排序逻辑使用。
- Radarr 接收 Prowlarr Torznab/Newznab 搜索结果时，需要保留音轨、字幕、每行附加数据搜索状态，以及整组附加数据搜索进度。
- Radarr 交互式搜索不应阻塞首批结果显示；当附加数据尚未返回时，对应行显示 loading，并显示类似“正在等待 3/11”的整组完成状态。
- 单行附加数据返回时，只更新该行，不触发整个搜索结果表格刷新，不自动改变当前排序结果；用户需要手动刷新或重新排序才改变排序视图。
- Radarr 自动追踪在使用这些附加字段判断候选 release 前，需要等待当前整组搜索结果的附加数据都完成或明确结束，再继续后续优先级/拒绝原因判断。

### Repositories Involved

- Prowlarr: 主要修改 M-Team indexer/API 解析和搜索结果字段。
- Sonarr: 暂不确定，取决于 Prowlarr 是否能同步这些字段。
- Radarr: 需要消费 Prowlarr 同步的音轨、字幕、附加数据搜索状态和进度字段，并把这些字段接入交互式搜索显示、排序稳定性和自动追踪等待逻辑。

### Acceptance Criteria

- M-Team 搜索结果中能看到音轨语言列表。
- M-Team 搜索结果中能看到字幕语言列表。
- 每个音轨语言能关联自己的规格，而不是只显示一个全局音频规格。
- 至少能覆盖 English TrueHD、Chinese DDP 5.1 这类同片不同语言不同规格的情况。
- Radarr `/api/v3/release` 能返回 Prowlarr 传来的音轨、字幕、每行附加数据状态和整组完成进度。
- Radarr 交互式搜索能在附加数据未完成时显示行级 loading 和整组等待进度，单行完成时不重建整个结果列表、不自动改变当前排序结果。
- Radarr 自动追踪在需要使用 R001 附加字段时，会等当前搜索结果整组附加数据完成后再进入候选 release 排序、匹配和拒绝判断。

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

## R005 - Custom Filter 支持嵌套条件组

Status: Draft
Priority: High

### Goal

扩展 Prowlarr 的 Custom Filter 条件组合能力，让用户可以在同一个自定义过滤器里配置可嵌套的 AND/OR 条件组，而不是只能把多条条件按单层 AND 组合；同时检查 Sonarr 和 Radarr 是否也存在相同限制，如果存在或缺少对应能力，也同步补齐。

### User Story

作为 Prowlarr/Sonarr/Radarr 用户，我希望 Custom Filter 可以表达“条件组 A 和条件组 B 同时满足”“条件组 A 或条件 C 满足”等更复杂的筛选逻辑，这样在搜索结果、电影/剧集列表、日历、历史记录等支持自定义过滤的页面里，不需要创建多个过滤器或反复手动切换。

示例：

- `(条件1 or 条件2) and (条件3 or 条件4)`
- `(条件1 and 条件2) or 条件3`

### Expected Behavior

- Custom Filter 可以继续保持当前默认 AND 行为，避免影响已有过滤器。
- 旧版本已保存的 Custom Filter 在升级后应自动解释为一个根级 AND 条件组。
- 用户可以在一个 Custom Filter 内创建条件组，条件组内可以包含普通条件，也可以包含子条件组。
- 每个条件组都可以选择组合方式，至少支持全部满足 `and` 和任一满足 `or`。
- 根级过滤器本身也应视为一个条件组，因此可以表达顶层 `and` 或顶层 `or`。
- 嵌套组合应支持不同字段之间的条件，例如“音轨包含 Chinese 或字幕包含 Chinese”。
- 嵌套组合应支持同一字段的多个条件，例如“Indexer 是 A 或 Indexer 是 B”。
- 嵌套组合应支持普通条件和条件组混合，例如 `(条件1 and 条件2) or 条件3`。
- 保存、读取、编辑、删除 Custom Filter 时，组层级、组内条件顺序、每个组的 `and`/`or` 组合方式都不会丢失。
- Prowlarr、Sonarr、Radarr 中已有 Custom Filter 的页面应尽量保持一致的交互和数据结构。

### UI / Interaction Expectations

- 当前 Filter Builder 的单行条件编辑能力应继续保留：字段选择、比较方式选择、值输入、单行新增和删除。
- UI 应支持把多条条件组织成视觉上清晰的条件组，可以参考用户草图：条件行之间用连接线或缩进表达层级，并在连接处显示当前组的 `and` 或 `or`。
- 每个条件或条件组旁边应有添加/删除入口，用于在同级增加条件、增加子条件组或移除当前项。
- 简单过滤器仍应易用：只有一层条件时，不应强迫用户理解复杂树结构。
- 当存在嵌套组时，界面应清楚显示每个 `and`/`or` 只作用于哪个条件组，避免用户误解优先级。
- 移动端或窄屏下也要能编辑嵌套结构，不能因为连接线或按钮过窄导致文字重叠或操作困难。

### Repositories Involved

- Prowlarr: 主要修改 Custom Filter 数据模型/API、Filter Builder UI、前端过滤执行逻辑，以及搜索结果等已支持 Custom Filter 的页面。
- Sonarr: 先确认当前 Custom Filter 覆盖页面和过滤执行逻辑；如果同样只有单层 AND 或缺少嵌套组，也同步增加。
- Radarr: 先确认当前 Custom Filter 覆盖页面和过滤执行逻辑；如果同样只有单层 AND 或缺少嵌套组，也同步增加。

### Acceptance Criteria

- Prowlarr 可以创建一个包含嵌套条件组的 Custom Filter，并正确显示满足条件树的结果。
- Prowlarr 可以表达并正确执行 `(条件1 or 条件2) and (条件3 or 条件4)`。
- Prowlarr 可以表达并正确执行 `(条件1 and 条件2) or 条件3`。
- Prowlarr 已有 Custom Filter 不需要用户迁移，仍按根级 AND 组生效。
- Sonarr 和 Radarr 的 Custom Filter 能力被检查并记录结论。
- 如果 Sonarr/Radarr 存在同样单层 AND 限制，也能创建和使用嵌套条件组。
- API 资源、数据库存储、前端状态类型和过滤执行逻辑都能表达条件节点、条件组节点、组层级和组组合方式。
- 至少覆盖一个跨字段嵌套示例、一个同字段多值 OR 示例，以及一个普通条件和条件组混合的示例。
- 编辑已保存的嵌套 Custom Filter 后再次保存，不会扁平化条件树或改变逻辑优先级。
- 删除条件或条件组后，剩余过滤器仍保持有效；如果某个组被删空，应有明确的 UI 处理和保存校验。

### Notes

- 初步代码搜索显示三套项目都存在 Custom Filter API 和前端 Filter Builder；客户端过滤入口里有按条件逐个判定的 AND 形态，需要实现前进一步确认 server-side collection 过滤和 client-side collection 过滤是否都要改。
- 实现时优先考虑可迁移的数据结构，例如用条件树表示过滤器：普通条件是叶子节点，条件组是包含子节点和 `and`/`or` 组合方式的分支节点。
- 设计时要避免破坏现有 Filter Builder 的简单使用体验；嵌套能力应在需要时展开，而不是让所有简单过滤器都显得复杂。

## R006 - Radarr 后端 Release Filter、音轨评分和互斥分数配置

Status: Draft
Priority: High - Next

### Goal

在 Radarr 中新增后端可执行的 Release Filter、可配置音轨语言映射、音轨评分、音轨语言偏好和互斥分数机制，让自动追踪和交互式搜索都能按照用户偏好筛选和排序资源。第一阶段不做全列加权排序，先实现 Custom Format 分数优先、音轨分数次优先。

详细设计见 `planning/radarr-release-filter-audio-scoring-design.md`。

### User Story

作为 Radarr 用户，我希望可以配置音轨语言识别、音轨评分、音轨语言偏好和后端筛选规则，使自动追踪不只依赖标题或前端表格过滤，而是能真正根据每个 release 的音轨、字幕、Custom Format 和质量配置选择最符合偏好的资源。

### Expected Behavior

- Radarr 支持后端 Release Filter Profile，自动搜索、RSS/追踪和交互式搜索 API 都能执行同一套筛选逻辑。
- Release Filter 支持嵌套 `and`/`or` 条件组，并能判断标题、站点、协议、质量、Custom Format 分数、大小、年龄、种子数、音轨语言、字幕语言、选定音轨和音轨分数等字段。
- 当 Filter 使用音轨/字幕/音轨分数等 R001 MediaInfo 字段时，自动追踪需要等待附加数据完成或明确失败后再做最终判断。
- 用户可以配置 Audio Language Mapping，例如把 `Guoyu`、`Mandarin`、`Chinese`、`国语`、`國語` 映射为标准语言 `Chinese`。
- 未配置映射的语言继续使用默认语言名或 ISO 语言匹配。
- 音轨与电影原始语言匹配时，应额外打上虚拟标签 `Origin`。
- 用户可以配置 Audio Score Profile，通过文本或正则规则给单条音轨加分。
- 音轨评分支持互斥组；同一个互斥组内多个规则命中同一音轨时，只取最高分。
- 用户可以配置 Audio Language Preference，例如 `Chinese` 优先，其次 `Origin`，并配置“备选语言音轨比首选语言最高音轨高出多少分时放弃首选”的阈值。
- Radarr 需要给每个音轨评分，再根据语言偏好和分差阈值选择唯一的 selected audio track。
- 只有 selected audio track 的分数进入 release 的音轨分数列和自动排序。
- Custom Format 支持互斥组；启用的互斥组里多个 Custom Format 同时命中时，只取最高分。
- Quality Profile 可以选择后端 Filter、要激活的 Custom Format 互斥组、音轨语言偏好、音轨评分配置和音轨互斥配置。
- 自动追踪排序第一阶段按 Custom Format 分数优先，再按音轨分数排序，后续沿用 Radarr 现有 tie-breaker。

### Repositories Involved

- Radarr: 主要修改后端筛选、质量配置、Custom Format 分数计算、音轨评分/选择、Release API、交互式搜索显示和自动追踪排序。
- Prowlarr: 不新增核心需求，但 R006 依赖 R001 已提供的 `audio`、`subs` 和 MediaInfo 附加数据。
- Sonarr: 暂不纳入第一阶段；后续可参考 Radarr 实现决定是否迁移。

### Acceptance Criteria

- 可以在 Radarr 中配置 `Guoyu`、`Mandarin`、`Chinese` 映射为标准 `Chinese` 音轨语言。
- 原始语言音轨能被打上 `Origin` 标签。
- 可以配置音轨语言偏好顺序，例如 `Chinese` -> `Origin`。
- 可以配置分差阈值，使高分备选语言音轨在超过阈值时替代首选语言音轨。
- 每个音轨独立评分，且只选择一个音轨作为 release 的 selected audio track。
- 音轨互斥组能避免 `7.1`/`5.1`、`TrueHD`/`DTS-HD MA`、`DDP`/`DD` 等同组规则重复加分。
- 交互式搜索显示 selected audio track 和音轨分数。
- Custom Format 互斥组启用后，同组命中项只计最高分。
- Quality Profile 可以绑定后端 Filter、Custom Format 互斥组和音轨评分/偏好配置。
- 自动搜索和 RSS/追踪能执行后端 Filter，而不是只依赖前端表格过滤。
- Filter 依赖 MediaInfo 字段时，自动追踪会等待 R001 附加数据再做最终通过/拒绝判断。
- 自动追踪候选排序在启用对应策略后先比较 Custom Format 分数，再比较音轨分数。

### Notes

- 这是当前优先处理的新功能计划。
- 第一阶段不实现全列加权排序。
- 设计稿：`planning/radarr-release-filter-audio-scoring-design.md`。
- 现有 Radarr 硬编码中文媒体偏好可作为实现参考，但 R006 应将其升级为可配置机制。
