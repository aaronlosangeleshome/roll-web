# Shipping your own build to the App Store (optional)

You only need this if you want to publish a fork. The open source build needs none of it.

## 1. Use the App Store flavour

Build with the **Roll-AppStore** scheme (configurations `Debug-AppStore` and `Release-AppStore`). It compiles with the `APP_STORE` flag, which turns on the paywall and StoreKit.

## 2. Make it yours

- Set `ROLL_BUNDLE_ID` and `DEVELOPMENT_TEAM` in `Config/Local.xcconfig`.
- Replace `com.yourname.roll.monthly` and `com.yourname.roll.lifetime` in `Roll/App/AppConfig.swift` and `Roll/Store/Products.storekit`.
- Replace `privacyURL` and `supportURL` in `AppConfig.swift` with live pages.
- Choose your own app name, icon and artwork. Do not reuse another app's branding (Guideline 4.1).

## 3. Products

| Product | Type | Suggested price point |
|---|---|---|
| Monthly | Auto-renewable subscription (group "Roll Plus") | $4.99 |
| Lifetime | Non-consumable | $9.99 |

Apple price points end in .99, so $5 and $10 become $4.99 and $9.99. Prices and limits (`freeDailyPics`) are yours to change.

## 4. App Store Connect

1. Create the app record and both in-app purchases, with display names, descriptions and a paywall screenshot.
2. Accept the Paid Apps agreement or products will not load.
3. App Privacy: **Data Not Collected** (matches `Roll/PrivacyInfo.xcprivacy`).
4. Product, Archive, Distribute, then attach the build and submit with both purchases selected.

## 5. Guideline checklist

| Guideline | Status in this codebase |
|---|---|
| 3.1.1 / 3.1.2 Purchases and subscriptions | StoreKit 2 only. Paywall shows localized price, period, auto-renew disclosure, Restore, Terms and Privacy links, and a visible close button. Entitlement comes from verified transactions. |
| 3.1.1 Restore | Restore Purchases on the paywall and in Settings |
| 5.1.1 Privacy | Purpose strings for camera and add only Photos. Privacy manifest included. Needs your hosted privacy policy. |
| 5.1.1(iv) Permissions | Camera asked on first use. Photos permission only when tapping Save, add only. |
| 4.1 Copycats | Original UI and art. Keep your listing free of other brands' names and trade dress. |
| 4.2 Minimum functionality | Complete camera, develop, edit, save and share flow |
| 2.1 Completeness | Add real URLs and App Review notes |
| 2.3.7 Metadata | Describe it as an "instant camera" or "retro film camera" without other brands' names |

## 6. App Review notes to paste

> Camera features require a physical device. Free users get 5 pictures per day. Tap a locked filter, frame or sticker, or use up the free pictures, to reach the paywall. Purchases use StoreKit 2.

## 7. Before you submit

Test: camera permission denied, offline paywall, restore on a second device, shake to develop, flash, and front camera mirroring.
