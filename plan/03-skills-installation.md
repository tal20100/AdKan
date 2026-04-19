# Plan 03 — Skills Installation

**Rule 9:** skills are installed by the orchestrator, not the founder. But there is a catch: the `/plugin` slash commands in Claude Code are user-typed, not tool-invokable by the agent. So "installation" here means:

1. **Orchestrator identifies the skill needed** and emits an `[ORCHESTRATOR-ACTION]` note in chat.
2. **Founder types the `/plugin` command once** when the orchestrator asks. This is a one-time keystroke per skill, not per session.
3. **Orchestrator verifies** the skill loaded by greping `.claude/plugins/` or whatever resolution path Claude Code exposes, and caches this in `plan/status.md`.

---

## Required skills by agent

From `plan/01-agent-definitions.md`, consolidated:

| Skill id | Source marketplace | Required by agents |
|---|---|---|
| `frontend-design` | `anthropics/claude-code` | ux-designer, ios-engineer, social-virality-designer |
| `owasp` | `agamm/claude-code-owasp` | security-reviewer |

Any other agent has no hard skill requirement — they work off repo docs (`/research`, `/plan`, `/specs`, `/adr`) plus WebFetch for authoritative Apple / Supabase / Deno / PostHog / Sentry docs.

---

## Installation commands (founder types these)

At the beginning of Day 1 (or the first moment Swift or UI code is about to be written), the orchestrator requests:

```
/plugin marketplace add anthropics/claude-code
/plugin install frontend-design@anthropics-claude-code

/plugin marketplace add agamm/claude-code-owasp
/plugin install owasp@claude-code-owasp
```

Founder pastes these into the Claude Code prompt line one at a time. After each install succeeds, founder types `ok` so the orchestrator can resume.

---

## Fallback if a skill is unavailable

Some marketplace skills may not exist with the exact IDs above in the 2026 ecosystem. If `/plugin install` fails:

1. Orchestrator notes it in `plan/status.md` as `[SKILL-UNAVAILABLE] <id>`.
2. Orchestrator writes an inline `SKILL.md` stub at `docs/skills/<skill-id>.md` describing the knowledge the skill was supposed to provide. Content is derived from authoritative sources (Apple HIG for frontend-design, OWASP Top 10 2026 for owasp).
3. Agents substitute `[SKILL-DECL] docs/skills/<skill-id>.md` for the missing marketplace reference.

Example SKILL.md stub for `frontend-design`:

```markdown
# SKILL: frontend-design (local fallback)

## Sources
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines
- SwiftUI documentation: https://developer.apple.com/documentation/swiftui
- iOS 16/17 system design: SF Symbols, Dynamic Type, system colors, safe areas, RTL semantics

## AdKan-specific layering
- Hebrew first — `.environment(\.layoutDirection, .rightToLeft)` at the root of HE views.
- SF Symbols preferred over custom iconography in v1.
- System colors (`.primary`, `.secondary`, `Color.accentColor`) — no hex literals outside DesignSystem.
- Dynamic Type compliant; no hard-coded font sizes.
- Safe area + keyboard avoidance via SwiftUI built-ins; no manual offsets.
```

---

## Skill declaration format (Rule 8)

Every code Write or Edit must be preceded by a `[SKILL-DECL]` line in the agent's own output. Format:

```
[SKILL-DECL] <skill-id | docs/skills/<id>.md | adr/000X-*.md | research/*.md | Apple doc URL>
```

Examples:

```
[SKILL-DECL] frontend-design + adr/0001-state-management.md
[SKILL-DECL] owasp + specs/0002-leaderboard-core.md §RLS
[SKILL-DECL] docs/skills/frontend-design.md  (marketplace unavailable, local fallback)
```

The pre-edit hook `pre-edit-skill-declaration.mjs` (see `plan/04-hooks-and-automation.md`) inspects the agent's preceding message for this line and blocks the Write/Edit if absent.

---

## Cache in `plan/status.md`

Once a skill loads successfully, `plan/status.md` gets a line like:

```
## Skills loaded
- [x] frontend-design@anthropics-claude-code — loaded 2026-04-19
- [x] owasp@claude-code-owasp — loaded 2026-04-19
- [ ] <any future skill>
```

Agents check this section before invoking `[SKILL-DECL]` with a marketplace id to confirm the skill is actually available this session.

---

## When orchestrator requests skills

Not on Day-1 first command. The Day-1 first three commands in §7 of the master plan touch only governance files + the hello-mac smoke test. No UI or security code gets written until Day 2 at earliest. Orchestrator requests skills just before they're needed:

- Before any `ux-designer` or `ios-engineer` Write that touches SwiftUI → request `frontend-design`.
- Before `security-reviewer` does their first diff review → request `owasp`.

Requesting a skill just-in-time keeps the founder's first-hour onboarding minimal and avoids `/plugin` commands that turn out to be unnecessary.
