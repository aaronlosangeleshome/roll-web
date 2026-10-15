# Contributing to Roll

Thanks for helping. Roll is a small, focused app, and the goal is to keep it that way.

## Ground rules

- **Offline and private.** No network calls, analytics, crash reporters or third party SDKs.
- **No dependencies.** Apple frameworks only (SwiftUI, AVFoundation, Core Image, StoreKit, Photos).
- **Original art only.** Do not submit artwork, names or trade dress copied from existing camera brands or apps.
- **Nothing locked in the open source build.** Any new Plus gating must go through `StoreManager.isPlus` so the default build stays fully unlocked.
- **Real device behaviour matters.** If you changed camera code, say whether you tested on a physical iPhone.

## Setup

Follow the Quick start in the [README](README.md). Run `xcodegen generate` whenever you add, move or delete files.

## Making a change

1. Fork, then create a branch: `git checkout -b add-sepia-filter`.
2. Make your change and add a unit test when logic is involved.
3. Run the tests: `xcodebuild test -project Roll.xcodeproj -scheme Roll -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO`.
4. Open a pull request and fill in the template. Attach screenshots for anything visual.

## Code style

- Swift 5.9, SwiftUI first, `@MainActor` for anything touching UI state.
- Prefer small views and pure helpers over large view bodies.
- Corner radii scale with size (see `InstantCard`): no fixed magic radii on cards.
- Colours and fonts come from `Theme` in `AppConfig.swift`, not inline literals.
- Every interactive control needs an accessibility label and at least a 44 pt hit area.

## Recipes

### Add a filter

In `Models/FilterStyle.swift`:

```swift
// 1. Add a case
case original, instant, fade, chrome, mono, noir, warm, vivid, sepia

// 2. Give it a title
case .sepia: "Sepia"

// 3. Decide whether it is a Plus feature (only matters in the App Store build)
// isPremium already returns true for everything except .original and .instant

// 4. Apply it
case .sepia: output = Self.run("CISepiaTone", input, [kCIInputIntensityKey: 0.8])
```

The filter chips in the editor are built from `FilterStyle.allCases`, so no UI change is needed.

### Add a frame

In `Models/Shot.swift`, add a case to `FrameStyle`, then give it a `title`, a `paper` colour and an `ink` colour.

### Add a sticker

Add an entry to `StickerAsset.all` with an SF Symbol name and a colour.

## Reporting bugs

Use the bug report template and include your device, iOS version and Xcode version.
