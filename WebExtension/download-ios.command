set -e
cd "$(dirname "$0")/.."
rm $TMPDIR/ios.zip 2> /dev/null || true
curl -fSL -o $TMPDIR/ios.zip https://github.com/raindropio/app/releases/latest/download/safari-ios-prod.zip
unzip -o $TMPDIR/ios.zip -d WebExtension/ios