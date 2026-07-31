#!/bin/sh
set -e

# Install sentry
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_UPGRADE=1
brew install getsentry/tools/sentry-cli

cd $CI_PRIMARY_REPOSITORY_PATH

# Decode GoogleService-Info.plist from environment variable
echo "$GOOGLE_SERVICE_INFO_BASE64" | base64 --decode > App/GoogleService-Info.plist

# Download Safari extension builds
sh WebExtension/download-ios.command
sh WebExtension/download-macos.command