#!/usr/bin/env bash
# 把 assets/ios_icons/AppIcon.appiconset 应用到 iOS 工程。
# 需要先生成 ios/ 目录（flutter create --platforms=ios .）。
#
# 用法：
#   bash tool/apply_ios_icon.sh                       # 默认写入 ios/Runner/Assets.xcassets/AppIcon.appiconset
#   bash tool/apply_ios_icon.sh <目标 AppIcon.appiconset 路径>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/assets/ios_icons/AppIcon.appiconset"
DEST="${1:-$ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset}"

if [ ! -d "$SRC" ]; then
  echo "找不到图标源目录: $SRC" >&2
  exit 1
fi

if [ ! -d "$(dirname "$DEST")" ]; then
  echo "找不到 iOS 资源目录: $(dirname "$DEST")" >&2
  echo "请先执行: flutter create --platforms=ios --org com.valo2 --project-name copyd ." >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST"
cp -R "$SRC/." "$DEST/"

echo "已应用 App 图标 -> $DEST"
ls -1 "$DEST" | sed 's/^/  /'
