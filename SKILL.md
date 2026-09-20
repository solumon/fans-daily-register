---
name: fans-daily-register
description: >-
  在工时管理系统查询名下任务、检查漏登记或不足 8 小时的日期、登记当日工时（按任务填工时/进度/工作内容并提交）。
  Use when the user asks to 登记工时、填工时、报工时、写日报、拉任务、有哪些任务、查漏登记、缺工时、工时报表、timesheet,
  or mentions timesheet.up366demo.cn.
metadata:
  hermes:
    tags: [timesheet, 工时, 日报]
    category: productivity
---

# 工时登记

登记入口是 **工时管理系统**，不是 TAPD。技能装在 `$HOME/.agents/skills/fans-daily-register`，Cursor / Codex / Hermes 或其它会读该目录的 Agent 都能用。Codex 可点名 `$fans-daily-register`；Hermes 可 `/fans-daily-register`。没有这三家时，按本 `SKILL.md` 直接执行即可。

禁止用 `tapd_timesheets_create` / `list` / `count` 代替本流程。

本技能目录 = 含本 `SKILL.md` 的文件夹（安装后通常是 `$HOME/.agents/skills/fans-daily-register`）。Windows 上 `$HOME` 即用户目录，如 `C:\Users\你`。

## 账号与地址

| 项 | 值 |
|----|----|
| 页面 | https://timesheet.up366demo.cn/ |
| 登记页 | https://timesheet.up366demo.cn/timesheet |
| 查询页 | https://timesheet.up366demo.cn/timesheet/query |
| API | `https://timesheet-manage.up366demo.cn` |
| Header | `Content-Type: application/json`、`X-App-Name: timesheet-html` |
| 登录 | 工作邮箱，无密码。`userName` 即邮箱 |
| 本机邮箱 | `$HOME/.config/fans-daily-register/email`（不进仓库） |
| Cookie | macOS/Linux：`/tmp/fans-timesheet-cookies.txt`；Windows：`%TEMP%\fans-timesheet-cookies.txt` |

环境由页面域名决定：`up366demo.cn` → API 也是 `*.up366demo.cn`。身份以 `me` 为准，不要写死姓名 / userId。

### 第一次使用（邮箱）

拉任务或登记前先确保已有本机邮箱。**有 bash 用 `.sh`，Windows PowerShell 用 `.ps1`。**

```bash
# macOS / Linux / WSL / Git Bash
"$HOME/.agents/skills/fans-daily-register/scripts/timesheet.sh" email
```

```powershell
# Windows PowerShell
powershell -NoProfile -File "$HOME/.agents/skills/fans-daily-register/scripts/timesheet.ps1" email
```

- 打印出邮箱 → 直接 `login`（无参数，用已存邮箱）
- 退出码 3 / `NO_EMAIL` → **停下来问用户工作邮箱**，不要猜。用户给出后对对应脚本再跑 `login 'you@up366.com'`。

登录成功会写入本机配置，以后同一台机器不用再问。用户要换账号时再 `login` 一次新邮箱即可覆盖。

禁止把邮箱写进 `SKILL.md` 或仓库文件。

## 不要用浏览器点页面

用本技能脚本调 API（cookie jar）。不要为了查询/登记去 Chrome 里点表单。用户明确说「你去看页面」时除外。不要依赖 `AskQuestion`、TAPD MCP。

Cookie：见上表。脚本：[scripts/timesheet.sh](scripts/timesheet.sh) / [scripts/timesheet.ps1](scripts/timesheet.ps1)

```bash
# macOS / Linux / WSL / Git Bash
"$HOME/.agents/skills/fans-daily-register/scripts/timesheet.sh" email
"$HOME/.agents/skills/fans-daily-register/scripts/timesheet.sh" login
"$HOME/.agents/skills/fans-daily-register/scripts/timesheet.sh" me
"$HOME/.agents/skills/fans-daily-register/scripts/timesheet.sh" daily [YYYY-MM-DD]
"$HOME/.agents/skills/fans-daily-register/scripts/timesheet.sh" range '<json>'
"$HOME/.agents/skills/fans-daily-register/scripts/timesheet.sh" submit '<json>'
```

```powershell
# Windows PowerShell（参数相同）
powershell -NoProfile -File "$HOME/.agents/skills/fans-daily-register/scripts/timesheet.ps1" email
```

若技能目录不在上述路径，用本 `SKILL.md` 旁的 `scripts/timesheet.sh` 或 `scripts/timesheet.ps1`。

`login` 不传参数则用本机已存邮箱。`daily` 默认当天。响应 `code === 0` 才算成功；业务数据在 `data`。

开发身份下 `POST /front/task/page` 会 **403**，不要用它列任务。

## 拉任务

用户说「有哪些任务 / 拉任务 / 我的任务」时：

```
- [ ] 1. 按「第一次使用」确保邮箱 → login → me，确认 realName
- [ ] 2. daily（默认当天）拿 cards
- [ ] 3. 按任务名 / 区间 / 当天是否已交 列表回报
```

`daily` 只返回 **日期落在任务区间内** 的卡片。当天没有不等于名下没有任务。

需要看更完整名单时：再 `daily` 几个代表日（如月初、月中、月末），按 `taskId` 去重；已交记录用 `range`（`dimension`: `week` | `month`）。

卡片字段：`taskId`、`taskName`、`startDate`、`endDate`、`hours`、`progress`、`content`、`submitted`、`submittedTime`。

无卡片时说明该日无待填任务（`EmptyDay`），不要空提交。

## 检查漏登记工时

用户问「有没有漏登记 / 哪天没填 / 是否缺工时」时，复用本技能的账号和 `range` 查询，不另建流程或技能：

```
- [ ] 1. 确定检查区间：用户指定优先；否则用对话中已确认的起算日到今天；仍不明确时默认本月 1 日到今天，并说明口径
- [ ] 2. login → me → range，当前账号不要带别人的 userId
- [ ] 3. 按实际工作日历生成候选工作日（包含调休上班的周末，排除休假的工作日），再与 range.data.days 按 workDate 对比
- [ ] 4. 分开列出「完全未登记」与「已登记但不足 8 小时」
- [ ] 5. 应用用户确认的起算日、请假日、休息日或调休规则，再给最终结论
```

判断口径：

- 不要只按星期判断工作日：周六、周日可能因调休或公司安排成为工作日，周一至周五也可能是假期。
- 工作日口径优先级：用户或公司明确安排 > 可核验的官方节假日/调休安排 > 普通周一至周五。用户明确某个周末是工作日时必须纳入检查，不得因其是周末而排除。
- 用户给出的工时起算日是检查边界，早于该日期的记录不要列为漏登。
- 请假日不算漏登；部分请假日允许少于 8 小时。只按用户明确提供的请假信息排除，不猜请假安排。
- `range` 只返回已有登记的日期。候选工作日在 `data.days` 中不存在，才是「完全未登记」；存在但 `totalHours < 8`，先列为「不足 8 小时」，不要直接断言漏登，因为可能有请假。
- `totalHours >= 8` 视为已满足普通日工时；若超过 24 小时，额外提示异常。
- 没有公司或官方节假日、调休信息时，才按普通周一至周五临时判断，并明确标注「未核验调休」；不要把周末一律当休息日，也不要猜具体调休日期。
- 近期会话里的具体起算日、请假日期属于当次用户状态，不要写死到技能。后续查询应使用当前对话中的最新口径；缺少关键口径时再询问。

推荐输出：检查区间与工作日口径来源、完全未登记日期、不足 8 小时日期（含已登记小时数）、已满 8 小时汇总。若用户随后要补登记，转入下方「登记工时」流程，仍须展示确认卡并等待明确提交授权。

## 登记工时

```
- [ ] 1. 确认日期（默认当天）
- [ ] 2. 按「第一次使用」确保邮箱 → login → daily 拉当天卡片
- [ ] 3. 按用户说明填 hours / progress / content（只改他说的任务）
- [ ] 4. 提交前把拟提交内容给用户看清；未确认不 submit
- [ ] 5. submit 成功后按「提交后汇总」输出，不要只说「提交成功」
```

提交 body：

```json
{
  "workDate": "2026-09-07",
  "cards": [
    { "taskId": 20, "hours": 8, "progress": 10, "content": "…" }
  ]
}
```

只提交有改动或已提交过的卡片。`hours`/`progress` 缺省按 0；空 `content` 可省略。

用户没给某任务的工时/内容时，保留 `daily` 里已有值，不要编造。

校验（提交前本地做）：

- 至少一张有效卡片，否则「请先填写工时」
- 工时为 0.5 的倍数（0.5、1、1.5…），≥ 0
- 进度 0–100 整数
- 内容 ≤ 1000 字
- 当天合计 **< 8h** 可提交，但要提醒「当天合计未满 8 小时」
- 当天合计 **> 24h** 要提醒「已超过 24 小时」，用户仍确认才交

## 提交后汇总

`submit` 返回 `code === 0` 后，用返回的 `data`（必要时再 `daily` 核对）给用户一份当天汇总。**每次登记/改工时完成都要出**，不要只回「提交成功」。

按下面结构写（表格即可）：

1. 一行标题：`{workDate} 已登记`
2. 姓名、邮箱：来自本次 `me` 的 `realName`、`userName`（没有刚调过就补一次 `me`）。不要用仓库里的示例名，不要猜。
3. 任务表：任务名、工时、进度、工作内容、提交时间
4. 当天合计小时数
5. 若合计 < 8h 或 > 24h，在合计下补一句提醒

内容按卡片原文，不要改写、不要省略任务。未填进度就写 `—`。

示例（姓名/邮箱以当次 `me` 为准）：

```
2026-09-07 已登记
姓名：{realName}
邮箱：{userName}

| 任务 | 工时 | 进度 | 内容 | 提交时间 |
|------|------|------|------|----------|
| 【业务1-1】日常维护 | 0.5 | — | 广东听说报告问题排查 | 16:00:37 |
| 【业务1-1】听说系列报告整合 - 一期 | 7.5 | 10% | 1. 现状梳理；2. 废弃代码清理 | 16:00:37 |

当天合计 **8** 小时。
```

## 查询已交工时

`POST /front/timesheet/range`

```json
{ "startDate": "2026-09-01", "endDate": "2026-09-30", "dimension": "month" }
```

`dimension`：`week` | `month`。负责人可再带 `userId`；当前账号不要替别人查。
