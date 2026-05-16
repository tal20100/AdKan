#!/bin/bash
set -e

echo "=== ci_post_clone: generating Xcode project ==="

if ! command -v xcodegen &> /dev/null; then
    echo "Installing xcodegen..."
    brew install xcodegen
fi

cd "$CI_PRIMARY_REPOSITORY_PATH"

# Overwrite the stub SupabaseSecrets.swift with real credentials
if [ -n "$SUPABASE_URL" ] && [ -n "$SUPABASE_ANON_KEY" ]; then
    echo "Injecting Supabase credentials into SupabaseSecrets.swift..."
    cat > App/Backend/SupabaseSecrets.swift <<SWIFT
enum SupabaseSecrets {
    static let url = "${SUPABASE_URL}"
    static let anonKey = "${SUPABASE_ANON_KEY}"
}
SWIFT
    echo "SupabaseSecrets.swift written with real credentials."
else
    echo "WARNING: SUPABASE_URL or SUPABASE_ANON_KEY not set — app will run in offline mode."
fi

xcodegen generate

# Fix ExtensionKit extension embed phase
# XcodeGen may generate incorrect dstPath for ExtensionKit extensions,
# causing "must be embedded in Extensions directory" export failures.
PBXPROJ="$CI_PRIMARY_REPOSITORY_PATH/AdKan.xcodeproj/project.pbxproj"
if grep -q "Embed ExtensionKit Extensions" "$PBXPROJ"; then
    echo "Fixing ExtensionKit embed phase..."
    echo "Before:"
    grep -A 5 "Embed ExtensionKit Extensions" "$PBXPROJ" || true

    sed -i '' '/Embed ExtensionKit Extensions/,/};/{
        s|dstPath = ".*";|dstPath = "\$(EXTENSIONS_FOLDER_PATH)";|
        s|dstSubfolderSpec = [0-9]*;|dstSubfolderSpec = 16;|
    }' "$PBXPROJ"

    echo "After:"
    grep -A 5 "Embed ExtensionKit Extensions" "$PBXPROJ" || true
fi

echo "=== ci_post_clone: done ==="
