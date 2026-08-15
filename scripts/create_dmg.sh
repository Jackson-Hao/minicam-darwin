#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
APP_NAME="MiniCam"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
DMG_TMP="${BUILD_DIR}/dmg_staging"

# 1. Ensure App is built
if [ ! -d "${APP_BUNDLE}" ]; then
    echo "==> [1/4] App bundle not found, running build.sh..."
    "${SCRIPT_DIR}/build.sh"
else
    echo "==> [1/4] Using existing app bundle: ${APP_BUNDLE}"
fi

# 2. Prepare staging directory
echo "==> [2/4] Preparing DMG staging directory..."
rm -rf "${DMG_TMP}" "${DMG_PATH}"
mkdir -p "${DMG_TMP}"

echo "Copying ${APP_NAME}.app..."
cp -R "${APP_BUNDLE}" "${DMG_TMP}/"

echo "Creating /Applications shortcut symlink..."
ln -s /Applications "${DMG_TMP}/Applications"

# 3. Create DMG using hdiutil
echo "==> [3/4] Packaging compressed DMG via hdiutil..."
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${DMG_TMP}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# 4. Clean up staging
echo "==> [4/4] Cleaning up staging..."
rm -rf "${DMG_TMP}"

DMG_SIZE=$(du -sh "${DMG_PATH}" | awk '{print $1}')

echo ""
echo "============================================================"
echo "  🎉 DMG Created Successfully!"
echo "  📦 Output: ${DMG_PATH} (${DMG_SIZE})"
echo "============================================================"
echo "You can mount and verify the DMG by running:"
echo "  open \"${DMG_PATH}\""
