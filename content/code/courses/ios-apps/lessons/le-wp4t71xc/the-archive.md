---
title: The archive, the build you hand over
version: 1
---

**An archive is a Release build of the app, signed, with its debug symbols beside it, kept so that
you can distribute it and later make sense of its crash reports.** It is what *Product*, *Archive*
in Xcode produces, and it is the only build App Store Connect accepts. Nothing here was run: there is
no Mac in this course's recording. It is written from Apple's Xcode help on distributing an app,
read on 30 October 2026.

Choose *Any iOS Device* as the destination, not a simulator, and run *Archive*. Xcode builds with
the scheme's **Release** configuration from lesson 1 section 06, signs with the team's identity, and
opens the **Organizer**, which lists every archive with its version and build number. From there,
*Distribute App* signs it again for where it is going, App Store Connect, Ad Hoc or development, and
uploads or exports it.

## The same steps, at the command line

A build server does the same with `xcodebuild`, and seeing the two commands makes the two steps
clear. They were not run:

```sh
# archive.sh: archive the planner and export it for App Store Connect
xcodebuild archive \
  -project Planner.xcodeproj \
  -scheme Planner \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/Planner.xcarchive

xcodebuild -exportArchive \
  -archivePath build/Planner.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build/export
```

The first builds and signs the archive. The second re-signs it for its destination, which
`ExportOptions.plist` names, and writes the `.ipa` file that is uploaded.

## What the archive keeps for later

**The dSYM**, the debug symbols, is the part people forget. A crash report from somebody's phone
lists memory addresses; with the archive's dSYM those addresses turn back into function names and
line numbers. Delete the archive and the crashes of that build can no longer be read.
`mobile-delivery` lessons 12 and 13 are about uploading symbols and reading the stack traces.

**Every archive you upload needs a higher build number**, the `CFBundleVersion` of lesson 1 section
08, and lesson 22 begins where the upload ends.
