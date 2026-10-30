---
title: The picker in a browser, and a picture with no description
version: 1
---

**On the web, `expo-image-picker` is a file input.** Pressing either button makes the library add an
invisible `<input type="file">` to the page and click it, which opens the browser's file chooser; *Take a
photo* adds `capture="camera"`, which a phone's browser takes as a request for the camera. There are no
permissions on the web side either: `requestCameraPermissionsAsync` answers *granted* there, and the
browser decides for itself.

Playwright can answer a file chooser as a person would, so the whole path can be run. This program
presses a button, hands the chooser a file and reports the picture the screen then draws. Save it as
`pick.mjs`:

```javascript
// pick.mjs: press a button that opens a file chooser, hand it a file as a person would, and
// describe the photo the screen shows afterwards.
//
//   node pick.mjs URL BUTTON FILE
import { chromium } from "playwright";

const [url, button, file] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(url);
await page.waitForLoadState("networkidle");
const opened = page.waitForEvent("filechooser");
await page.getByRole("button", { name: button }).click();
const chooser = await opened;
const capture = await chooser.element().getAttribute("capture");
console.log("file chooser:", capture ? `capture="${capture}"` : "no capture attribute");
await chooser.setFiles(file);
// the <img> react-native-web draws, found by its address rather than by its name
const photo = page.locator('img[src^="blob:"]');
await photo.waitFor();
const [alt, w, h] = await photo.evaluate((img) => [img.alt, img.naturalWidth, img.naturalHeight]);
console.log(`photo: ${w}×${h}, alt="${alt}"`);
await browser.close();
```

The file it hands over is the planner's own icon, `assets/icon.png`, which every Expo project has. Start
the server, export the web build and serve it, as in lesson 10, then choose a photo on the guitar course:

```
ana@dev:~/planner$ node pick.mjs http://localhost:8082/course/guitar 'Choose a photo' assets/icon.png
file chooser: no capture attribute
photo: 1024×1024, alt=""
```

**The photo arrived, 1024 pixels square, and its `alt` is empty.** To a screen reader that is a picture
announced as nothing, or skipped. The component says `alt="Your photo of the notes"`, and the test of the
last section found the image by that very label, so the label is not missing from the code; it is missing
from the page.

**`react-native-web` does not read the `alt` prop.** On a phone, React Native turns `alt` into the image's
accessibility label, and Jest, which renders as a phone would, saw that label. The web renderer takes its
description from `aria-label` instead and writes it into the `<img>`. In `src/NotesPhoto.tsx`, change the
image's `alt=` to `aria-label=`, so the line reads:

```tsx
{uri && <Image source={{ uri }} aria-label="Your photo of the notes" style={styles.photo} resizeMode="contain" />}
```

`aria-label` is what the planner already gives its buttons and its bar, and React Native reads it on both phones too.
Export again and run both buttons:

```
ana@dev:~/planner$ grep -n 'aria-label="Your photo' src/NotesPhoto.tsx
59:      {uri && <Image source={{ uri }} aria-label="Your photo of the notes" style={styles.photo} resizeMode="contain" />}
ana@dev:~/planner$ npx jest NotesPhoto --forceExit 2>&1 | tail -5
Tests:       5 passed, 5 total
Snapshots:   0 total
Time:        0.687 s, estimated 1 s
Ran all test suites matching NotesPhoto.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
ana@dev:~/planner$ node pick.mjs http://localhost:8082/course/guitar 'Choose a photo' assets/icon.png
file chooser: no capture attribute
photo: 1024×1024, alt="Your photo of the notes"
ana@dev:~/planner$ node pick.mjs http://localhost:8082/course/guitar 'Take a photo' assets/icon.png
file chooser: capture="camera"
photo: 1024×1024, alt="Your photo of the notes"
```

**The tests still pass, and now the browser agrees with them.** That is the lesson of this section, and
it is bigger than one prop: Jest renders one platform. It answered the question it was asked, whether the
component gives the image a label, and could not answer whether every renderer reads it. *Take a photo*
opened the same chooser with `capture="camera"`; on a desktop browser that changes nothing, and on a
phone's browser it opens the camera.
