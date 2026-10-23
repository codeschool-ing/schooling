---
title: Inside the iOS project
version: 1
---

**The iOS project is an Xcode project, and on a Mac you open `ios/App/App.xcodeproj` and press Run.**
Everything in it can be read on any computer, and should be, because some of it you will change
whatever computer you build on. On Linux it is a folder of text files:

```
ana@dev:~/planner$ ls ios/App/App
AppDelegate.swift
Assets.xcassets
Base.lproj
Info.plist
SceneDelegate.swift
capacitor.config.json
config.xml
public
ana@dev:~/planner$ grep -A1 -E "CFBundle(DisplayName|Identifier|ShortVersionString|Version)<" ios/App/App/Info.plist
	<key>CFBundleDisplayName</key>
        <string>Study planner</string>
--
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
--
	<key>CFBundleShortVersionString</key>
	<string>$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key>
	<string>$(CURRENT_PROJECT_VERSION)</string>
ana@dev:~/planner$ head -n 12 ios/App/App/AppDelegate.swift
import UIKit
import Capacitor

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
```

**`Info.plist` is the iOS manifest**, a list of keys and values in XML. `CFBundleDisplayName` is the
name under the icon, the `appName` of lesson 2. The others are not written there at all: they are
`$(…)` variables that Xcode fills in from the project's build settings, so the bundle identifier,
which is your `appId`, and the two version numbers are edited in Xcode, under the target's "General"
tab, and not in this file. Lesson 15 comes back to the two version numbers, which mean different
things.

**`AppDelegate.swift` is the app's entry point**, with one method for each moment of its life:
launched, about to go to the background, back in front. Capacitor's template leaves them empty, and
they are where a plugin that needs to know about those moments is wired in. `SceneDelegate.swift`
does the same for each window, and `Base.lproj` holds the launch screen and the storyboard that
contains the WebView.

Every permission an iOS app asks for is a key in `Info.plist` with a sentence beside it, the text of
the dialog the user sees. **An app that asks without that sentence is closed by iOS on the spot**,
which is why lesson 4 adds one for each plugin.

## Running it, from Apple's steps

*None of this was run for this course, which was recorded on Linux. It is taken from Capacitor's
documentation for iOS and Apple's for Xcode.*

1. Install **Xcode** from the Mac App Store, open it once to accept its licence, and let it install
   its components and an iOS simulator.
2. On the Mac, in the planner's folder, `npm install`, `npm run build` and `npx cap sync ios`, as on
   any other computer.
3. `npx cap open ios` opens the project in Xcode. Choose a simulator in the bar at the top and press
   Run; the planner opens in it.
4. To run on your own iPhone, Xcode asks for a **team**: an Apple ID signed in under Xcode's
   "Accounts" settings is enough to run on a phone you own, for a limited time. Publishing needs the
   paid membership, and lesson 14 is about that.
