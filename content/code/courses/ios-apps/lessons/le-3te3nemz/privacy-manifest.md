---
title: The privacy manifest, and a checker for both files
version: 1
---

**`Info.plist` says why the app asks; the privacy manifest says what the app does without asking.**
The manifest is a file named `PrivacyInfo.xcprivacy`, a property list like `Info.plist`, and
Apple's documentation for privacy manifest files, read on 30 October 2026, says it records "the
types of data collected by your app" and "the required reasons APIs your app or third-party SDK
uses". Xcode makes one with *File*, *New File*, *App Privacy*. Nothing from Xcode was run for this
section; the checker at the end of it was.

## Required-reason APIs

Some ordinary APIs can be misused to tell one device from another, which Apple calls
**fingerprinting**: the free disk space, the time the system booted, the timestamps of files, the
keyboards installed, and `UserDefaults`. An app may use them, and it has to say why, by picking a
reason code from Apple's list for each category. Apple's page *Describing use of required reason
API* states the consequence: "Starting May 1, 2024, apps that don't describe their use of required
reason API in their privacy manifest file aren't accepted by App Store Connect."

The planner remembers which course was open last in `UserDefaults`, so it declares that category
with **`CA92.1`**, which Apple's list describes as reading and writing "information that is only
accessible to the app itself". It collects no data about the person and tracks nobody, so the other
three lists are empty. Save it as `PrivacyInfo.xcprivacy` in `~/privacy`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- PrivacyInfo.xcprivacy -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

## A checker for both files

Foundation reads both files on Linux as it read `Info.plist` in lesson 1, so the agreement between
what the code uses and what the two files say can be checked anywhere. Save this as
`check-privacy.swift` in `~/privacy`:

```schooling-example
{"language": "swift", "file": "check-privacy.swift", "parts": [{"code": "// check-privacy.swift: does the app say why, for everything its code uses?\nimport Foundation\n\nfunc plist(_ path: String) -> [String: Any] {\n    let data = try! Data(contentsOf: URL(fileURLWithPath: path))\n    return try! PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]\n}\n\nlet info = plist(CommandLine.arguments[1])\nlet manifest = plist(CommandLine.arguments[2])\nlet uses = CommandLine.arguments.dropFirst(3).sorted()\n\n", "note": "Both files are property lists, so one function reads either. The `try!` and `as!` stop the program on a file that is missing or is not a dictionary, which for a checker run by hand is the right kind of loud. What the code uses is given as words after the two paths."}, {"code": "let usageKeys = [\n    \"camera\": \"NSCameraUsageDescription\",\n    \"location\": \"NSLocationWhenInUseUsageDescription\",\n    \"photos-add\": \"NSPhotoLibraryAddUsageDescription\",\n    \"tracking\": \"NSUserTrackingUsageDescription\",\n]\nlet reasonAPIs = [\n    \"userdefaults\": \"NSPrivacyAccessedAPICategoryUserDefaults\",\n    \"file-timestamps\": \"NSPrivacyAccessedAPICategoryFileTimestamp\",\n]\n", "note": "Two tables: what each kind of access needs in `Info.plist`, and what each required-reason API needs in the manifest. They are short on purpose; a real list is in Apple's documentation, and a word this checker does not know is reported rather than passed."}, {"code": "var problems = 0\nfunc report(_ line: String, ok: Bool) {\n    print(ok ? \"ok       \\(line)\" : \"MISSING  \\(line)\")\n    if !ok { problems += 1 }\n}\n\n", "note": "Every line it prints starts with `ok` or `MISSING`, and every `MISSING` is counted."}, {"code": "for use in uses {\n    if let key = usageKeys[use] {\n        let text = (info[key] as? String ?? \"\").trimmingCharacters(in: .whitespaces)\n        report(\"\\(use): \\(key) \\(text.isEmpty ? \"is not in Info.plist\" : \"\\\"\\(text)\\\"\")\", ok: !text.isEmpty)\n    } else if let category = reasonAPIs[use] {\n        let entries = manifest[\"NSPrivacyAccessedAPITypes\"] as? [[String: Any]] ?? []\n        let entry = entries.first { $0[\"NSPrivacyAccessedAPIType\"] as? String == category }\n        let reasons = entry?[\"NSPrivacyAccessedAPITypeReasons\"] as? [String] ?? []\n        report(\"\\(use): \\(category) \\(reasons.isEmpty ? \"has no reason\" : reasons.joined(separator: \", \"))\", ok: !reasons.isEmpty)\n    } else {\n        report(\"\\(use): this checker does not know it\", ok: false)\n    }\n}\n\n", "note": "For a usage key, the string has to be there and not blank. For an API, the manifest needs an entry for its category with at least one reason. The reason codes are Apple's, and the checker does not judge whether the code given is the right one; that part is yours."}, {"code": "let tracks = manifest[\"NSPrivacyTracking\"] as? Bool ?? false\nreport(\"NSPrivacyTracking is \\(tracks)\", ok: tracks == uses.contains(\"tracking\"))\nprint(problems == 0 ? \"nothing missing\" : \"\\(problems) missing\")\nexit(problems == 0 ? 0 : 1)\n", "note": "The last rule joins the two files: the manifest's `NSPrivacyTracking` has to match whether the code tracks. The exit status is 1 when anything is missing, so a build script could stop on it."}]}
```

Run it as the planner stands: it takes photos with the camera and keeps the last course in
`UserDefaults`. Then on lesson 1's `Info.plist`, which predates the camera, saved here as
`Lesson1.plist`; and then claiming the code also tracks:

```
ana@vm:~/privacy$ swift check-privacy.swift Info.plist PrivacyInfo.xcprivacy camera userdefaults; echo $?
ok       camera: NSCameraUsageDescription "Planner uses the camera to photograph your notes and attach them to a study session."
ok       userdefaults: NSPrivacyAccessedAPICategoryUserDefaults CA92.1
ok       NSPrivacyTracking is false
nothing missing
0
ana@vm:~/privacy$ cp ~/plist/Info.plist Lesson1.plist
ana@vm:~/privacy$ swift check-privacy.swift Lesson1.plist PrivacyInfo.xcprivacy camera userdefaults; echo $?
MISSING  camera: NSCameraUsageDescription is not in Info.plist
ok       userdefaults: NSPrivacyAccessedAPICategoryUserDefaults CA92.1
ok       NSPrivacyTracking is false
1 missing
1
ana@vm:~/privacy$ swift check-privacy.swift Info.plist PrivacyInfo.xcprivacy camera userdefaults tracking; echo $?
ok       camera: NSCameraUsageDescription "Planner uses the camera to photograph your notes and attach them to a study session."
MISSING  tracking: NSUserTrackingUsageDescription is not in Info.plist
ok       userdefaults: NSPrivacyAccessedAPICategoryUserDefaults CA92.1
MISSING  NSPrivacyTracking is false
2 missing
1
```

**The second run is the one that would have shipped a crash.** Lesson 1's file had no camera key,
and nothing about building the app would have said so; the first tap on the camera button would
have. The third run fails twice for one change, because tracking needs both its usage string and a
manifest that admits it.
