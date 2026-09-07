# fans-daily-register

工时管理系统登记技能（Cursor / Codex / Hermes 共用）：查名下任务、按任务填工时并提交。

不要用 TAPD 工时接口。登录是工作邮箱、无密码。

## 目录

| 路径 | 说明 |
|------|------|
| `SKILL.md` | 技能正文（安装后给 Agent 读） |
| `scripts/timesheet.sh` | 登录 / 拉当日卡片 / 提交 / 查询 |
| `scripts/install.sh` | 装到 `$HOME`，并软链 Cursor、Codex、Hermes |
| `agents/openai.yaml` | Codex 界面名与自动选用 |

## 别人怎么用

推荐把仓库地址直接发给 AI，让它安装，不必自己敲命令。

把下面整段复制到 Cursor / Codex / Hermes：

```
请安装这个技能：https://github.com/solumon/fans-daily-register

这是工时管理系统登记技能（Cursor / Codex / Hermes 共用）：查询名下任务、按任务填工时并提交。不要用 TAPD 工时接口。登录是工作邮箱、无密码。

请克隆该仓库，在仓库根目录执行 ./scripts/install.sh（克隆到哪都可以）。安装会把技能放到 ~/.agents/skills/fans-daily-register，并软链到 Cursor、Codex、Hermes。装完告诉我可以开始用。
```

收到这段的 Agent 应按上述执行 `./scripts/install.sh`，不要只把命令丢回给用户。

### 手动安装

```bash
git clone https://github.com/solumon/fans-daily-register.git
cd fans-daily-register
./scripts/install.sh
```

安装后：

- 技能 → `$HOME/.agents/skills/fans-daily-register`
- 软链 → `$HOME/.cursor/skills/fans-daily-register`
- 软链 → `$HOME/.codex/skills/fans-daily-register`
- 软链 → `$HOME/.hermes/skills/fans-daily-register`（本机有 `~/.hermes` 时）

依赖：`bash`、`curl`、`rsync`、`python3`。改完 `SKILL.md` 或脚本后重新执行 `./scripts/install.sh`。

当前默认环境：

- 页面：https://timesheet.up366demo.cn/
- API：`https://timesheet-manage.up366demo.cn`

生产若是 `up366.com.cn`，改 `scripts/timesheet.sh` 里的 `TIMESHEET_API` 后重新安装。

### 第一次用：报邮箱

安装后不必改技能正文。在 Cursor / Codex / Hermes 里说「拉任务」或「登记工时」时，Agent 发现本机还没有邮箱，会问你的 **工作邮箱**，登录成功后写入：

`$HOME/.config/fans-daily-register/email`

同一台电脑以后不用再问。换账号再说一次新邮箱即可。这份文件不进仓库。

### 在 Cursor / Codex / Hermes 里用

任意项目、任意会话即可，不必打开本仓库。

| 你想做 | 怎么说 |
|--------|--------|
| 看名下任务 | 「拉任务」「我有哪些任务」 |
| 登记当天工时 | 「登记工时」，并给出任务、小时数、工作内容 |
| 改已交工时 | 「某某任务工时改为 x」 |
| Codex 点名 | `$fans-daily-register` |
| Hermes 点名 | `/fans-daily-register` |

工时必须是 **0.5 的倍数**（0.5、1、1.5…）。提交前 Agent 会列出拟提交内容；未确认不会交。登记完成后会给出姓名、邮箱、当天任务、工时、内容与合计。

开发账号看不到任务后台（`/front/task/page` 会 403），任务列表来自当日 `daily` 卡片。

Hermes 装完后若当前会话还看不到技能，新开一轮对话，或执行技能重载（若你用的 Hermes 版本提供 `hermes` 技能刷新命令）。
