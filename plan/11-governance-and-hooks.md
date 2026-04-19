# Plan 11 — Governance and Hooks

Drift-check process, PR gate matrix, veto protocols, escalation ladder, how `status.md` stays current.

---

## Drift-check process

After each feature (typically end-of-day on Days 3–7), the orchestrator invokes `architecture-auditor` to run drift checks:

1. **Import audit** — grep for `import FamilyControls`, `import DeviceActivity`, `import ManagedSettings`. Allowed only in:
   - `App/ScreenTime/Provider/RealScreenTimeProvider.swift`
   - `DeviceActivityMonitorExtension/**`
   If any other file imports these, flag as drift.
2. **Secret pattern audit** — scan new Swift/TS files for `[A-Za-z0-9+/=]{40,}` tokens.
3. **Schema drift audit** — compare current `supabase/migrations/*.sql` against the lock in `/specs/0002`. Unexpected tables/columns flag for `security-reviewer` review.
4. **Payload shape audit** — verify `DailySyncPayload` still has exactly the ADR-0004 three keys (`DailySyncPayloadAntiDriftTest` is the tripwire).
5. **Localization parity audit** — every `.xcstrings` key has `he` + `en`.
6. **Extension size audit** — `DeviceActivityMonitorExtension.appex` binary size <2 MB stripped (well under 6 MB Jetsam cliff).
7. **Dependency audit** — the extension's `Package.swift` lists only `AdKanAppGroupShared`. No other SPM deps.

Results: posted to `plan/status.md` under `## Drift check — <date>`.

---

## PR gate matrix

Every PR must pass these gates. `required` = merge-blocking. `warn` = annotate only.

| Gate | Level | Owner |
|---|---|---|
| CI build succeeds | required | Xcode Cloud |
| All tests pass | required | Xcode Cloud |
| Snapshot tests match | required | Xcode Cloud |
| SwiftLint clean (warnings-as-errors on critical rules) | required | Xcode Cloud |
| Secret scan clean | required | gitleaks + regex hook |
| Localization parity | required | pre-commit hook 6 |
| TDD proof (test file accompanies source) | required | pre-commit hook 7 |
| `[SKILL-DECL]` declared before code writes | required | pre-edit hook 3 |
| `security-reviewer` review | required on any of: secret, auth, network, RLS, signing | veto-capable |
| `privacy-engineer` review | required on any of: sync payload, analytics event, extension code | veto-capable |
| `localization-lead` review | required on any `.xcstrings` or UI-string Swift file | veto-capable |
| `app-store-reviewer` review | required before App Store submission (not TestFlight) | advisory |
| `architecture-auditor` review | required on module-boundary-affecting changes | advisory |

---

## VETO protocol

Three agents hold VETO: `security-reviewer`, `privacy-engineer`, `localization-lead`.

**When to veto:** when a change makes the product demonstrably worse along that agent's dimension, and the agent has no acceptable amendment.

**How to veto:**
1. Agent comments in the PR with `[VETO] <reason>`.
2. Agent appends a line to `plan/status.md` under `## Vetoes this week`: `- <date> <agent> vetoed "<PR title>": <reason>`.
3. Orchestrator must NOT merge unless either (a) the underlying change is amended to agent's satisfaction, or (b) founder explicitly overrides with `founder-override: <reason>` in chat. Founder overrides are rare by design.

**Standing vetoes** (per-agent pre-commitment, active on every PR):
- `security-reviewer`: any change introducing a new secret, any broadening of RLS policies, any new outbound network call from the extension target.
- `privacy-engineer`: any field added to `DailySyncPayload`, any new PostHog event property with cardinality >10, any Sentry breadcrumb containing usage minutes or friend counts or raw event data.
- `localization-lead`: any Swift file with a user-visible string not routed through `L10n.*`, any `.xcstrings` entry lacking HE or EN, any RTL-sensitive layout without a snapshot test covering it.

---

## Escalation ladder

| Ambiguity class | First owner | Escalates to |
|---|---|---|
| Technical (which library, which pattern) | implementation agent | `architecture-auditor` |
| Product scope / feature cut | `product-strategist` | Founder via `AskUserQuestion` |
| Pricing / copy | founder (locked) | Founder via `AskUserQuestion` for exceptions |
| Security / secret handling | `security-reviewer` | Founder if reviewer wants to merge a risky change |
| Privacy / data export | `privacy-engineer` | Founder if engineer wants to merge a risky change |
| Localization phrasing | `localization-lead` | Founder (native speaker) for Hebrew nuance |
| Schedule / timeline | orchestrator | Founder via `AskUserQuestion` |
| External system availability | agent that hit the block | Founder via `[FOUNDER-ACTION]` in `status.md` |

**AskUserQuestion** is the primary escalation channel during active conversation. **`[FOUNDER-ACTION]` in `status.md`** is the async channel when founder may not be at the keyboard.

Never: invent a default answer. Never: silently downgrade a scope.

---

## `plan/status.md` as live dashboard

Structure enforced by `subagent-stop-status-update.mjs` hook + manual edits:

```markdown
# AdKan — Live Status

**Updated:** <timestamp>

## Current phase
<e.g., "Build — Day 3 afternoon">

## Last commit
<SHA + one-line subject>

## Active blockers
- <none> OR <itemized list>

## Next action
<one sentence>

## Founder actions outstanding
- [ ] <Action ref §plan/02-*>

## Skills loaded
- [x] frontend-design — 2026-04-19
- [ ] owasp

## Turn log (last 20)
- <timestamp> <agent> — <subject> — <files> files — <exit>
- ...

## Drift checks
- <date> clean / issues
- ...

## Vetoes this week
- <none>

## FOUNDER-ACTIONS surfaced since last review
- <itemized>
```

Agents do NOT hand-edit the `Turn log` section — the hook writes it. Other sections are authored by the orchestrator or relevant agent.

---

## Pause-every-4-5-files protocol

After each 4-to-5 file batch (Rule from master plan §12):

1. Orchestrator writes: files touched, tests added, hooks that fired, surprises encountered.
2. Updates `plan/status.md`.
3. Posts a short summary to the founder.
4. Awaits founder `continue` or `pause` or `change X`.
5. Does NOT write more code until response received.

Exception: trivially-dependent files (e.g., a view + its view model + its view-model test written together as an atomic unit) may exceed 5 if they'd be meaningless individually. Document the exception in the status summary.

---

## Commit hygiene

- One logical change per commit. No "misc fixes."
- Conventional-commits style: `feat:`, `fix:`, `test:`, `docs:`, `chore:`, `refactor:`.
- Subject ≤72 chars. Body explains WHY, not WHAT (diff shows what).
- No AI attribution lines in commit messages unless founder asks for them. Commits are the founder's authorship for App Store compliance.
- Never `--no-verify`. Ever. If a hook blocks, fix the underlying issue.
- Never `git push --force` on `main`. Feature branches OK if branch is solely the agent's.
- The agent never pushes without explicit founder authorization. Pushing is a founder-action — agents create PRs only.

---

## Branch strategy (MVP-simple)

- `main` — protected. All merges via PR.
- `feat/<short-name>` — agent-authored feature branches. E.g., `feat/onboarding-q1` or `feat/apns-wiring`.
- No `develop`, no `release`, no long-lived feature branches. 1-to-2-day branch life max.

MVP is too small to warrant gitflow. Revisit if scope grows.

---

## Escaping the `--no-verify` temptation

Hooks will occasionally be wrong. The procedure when a hook blocks legitimately:

1. Read the hook's output. Understand the pattern it matched.
2. If the match is a true positive → fix the code.
3. If the match is a false positive → amend the hook (not bypass it). Pin the fix in a separate commit. Add a test fixture in `scripts/hooks/fixtures/` that covers the new edge case.
4. Never `--no-verify`. Never. If founder is on call, escalate. If not, leave the change uncommitted and escalate via `[FOUNDER-ACTION]` in status.md.

The bypass path corrupts the governance signal that makes the rest of these hooks trustworthy.
