---
title: Entitlements, what the app claims and what the profile allows
version: 1
---

**An entitlement is a permission written into the app's signature: push notifications, iCloud, a
shared keychain, Sign in with Apple.** iOS reads them from the signed app, not from `Info.plist`,
which is why an app cannot grant itself one by editing a file after it is signed. They come from two
places that have to agree. The **app** says which it wants, in a file Xcode creates when you add a
capability in the target's *Signing & Capabilities* tab, `Planner.entitlements`. The **provisioning
profile** of section 06 says which the App ID is allowed. Codesigning copies the app's entitlements
into the signature, and iOS refuses to install an app that claims one its profile does not allow.

This section's two files are property lists, so the agreement can be checked anywhere. The Xcode
half was not run: it is written from Apple's documentation for entitlements and for capabilities in
Xcode, read on 30 October 2026.

## The two files

The planner has one capability, push notifications from lesson 17, and so one entitlement. In
development it says `development`, which points the app at Apple's sandbox push service. Save it as
`Planner.entitlements` in `~/entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Planner.entitlements -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
</dict>
</plist>
```

A development profile carries its own `Entitlements` dictionary: what the App ID was registered with,
plus a few Xcode always adds, such as `get-task-allow`, which lets a debugger attach. **This one is
written by the course as an example of that dictionary**, with the team identifier from lesson 1
section 07; it is not copied from a real profile, since none was made for this course. Save it as
`allowed.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- allowed.plist -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>application-identifier</key>
    <string>ABCDE12345.com.example.planner</string>
    <key>com.apple.developer.team-identifier</key>
    <string>ABCDE12345</string>
    <key>aps-environment</key>
    <string>development</string>
    <key>get-task-allow</key>
    <true/>
</dict>
</plist>
```

## The check

Every key the app claims has to be in the profile with the same value. Save this as
`check-entitlements.swift`:

```schooling-example
{"language": "swift", "file": "check-entitlements.swift", "parts": [{"code": "// check-entitlements.swift: does the profile allow everything the app claims?\nimport Foundation\n\nfunc plist(_ path: String) -> [String: Any] {\n    let data = try! Data(contentsOf: URL(fileURLWithPath: path))\n    return try! PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]\n}\n\nlet claimed = plist(CommandLine.arguments[1])\nlet allowed = plist(CommandLine.arguments[2])\n", "note": "The same reader as lesson 18's checker. The first argument is the app's entitlements, the second what the profile allows."}, {"code": "var refused = 0\nfor key in claimed.keys.sorted() {\n    let want = \"\\(claimed[key]!)\"\n    guard let have = allowed[key] else {\n        print(\"refused  \\(key): the profile does not have it\")\n        refused += 1\n        continue\n    }\n    if \"\\(have)\" == want {\n        print(\"ok       \\(key) = \\(want)\")\n    } else {\n        print(\"refused  \\(key): the app wants \\(want), the profile says \\(have)\")\n        refused += 1\n    }\n}\nexit(refused == 0 ? 0 : 1)\n", "note": "Two ways to fail: a key the profile does not have at all, and a key with a different value, such as `production` against `development`. Comparing the values as text is enough for strings and booleans, which is what these files hold."}]}
```

On the planner as it is, and then on a copy that also claims HealthKit, as somebody might after
copying a capability from another project:

```
ana@vm:~/entitlements$ swift check-entitlements.swift Planner.entitlements allowed.plist; echo $?
ok       aps-environment = development
0
ana@vm:~/entitlements$ sed 's|<key>aps-environment</key>|<key>com.apple.developer.healthkit</key><true/><key>aps-environment</key>|' Planner.entitlements > More.entitlements
ana@vm:~/entitlements$ swift check-entitlements.swift More.entitlements allowed.plist; echo $?
ok       aps-environment = development
refused  com.apple.developer.healthkit: the profile does not have it
1
```

**The second run is the message a device install would have given, earlier.** On a phone it arrives
as an install that fails with a complaint about entitlements; here it names the one key and says the
profile does not have it. The fix is never to edit the profile: add the capability to the App ID in
the developer account, or let Xcode do it (section 08), and download the new profile that comes back.
