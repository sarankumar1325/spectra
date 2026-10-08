#!/bin/bash
set -e

echo "Building Spectra (Release)..."
swift build -c release

APP_NAME="Spectra"
APP_DIR="${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Creating Application Bundle at ${APP_DIR}..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy compiled executable
cp ".build/release/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Copy icon if present
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${RESOURCES_DIR}/AppIcon.icns"
fi

# Create Info.plist
cat <<EOF > "${CONTENTS_DIR}/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.spectra.systemmonitor</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
</dict>
</plist>
EOF

# Sign application bundle ad-hoc for local execution
echo "Code signing ${APP_DIR}..."
codesign --force --deep --sign - "${APP_DIR}"

# Optional direct installation to /Applications
if [ "$1" == "--install" ] || [ "$2" == "--install" ]; then
    echo "Installing ${APP_NAME}.app to /Applications/..."
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "${APP_DIR}" "/Applications/${APP_NAME}.app"
    echo "Installed to /Applications/${APP_NAME}.app"
fi

# Create standalone zip archive
ZIP_NAME="${APP_NAME}-v1.0.0-macOS.zip"
echo "Creating zip archive: ${ZIP_NAME}..."
rm -f "${ZIP_NAME}"
ditto -c -k --sequesterRsrc --keepParent "${APP_DIR}" "${ZIP_NAME}"

# Create drag-and-drop installer DMG if requested or by default
DMG_NAME="${APP_NAME}-v1.0.0-macOS.dmg"
echo "Creating drag-and-drop DMG: ${DMG_NAME}..."
rm -f "${DMG_NAME}"
STAGING_DIR=".dmg_staging"
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
cp -R "${APP_DIR}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"
hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGING_DIR}" -ov -format UDZO "${DMG_NAME}" >/dev/null
rm -rf "${STAGING_DIR}"

echo ""
echo "=== Spectra Local Build Complete ==="
echo "1. Application Bundle: ${APP_DIR} (signed, ready to launch)"
echo "2. Disk Image:         ${DMG_NAME} (drag-and-drop installer)"
echo "3. Portable Zip:       ${ZIP_NAME}"
echo ""
echo "To launch immediately: open ${APP_DIR}"
echo "To install to /Applications: ./bundle_app.sh --install"
