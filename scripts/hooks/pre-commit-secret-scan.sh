#!/usr/bin/env bash
# scripts/hooks/pre-commit-secret-scan.sh
# Invoked from .git/hooks/pre-commit (wired up during Day 1 setup).
# Fails commit if any staged file contains a secret-looking token.
set -e

# Prefer gitleaks if installed.
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks protect --staged --redact || {
    echo "[pre-commit-secret-scan] gitleaks flagged a secret. Fix before committing."
    exit 1
  }
fi

# Fallback regex sweep over staged text files.
STAGED=$(git diff --cached --name-only --diff-filter=ACM)
FAIL=0

while IFS= read -r f; do
  [ -z "$f" ] && continue
  # skip binaries and docs that legitimately carry example tokens
  case "$f" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.pdf|*.zip|*.ipa|*.mobileprovision) continue ;;
    .env.example|*.xcstrings) continue ;;
  esac
  if [ -f "$f" ]; then
    # High-entropy token check; allow [FAKE] tag
    if grep -HnE '[A-Za-z0-9+/=]{40,}' "$f" | grep -v '\[FAKE\]' >/dev/null 2>&1; then
      echo "[pre-commit-secret-scan] possible secret in: $f"
      grep -HnE '[A-Za-z0-9+/=]{40,}' "$f" | grep -v '\[FAKE\]' | head -n 3
      FAIL=1
    fi
    # Known prefix patterns
    if grep -HnE 'sk-[A-Za-z0-9]{20,}|pk_live_[A-Za-z0-9]{20,}|-----BEGIN (PRIVATE|RSA PRIVATE|EC PRIVATE|OPENSSH PRIVATE) KEY-----' "$f" >/dev/null 2>&1; then
      echo "[pre-commit-secret-scan] known-secret pattern in: $f"
      FAIL=1
    fi
  fi
done <<< "$STAGED"

if [ "$FAIL" -ne 0 ]; then
  echo "[pre-commit-secret-scan] aborting commit."
  exit 1
fi

exit 0
