# Roll

A retro instant camera for iPhone. Point, shoot, and watch the print develop.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-lightgrey.svg)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Build](https://github.com/aaronlosangeleshome/roll-ios/actions/workflows/build.yml/badge.svg)](https://github.com/aaronlosangeleshome/roll-ios/actions/workflows/build.yml)

Roll is free and open source. It is written in SwiftUI with zero third party dependencies, no accounts, no analytics and no network access. Your photos never leave your phone.

> Roll is an independent project and is not affiliated with any instant camera or film manufacturer.

## How it works

1. **Frame the shot.** The camera body has a square viewfinder, so what you see is the print you get. A mechanical style film counter shows how many shots you have left.
2. **Press the shutter.** The photo is center cropped to a square and a blank print slides out of the exit slot.
3. **Watch it develop.** The print starts as a dark, blurry, desaturated sheet and gradually clears over about 25 seconds. Shake your phone to speed it up, or tap Develop now.
4. **Make it yours.** Once developed, open the print to change the filter, swap the frame, add stickers (drag, pinch, double tap to remove) and write a handwritten caption.
5. **Keep it.** Save the finished print to Photos or share it. Prints are stored privately on the device.

| Feature | Details |
|---|---|
| Camera | Rear and front camera, flash, 3 and 10 second selfie timer, haptic shutter |
| Development | Time based, persists across launches, shake to accelerate |
| Filters | Original, Instant, Fade, Chrome, Mono, Noir, Warm, Vivid (Core Image) |
| Frames | Classic, Noir, Kraft, Sunbleach, Sage |
| Stickers | 12 original SF Symbol stickers, movable and resizable |
| Export | Flattened 1080 px wide print through `ImageRenderer` |
| Privacy | Offline only. Camera access, plus add only Photos access when you tap Save |

## Requirements

- A Mac with **Xcode 16 or newer**
- **iOS 17+** iPhone for the camera (the Simulator works too, see below)
- [Homebrew](https://brew.sh) to install XcodeGen
- A free Apple ID is enough. You do not need the paid Apple Developer Program.

## Quick start

```bash
# 1. Clone
git clone https://github.com/aaronlosangeleshome/roll-ios.git
cd roll-ios

# 2. Install XcodeGen (generates the .xcodeproj from project.yml)
brew install xcodegen

# 3. Required: set a unique bundle ID (the default com.example.roll cannot be signed)
cp Config/Local.xcconfig.example Config/Local.xcconfig
#    then edit ROLL_BUNDLE_ID, for example com.janedoe.roll

# 4. Generate and open the project
xcodegen generate
open Roll.xcodeproj
```

In Xcode:

1. Select the **Roll** project, then the **Roll** target, then **Signing & Capabilities**.
2. Under **Team**, choose your personal team. If it is not listed, add your Apple ID in Xcode, Settings, Accounts.
3. Pick your iPhone (or an iPhone Simulator) as the run destination and press **Run**.

Use the **Roll** scheme. It builds the open source flavour with everything unlocked.

### Running on a real iPhone with a free Apple ID

- On the phone, enable **Settings, Privacy & Security, Developer Mode**, then restart.
- The first launch may say "Untrusted Developer". Go to **Settings, General, VPN & Device Management**, tap your Apple ID, and choose Trust.
- Apps signed with a free Apple ID expire after **7 days**. Rebuild from Xcode to renew. A free account is also limited to a few apps installed at once.
- If Xcode says the bundle identifier is unavailable, someone already used it. Change `ROLL_BUNDLE_ID` in `Config/Local.xcconfig`, run `xcodegen generate` again, and rebuild.

### Running in the Simulator

The Simulator has no camera. Roll detects this, shows a "SIMULATOR" note in the viewfinder, and the shutter produces a synthetic test image. The full flow works: eject, develop, filters, frames, stickers, captions and gallery. Saving to Photos works too.

## Open source build vs App Store build

The same code produces two flavours, controlled by one compile flag.

| | `Roll` scheme (default) | `Roll-AppStore` scheme |
|---|---|---|
| Configurations | `Debug`, `Release` | `Debug-AppStore`, `Release-AppStore` |
| Compile flag | none | `APP_STORE` |
| Paywall | Never shown | Shown |
| Pics per day | Unlimited | 5 free, unlimited with Plus |
| Filters, frames, stickers, timer | All unlocked | Free subset, rest need Plus |
| StoreKit | Not used at runtime | StoreKit 2 |
| Needs App Store Connect products | No | For release, yes |

Everything gated by the paywall is decided by `StoreManager.isPlus`. In the open source build `StoreManager` sets `isPlus = true` at launch and never touches StoreKit, so nothing is locked and there is no code path that can lock it. You do not need to remove anything to use Roll for free.

### Testing the paywall locally without App Store Connect

If you want to work on the paywall or run your own paid fork:

1. In Xcode choose the **Roll-AppStore** scheme.
2. Run it. The scheme is wired to `Roll/Store/Products.storekit`, a local StoreKit configuration that defines a monthly subscription and a lifetime purchase.
3. Purchases complete instantly with fake money. Use Xcode, Debug, StoreKit, Manage Transactions to refund, expire or clear them.

No App Store Connect setup, sandbox account or network is needed for this. To ship your own paid build you would also create the matching product IDs in App Store Connect and replace `com.yourname.roll.*` in `AppConfig.swift` and `Products.storekit`.

## Project structure

```
Roll/
  project.yml                XcodeGen spec: targets, schemes, build flavours
  Config/
    Roll.xcconfig            Defaults (bundle ID, team)
    Local.xcconfig.example   Copy to Local.xcconfig for your own values
  Roll/
    App/                     RollApp entry point, AppConfig (limits, URLs, theme)
    Camera/                  AVFoundation session, preview layer, crop and save helpers
    Models/                  Shot, FilterStyle, ShotStore (on device persistence), UsageTracker
    Store/                   StoreManager (StoreKit 2), local Products.storekit
    Views/                   CameraView, InstantCard, GalleryView, ShotDetailView, Paywall, Settings
    Support/                 Shake detection, haptics
    Assets.xcassets/         App icon and accent colour
  RollTests/                 Unit tests
  scripts/make_icon.py       Regenerates the app icon with Pillow
```

`Roll.xcodeproj` is generated and gitignored, so there are no project file merge conflicts. Add or remove Swift files freely, then run `xcodegen generate`.

## Tests and CI

```bash
xcodegen generate
xcodebuild test -project Roll.xcodeproj -scheme Roll \
  -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

GitHub Actions runs the same command on every push and pull request, and also confirms the `Roll-AppStore` flavour still compiles. If your Xcode does not have an "iPhone 16" simulator, pick any available name from `xcrun simctl list devices`.

## Contributing

Contributions are welcome: new filters, frames, stickers, bug fixes, accessibility and translations. See [CONTRIBUTING.md](CONTRIBUTING.md) for the ground rules, including how to add a filter in about ten lines.

## Privacy

Roll collects nothing. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## License

Released under the [MIT License](LICENSE). Use it, learn from it, fork it, even ship your own version, as long as you keep the copyright notice. If you publish a fork to the App Store, please use your own name, icon and artwork.
