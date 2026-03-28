#!/usr/bin/env bash
set -euo pipefail

# git-workflow-plugins uninstaller
# install.sh で作成した設定・シンボリックリンクを全て削除する

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_NAME="git-workflow"
MARKETPLACE_NAME="git-workflow-plugins"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
CACHE_DIR="$PLUGINS_DIR/cache/$MARKETPLACE_NAME"
KNOWN_MARKETPLACES="$PLUGINS_DIR/known_marketplaces.json"
INSTALLED_PLUGINS="$PLUGINS_DIR/installed_plugins.json"
GLOBAL_SETTINGS="$CLAUDE_DIR/settings.json"

# 色付き出力
info()  { printf '\033[1;34m%s\033[0m\n' "$1"; }
ok()    { printf '\033[1;32m%s\033[0m\n' "$1"; }
warn()  { printf '\033[1;33m%s\033[0m\n' "$1"; }

PLUGIN_KEY="$PLUGIN_NAME@$MARKETPLACE_NAME"

# --- 1. シンボリックリンク・キャッシュを削除 ---
info "キャッシュを削除中..."

if [ -L "$CACHE_DIR/$PLUGIN_NAME" ] || [ -d "$CACHE_DIR" ]; then
  rm -rf "$CACHE_DIR"
  ok "  削除: $CACHE_DIR"
else
  warn "  スキップ: $CACHE_DIR（存在しない）"
fi

# --- 2. installed_plugins.json からプラグインを削除 ---
info "インストール情報を削除中..."

if [ -f "$INSTALLED_PLUGINS" ]; then
  TMP="${INSTALLED_PLUGINS}.tmp"
  python3 -c "
import json
with open('$INSTALLED_PLUGINS') as f:
    data = json.load(f)
data.get('plugins', {}).pop('$PLUGIN_KEY', None)
with open('$TMP', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
  mv "$TMP" "$INSTALLED_PLUGINS"
  ok "  削除: $PLUGIN_KEY from installed_plugins.json"
else
  warn "  スキップ: installed_plugins.json（存在しない）"
fi

# --- 3. known_marketplaces.json からマーケットプレイスを削除 ---
info "マーケットプレイス登録を削除中..."

if [ -f "$KNOWN_MARKETPLACES" ]; then
  TMP="${KNOWN_MARKETPLACES}.tmp"
  python3 -c "
import json
with open('$KNOWN_MARKETPLACES') as f:
    data = json.load(f)
data.pop('$MARKETPLACE_NAME', None)
with open('$TMP', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
  mv "$TMP" "$KNOWN_MARKETPLACES"
  ok "  削除: $MARKETPLACE_NAME from known_marketplaces.json"
else
  warn "  スキップ: known_marketplaces.json（存在しない）"
fi

# --- 4. グローバル settings.json から enabledPlugins を削除 ---
info "グローバル設定を更新中..."

if [ -f "$GLOBAL_SETTINGS" ]; then
  TMP="${GLOBAL_SETTINGS}.tmp"
  python3 -c "
import json
with open('$GLOBAL_SETTINGS') as f:
    data = json.load(f)
data.get('enabledPlugins', {}).pop('$PLUGIN_KEY', None)
with open('$TMP', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
  mv "$TMP" "$GLOBAL_SETTINGS"
  ok "  削除: $PLUGIN_KEY from settings.json"
else
  warn "  スキップ: settings.json（存在しない）"
fi

# --- 5. プラグインソース内のバージョンキャッシュを削除 ---
PLUGIN_SOURCE="$SCRIPT_DIR/plugins/$PLUGIN_NAME"
for hash_dir in "$PLUGIN_SOURCE"/[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]; do
  if [ -d "$hash_dir" ]; then
    rm -rf "$hash_dir"
    ok "  削除: バージョンキャッシュ $(basename "$hash_dir")"
  fi
done

# --- 完了 ---
echo ""
ok "✓ アンインストール完了!"
echo ""
echo "  Claude Code で /reload-plugins を実行してください。"
