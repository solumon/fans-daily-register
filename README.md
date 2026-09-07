# fans-daily-register

工时管理系统登记技能：查名下任务、按任务填工时并提交。Cursor / Codex / Hermes 以及其它会读 `~/.agents/skills` 的 Agent 都能用。

不要用 TAPD 工时接口。登录是工作邮箱、无密码。

## 目录

| 路径 | 说明 |
|------|------|
| `SKILL.md` | 技能正文（安装后给 Agent 读） |
| `scripts/timesheet.sh` | 登录 / 拉当日卡片 / 提交 / 查询 |
| `scripts/install.sh` | 装到 `~/.agents/skills`；有 Cursor / Codex / Hermes 再软链 |
| `agents/openai.yaml` | Codex 界面名与自动选用 |

## 别人怎么用

推荐把仓库地址直接发给 **能在本机执行命令的 AI**（Cursor、Codex、Hermes、Claude Code 等均可），让它安装。没有 Cursor / Codex / Hermes 也没关系：技能会落到通用目录 `~/.agents/skills`，当前这个 Agent 按 `SKILL.md` 执行即可。网页版聊天框不能跑 git/bash，装不了。

把下面整段复制给 AI：

```
请安装这个技能：https://github.com/solumon/fans-daily-register

这是工时管理系统登记技能：查询名下任务、按任务填工时并提交。不要用 TAPD 工时接口。登录是工作邮箱、无密码。

请克隆该仓库，在仓库根目录执行 ./scripts/install.sh（克隆到哪都可以）。安装会把技能放到 ~/.agents/skills/fans-daily-register；本机若有 Cursor / Codex / Hermes 再软链过去，没有就跳过。装完告诉我可以开始用。
```

收到这段的 Agent 应自己执行 `./scripts/install.sh`，不要只把命令丢回给用户。

### 手动安装

```bash
git clone https://github.com/solumon/fans-daily-register.git
cd fans-daily-register
./scripts/install.sh
```

安装后：

- 技能（必有）→ `$HOME/.agents/skills/fans-daily-register`
- 软链（本机有对应软件才装）→ Cursor / Codex / Hermes 的 skills 目录

依赖：`bash`、`curl`、`rsync`、`python3`。改完 `SKILL.md` 或脚本后重新执行 `./scripts/install.sh`。

当前默认环境：

- 页面：https://timesheet.up366demo.cn/
- API：`https://timesheet-manage.up366demo.cn`

生产若是 `up366.com.cn`，改 `scripts/timesheet.sh` 里的 `TIMESHEET_API` 后重新安装。

### 第一次用：报邮箱

安装后不必改技能正文。说「拉任务」或「登记工时」时，Agent 发现本机还没有邮箱，会问你的 **工作邮箱**，登录成功后写入：

`$HOME/.config/fans-daily-register/email`

同一台电脑以后不用再问。换账号再说一次新邮箱即可。这份文件不进仓库。

### 日常怎么用

装好后任意会话即可，不必打开本仓库。当前这个 Agent 读到技能就会用；Cursor / Codex / Hermes 只是常见宿主，不是前提。

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
