# git-workflow plugin

Claude Code 用の git ワークフロー自動化プラグイン。

## コマンド

| コマンド | 説明 |
|---------|------|
| `/commit` | Conventional Commits 形式でコミットを作成。プッシュ・ライフサイクルフックに対応 |
| `/create-pr` | GitHub PR の作成・更新。自動 rebase、差分分析、ライフサイクルフックに対応 |
| `/sync-main` | main に切り替えて最新化し、リモートで削除済みのローカルブランチをクリーンアップ |

## ライフサイクルフック

プロジェクト固有の拡張を **スキルフック** 設定ファイルで定義できる。プロジェクトルートに `.claude/skill-hooks.md` を作成してフックとスキルを紐付ける。

### フックの書式

```markdown
# Skill Hooks

## commit

| フック | スキル | 説明 |
|-------|-------|------|
| pre-commit | your-skill | コミット前に実行（例: ドキュメント更新、リント） |
| post-push | your-skill | プッシュ後にユーザー確認付きで実行（質問: "...", 選択肢: ["...", "..."]） |

## create-pr

| フック | スキル | 説明 |
|-------|-------|------|
| post-pr | your-skill | PR 作成・更新後にユーザー確認付きで実行 |
```

### 利用可能なフック

| コマンド | フック | タイミング |
|---------|-------|-----------|
| `/commit` | `pre-commit` | ステータス確認後、ステージング前 |
| `/commit` | `post-push` | プッシュ後（実行前にユーザーに確認） |
| `/create-pr` | `post-pr` | PR 作成・更新後（実行前にユーザーに確認） |

`.claude/skill-hooks.md` が存在しない場合やフックが未定義の場合はスキップされる。

## `/commit` の引数

| 引数 | 効果 |
|------|------|
| `skip-hooks` | pre-commit / post-push フックをスキップ |
| `skip-push` | プッシュ確認ステップをスキップ |

他のコマンド（例: `/deploy`）から `/commit skip-push skip-hooks` を呼び出すことで、コアのコミット処理のみを実行できる。

## インストール

### GitHub 経由（推奨）

```bash
# 1. マーケットプレイスを追加
/plugin marketplace add yoshiyasuko/claude-code-git-workflow-plugins

# 2. プラグインをインストール
/plugin install git-workflow@git-workflow-plugins
```

### シンボリックリンク方式（開発者向け）

`git pull` するだけでプラグインが最新に更新される方式。

```bash
git clone git@github.com:yoshiyasuko/claude-code-git-workflow-plugins.git
cd claude-code-git-workflow-plugins
./install.sh
```

`install.sh` は以下を実行する:
1. マーケットプレイスを `~/.claude/plugins/known_marketplaces.json` に登録
2. `~/.claude/plugins/cache/` にシンボリックリンクを作成（コピーではなくリンク）
3. `~/.claude/plugins/installed_plugins.json` にプラグインを登録
4. `~/.claude/settings.json` の `enabledPlugins` でグローバルに有効化

前提: macOS 標準の `python3`（JSON 操作に使用）

## 使用例: GAS プロジェクトのフック

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
