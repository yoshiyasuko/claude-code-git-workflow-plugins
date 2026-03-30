# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 概要

`git-workflow` プラグインをホストする Claude Code プラグインマーケットプレイス。git ワークフロー自動化をスラッシュコマンドとして提供する。

## アーキテクチャ

- `.claude-plugin/marketplace.json` — マーケットプレイスマニフェスト（名前、オーナー、プラグイン一覧）
- `plugins/git-workflow/.claude-plugin/plugin.json` — プラグインマニフェスト（名前、説明、作者）
- `plugins/git-workflow/commands/*.md` — 各ファイルがスラッシュコマンドを定義するMarkdownプロンプト。ファイル名がコマンド名になる（例: `commit.md` → `/commit`）

### コマンドの設計パターン

コマンドは日本語の手順書形式で記述されている。共通規約：
- ユーザー確認には `AskUserQuestion` ツールを使用（テキスト内での質問はしない）
- 利用先プロジェクトの `.claude/skill-hooks.md` による**ライフサイクルフック**に対応 — コマンドがこのファイルを読み込み、フックポイントで `Skill` ツール経由で指定スキルを実行する
- git コミットメッセージは HEREDOC 構文で渡す（シェルのエスケープ問題を回避）
- コミットメッセージと PR タイトルは Conventional Commits 形式（`<type>(<scope>): <subject>`）

### ライフサイクルフックシステム

プロジェクトルートに `.claude/skill-hooks.md` を定義することで、コマンドをプロジェクト固有に拡張できる：
- `/commit`: `pre-commit`（ステージング前）、`post-push`（プッシュ後、ユーザー確認付き）
- `/create-pr`: `post-pr`（PR 作成・更新後、ユーザー確認付き）

フック対応コマンドは `skip-pre-hooks`（pre フックをスキップ）と `skip-post-hooks`（post フックをスキップ）引数でフック実行を個別にバイパスできる。`/commit` は `skip-push` 引数でプッシュステップもスキップ可能。`/create-pr` も同じ `skip-pre-hooks` / `skip-post-hooks` 引数を受け取り、内部の `/commit` 呼び出しや自身の post-pr フックに反映する。

### コマンド間の依存関係

`/create-pr` は未コミット変更がある場合に `/commit` を（Skill ツール経由で）呼び出す。常に `skip-push skip-post-hooks` を渡し（プッシュと post-push フックは create-pr 側で管理）、`skip-pre-hooks` は create-pr 自身の引数に含まれている場合のみ転送する。呼び出し後は create-pr フローのステップ4から再開する。`commit.md` および `create-pr.md` 双方にフロー復帰の指示を記述し、制御が途切れないようにしている。
