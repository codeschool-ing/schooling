---
title: An Electron app that updates itself
version: 1
---

**A store updates a phone app; a desktop app downloaded from your site has to update itself.** Lesson 11 ended
on why that matters: an Electron app carries a Chromium, and its security fixes reach people only when a new
version of the app does. `electron-updater`, from the same project as electron-builder, is the usual way, and it
needs three things: a place that serves the releases, a file there that names the latest one, and code in the
app that asks.

**The place is any web server**, with the `generic` provider: a folder of files at an address. electron-builder
also knows GitHub Releases and S3, which are the same idea with an account. The planner's is
`http://localhost:8080/`, served from your own computer, so the whole loop can be watched without publishing
anything. The library goes into `dependencies`, because the main process loads it at run time, and the address
into the configuration:

```
ana@dev:~/planner$ npm install -E electron-updater@6.8.11 > /dev/null 2>&1
ana@dev:~/planner$ npm pkg set build.publish.provider=generic build.publish.url=http://localhost:8080/
ana@dev:~/planner$ git add . && git commit -q -m "Check for updates at start" && git log --oneline -1
a065bcf Check for updates at start
```

The code is a file of its own, `electron/updater.mjs`, which the main process calls once it is ready:

```javascript
// electron/updater.mjs: ask the release server whether a newer version exists, and fetch it.
import { app } from "electron";
import updater from "electron-updater";

export function checkForUpdates() {
  const { autoUpdater } = updater;
  autoUpdater.on("update-available", (info) => console.log(`update available: ${info.version}`));
  autoUpdater.on("update-not-available", (info) => console.log(`up to date: ${info.version}`));
  autoUpdater.on("update-downloaded", (info) => console.log(`downloaded ${info.version}; it installs on quit`));
  autoUpdater.on("error", (error) => console.log(`update failed: ${error.message}`));
  // Only a packaged app has a version to compare; npm start has nothing to replace.
  if (app.isPackaged) autoUpdater.checkForUpdates();
}
```

`electron/main.mjs` gains an import beside the others and one call, the first thing after `serveSite()`:

```javascript
import { checkForUpdates } from "./updater.mjs";
```

```javascript
  checkForUpdates();
```

**The `console.log` lines are there to be read in a terminal**; a real app shows the person a quiet notice
instead, or nothing at all, since the update installs on its own when the app quits.

## An old version, and a new one

To see an update, somebody needs the old version installed. Build `0.2.0`, copy its AppImage somewhere else,
as if a person had downloaded it, then release `0.3.0` with the command of the previous section:

```
ana@dev:~/planner$ rm -rf release && npx electron-builder --linux AppImage 2>&1 | grep -o "target=.*"
target=AppImage arch=x64 file=release/planner-0.2.0-x86_64.AppImage
ana@dev:~/planner$ mkdir ~/installed && cp release/planner-0.2.0-x86_64.AppImage ~/installed/
```

```
ana@dev:~/planner$ npm version minor

> version
> node scripts/version.mjs && git add android ios

version 0.3.0, build 300
v0.3.0
ana@dev:~/planner$ npx electron-builder --linux AppImage > /dev/null 2>&1; ls release
builder-debug.yml
latest-linux.yml
linux-unpacked
planner-0.2.0-x86_64.AppImage
planner-0.3.0-x86_64.AppImage
ana@dev:~/planner$ cat release/latest-linux.yml
version: 0.3.0
files:
  - url: planner-0.3.0-x86_64.AppImage
    sha512: oZimtcTzcMUGYgsQx8RfGs1dqw2huly6TaXz25UIs6utgqE19BTMC2CFOy+UQ2TSc6oDNWSTK2rxRhMOunraeg==
    size: 126764447
    blockMapSize: 132531
path: planner-0.3.0-x86_64.AppImage
sha512: oZimtcTzcMUGYgsQx8RfGs1dqw2huly6TaXz25UIs6utgqE19BTMC2CFOy+UQ2TSc6oDNWSTK2rxRhMOunraeg==
releaseDate: '2026-10-24T02:07:31.180Z'
```

**`latest-linux.yml` is the file the app asks for.** It names the newest version, the file to download, its size,
and its **SHA-512**, the checksum lesson 14 made by hand, here made by electron-builder for every release.
Upload the AppImage and this file together, every time, or the app goes on finding the old one.

## The update

Serve `release/` in a second terminal with `python3 -m http.server 8080 --directory release`, and start the
installed `0.2.0`:

```
ana@dev:~$ xvfb-run -a sh -c "APPIMAGE_EXTRACT_AND_RUN=1 timeout 40 installed/planner-0.2.0-x86_64.AppImage 2>/dev/null | grep -v appimage_extracted"
Found version 0.3.0 (url: planner-0.3.0-x86_64.AppImage)
update available: 0.3.0
Downloading update from planner-0.3.0-x86_64.AppImage
updater cache dir: /home/ana/.cache/planner-updater
New version 0.3.0 has been downloaded to /home/ana/.cache/planner-updater/pending/planner-0.3.0-x86_64.AppImage
downloaded 0.3.0; it installs on quit
Auto install update on quit
Install: isSilent: true, isForceRunAfter: false
```

**It asked, found `0.3.0`, downloaded it, and will put it in place of the installed file when it quits.** The
two lines from `updater.mjs` are `update available` and `downloaded`; the rest is electron-updater's own log. Its
first line, `Checking for update`, was printed on the same line as the end of the runtime's list of files, so
the `grep` that hides the list took it too. `timeout` then stopped the app, which is a quit, and the next start
shows what happened to the file:

```
ana@dev:~$ ls installed
planner-0.3.0-x86_64.AppImage
ana@dev:~$ sha256sum installed/*.AppImage planner/release/planner-0.3.0-x86_64.AppImage | cut -c1-16,66-
acee15a1a238fe71 installed/planner-0.3.0-x86_64.AppImage
acee15a1a238fe71 planner/release/planner-0.3.0-x86_64.AppImage
```

**The `0.2.0` in `~/installed` is gone, and `0.3.0` is in its place**, byte for byte the file on the server: the
updater replaces the AppImage the person started, in the folder where they keep it, and since the old name had the
version in it, the new file takes the new version's name. The next start runs `0.3.0`.

**The checksum is checked, not decorative.** Here one byte is added to the AppImage on the server after the
release was made, as if somebody had replaced it, and a fresh copy of the old version asks again:

```
ana@dev:~$ rm -rf installed/* ~/.cache/planner-updater && cp planner/release/planner-0.2.0-x86_64.AppImage installed/
ana@dev:~$ printf x >> planner/release/planner-0.3.0-x86_64.AppImage
ana@dev:~$ xvfb-run -a sh -c "APPIMAGE_EXTRACT_AND_RUN=1 timeout 40 installed/planner-0.2.0-x86_64.AppImage 2>/dev/null | grep -E \"^(up to date|update)|sha512\" | cut -c1-110"
update available: 0.3.0
updater cache dir: /home/ana/.cache/planner-updater
update failed: sha512 checksum mismatch, expected oZimtcTzcMUGYgsQx8RfGs1dqw2huly6TaXz25UIs6utgqE19BTMC2CFOy+U
```

**The download was refused, and the installed version stayed as it was.** The SHA-512 in `latest-linux.yml` is
what makes that possible, which is also its limit: whoever can change both files on the server can change both
consistently. On macOS and Windows electron-updater also checks the new version's code signature against the
installed one's, which is the stronger guarantee lesson 14 bought with a certificate.

## Tauri's updater

Tauri has an updater plugin, `@tauri-apps/plugin-updater`, and it makes the signature part of the deal: every
update is signed with a key of its own, and the app refuses one that is not. The key is made by the CLI:

```
ana@dev:~/planner$ npx tauri signer generate --ci -p recording-machine-only -w ~/keys/planner-updater.key 2>&1 | grep -v "^ *$" | head -n 4
Your keypair was generated successfully:
Private: /home/ana/keys/planner-updater.key (Keep it secret!)
Public: /home/ana/keys/planner-updater.key.pub
---------------------------
ana@dev:~/planner$ ls ~/keys
planner-updater.key
planner-updater.key.pub
planner-upload.jks
```

**The public key goes into `tauri.conf.json`**, under `plugins.updater.pubkey`, with the address of a
`latest.json` under `endpoints`; **the private key stays in `~/keys`** with the Android keystore, and the build
reads it from the `TAURI_SIGNING_PRIVATE_KEY` variable to sign each bundle. *The plugin was not added to the
planner: it needs another Rust build and a second app to update, and the Electron loop above already showed each
step.* Tauri's documentation has the `latest.json` format and the Rust and JavaScript sides of the plugin.
