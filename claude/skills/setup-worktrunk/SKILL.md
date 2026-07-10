---
name: setup-worktrunk
description: Configure the worktrunk (wt) CLI for a project to use conventional commits. Creates or updates ~/.config/worktrunk/config.toml with a commit message template that follows the conventional commits convention. Use this skill whenever the user says "setup worktrunk", "configure wt", "setup wt commit", "add wt conventions", or wants wt to generate commit messages following a convention.
---

# Setup Worktrunk

Configure `wt` commit message generation to follow the conventional commits convention.

## How wt commit generation works

`wt` generates commit messages by:
1. Filling a template with diff/context variables (`{{ git_diff }}`, `{{ git_diff_stat }}`, `{{ branch }}`, `{{ repo }}`, `{{ recent_commits }}`)
2. Sending the result to a `command` (which reads stdin and writes the commit message to stdout)
3. Using the command's text output as the commit message

Config lives at two levels:
- **User-level** `~/.config/worktrunk/config.toml` — where `command` and `template` must be set (this is the only location wt reads generation config from)
- **Project-level** `.config/wt.toml` — for project-specific settings (hooks, merge config, etc.) but NOT for `command`/`template`

## Steps

### 1. Check existing state

- Run `which wt` to confirm wt is installed; warn if not
- Read `~/.config/worktrunk/config.toml` if it exists; if it already has `[commit.generation]`, offer to update rather than overwrite

### 2. Update `~/.config/worktrunk/config.toml`

Add or replace the `[commit.generation]` block with the following. Create the file and directory if they don't exist. Preserve any other existing sections.

```toml
[commit.generation]
command = "CLAUDECODE= MAX_THINKING_TOKENS=0 claude -p --no-session-persistence --model=haiku --tools='' --disable-slash-commands --setting-sources='' --system-prompt=''"
template = """
Generate a git commit message for the staged changes below.

Follow the Conventional Commits format strictly:

  <type>[optional scope]: <description>

  [optional body]

Types: feat, fix, refactor, perf, test, docs, style, build, ci, chore, revert
- Use imperative mood: "add" not "added"
- One type per commit
- Scope is optional; use it only when it adds clarity
- Description must be short (under 72 chars)
- Add a body only if the description alone doesn't explain the why
- For breaking changes: append ! after the type and add a BREAKING CHANGE: footer
- Output only the commit message — no explanation, no quotes, no code block

<diff_stat>
{{ git_diff_stat }}
</diff_stat>

<diff>
{{ git_diff }}
</diff>

<context>
Branch: {{ branch }}
Repo: {{ repo }}
Recent commits:
{{ recent_commits }}
</context>
"""
```

The `CLAUDECODE=` env var unsets the Claude Code detection flag so the command works when invoked from within a Claude Code session.

### 3. Verify

Run `wt step commit --show-prompt`. The output should start with "Generate a git commit message..." — not the default "Write a commit message...". If it still shows the default, the user-level config is not being picked up.

### 4. Note about project config

If the project has a `.config/wt.toml`, remind the user that generation config (command/template) must live in the user-level file. Project-level `.config/wt.toml` can still hold other wt settings.
