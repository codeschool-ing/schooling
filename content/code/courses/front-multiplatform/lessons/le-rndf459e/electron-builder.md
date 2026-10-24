---
title: Packaging Electron with electron-builder
version: 1
---

**Electron has no packaging command of its own; the planner's Electron app becomes a package with
`electron-builder`**, the tool most Electron apps use, at version 26.18.0 here. It copies Electron's
runtime, puts the app's files beside it in one archive, and wraps the result in the formats it is asked
for. The first run, with no configuration at all, shows what it does when nobody tells it anything:

```
ana@dev:~/planner$ npm install -E -D electron-builder@26.18.0 > /dev/null 2>&1
ana@dev:~/planner$ npx electron-builder --linux AppImage > /dev/null 2>&1; ls dist
assets
builder-debug.yml
courses.json
index.html
linux-unpacked
planner-0.0.0.AppImage
ana@dev:~/planner$ rm -rf dist && npm run build > /dev/null && ls dist
assets
courses.json
index.html
```

**It wrote the AppImage into `dist/`, the folder Vite builds the site into.** `dist` is electron-builder's
default output folder, and the planner's site already lives there. Left like that, the next `npm run build`
deletes the package, and the next package carries the previous package inside it, because `dist/` is what
it packs. The second command put `dist/` back as Vite makes it. The first rule of the configuration is
therefore **a folder of its own for the packages**, `release/`.

The first build also downloaded the tools it uses, the AppImage runtime, an archiver, and later `fpm` for
the `.deb`, from GitHub, so it was slow; they are kept in `~/.cache` for the next one.

## The configuration

electron-builder reads its settings from a `build` key in `package.json`. **`npm pkg set` writes it** without
opening the file, one key at a time, and a `[]` at the end of a key adds to a list:

```
ana@dev:~/planner$ npm pkg set build.appId=com.example.studyplanner build.productName="Study planner" build.directories.output=release "build.files[]=dist/**" "build.files[]=electron/**"
ana@dev:~/planner$ npm pkg set build.linux.category=Education build.linux.icon=src-tauri/icons/icon.png "build.linux.target[]=AppImage" "build.linux.target[]=deb" "build.artifactName=\${name}-\${version}-\${arch}.\${ext}"
ana@dev:~/planner$ npx electron-builder --linux 2>&1 | grep -E "^(Please|It is required)"
Please specify author 'email' in the application package.json
It is required to set Linux .deb package maintainer. Or you can set maintainer in the custom linux options.
```

Each setting is a decision:

| key | value | why |
|---|---|---|
| `appId` | `com.example.studyplanner` | the same identity as the phone app and the Tauri app |
| `productName` | `Study planner` | the name a person sees in the menu |
| `directories.output` | `release` | out of Vite's way |
| `files` | `dist/**`, `electron/**` | **only what the app runs**: not `android/`, `ios/`, `src-tauri/` or the sources |
| `linux.category` | `Education` | where the desktop's menu files it |
| `linux.icon` | the 512-pixel PNG of the previous section | the same icon as Tauri's |
| `linux.target` | `AppImage`, `deb` | the two formats to build |
| `artifactName` | `${name}-${version}-${arch}.${ext}` | a file name with no space in it, so scripts can handle it |

**The `.deb` refused to be built.** A Debian package has to name its maintainer, a person with an e-mail
address, and electron-builder takes it from the `author` of `package.json`, which the planner never had.
The planner's version was also still Vite's `0.0.0`, and a package with that version says nothing to the
person installing it. Lesson 15 is about version numbers; here the planner becomes `0.1.0`, the version
Tauri's configuration already carried:

```
ana@dev:~/planner$ npm pkg set version=0.1.0 description="A study planner" homepage=https://example.com/planner author.name=Ana author.email=ana@example.com
ana@dev:~/planner$ rm -rf release && npx electron-builder --linux 2>&1 | grep -o "target=.*"
target=AppImage arch=x64 file=release/planner-0.1.0-x86_64.AppImage
target=deb arch=x64 file=release/planner-0.1.0-amd64.deb
ana@dev:~/planner$ du -sh release/*.AppImage release/*.deb
121M	release/planner-0.1.0-x86_64.AppImage
97M	release/planner-0.1.0-amd64.deb
```

**121 MB for the AppImage and 97 MB for the `.deb`**, against 2.85 MB for Tauri's `.deb` in lesson 12. The
difference is the one lesson 12 measured on disk, now in what a person downloads.

## What is inside

Electron's package keeps the app's own files in one archive, `app.asar`, which `npx asar` can list:

```
ana@dev:~/planner$ npx asar list release/linux-unpacked/resources/app.asar | cut -d/ -f2-3 | sort -u
dist
dist/assets
dist/courses.json
dist/index.html
electron
electron/main.mjs
electron/preload.cjs
node_modules
node_modules/@capacitor
node_modules/@tauri-apps
node_modules/capacitor-keep-awake
node_modules/tslib
package.json
```

**`files` did its job for the project's folders**: `dist/`, `electron/` and `package.json`, and none of
`android/`, `ios/`, `src-tauri/` or `src/`. But **`node_modules` is there**, with Capacitor's packages and
the Tauri API in it. electron-builder always adds the packages listed under `dependencies` in
`package.json`, because an Electron app's main process may `require` them at run time. The planner's main
process requires none of them: Vite has already bundled what the page uses into `dist/assets`. Moving those
packages to `devDependencies` would leave them out of the archive. They are small, so the planner leaves
them where they are, and you now know where to look when a package is larger than it should be.
