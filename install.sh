#!/usr/bin/env bash
set -euo pipefail

# git-workflow-plugins installer
# シンボリックリンク方式でインストールするため、git pull で自動更新される

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_NAME="git-workflow"
MARKETPLACE_NAME="git-workflow-plugins"
CLAUDE_DIR="$HOME/.claude"
PLUGINS_DIR="$CLAUDE_DIR/plugins"
CACHE_DIR="$PLUGINS_DIR/cache/$MARKETPLACE_NAME/$PLUGIN_NAME"
KNOWN_MARKETPLACES="$PLUGINS_DIR/known_marketplaces.json"
INSTALLED_PLUGINS="$PLUGINS_DIR/installed_plugins.json"
GLOBAL_SETTINGS="$CLAUDE_DIR/settings.json"

# 色付き出力
info()  { printf '\033[1;34m%s\033[0m\n' "$1"; }
ok()    { printf '\033[1;32m%s\033[0m\n' "$1"; }
error() { printf '\033[1;31m%s\033[0m\n' "$1" >&2; }

mkdir -p "$PLUGINS_DIR"

# --- JSON更新ヘルパー（jq不要） ---
# 指定キーのブロックを更新または追加する
update_json_block() {
  local file="$1" key="$2" block="$3"

  if [ ! -f "$file" ]; then
    printf '{\n%s\n}\n' "$block" > "$file"
    return
  fi

  if grep -q "\"$key\"" "$file"; then
    # 既存キーを置換: キー行から対応する閉じブラケットまで
    # 安全のため、一旦全体を書き直す方式
    local tmp="${file}.tmp"
    python3 -c "
import json, sys
with open('$file') as f:
    data = json.load(f)
# block is valid JSON wrapped in key
patch = json.loads('{' + '''$block''' + '}')
data.update(patch)
with open('$tmp', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
    mv "$tmp" "$file"
  else
    # 末尾の } の前にブロックを挿入
    local tmp="${file}.tmp"
    python3 -c "
import json, sys
with open('$file') as f:
    data = json.load(f)
patch = json.loads('{' + '''$block''' + '}')
data.update(patch)
with open('$tmp', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
    mv "$tmp" "$file"
  fi
}

# --- 1. マーケットプレイスを登録 ---
info "マーケットプレイスを登録中..."

NOW="$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"

MARKETPLACE_BLOCK="\"$MARKETPLACE_NAME\": {
    \"source\": { \"source\": \"directory\", \"path\": \"$SCRIPT_DIR\" },
    \"installLocation\": \"$SCRIPT_DIR\",
    \"lastUpdated\": \"$NOW\"
  }"

update_json_block "$KNOWN_MARKETPLACES" "$MARKETPLACE_NAME" "$MARKETPLACE_BLOCK"

# --- 2. キャッシュをシンボリックリンクに置換 ---
info "シンボリックリンクを作成中..."

PLUGIN_SOURCE="$SCRIPT_DIR/plugins/$PLUGIN_NAME"

if [ ! -d "$PLUGIN_SOURCE" ]; then
  error "プラグインが見つかりません: $PLUGIN_SOURCE"
  exit 1
fi

# 既存のキャッシュを削除（ディレクトリまたはシンボリックリンク）
if [ -L "$CACHE_DIR" ]; then
  rm "$CACHE_DIR"
elif [ -d "$CACHE_DIR" ]; then
  rm -rf "$CACHE_DIR"
fi

mkdir -p "$(dirname "$CACHE_DIR")"
ln -s "$PLUGIN_SOURCE" "$CACHE_DIR"

# --- 3. installed_plugins.json を更新 ---
info "インストール情報を登録中..."

PLUGIN_KEY="$PLUGIN_NAME@$MARKETPLACE_NAME"

# installed_plugins.json は "version" + "plugins" のネスト構造
if [ ! -f "$INSTALLED_PLUGINS" ]; then
  cat > "$INSTALLED_PLUGINS" << EOJSON
{
  "version": 2,
  "plugins": {
    "$PLUGIN_KEY": [
      {
        "scope": "user",
        "installPath": "$CACHE_DIR",
        "version": "symlink",
        "installedAt": "$NOW",
        "lastUpdated": "$NOW"
      }
    ]
  }
}
EOJSON
else
  TMP="${INSTALLED_PLUGINS}.tmp"
  python3 -c "
import json
with open('$INSTALLED_PLUGINS') as f:
    data = json.load(f)
data.setdefault('plugins', {})['$PLUGIN_KEY'] = [{
    'scope': 'user',
    'installPath': '$CACHE_DIR',
    'version': 'symlink',
    'installedAt': '$NOW',
    'lastUpdated': '$NOW'
}]
with open('$TMP', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
  mv "$TMP" "$INSTALLED_PLUGINS"
fi

# --- 4. グローバル settings.json で enabledPlugins を有効化 ---
info "グローバル設定を更新中..."

if [ -f "$GLOBAL_SETTINGS" ]; then
  TMP="${GLOBAL_SETTINGS}.tmp"
  python3 -c "
import json
with open('$GLOBAL_SETTINGS') as f:
    data = json.load(f)
data.setdefault('enabledPlugins', {})['$PLUGIN_KEY'] = True
with open('$TMP', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
"
  mv "$TMP" "$GLOBAL_SETTINGS"
else
  cat > "$GLOBAL_SETTINGS" << EOJSON
{
  "enabledPlugins": {
    "$PLUGIN_KEY": true
  }
}
EOJSON
fi

# --- 5. プラグインソース内のバージョンキャッシュを削除 ---
# シンボリックリンク経由でプラグインシステムがハッシュ付きディレクトリを作成することがある
for hash_dir in "$PLUGIN_SOURCE"/[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]; do
  if [ -d "$hash_dir" ]; then
    rm -rf "$hash_dir"
    info "キャッシュを削除: $(basename "$hash_dir")"
  fi
done

# --- 完了 ---
echo ""
ok "✓ インストール完了!"
echo ""
echo "  マーケットプレイス: $MARKETPLACE_NAME"
echo "  プラグイン:         $PLUGIN_NAME"
echo "  リンク:             $CACHE_DIR -> $PLUGIN_SOURCE"
echo ""
echo "  Claude Code で /reload-plugins を実行してください。"
echo "  git pull するだけでプラグインが最新に更新されます。"
