#!/bin/bash
set -euo pipefail

task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$task_root"
task_archive="$task_root/build/AppStore/YarMinsk-signed.xcarchive"
task_export="$task_root/build/AppStore/Upload"

# Requires the developer account for team 2W876M34X7 in Xcode Apple Accounts.
# Always rebuild with signing; never upload the unsigned compilation archive.
xcodebuild -project YarMinsk.xcodeproj -scheme YarMinsk \
  -destination 'generic/platform=iOS' -configuration Release \
  -archivePath "$task_archive" -allowProvisioningUpdates archive

xcodebuild -exportArchive -archivePath "$task_archive" \
  -exportPath "$task_export" \
  -exportOptionsPlist Configuration/AppStoreExport.plist \
  -allowProvisioningUpdates

printf '%s\n' 'Build uploaded. Wait for App Store Connect processing, select the new build, then submit the version for review.'
