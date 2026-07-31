set -e
cd "$(dirname "$0")/.."
rm $TMPDIR/macos.zip 2> /dev/null || true
curl -fSL -o $TMPDIR/macos.zip https://github.com/raindropio/app/releases/latest/download/safari-prod.zip
unzip -o $TMPDIR/macos.zip -d WebExtension/macos