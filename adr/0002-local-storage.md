# ADR 0002 — Local Storage

**Status:** Accepted.
**Date:** 2026-04-18.
**Deciders:** architecture-auditor, ios-engineer, privacy-engineer.

## Context

AdKan stores sensitive data locally:
- Survey answers (PRD 0001).
- Cached leaderboard entries.
- Cached entitlement state.
- Crumbs from the DeviceActivityMonitor extension (raw usage events).

A device lost or jailbroken should not leak any of this. Encryption-at-rest is a non-negotiable for the `privacy-engineer` veto.

iOS 16 deployment target rules out SwiftData (iOS 17+ only).

## Decision

Use **GRDB.swift + SQLCipher** for the main-app local SQLite database. The `DeviceActivityMonitor` extension writes to a separate shared-App-Group SQLite file using the system `sqlite3` C library directly (no GRDB, no SDKs in the extension — see `/specs/0004-privacy-and-permissions.md`).

Specifically:
- Main-app DB: `<Application Support>/adkan.db`, encrypted with a key derived from the user's Keychain-stored passkey. GRDB `DatabasePool` for writer-goroutine concurrency.
- Extension crumbs DB: `<AppGroupContainer>/adkan-extension-crumbs.db`, WAL mode, unencrypted (low sensitivity — only raw event timestamps; aggregation happens in the main app and never leaks).

## Alternatives considered

### Core Data
- **Pros:** Apple-native, stable, mature.
- **Cons:** No native encryption (SQLCipher integration is fragile), verbose boilerplate, NSManagedObject lifecycle pain, no strong typing without third-party generators.

Rejected for encryption story alone.

### SwiftData (iOS 17+)
- **Pros:** modern, macro-based, trivial CRUD.
- **Cons:** iOS 17+ only — violates our iOS 16 deployment target. Also young — known predicate bugs in early 2026.

Rejected.

### Realm
- **Pros:** encryption built-in, mature.
- **Cons:** large binary size (~6 MB unstripped), MongoDB acquisition uncertainty for long-term support, our App Group extension constraint rules it out (Realm is heavy).

Rejected.

### Raw SQLite everywhere (including main app)
- **Pros:** zero dependencies, smallest footprint.
- **Cons:** prepared-statement boilerplate multiplied across features = bugs. Extension is fine with raw SQLite (one call site); main app has dozens.

Rejected for main app; accepted for extension.

## Consequences

**Positive:**
- Encryption at rest with battle-tested SQLCipher.
- GRDB's DatabaseQueue / DatabasePool covers concurrency correctly.
- Type-safe record definitions via `Codable` + `FetchableRecord`.
- Extension stays SDK-free and well under the 6 MB Jetsam cliff.

**Negative:**
- SQLCipher adds ~800KB to the binary.
- GRDB is a single-maintainer project (groue). Mitigation: active for 10+ years, widely used, and the SQL layer underneath is pure SQLite — we can migrate away if needed.
- Two-database architecture (main-app encrypted + extension plain) requires careful migration thinking.

## Implementation notes

- SQLCipher integration via SPM: `https://github.com/duckduckgo/GRDB.swift` fork which bundles SQLCipher, OR use the main GRDB + add SQLCipher as a separate SPM package. Decision deferred to the first actual build; both work.
- Key derivation: app-specific random 256-bit key generated on first launch, stored in the Keychain with `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Never leaves the device; never synced to iCloud.
- Database migrations via GRDB's `DatabaseMigrator` — versioned, tested.
- No `UserDefaults` for sensitive data. `@AppStorage` is fine for UI state (tab index, onboarding completed flag) but never PII or entitlement booleans (the latter is re-verified from StoreKit anyway).
