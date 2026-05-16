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

# Fail fast if NSExtensionPrincipalClass leaks into DeviceActivityReport
PBXPROJ="$CI_PRIMARY_REPOSITORY_PATH/AdKan.xcodeproj/project.pbxproj"
echo "=== Verifying DeviceActivityReport has no NSExtensionPrincipalClass ==="
if grep -A 50 "DeviceActivityReport" "$PBXPROJ" | grep -q "NSExtensionPrincipalClass"; then
    echo "FATAL: NSExtensionPrincipalClass found in DeviceActivityReport!"
    exit 1
fi
echo "PASS: DeviceActivityReport clean"

# Diagnostic: show how XcodeGen embedded extensions
echo "=== Extension embed phases ==="
grep -B 1 -A 8 "Embed.*Extension" "$PBXPROJ" || echo "No embed phases found"
echo "=== End embed phases ==="

echo "=== ci_post_clone: done ==="
