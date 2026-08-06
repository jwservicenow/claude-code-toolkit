# Claude Code Setup Guide
## Dual-Subscription Configuration — Personal Pro + Enterprise
**macOS**

This guide is for anyone running both a Personal Claude Pro subscription and a work Claude Enterprise plan on the same Mac. The technique keeps the two configs, auth tokens, MCP servers, and session histories cleanly separated so work data never flows through your personal account.

---

## Prerequisites

Before starting, confirm you have:

- Claude Pro subscription (personal) and/or work Claude Enterprise access
- macOS with Homebrew installed — if not: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Claude Code installed: `curl -fsSL https://claude.ai/install.sh | bash`
- Find your claude binary path (you'll need this): `/usr/bin/which claude`

---

## Concept — Why This Setup Matters

Claude Code stores config, session history, MCP servers, and auth tokens in a single directory (`~/.claude/` by default). If you use both a Personal Pro and a work Enterprise subscription from the same config, you risk:

- Work data flowing through your personal account
- Session history and file access crossing the personal/work boundary
- Enterprise compliance issues under your company's acceptable use policy

The solution is two separate config directories, two aliases, and one blocked default.

---

## Step 1 — Create Local Directory Structure

```bash
mkdir -p ~/ClaudeOS/personal/inbox
mkdir -p ~/ClaudeOS/personal/outputs
mkdir -p ~/ClaudeOS/personal/projects
mkdir -p ~/ClaudeOS/personal/prompts
mkdir -p ~/ClaudeOS/work/inbox
mkdir -p ~/ClaudeOS/work/outputs
mkdir -p ~/ClaudeOS/work/projects
mkdir -p ~/ClaudeOS/work/prompts
```

**What each folder is for:**

| Folder | Purpose |
|---|---|
| `inbox/` | Staging area for files before moving into a project |
| `outputs/` | Downloaded artifacts from Claude Chat sessions |
| `projects/` | Subfolders per customer or project |
| `prompts/` | Saved system prompts and instructions |

> **Important:** Claude Chat does NOT sync to your local machine. Artifacts, uploaded files, and conversation history all stay in Anthropic's cloud. You are the sync mechanism — download and save anything you want to keep.

---

## Step 2 — Create Separate Config Directories

```bash
mkdir -p ~/.claude-personal
mkdir -p ~/.claude-work
```

---

## Step 3 — Configure Shell Aliases

```bash
nano ~/.zshrc
```

Add these three lines — replace `/Users/YOUR_USERNAME/.local/bin/claude` with your actual binary path from the prerequisite step:

```bash
alias claudep='cd ~/ClaudeOS/personal && CLAUDE_CONFIG_DIR=$HOME/.claude-personal /Users/YOUR_USERNAME/.local/bin/claude'
alias claudew='cd ~/ClaudeOS/work && CLAUDE_CONFIG_DIR=$HOME/.claude-work /Users/YOUR_USERNAME/.local/bin/claude'
alias claude='echo "⚠️  Use claudep (personal) or claudew (work) instead of bare claude."'
```

Save with `Ctrl+X` → `Y` → Enter, then reload:

```bash
source ~/.zshrc
```

**Test the block works:**
```bash
claude
```
Should print: `⚠️  Use claudep (personal) or claudew (work) instead of bare claude.`

---

## Step 4 — Restrict the Default Orphan Config

The default `~/.claude/` config still exists and has broad access. Restrict it:

```bash
nano ~/.claude/settings.json
```

Replace entire contents with:
```json
{
  "mcpServers": {}
}
```

Save with `Ctrl+X` → `Y` → Enter.

---

## Step 5 — Authenticate Personal Pro

```bash
claudep
```

- Select: `1. Claude account with subscription`
- Log in with your personal Claude account
- Run `/status` inside Claude Code — confirm your personal email shows
- Run `/exit`

---

## Step 6 — Authenticate Work Enterprise

```bash
claudew
```

- Select: `1. Claude account with subscription`
- Enter `your.name@company.com`
- Click **Continue with SSO** — do NOT use password or Google
- Complete your company's SSO authentication
- Click **Authorize** on the Claude Code connection screen
- Run `/status` inside Claude Code — confirm:
  - `Login method: Claude Enterprise account`
  - `Organization: <your company>`
  - `Email: your.name@company.com`
- Run `/exit`

> **Two Chrome profiles tip:** If you use Chrome, create separate profiles for your personal and work accounts. When Claude Code opens a browser for authentication, make sure the correct profile handles it. This avoids token conflicts between accounts.

---

## Step 7 — Add Personal MCP Servers

Run these commands one at a time. These add MCP servers at **user scope** (`-s user`) so they load regardless of which subdirectory you launch from.

> **Note:** The `npx`-based MCP servers below require Node.js 18+. Check with `node --version`; install with `brew install node` if needed.

**filesystem** — gives Claude Code read/write access to your personal Claude folder:
```bash
CLAUDE_CONFIG_DIR=$HOME/.claude-personal /Users/YOUR_USERNAME/.local/bin/claude mcp add filesystem -s user -- npx -y @modelcontextprotocol/server-filesystem /Users/YOUR_USERNAME/ClaudeOS/personal
```

**fetch** — allows Claude Code to fetch URLs and web content:
```bash
CLAUDE_CONFIG_DIR=$HOME/.claude-personal /Users/YOUR_USERNAME/.local/bin/claude mcp add fetch -s user -- uvx --with 'mcp<2.0.0' mcp-server-fetch
```

> **Note:** `uvx` requires the `uv` package manager. Install if needed: `brew install uv`

**github** — connects Claude Code to your GitHub account (optional):
```bash
CLAUDE_CONFIG_DIR=$HOME/.claude-personal /Users/YOUR_USERNAME/.local/bin/claude mcp add github -s user -e GITHUB_PERSONAL_ACCESS_TOKEN=YOUR_TOKEN_HERE -- npx -y @modelcontextprotocol/server-github
```

> **GitHub token:** Generate at https://github.com/settings/tokens/new — scopes needed: `repo`, `read:org`, `read:user`. Copy it and paste directly into the Terminal command above — never paste tokens into Claude Chat.

**ollama (optional)** — connects Claude Code to a local AI stack such as Ollama. Replace `192.168.xx.xx` with your Ollama host IP:
```bash
CLAUDE_CONFIG_DIR=$HOME/.claude-personal /Users/YOUR_USERNAME/.local/bin/claude mcp add ollama -s user -e OLLAMA_HOST=http://192.168.xx.xx:11434 -- npx -y ollama-mcp-server
```

**Verify:**
```bash
CLAUDE_CONFIG_DIR=$HOME/.claude-personal /Users/YOUR_USERNAME/.local/bin/claude mcp list
```

---

## Step 8 — Add Work MCP Servers

```bash
CLAUDE_CONFIG_DIR=$HOME/.claude-work /Users/YOUR_USERNAME/.local/bin/claude mcp add filesystem -s user -- npx -y @modelcontextprotocol/server-filesystem /Users/YOUR_USERNAME/ClaudeOS/work /Users/YOUR_USERNAME/Documents/Work "/Users/YOUR_USERNAME/OneDrive - YourCompany"

CLAUDE_CONFIG_DIR=$HOME/.claude-work /Users/YOUR_USERNAME/.local/bin/claude mcp add fetch -s user -- uvx --with 'mcp<2.0.0' mcp-server-fetch
```

> **GitHub for work:** Do NOT connect a personal GitHub token to `claudew` without checking with IT. Your employer may require a company-managed GitHub org.

> **Local AI stack (optional):** If you run a personal local AI stack such as Ollama, you can optionally add it to either config. This is personal infrastructure — not a standard team MCP and not required for work.

**Verify:**
```bash
CLAUDE_CONFIG_DIR=$HOME/.claude-work /Users/YOUR_USERNAME/.local/bin/claude mcp list
```

If your work Enterprise plan provisions MCP servers automatically (e.g., internal data connectors, ticketing, content libraries), they should appear in the list. If they show `! Needs authentication`, launch `claudew` and navigate to each one via `/mcp` to authenticate via SSO.

---

## Step 9 — Create CLAUDE.md Files

`CLAUDE.md` files give Claude Code persistent context about who you are and what you're working on. Claude Code reads them automatically at session start — parent directories first, then project-level files.

**Global** (`~/.claude/CLAUDE.md`) — applies to every session:
```markdown
# Your Name — Global Claude Code Context

## Who I am
- Name: Your Name
- macOS user
- Two Claude subscriptions: Personal Pro and Work Enterprise

## How I like to work
- Be direct and concise
- When I ask to make changes, make them — don't just describe what to do
- Ask before destructive operations (deletes, force pushes, drops)

## Machine
- MacBook, macOS, zsh shell
- `~/.claude-personal/` — Personal Pro CLI config
- `~/.claude-work/`     — Work Enterprise CLI config
- `~/ClaudeOS/personal/`  — Personal projects, prompts, outputs, inbox
- `~/ClaudeOS/work/`      — Work projects, prompts, outputs, inbox
```

**Work** (`~/ClaudeOS/work/CLAUDE.md`) — applies to all `claudew` sessions:
```markdown
# Work Context

## Role
YOUR ROLE at YOUR COMPANY
Focus: your focus areas

## Core domain areas
- list your domains

## File locations
- Work files: `~/ClaudeOS/work/`
- OneDrive sync: `~/OneDrive - YourCompany/`
- Reference docs: `~/Documents/Work/`

## Preferences for work tasks
- Customer-facing output should be professional and polished
- Internal notes can be casual
```

**Project-level** (e.g., `~/ClaudeOS/work/projects/customer-name/CLAUDE.md`):
- Add customer-specific context, current engagement details, key contacts
- Claude Code merges all CLAUDE.md files from parent to project level

---

## Step 10 — Final Verification

Run this complete check:

```bash
# Test aliases
cd ~
claude          # Should print warning
claudep         # Should launch in ~/ClaudeOS/personal with personal account
```

Inside claudep:
```
/status         # Confirm personal account + correct cwd
/mcp            # Confirm User MCPs showing all servers
/exit
```

```bash
claudew         # Should launch in ~/ClaudeOS/work with Enterprise account
```

Inside claudew:
```
/status         # Confirm Enterprise account + correct org
/mcp            # Confirm User MCPs + any Enterprise-provisioned MCPs
/exit
```

---

## Step 11 — VS Code Integration (Optional but Recommended)

Claude Code has deep VS Code integration — file diffs appear in VS Code's diff viewer instead of the terminal, making it much easier to review and approve changes.

### 11.1 — Install VS Code Profiles

Create two separate VS Code profiles to keep personal and work settings, extensions, and git identities separate:

1. Open VS Code
2. Click the **gear icon** bottom left → **Profiles** → **Create Profile**
3. Name it `Personal`
4. Repeat → **Create Profile** → name it `Work`

Switch between profiles by clicking the gear icon → **Profile** → select the one you want.

### 11.2 — Add the `code` Command to PATH

This is required for Claude Code's VS Code integration to work:

1. Press `Cmd+Shift+P` to open the Command Palette
2. Type `shell command`
3. Click **Shell Command: Install 'code' command in PATH**

Verify it worked:
```bash
which code
```
Should return `/usr/local/bin/code` or similar.

### 11.3 — Install the Claude Code VS Code Extension

```bash
code --force --install-extension anthropic.claude-code
```

### 11.4 — The Correct VS Code Workflow

Always use the **integrated terminal** to launch Claude Code — not the Claude Code toolbar icon. The toolbar icon bypasses your aliases and uses the wrong config.

```
1. Switch to correct VS Code profile (Personal or Work)
2. File → Open Folder → select your project folder
3. View → Terminal  (or Ctrl+`)
4. Type claudep or claudew
```

### 11.5 — Verify IDE Integration

Inside claudep or claudew run `/status` and check the IDE line:

```
IDE: Installed VS Code extension ✅
```

If it shows an error, run `/exit` and re-run `claudep` or `claudew` — it usually resolves on the second launch after the extension is installed.

### 11.6 — VS Code Toolbar Icon Warning

The ✳ Claude Code icon in the VS Code toolbar looks useful but **bypasses your alias setup**:

| | Terminal `claudep`/`claudew` | Toolbar ✳ icon |
|---|---|---|
| Uses your config? | ✅ Yes | ❌ No — uses default `~/.claude/` |
| Correct account? | ✅ Yes | ❌ May use wrong account |
| MCPs loaded? | ✅ All servers | ❌ Unreliable |

**Always use the terminal.** Use the toolbar icon only for quick one-off questions where account separation doesn't matter.

---

## Quick Reference

### Daily Usage

| Command | What happens |
|---|---|
| `claudep` | Launches in `~/ClaudeOS/personal` with Personal Pro |
| `claudew` | Launches in `~/ClaudeOS/work` with Work Enterprise |
| `claude` | Blocked — prints warning |

### MCP Scope — Important Lesson

Always add MCP servers with `-s user` flag:
```bash
claude mcp add servername -s user -- command args
```
Without `-s user`, servers are added at project scope and only load from that specific directory. User scope loads them in every session.

### ⚠️ Rules To Remember

- Never paste GitHub tokens, API keys, or passwords in Claude Chat
- Never use bare `claude` — always `claudep` or `claudew`
- Work / customer data goes in `claudew` only — never `claudep`
- Follow your company's AI acceptable use policy for what data can be entered into any AI tool
- Browser downloads go to `~/Downloads` — manually move Claude artifacts to `~/ClaudeOS/*/outputs/`
- Always download artifacts from Claude Chat before closing a session — nothing syncs automatically

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `claudep`/`claudew` shows wrong account | Run `/logout` then `/login` inside the session — use correct Chrome profile |
| MCP servers not loading | Check scope: re-add with `-s user` flag |
| `fetch` MCP fails | Package is Python-based — use `uvx` not npm. Include `--with 'mcp<2.0.0'` (quotes required in a shell) or dependency resolution fails |
| Browser doesn't open for auth | Copy/paste the URL manually — this is normal for Enterprise SSO |
| Accidentally ran bare `claude` | Press `2. No, exit` at the workspace trust prompt |
| MCP config not being picked up | MCP servers belong in `.claude.json`, not `settings.json` |
| IDE extension install failed | Run `Cmd+Shift+P` → install `code` in PATH, then `code --force --install-extension anthropic.claude-code` |
| VS Code diff viewer not showing | Run `/status` inside Claude Code — check IDE line shows `Installed VS Code extension` |
| Toolbar icon uses wrong account | Always use terminal + `claudep`/`claudew` — never the ✳ toolbar icon |

---

*Anthropic Claude Code documentation: https://docs.anthropic.com/en/docs/claude-code/overview*
