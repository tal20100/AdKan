#!/bin/bash
set -e

echo "=== ci_post_clone: generating Xcode project ==="

if ! command -v xcodegen &> /dev/null; then
    echo "Installing xcodegen..."
    brew install xcodegen
fi

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Generate SupabaseSecrets.plist BEFORE xcodegen so it's included in the project
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "Generating SupabaseSecrets.plist..."
    cat > App/SupabaseSecrets.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>SUPABASE_URL</key>
    <string>${SUPABASE_URL}</string>
    <key>SUPABASE_ANON_KEY</key>
    <string>${SUPABASE_ANON_KEY}</string>
</dict>
</plist>
PLIST
    echo "SupabaseSecrets.plist created."
else
    echo "WARNING: SUPABASE_URL or SUPABASE_ANON_KEY not set."
fi

xcodegen generate

echo "=== ci_post_clone: done ==="
