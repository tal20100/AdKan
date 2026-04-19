# Spec 0003 — Monetization and Paywall (implementation)

**Implements:** `/prd/0003-monetization-and-paywall.md`.
**Owner:** payments-engineer. **Reviewers:** security-reviewer (veto), qa-engineer, app-store-reviewer.

## App Store Connect products

Three products, all under the same app record (`com.taltalhayun.adkan`). Configured manually by founder per `/plan/02-infrastructure-setup.md` §app-store-connect.

| Product ID | Type | Price ILS | Intro offer |
|---|---|---|---|
| `com.taltalhayun.adkan.subscription.monthly` | auto-renewable subscription | ₪12.90 | 3-day free trial |
| `com.taltalhayun.adkan.subscription.annual` | auto-renewable subscription | ₪69.00 | 3-day free trial |
| `com.taltalhayun.adkan.lifetime` | non-consumable | ₪99.00 | none |

Subscription group: `com.taltalhayun.adkan.premium`. Monthly and annual both belong to this group.

## Module layout

```
App/Features/Paywall/
├── Models/
│   ├── Entitlement.swift         # enum: none, trial, subscriber, lifetime
│   ├── AdKanProduct.swift        # wraps StoreKit Product + localized price strings
│   └── PaywallTrigger.swift      # .fourthFriend | .settingsUpgrade | .trialExpired | .premiumToggle
├── ViewModels/
│   ├── PaywallViewModel.swift    # @Observable; loads products, handles purchase
│   └── EntitlementResolver.swift # merges Transaction.updates into current Entitlement
├── Views/
│   ├── PaywallScreen.swift       # lifetime hero + annual + monthly layout
│   ├── ProductCard.swift
│   └── TrialCountdownBadge.swift
└── Store/
    ├── TransactionObserver.swift # @MainActor singleton; Task { for await ... Transaction.updates }
    └── ReceiptVerifier.swift     # calls Supabase Edge Function validate-receipt
```

## Entitlement enum

```swift
enum Entitlement: Equatable {
    case none
    case trial(expiresAt: Date, source: TrialSource)
    case subscriber(productId: String, expiresAt: Date)
    case lifetime

    var isPremium: Bool {
        switch self {
        case .none: return false
        case .trial, .subscriber, .lifetime: return true
        }
    }
}

enum TrialSource { case viralUnlock, introOffer }
```

## TransactionObserver

```swift
@MainActor
final class TransactionObserver {
    static let shared = TransactionObserver()
    private var task: Task<Void, Never>?

    func start() {
        task = Task.detached {
            for await result in Transaction.updates {
                await self.handle(result)
            }
        }
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let tx) = result else { return }
        let verified = await ReceiptVerifier.shared.verifyServerSide(tx)
        guard verified else { return }
        await EntitlementResolver.shared.apply(tx)
        await tx.finish()
    }
}
```

`TransactionObserver.shared.start()` is called from `AdKanApp.init()`.

## ReceiptVerifier

```swift
final class ReceiptVerifier {
    static let shared = ReceiptVerifier()

    func verifyServerSide(_ tx: Transaction) async -> Bool {
        let jwsRepresentation = tx.jwsRepresentation
        let response = try await supabase.functions.invoke(
            "validate-receipt",
            options: .init(body: ["jws": jwsRepresentation])
        )
        return response.data["valid"] as? Bool ?? false
    }
}
```

Edge Function `validate-receipt` (Deno) calls Apple's App Store Server API with a JWT signed by the `.p8` key from Supabase secrets. Returns `{ valid: bool, entitlement: EntitlementSnapshot }`.

## EntitlementResolver

Reads all current active transactions on app launch via `Transaction.currentEntitlements`. Resolves to the highest tier:
1. Any `.lifetime` product verified → `.lifetime`.
2. Any active subscription (non-expired) → `.subscriber`.
3. Viral-unlock trial active (set by Edge Function `viral-unlock-check`) → `.trial`.
4. StoreKit intro-offer trial active → `.trial`.
5. None of the above → `.none`.

Cached in `@AppStorage("currentEntitlement")` with a Date for last-checked. Re-verified on every foreground.

## PaywallScreen layout (locked)

```
┌─────────────────────────────────────┐
│  הקבוצה שלך מלאה.                   │  <- trigger-specific header
│  שדרג כדי להזמין עד 15 חברים.        │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │ LIFETIME       ⭐ הכי משתלם │    │  <- hero, largest, badge
│  │ ₪99 פעם אחת                 │    │
│  │ לכל החיים                    │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ ANNUAL                        │    │
│  │ ₪69 בשנה · חינם 3 ימים       │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ MONTHLY                       │    │
│  │ ₪12.90 בחודש · חינם 3 ימים   │    │
│  └─────────────────────────────┘    │
│                                      │
│  [שחזר רכישה | Restore purchases]   │
└─────────────────────────────────────┘
```

No exit-discount modal. No "last chance" timer. No secondary offer after dismiss. Tapping X dismisses cleanly.

## The 4th-friend trigger

`InviteFriendViewModel.invite()`:
```swift
func invite(_ email: String) async {
    guard await entitlementResolver.current.isPremium || group.members.count < 4 else {
        router.present(.paywall(trigger: .fourthFriend))
        return
    }
    // proceed with invite
}
```

## Trial countdown badge

Shown in home-screen top bar when `currentEntitlement == .trial`.
```swift
struct TrialCountdownBadge: View {
    let expiresAt: Date
    var body: some View {
        if let hours = Date.now.hours(until: expiresAt), hours < 24 {
            Text(String(localized: "trial.last_day \(hours)"))
        } else {
            Text(String(localized: "trial.through \(expiresAt.formatted(.dateTime.day().month()))"))
        }
    }
}
```

## Refund handling

Apple sends `REFUND` server notification → Edge Function `app-store-server-notifications` updates `entitlements.tier = 'none'`. On next iOS app foreground, Supabase realtime subscription pushes the change. User sees non-shaming banner.

## Tests

- `EntitlementResolverTests` — tier merging matrix (lifetime beats subscriber beats trial beats none).
- `ReceiptVerifierTests` — mocked Supabase response, verify true/false paths.
- `PaywallTriggerTests` — each trigger enum variant shows correct copy.
- `InviteFriendGateTests` — 4th invite on free tier → paywall. 4th invite on premium → proceeds.
- `RefundFlowTests` — REFUND notification → entitlement downgrade → banner visible.

`payments-engineer` MUST test against StoreKit configuration file (XCTestCase + `StoreKitTest`) in simulator. No real App Store Connect products needed to pass tests.

## Out of scope for v1

- Promo codes.
- Referral discounts beyond viral unlock.
- Family Sharing of Premium.
- Multi-device entitlement sync beyond iCloud's built-in.
