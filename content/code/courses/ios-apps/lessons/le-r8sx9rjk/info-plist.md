---
title: Info.plist, the app's description of itself
version: 1
---

**Every app carries a file that tells iOS what it is before a line of its code runs.** It is called
`Info.plist`, it sits at the top of the app bundle, and the system reads it to learn the app's
identifier, its version, the name under the icon, which orientations it supports, which iOS it needs
and, from lesson 18 on, the sentence it shows when the app asks for the camera.

A common belief is that `Info.plist` is a file you edit by hand. In a project made by a current
Xcode it usually is not a file at all. Apple's documentation for the `Info.plist` build settings
describes the arrangement: most keys are **build settings** of the target, shown in the target's
*Info* tab, and Xcode writes the real file into the app when it builds. You add a file of your own
only for keys no build setting covers, and Xcode merges the two. Either way, what reaches the phone
is one file, and that file is what this section reads.

## What the file looks like

A property list is a tree of dictionaries, arrays, strings, numbers, booleans and dates, stored as
XML or in a binary form. This is the planner's, as it would come out of a build. Save it as
`Info.plist` in a directory of its own, `~/plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Info.plist -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Planner</string>
    <key>CFBundleExecutable</key>
    <string>Planner</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.planner</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>MinimumOSVersion</key>
    <string>17.0</string>
    <key>UILaunchScreen</key>
    <dict/>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
</dict>
</plist>
```

The keys that start with `CF` come from Core Foundation and are shared with macOS; the ones that
start with `UI` and `LS` are about the interface and launching. **Two of them are versions, and they
are not the same version.** `CFBundleShortVersionString` is the one people see in the App Store,
`1.0`. `CFBundleVersion` is the build number, and every build you upload for the same version needs
a higher one, which lesson 22 is where you meet it refusing.

## Reading it with a program

Foundation reads property lists on every platform Swift runs on, so a few lines of Swift can read
this file on Linux and check the two rules Apple's documentation gives for the fields that most
often go wrong: the bundle identifier may contain only letters, digits, hyphens and periods, and
the short version is up to three integers separated by periods. Save this as `check.swift` in
`~/plist`:

```schooling-example
{"language": "swift", "file": "check.swift", "parts": [{"code": "// check.swift: read an Info.plist and check the fields that most often go wrong\nimport Foundation\n\nlet path = CommandLine.arguments[1]\nlet data = try Data(contentsOf: URL(fileURLWithPath: path))\nlet plist = try PropertyListSerialization.propertyList(from: data, format: nil)\nguard let info = plist as? [String: Any] else { fatalError(\"\\(path) is not a dictionary\") }\n", "note": "`PropertyListSerialization` reads XML and binary property lists alike and hands back `Any`, because a property list can hold six kinds of value. The cast to a dictionary is where a file that is not an `Info.plist` stops."}, {"code": "func text(_ key: String) -> String {\n    info[key] as? String ?? \"\"\n}\n\nlet id = text(\"CFBundleIdentifier\")\nlet idOK = !id.isEmpty && id.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == \"-\" || $0 == \".\") }\nprint(\"identifier  \\(id)  \\(idOK ? \"ok\" : \"only A-Z a-z 0-9 - . allowed\")\")\n", "note": "The identifier rule, letter by letter. `isASCII` matters: `isLetter` alone would accept `é`, which the rule does not."}, {"code": "let short = text(\"CFBundleShortVersionString\")\nlet parts = short.split(separator: \".\", omittingEmptySubsequences: false)\nlet shortOK = (1...3).contains(parts.count) && parts.allSatisfy { !$0.isEmpty && $0.allSatisfy(\\.isNumber) }\nprint(\"version     \\(short)  \\(shortOK ? \"ok\" : \"must be up to three integers, like 1.2.3\")\")\nprint(\"build       \\(text(\"CFBundleVersion\"))\")\nprint(\"needs iOS   \\(text(\"MinimumOSVersion\"))\")\n", "note": "`omittingEmptySubsequences: false` keeps the empty piece in `1..2`, so a doubled period fails instead of slipping through as two parts."}]}
```

`swift check.swift` runs a single file without a package: the toolchain compiles it into memory and
runs it. Here it is on the planner's file, and then on a copy that `sed` makes with two mistakes in
it, an underscore in the identifier and a word in the version:

```
ana@vm:~/plist$ swift check.swift Info.plist
identifier  com.example.planner  ok
version     1.0  ok
build       1
needs iOS   17.0
ana@vm:~/plist$ sed -e 's/com.example.planner/com.example.study_planner/' -e 's|<string>1.0</string>|<string>1.0 beta</string>|' Info.plist > Broken.plist
ana@vm:~/plist$ diff Info.plist Broken.plist
13c13
<     <string>com.example.planner</string>
---
>     <string>com.example.study_planner</string>
17c17
<     <string>1.0</string>
---
>     <string>1.0 beta</string>
ana@vm:~/plist$ swift check.swift Broken.plist
identifier  com.example.study_planner  only A-Z a-z 0-9 - . allowed
version     1.0 beta  must be up to three integers, like 1.2.3
build       1
needs iOS   17.0
```

**Apple's tools hold both rules, and the point of seeing them here is to recognise the message when
it comes.** A new Xcode project named `study_planner` proposes the identifier with a hyphen in place of
the underscore, and App Store Connect refuses an upload whose version string is not in that form,
which lesson 22 shows. The underscore is
the commoner mistake, because it looks natural in a name made of two words, `study_planner`, and it
is a character a Swift identifier allows and a bundle identifier does not.
