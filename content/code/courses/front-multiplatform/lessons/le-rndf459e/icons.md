---
title: One icon, every size
version: 1
---

**Every package of the previous section needs an icon, and each system wants it in its own sizes and
formats.** Android wants a set of PNGs in five densities, with a round version for the launchers that cut icons into circles. iOS wants one 1024-pixel image in an asset catalogue; Windows wants an `.ico`
holding several sizes in one file; macOS wants an `.icns`; Linux wants PNGs. Nobody draws those by hand.
**You draw one icon, large and square, and a tool cuts the rest.**

The planner's icon is an SVG, so it can be scaled to any size without blurring: a page of a calendar on a
dark green square, with a tick on one of the days. Save it as `icon.svg`, in `~/planner`:

```xml
<!-- icon.svg -->
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <rect width="1024" height="1024" rx="224" fill="#1d3b2f"/>
  <rect x="232" y="268" width="560" height="520" rx="48" fill="#f3efe4"/>
  <rect x="232" y="268" width="560" height="120" rx="48" fill="#e0a43a"/>
  <rect x="232" y="340" width="560" height="48" fill="#e0a43a"/>
  <g fill="#1d3b2f">
    <rect x="312" y="456" width="96" height="96" rx="16"/>
    <rect x="464" y="456" width="96" height="96" rx="16"/>
    <rect x="616" y="456" width="96" height="96" rx="16" opacity=".25"/>
    <rect x="312" y="600" width="96" height="96" rx="16" opacity=".25"/>
  </g>
  <path d="M478 640 l40 40 l80 -96" fill="none" stroke="#e0a43a" stroke-width="36" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
```

**An icon is drawn for sixteen pixels as much as for a thousand.** A launcher shows it at about 48 pixels
and a taskbar at 16 to 32, where a line of text inside it would be a grey smudge. That is why this one is
four squares and a tick, and why its corners are already rounded: the shape survives being small.

## The desktop sizes, from Tauri

The Tauri CLI of lesson 12 has a command that does the cutting, and it reads SVG:

```
ana@dev:~/planner$ npx tauri icon icon.svg > /dev/null 2>&1
ana@dev:~/planner$ ls src-tauri/icons
128x128.png
128x128@2x.png
32x32.png
64x64.png
Square107x107Logo.png
Square142x142Logo.png
Square150x150Logo.png
Square284x284Logo.png
Square30x30Logo.png
Square310x310Logo.png
Square44x44Logo.png
Square71x71Logo.png
Square89x89Logo.png
StoreLogo.png
android
icon.icns
icon.ico
icon.png
ios
ana@dev:~/planner$ file src-tauri/icons/icon.png src-tauri/icons/android/mipmap-xxxhdpi/ic_launcher.png | cut -d, -f1,2
src-tauri/icons/icon.png:                               PNG image data, 512 x 512
src-tauri/icons/android/mipmap-xxxhdpi/ic_launcher.png: PNG image data, 192 x 192
```

**`tauri icon` wrote every file `tauri.conf.json` asks for**: the PNGs, `icon.ico` for Windows and
`icon.icns` for macOS, plus the `Square…Logo.png` files the Windows store uses. It also wrote `android/`
and `ios/` folders inside `src-tauri/icons`, for Tauri's own mobile builds, which this course does not
make. The 512-pixel `icon.png` is the one the Electron packages of the next section use too, so the two
desktop apps carry the same icon.

## The phone sizes, from Capacitor

The Android and iOS projects of lesson 3 still carry Capacitor's default icon. **`@capacitor/assets`**
reads a folder called `assets` and writes the icons, and the splash screens shown while the app starts,
into both native projects. Given only a `logo.svg`, it puts the logo on a plain background for every size:

```
ana@dev:~/planner$ npm install -E -D @capacitor/assets@3.0.5 > /dev/null 2>&1
ana@dev:~/planner$ mkdir assets && cp icon.svg assets/logo.svg
ana@dev:~/planner$ npx capacitor-assets generate --android --ios 2>&1 | tail -n 3
Totals:
android: 74 generated, 466.33 KB total
ios: 7 generated, 618.2 KB total
ana@dev:~/planner$ git status --short --untracked-files=all android ios | wc -l
62
```

**81 files written, and 62 of them new or different in the two native projects**, by git's count: every
one is a size or a screen some device asks for, which is the reason for a tool. The splash screens come in light and dark, because a phone in dark
mode would otherwise flash white at every start. If you want more control, the tool also reads
`icon-only.png`, `icon-foreground.png` and `icon-background.png`, 1024 pixels square, for Android's
adaptive icons, whose foreground moves over the background as the launcher animates it. *The icons were
never seen on a phone in this course, since the Android and iOS projects were never built; what the
transcript shows is the files that the build would pack.*
