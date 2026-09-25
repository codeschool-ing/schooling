---
title: macOS: the App Store, disk images and Homebrew
version: 1
---

**The Mac App Store** is the Mac's store route, and apps from it are sandboxed and update themselves.
Many professional apps are not in it, and arrive in one of two other forms:

- **A `.dmg`**, a *disk image*. Opening it mounts it like a USB stick, usually showing the app and an
  arrow to *Applications*. **Installing is dragging the app into Applications**, and removing it is
  dragging it to the Trash. Eject the image afterwards; running the app from inside it is the most common
  reason "it disappears after a restart".
- **A `.pkg`**, an installer package, which runs through steps and asks for an administrator's password
  because it writes outside the user's folders.

## Gatekeeper

The first time a downloaded app opens, macOS checks it. *Gatekeeper* allows apps from the App Store and
from *identified developers* whose apps Apple has *notarised*, scanned and signed. Anything else is
refused with a message saying it cannot be verified. The download itself carries a mark, the
*quarantine* attribute, saying where it came from; that mark is what triggers the check.

## Homebrew

The Mac has no package manager from Apple. **Homebrew** is the one almost everybody uses, installed once
from its own site:

```sh
brew search --cask firefox                  # Homebrew: formulae are tools, casks are apps
brew install tree
brew install --cask firefox
brew upgrade                                # everything Homebrew installed
xattr -l ~/Downloads/Tool.dmg               # com.apple.quarantine: where it came from
```

**None of those were run for this lesson.** *Formulae* are command-line tools, as with apt; *casks*
are ordinary Mac apps, downloaded from their publishers as winget does. `brew upgrade` updates
everything it installed.

## The same rule on all three

**Install from the most managed route that has the program**, keep a list of what each machine has,
and remove what nobody uses. Every program installed is one more thing that needs updates, and lesson 16
is about what happens to the ones that do not get them.
