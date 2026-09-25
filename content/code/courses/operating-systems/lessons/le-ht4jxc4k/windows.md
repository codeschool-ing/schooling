---
title: Windows: winget, the Store and installers
version: 1
---

Windows has all three routes, and the one to reach for first is newer than most people realise.

**`winget`**, the *Windows Package Manager*, comes with Windows 11 and does for Windows what apt does for
Ubuntu: search, install, list, upgrade.

```sh
winget search 7zip                          # what the Windows package manager knows
winget install --id 7zip.7zip               # install, with the publisher's installer
winget list                                 # everything installed, from any source
winget upgrade --all                        # every program winget can update
msiexec /i agent.msi /qn                    # an .msi, silently, as a deployment does
```

**None of those were run for this lesson.** Two differences from apt matter:

- winget's list is **a catalogue of where to download each publisher's own installer**, with a checksum
  for each. It runs that installer silently. So a program installed by winget is the same as one
  installed by hand, and `winget upgrade --all` updates programs **whatever installed them**, as long as
  winget recognises them.
- There are **no shared dependencies**: each installer brings its own, as section 03 said.

**The Microsoft Store** installs apps per user, often without an administrator, and updates them on its
own. For office machines managed by an organisation it can be restricted to an approved list.

**Installers** come in two kinds. An **`.msi`** is a *Windows Installer* package with a standard
format, so it can be installed silently (`/qn`) and removed cleanly, and it is what IT departments push
to many machines. An **`.exe`** installer is whatever its publisher wrote, and each has its own
switches for a silent install, if any.

Installed programs go to **`C:\Program Files`**, or `Program Files (x86)` for 32-bit ones, and are
removed in *Settings > Apps > Installed apps*. Programs that install into the user's own `AppData`
folder, as many browsers and chat apps do, need no administrator, which is convenient and also how
software nobody approved ends up on office PCs.
