---
title: A release, from tag to download
version: 1
---

**The planner's own release is the worked example: `v0.3.0`, the tag lesson 15 made.** Every command below is
one you have met; the point of this section is the order, and what a finished release folder holds. The
repository first, because a release is built from a commit everybody can find again:

```
ana@dev:~/planner$ git log --oneline | wc -l
14
ana@dev:~/planner$ git log --oneline | head -n 8
de97f95 0.3.0
a065bcf Check for updates at start
7519a04 0.2.0
b876c9c One version, in package.json
531775b Keep signing keys out of the repository
926f02e Icons, and the Electron packages
676a8f1 The planner as a desktop app, with Tauri
ea58854 The planner as a desktop app, with Electron
ana@dev:~/planner$ git describe --tags
v0.3.0
```

**Fourteen commits, one for each step the planner took in this course, and `git describe` says the code sits
exactly on the tag.** A
release built from a commit that is not tagged, or from a tree with changes nobody committed, cannot be built
again, and a bug report against it cannot be reproduced.

## The packages

Built from that commit, with lesson 13's configuration. The Tauri build is here only to show what lesson 15
promised: its version comes from `package.json` now, with nothing edited by hand:

```
ana@dev:~/planner$ npm run build > /dev/null && npx electron-builder --linux 2>&1 | grep -o "target=.*"
target=AppImage arch=x64 file=release/planner-0.3.0-x86_64.AppImage
target=deb arch=x64 file=release/planner-0.3.0-amd64.deb
ana@dev:~/planner$ npx tauri build --bundles deb 2>&1 | tail -n 2
        /home/ana/planner/src-tauri/target/release/bundle/deb/planner_0.3.0_amd64.deb (2.82 MiB)

ana@dev:~/planner$ dpkg-deb -f src-tauri/target/release/bundle/deb/planner_0.3.0_amd64.deb Version
0.3.0
```

## The folder

A release folder holds what a person downloads, and the means to check it. The notes are a plain text file,
written for people, saying what changed, `RELEASE-NOTES.md`:

```
# Study planner 0.3.0

## What changed
- The desktop app checks for a new version when it starts, and installs it when it quits.
- One version number for every platform: 0.3.0 here, build 300 on Android and iOS.

## Install
- AppImage, any Linux: make it executable with `chmod +x` and run it.
- .deb, Ubuntu and Debian: `sudo apt install ./planner-0.3.0-amd64.deb`.

## Check the download
    gpg --import planner-signing-key.asc
    gpg --verify SHA256SUMS.asc SHA256SUMS
    sha256sum -c SHA256SUMS

## Not in this release
No Windows or macOS package, and no store: they were not built.
```

Then the checksums and the signature, as in lesson 14, with the key lesson 14 made:

```
ana@dev:~/planner$ mkdir ~/release-0.3.0 && cp release/planner-0.3.0-x86_64.AppImage release/planner-0.3.0-amd64.deb release/latest-linux.yml ~/release-0.3.0/
ana@dev:~/release-0.3.0$ sha256sum planner-0.3.0-x86_64.AppImage planner-0.3.0-amd64.deb > SHA256SUMS
ana@dev:~/release-0.3.0$ gpg --batch --pinentry-mode loopback --passphrase "$KEY_PASS" --armor --detach-sign SHA256SUMS
ana@dev:~/release-0.3.0$ gpg --armor --export ana@example.com > planner-signing-key.asc
ana@dev:~/release-0.3.0$ ls -sh1
total 218M
4.0K RELEASE-NOTES.md
4.0K SHA256SUMS
4.0K SHA256SUMS.asc
4.0K latest-linux.yml
 97M planner-0.3.0-amd64.deb
121M planner-0.3.0-x86_64.AppImage
4.0K planner-signing-key.asc
```

**Seven files**: the two packages, `latest-linux.yml` for the updater of lesson 15, the notes, the list of
checksums, its signature, and the public key. Upload all seven together, wherever the release lives. The last
check is the one a stranger makes, in a folder of their own:

```
ana@dev:~$ mkdir download && cp release-0.3.0/* download/ && cd download && gpg --verify SHA256SUMS.asc SHA256SUMS 2>&1 | grep -E "Good|BAD" && sha256sum -c SHA256SUMS
gpg: Good signature from "Ana <ana@example.com>" [ultimate]
planner-0.3.0-x86_64.AppImage: OK
planner-0.3.0-amd64.deb: OK
```

**A release that its own author has verified as a stranger would** is one the next section can put in front
of people.
