# Plan 04 — Hooks and Automation

Defines all 9 hooks wired into `.claude/settings.json` (Batch 11). Hooks are Claude Code's enforcement layer — they run shell commands on tool-call events and can block actions. Windows-compatible: forward slashes in paths, Node.js or Bash via Git Bash shebang.

---

## Event → Hook matrix

| # | Event | Hook name | Behavior | Agents affected |
|---|---|---|---|---|
| 1 | `PreToolUse` (Write, Edit) | `pre-edit-secret-scan.mjs` | Block if file path or content matches secret patterns | all |
| 2 | `PreToolUse` (Write, Edit) | `pre-edit-deny-path.mjs` | Block if path is in deny-list or in agent's per-agent deny_paths | all |
| 3 | `PreToolUse` (Write, Edit) | `pre-edit-skill-declaration.mjs` | Block if agent's last message lacks `[SKILL-DECL]` line | implementation agents |
| 4 | `PreToolUse` (Bash) | `pre-ssh-check.mjs` | Block SSH for non-whitelisted agents; scan for secrets in command | all |
| 5 | `PreCommit` (git) | `pre-commit-secret-scan.sh` | Run gitleaks + fallback regex grep on staged files | all |
| 6 | `PreCommit` (git) | `pre-commit-localization-gate.mjs` | Block commit if any `.xcstrings` key missing `he` or `en` | all |
| 7 | `PreCommit` (git) | `pre-commit-test-gate.mjs` | Block commit to `App/` without corresponding `Tests/` file | implementation agents |
| 8 | `PostToolUse` (Edit, Write) | `post-edit-template-check.mjs` | Warn if hard-coded `AdKan` / `עד כאן` appears in Swift/TS source | all |
| 9 | `SubagentStop` | `subagent-stop-status-update.mjs` | Append turn summary to `plan/status.md` | all |

All hooks live in `scripts/hooks/` (written during Batch 11 alongside `.claude/settings.json`). Hook scripts are Node ESM (`.mjs`) for cross-platform consistency; one is Bash for git integration.

---

## Hook 1 — `pre-edit-secret-scan.mjs`

**Trigger:** every `Write` or `Edit`.
**Block condition:**
- File path matches any deny pattern: `.env` (unless `.env.example`), `*.p8`, `*.p12`, `*.pem`, `*.cer`, `*.mobileprovision`, `AuthKey_*`, `~/.ssh/**`, `**/Keys/**`, `id_rsa*`, `id_ed25519*`.
- OR file **content** matches `/[A-Za-z0-9+/=]{40,}/` outside allowed contexts (docs using example hashes must be tagged `[FAKE]`).
- OR content matches specific prefixes: `sk-`, `pk_live_`, `eyJ` longer than 100 chars (likely JWT), `SUPABASE_SERVICE_ROLE_KEY=<real value>`.

**Exit code:** non-zero = block. Print remediation: "This looks like a secret. Remove it, or tag the context with `[FAKE]` if it's a documentation placeholder."

---

## Hook 2 — `pre-edit-deny-path.mjs`

**Trigger:** every `Write` or `Edit`.
**Block condition:**
- Global deny-list: `.env.local`, `node_modules/**`, `Pods/**`, `DerivedData/**`, `.git/objects/**`, `.git/refs/**` (reading `HEAD` is OK).
- Per-agent: read `.claude/agents/<current-agent>.md` frontmatter `deny_paths`; block if target matches any pattern.

**Exit code:** non-zero = block.

---

## Hook 3 — `pre-edit-skill-declaration.mjs`

**Trigger:** `Write` or `Edit` on source files (`*.swift`, `*.ts`, `*.tsx`, `*.sql`, `*.mjs`, `*.js`).
**Block condition:** the agent's preceding message in this turn lacks a `[SKILL-DECL] ...` line.
**Exit code:** non-zero = block. Print: "Rule 8: print `[SKILL-DECL] <skill or doc reference>` before this edit."

Exempt: `.md`, `.json`, `.yml`, `.xcstrings` — documentation and config don't require skill declaration.

---

## Hook 4 — `pre-ssh-check.mjs`

**Trigger:** `Bash` where command starts with `ssh ` or `scp `.
**Block condition:**
- Current agent not in whitelist: `ios-engineer`, `qa-engineer`, `release-engineer`.
- OR command contains `[A-Za-z0-9+/=]{40,}` literal token.
- OR command references `.p8`, `.p12`, `.pem` file contents inline.

**Side effect:** append one line to `logs/ssh-audit.log` (gitignored): `<ISO timestamp> <agent> <host>`.
**Exit code:** non-zero = block.

---

## Hook 5 — `pre-commit-secret-scan.sh`

**Trigger:** `git commit`.
**Behavior:**
```bash
#!/bin/bash
set -e
if command -v gitleaks >/dev/null; then
  gitleaks protect --staged --redact
fi
# fallback regex sweep
git diff --cached --name-only -z | xargs -0 -I{} grep -HnE '[A-Za-z0-9+/=]{40,}' {} && {
  echo "Possible secret in staged files (regex fallback)."
  exit 1
} || true
```
**Exit code:** non-zero = block commit.

---

## Hook 6 — `pre-commit-localization-gate.mjs`

**Trigger:** `git commit` where staged files include any `*.xcstrings`.
**Behavior:** parse each staged `.xcstrings`, enumerate keys, assert every key has BOTH `he` and `en` entries with non-empty `stringUnit.value`.
**Block condition:** any key missing either language, or containing only whitespace.
**Exit code:** non-zero = block. Print missing keys.

---

## Hook 7 — `pre-commit-test-gate.mjs`

**Trigger:** `git commit` where staged files include any `App/**/*.swift` that is not a `*Tests.swift` file.
**Behavior:**
- For each staged source file `App/Features/<feature>/<Type>.swift`, verify existence of at least one `Tests/<feature>Tests/*Tests.swift` under git tracking.
- Exemption: files matching patterns `App/**/Views/**`, `App/**/Fixtures/**`, `App/**/DesignSystem/**` are exempt (snapshot tests cover views; fixtures and design tokens don't need unit tests).
**Block condition:** non-exempt source file without accompanying tests.
**Exit code:** non-zero = block. Print: "TDD violation: write a failing test first (Rule 5). Exempt view/fixture files end in `View.swift` or live in `Fixtures/`."

---

## Hook 8 — `post-edit-template-check.mjs`

**Trigger:** `Write` or `Edit` on `*.swift`, `*.ts`, `*.tsx`, `*.sql`, `*.mjs`.
**Behavior:** grep staged content for literal `AdKan` or `עד כאן`.
**Block condition:** NONE — this is a **warn-only** hook. It prints a yellow `[template-warn]` line pointing to `config/app-identity.json`.
**Exit code:** always 0.

Allowed exceptions (identified by path):
- `CLAUDE.md`, `plan/**`, `research/**`, `prd/**`, `specs/**`, `adr/**`, `README.md` — prose files, literal names allowed.
- `config/app-identity.json` — the source of truth.
- `App/Localization/**.xcstrings` — user-visible strings.
- `.env.example`, `.env.local`, `package.json`, `Package.swift` manifest strings.

---

## Hook 9 — `subagent-stop-status-update.mjs`

**Trigger:** `SubagentStop` event.
**Behavior:** append to `plan/status.md`:
```
## Turn log
- <ISO timestamp> <subagent name> — <subject> — <files touched count> files — <exit status>
```
Keeps history of what each subagent did. `plan/status.md` is the live dashboard; this hook is why it stays current without manual updates.

---

## Windows-Bash compatibility

All `.mjs` hooks use:
- `path.sep` or `path.posix.join` — never literal `/` or `\` in code.
- `process.platform` checks when shelling out.
- Node's `spawn` with `shell: true` only when necessary; prefer arg arrays.
- Line endings: hooks tolerate both `\r\n` and `\n` when parsing text.

Bash hooks (`pre-commit-secret-scan.sh`) require Git Bash on Windows — which is already installed for any Git for Windows user, including this founder.

---

## Testing hooks before wiring

`scripts/hooks/test-hooks.mjs` (written in Batch 11) runs each hook against a fixture directory:
- `fixtures/pre-edit-secret-scan/` — a file with a fake token should block; a file with `[FAKE] eyJ...` should pass.
- `fixtures/pre-commit-localization-gate/` — an `.xcstrings` missing `he` should block.
- `fixtures/pre-commit-test-gate/` — an `App/Feature/Foo.swift` without corresponding `Tests/FeatureTests/FooTests.swift` should block.

Hook testing runs before the first real commit (Day 1, after `CLAUDE.md` + config + `.env.example` are staged).
