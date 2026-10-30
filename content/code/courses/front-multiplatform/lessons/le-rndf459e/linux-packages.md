---
title: The Linux packages, opened and compared
version: 1
---

**An AppImage is run, not installed**: it is made executable, which electron-builder already did, and
started like any program. On a desktop you double-click it. The recording machine had no screen, and a
container has no FUSE, the part of Linux an AppImage uses to mount itself, so it ran with
`APPIMAGE_EXTRACT_AND_RUN=1`, which unpacks it into a temporary folder instead, and on Xvfb:

```
ana@dev:~/planner$ xvfb-run -a sh -c "APPIMAGE_EXTRACT_AND_RUN=1 timeout 12 release/*.AppImage > /dev/null 2>&1 & sleep 10; xwininfo -root -tree | grep -o \"Study planner.*\" | head -n 1"
Study planner": ("planner" "planner")  900x700+190+162  +190+162
```

**The window is there, with the planner's title, at Electron's 900 by 700.** Nothing about the app changed
between `npm start` and the AppImage; what changed is that the person running it needs no Node, no npm and no
project.

## What a `.deb` asks of the computer

A `.deb` is installed with `sudo apt install ./planner-0.1.0-amd64.deb`, and `apt` reads the package's
control fields first. `dpkg-deb -f` prints them without installing anything. The Tauri package of lesson 12
is rebuilt here, with only the `.deb` this time, because it now carries the new icon:

```
ana@dev:~/planner$ npx tauri build --bundles deb 2>&1 | tail -n 2
        /home/ana/planner/src-tauri/target/release/bundle/deb/planner_0.1.0_amd64.deb (2.82 MiB)

ana@dev:~/planner$ dpkg-deb -f release/*.deb Package Version Depends
Package: planner
Version: 0.1.0
Depends: libgtk-3-0, libnotify4, libnss3, libxss1, libxtst6, xdg-utils, libatspi2.0-0, libuuid1, libsecret-1-0
ana@dev:~/planner$ dpkg-deb -f src-tauri/target/release/bundle/deb/planner_0.1.0_amd64.deb Package Version Depends
Package: planner
Version: 0.1.0
Depends: libwebkit2gtk-4.1-0, libgtk-3-0
```

**Both packages name GTK, and only Tauri's names WebKitGTK**, which is lesson 12's trade written into the
package: Electron carries its browser and asks the system for the libraries around a window, notifications
and the keyring; Tauri asks the system for the browser itself. On Ubuntu 24.04 every one of those is in the
archive, so `apt` installs what is missing and the person never sees a list.

## Which one to hand out

| | AppImage | `.deb` | `.rpm` |
|---|---|---|---|
| runs on | most distributions, as a file | Debian, Ubuntu and their family | Fedora, openSUSE and their family |
| installed by | nobody: made executable and run | `apt` | `dnf` or `zypper` |
| a menu entry | only if the person or a helper adds one | yes | yes |
| removed by | deleting the file | `apt remove planner` | `dnf remove planner` |
| updated by | itself, or a new download (lesson 15) | a new package, or a repository | a new package, or a repository |
| Electron's planner | 121 MB | 97 MB | not built here |
| Tauri's planner | 77.85 MiB, in lesson 12 | 2.82 MiB | 2.86 MiB, in lesson 12 |

**For a first release, offer the AppImage and the `.deb`**: one runs anywhere and the other installs
properly on the family most people use. Linux has stores of its own too, Flathub and the Snap Store, which
take a package in their own formats, Flatpak and Snap; *neither was built for this course*, and both tools'
documentation has a page on them.

The project goes into git with `release/` ignored, as `src-tauri/target` already was, because a package is
built from the code and never kept beside it:

```
ana@dev:~/planner$ echo release/ >> .gitignore
ana@dev:~/planner$ git add . && git commit -q -m "Icons, and the Electron packages" && git log --oneline -1
926f02e Icons, and the Electron packages
```
