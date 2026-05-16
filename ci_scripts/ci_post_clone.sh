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

# Diagnostic: show how XcodeGen embedded extensions (no modification)
PBXPROJ="$CI_PRIMARY_REPOSITORY_PATH/AdKan.xcodeproj/project.pbxproj"
echo "=== Extension embed phases ==="
grep -B 1 -A 8 "Embed.*Extensions" "$PBXPROJ" || echo "No embed phases found"
echo "=== End embed phases ==="

echo "=== ci_post_clone: done ==="
