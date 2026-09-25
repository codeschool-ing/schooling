---
title: Changing the registry, and the Mac's version of it
version: 1
---

The rules of section 03 apply, and matter more: a text file broken by a typo is fixed with an editor, a
registry broken in the wrong key can stop Windows from starting.

1. **Export before changing.** In `regedit`, *File > Export* the key you are about to touch; the `.reg`
   file it writes can be double-clicked to put it back.
2. **Prefer the setting's own screen.** Almost everything in the registry has a place in Settings, a
   program's options or Group Policy that writes the value for you, correctly typed. Group Policy, lesson
   5, writes its settings under `HKLM\SOFTWARE\Policies`.
3. **Change the smallest thing**, in **HKCU** when it concerns one person.

From the command line, in the Command Prompt and in PowerShell:

```sh
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild
reg export "HKCU\Software\OfficeApp" C:\Backup\officeapp.reg
reg add "HKCU\Software\OfficeApp" /v Server /t REG_SZ /d printer.office /f
reg import C:\Backup\officeapp.reg
```

```sh
Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' |
  Select-Object ProductName, DisplayVersion, CurrentBuild
New-Item -Path 'HKCU:\Software\OfficeApp' -Force
Set-ItemProperty -Path 'HKCU:\Software\OfficeApp' -Name Server -Value 'printer.office'
Remove-ItemProperty -Path 'HKCU:\Software\OfficeApp' -Name Server
```

**None of those were run for this lesson.** PowerShell treats the registry as a drive, `HKLM:` and
`HKCU:`, so lesson 12's `New-Item`, `Get-ItemProperty` and `Remove-ItemProperty` work on keys and values
as they work on folders and files, and `-WhatIf` works too.

**System Restore**, when it is turned on, saves the registry with each restore point, and is the way back
when a change stops Windows from working normally. Lesson 17 uses it.

## macOS: property lists

A Mac keeps settings in **property list** files, `.plist`, the same format as lesson 14's launchd jobs:
the machine's in `/Library/Preferences`, each person's in `~/Library/Preferences`. They are files, like
Linux, and structured, like the registry. The **`defaults`** command reads and writes them by the
program's identifier:

```sh
defaults read com.apple.dock autohide           # 0 or 1
defaults write com.apple.dock autohide -bool true
killall Dock                                     # the Dock rereads its settings
plutil -p ~/Library/Preferences/com.apple.dock.plist | head
```

**Not run for this lesson.** An app reads its settings when it starts, which is why the Dock had to be
restarted with `killall Dock` to notice.
