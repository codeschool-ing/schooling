---
title: Built, opened and measured
version: 1
---

**`npx tauri build` runs `npm run build` first, as `tauri.conf.json` tells it to, then compiles the Rust
core in release mode and packages the result.** The first build downloads and compiles every Rust library
Tauri uses, and took several minutes on the recording machine; later builds compile only what changed. The
last lines of it, and then a count of the libraries Cargo had downloaded into `~/.cargo/registry` by then:

```
ana@dev:~/planner$ npx tauri build 2>&1 | tail -n 9
        Info Patching /home/ana/planner/src-tauri/target/release/app with bundle type information: rpm
    Bundling planner-0.1.0-1.x86_64.rpm (/home/ana/planner/src-tauri/target/release/bundle/rpm/planner-0.1.0-1.x86_64.rpm)
        Info Patching /home/ana/planner/src-tauri/target/release/app with bundle type information: appimage
    Bundling planner_0.1.0_amd64.AppImage (/home/ana/planner/src-tauri/target/release/bundle/appimage/planner_0.1.0_amd64.AppImage)
    Finished 3 bundles at:
        /home/ana/planner/src-tauri/target/release/bundle/deb/planner_0.1.0_amd64.deb (2.85 MiB)
        /home/ana/planner/src-tauri/target/release/bundle/rpm/planner-0.1.0-1.x86_64.rpm (2.86 MiB)
        /home/ana/planner/src-tauri/target/release/bundle/appimage/planner_0.1.0_amd64.AppImage (77.85 MiB)

ana@dev:~/planner$ ls ~/.cargo/registry/src/*/ | wc -l
287
```

**287 libraries is the size of the Rust side**, and nearly all of them are Tauri's and the libraries it
stands on; the planner's own Rust is the one file of the previous section. **Three packages came out of one
build**, because `"targets": "all"` asks for every format Linux has: a
`.deb` for Debian and Ubuntu, an `.rpm` for Fedora and its relatives, and an **AppImage**, one file that
runs on most distributions without being installed. Lesson 13 is about these formats and what each asks
of the person installing it. The size of the AppImage stands out, and it has a reason: the `.deb` and the
`.rpm` say they depend on the system's WebKitGTK and let the package manager install it, while an AppImage
cannot depend on anything, so it carries its own copy.

While you work, **`npx tauri dev`** is the command you run instead: it starts `npm run dev`, opens the
window on the Vite server of `devUrl`, reloads the page as you edit the TypeScript, and recompiles the Rust
when a `.rs` file changes. It is the Tauri side of `npm start` in lesson 11.

## What the program is made of

The program the packages carry is `src-tauri/target/release/app`, named after the Rust package, `app` in
`Cargo.toml`. It contains no browser engine, and the system's linker says where the engine comes from:

```
ana@dev:~/planner$ ldd src-tauri/target/release/app | grep -E "webkit|gtk-3" | cut -d" " -f1
	libwebkit2gtk-4.1.so.0
	libgtk-3.so.0
```

**The page is drawn by `libwebkit2gtk-4.1`, the library the `apt` line of the installing section put
there**, with GTK around it for the window. On a computer with no WebKitGTK the program does not start,
which is the dependency the `.deb` declares. On Windows the same place is taken by WebView2 and on macOS by
the system's WebKit, and neither is in the download either.

## The window

The recording machine has no screen, so the window opened on Xvfb, as in lesson 11, and the transcript asks
the display what it holds:

```
ana@dev:~/planner$ xvfb-run -a sh -c "src-tauri/target/release/app 2>/dev/null & sleep 5; xwininfo -root -tree | grep -o \"Study planner.*\" | head -n 1; kill \$!"
Study planner": ("app" "App")  800x600+0+0  +0+0
```

**The window is there, with the title `tauri.conf.json` gave it**, and 800 by 600 pixels, the size the
template wrote. What the recording machine could not do is look inside it: Playwright drives Chromium and
Electron, and has no way into a WebKitGTK window, so the planner's export was never pressed in this window.
The Rust half of it is what `cargo test` proved; on your own computer, `npx tauri dev` and a click on
**Export** show the other half, and the path that comes back is under
`~/.local/share/com.example.studyplanner`.

## The sizes, side by side

```
ana@dev:~/planner$ du -sh src-tauri/target/release/app node_modules/electron/dist
11M	src-tauri/target/release/app
274M	node_modules/electron/dist
```

**The Tauri program is 11 MB; Electron's runtime alone, before the planner is added to it, is 274 MB.**
That is the trade of the first section in two numbers. The 11 MB carries the Rust core and the planner's
`dist/`, compressed inside it; the 274 MB carries a whole Chromium and a whole Node, and the same planner
on top. What the small number does not count is WebKitGTK itself, which is on the computer already, and
the time spent trying the planner in three different engines, which is on you.

The project is committed, with `src-tauri/target`, which holds the build, left out by the `.gitignore` that
`tauri init` wrote:

```
ana@dev:~/planner$ git status --short
 M package-lock.json
 M package.json
 M src/device.ts
?? src-tauri/
ana@dev:~/planner$ git add . && git commit -q -m "The planner as a desktop app, with Tauri" && git log --oneline -1
676a8f1 The planner as a desktop app, with Tauri
```
