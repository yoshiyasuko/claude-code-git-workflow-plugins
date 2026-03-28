# git-workflow plugin

Claude Code plugin for git workflow automation.

## Commands

| Command | Description |
|---------|-------------|
| `/commit` | Create commits in Conventional Commits format with optional push and lifecycle hooks |
| `/create-pr` | Create or update GitHub PRs with automatic rebase, diff analysis, and lifecycle hooks |
| `/sync-main` | Switch to main, pull latest, and clean up local branches deleted on remote |

## Lifecycle Hooks

Generic commands support project-specific extensions via a **skill hooks** configuration file. Create `.claude/skill-hooks.md` in your project root to map hooks to your project's skills.

### Hook format

```markdown
# Skill Hooks

## commit

| フック | スキル | 説明 |
|-------|-------|------|
| pre-commit | your-skill | Runs before commit (e.g., doc updates, linting) |
| post-push | your-skill | Runs after push with user confirmation (質問: "...", 選択肢: ["...", "..."]) |

## create-pr

| フック | スキル | 説明 |
|-------|-------|------|
| post-pr | your-skill | Runs after PR creation/update with user confirmation |
```

### Available hooks

| Command | Hook | Timing |
|---------|------|--------|
| `/commit` | `pre-commit` | After status check, before staging |
| `/commit` | `post-push` | After push (asks user before executing) |
| `/create-pr` | `post-pr` | After PR create/update (asks user before executing) |

If `.claude/skill-hooks.md` doesn't exist or a hook isn't defined, the step is silently skipped.

## `/commit` arguments

| Argument | Effect |
|----------|--------|
| `skip-hooks` | Skip pre-commit and post-push hooks |
| `skip-push` | Skip push confirmation step |

Other commands (e.g., `/deploy`) can call `/commit skip-push skip-hooks` to run only the core commit workflow.

## Installation

```bash
# From GitHub (private repo)
claude /install-plugin https://github.com/yoshiyasuko/git-workflow-plugin

# Local development
claude --plugin-dir ~/git-workflow-plugin
```

## Example: GAS project hooks

```markdown
# Skill Hooks

## commit

| フック | スキル | 説明 |
|-------|-------|------|
| pre-commit | update-docs | コミット前にドキュメント更新チェックを実行 |
| post-push | deploy | プッシュ後にデプロイするか確認（質問: 「デプロイしますか？」、選択肢: ["デプロイする", "スキップ"]） |

## create-pr

| フック | スキル | 説明 |
|-------|-------|------|
| post-pr | preview-deploy | PR作成/更新後にプレビューデプロイするか確認（質問: 「プレビューデプロイしますか？」、選択肢: ["デプロイする", "スキップ"]） |
```
