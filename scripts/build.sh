#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
APP_NAME="MiniCam"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "==> [1/5] Checking App Icon..."
if [ ! -f "${ROOT_DIR}/Resources/AppIcon.icns" ]; then
    echo "Generating AppIcon.icns..."
    python3 "${SCRIPT_DIR}/generate_icon.py"
fi

echo "==> [2/5] Cleaning previous build..."
rm -rf "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

echo "==> [3/5] Compiling Swift source files..."
SWIFT_FILES=(
    "${ROOT_DIR}/App/MediaManager.swift"
    "${ROOT_DIR}/App/CameraController.swift"
    "${ROOT_DIR}/App/CameraPreviewView.swift"
    "${ROOT_DIR}/App/ContentView.swift"
    "${ROOT_DIR}/App/MiniCamApp.swift"
)

TARGET_ARCH="arm64-apple-macosx14.0"

swiftc \
    -O \
    -whole-module-optimization \
    -swift-version 5 \
    -target "${TARGET_ARCH}" \
    -parse-as-library \
    -framework SwiftUI \
    -framework AppKit \
    -framework AVFoundation \
    -framework CoreMedia \
    -framework UniformTypeIdentifiers \
    "${SWIFT_FILES[@]}" \
    -o "${MACOS_DIR}/${APP_NAME}"

echo "==> [4/5] Packaging .app bundle..."
cp "${ROOT_DIR}/Resources/Info.plist" "${CONTENTS_DIR}/Info.plist"
cp "${ROOT_DIR}/Resources/AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"

# Create standard PkgInfo
echo "APPL????" > "${CONTENTS_DIR}/PkgInfo"

# Set executable permission
chmod +x "${MACOS_DIR}/${APP_NAME}"

echo "==> [5/5] Ad-hoc code signing..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo ""
echo "============================================================"
echo "  🎉 Successfully built: ${APP_BUNDLE}"
echo "============================================================"
echo "You can launch the app by running:"
echo "  open \"${APP_BUNDLE}\""
