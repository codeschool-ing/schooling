---
title: The memory a photo takes
version: 1
---

**A photo's file size says nothing about its memory.** A JPEG of 3 megabytes is compressed; to draw it,
the phone decodes every pixel into four bytes, red, green, blue and transparency. So the memory is width ×
height × 4, whatever the file weighs:

| photo | pixels | decoded |
|---|---|---|
| a phone camera's, 4000 × 3000 | 12 million | 48 MB |
| the same, 1600 × 1200 | 1.9 million | 7.7 MB |
| the planner's icon, 1024 × 1024 | 1 million | 4.2 MB |

A screen of course photos at full size is hundreds of megabytes, and an app that holds that much is the one
the system closes first. Lesson 13's `quality: 0.7` made the file smaller and left the pixels exactly as
many. **The planner should keep a photo no larger than a screen can show.** `expo-image-manipulator`
resizes images on the phone, and in a browser with a canvas:

```
ana@dev:~/planner$ npx expo install expo-image-manipulator
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 1 SDK 58.0.0 compatible native module using npm
> npm install

added 1 package, and audited 1129 packages in 7s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

Save `src/shrink.ts`:

```ts
// src/shrink.ts: a photo made no larger than a phone's screen can show, before anything keeps it.
import { ImageManipulator, SaveFormat } from "expo-image-manipulator";

export const LONGEST = 1600; // pixels on the longer side: sharp on any phone, a fifth of a camera's photo

export async function shrink(uri: string, width: number, height: number): Promise<string> {
  if (Math.max(width, height) <= LONGEST) return uri;
  const size = width >= height ? { width: LONGEST } : { height: LONGEST };
  const image = await ImageManipulator.manipulate(uri).resize(size).renderAsync();
  const saved = await image.saveAsync({ compress: 0.7, format: SaveFormat.JPEG });
  return saved.uri;
}
```

`manipulate` starts a chain of changes, `resize` with one side given keeps the proportions, `renderAsync`
does the work, and `saveAsync` writes a JPEG and returns its address. A photo already small enough comes
back untouched, so the icon is not made worse. In `src/NotesPhoto.tsx`, `use` shrinks before it keeps:

```tsx
// src/NotesPhoto.tsx: a photo of a course's notes, chosen from the library or taken with the camera.
import * as ImagePicker from "expo-image-picker";
import { useState } from "react";
import { Image, Linking, Pressable, StyleSheet, Text, View } from "react-native";
import { keepPhoto } from "./keepPhoto";
import { shrink } from "./shrink";
import { useTheme } from "./theme";

const OPTIONS: ImagePicker.ImagePickerOptions = { mediaTypes: ["images"], quality: 0.7 };
type Camera = "unasked" | "refused" | "blocked";

export function NotesPhoto({ course }: { course: string }) {
  const t = useTheme();
  const [uri, setUri] = useState<string | null>(null);
  const [camera, setCamera] = useState<Camera>("unasked");

  async function use(result: ImagePicker.ImagePickerResult) {
    if (result.canceled) return;
    const { uri, width, height } = result.assets[0];
    setUri(keepPhoto(await shrink(uri, width, height), course));
  }

  async function choose() {
    use(await ImagePicker.launchImageLibraryAsync(OPTIONS)); // the system's picker: no permission
  }

  async function take() {
    const permission = await ImagePicker.requestCameraPermissionsAsync();
    if (!permission.granted) {
      setCamera(permission.canAskAgain ? "refused" : "blocked");
      return;
    }
    setCamera("unasked");
    use(await ImagePicker.launchCameraAsync(OPTIONS));
  }

  return (
    <View style={styles.box}>
      <View style={styles.buttons}>
        <Pressable role="button" onPress={choose} hitSlop={8}>
          <Text style={[styles.action, { color: t.accent }]}>Choose a photo</Text>
        </Pressable>
        <Pressable role="button" onPress={take} hitSlop={8}>
          <Text style={[styles.action, { color: t.accent }]}>Take a photo</Text>
        </Pressable>
      </View>
      {camera === "refused" && (
        <Text role="alert" style={{ color: t.text }}>
          Without the camera the planner cannot take a photo. You can choose one you already have.
        </Text>
      )}
      {camera === "blocked" && (
        <View>
          <Text role="alert" style={{ color: t.text }}>
            The camera is turned off for the planner. You can turn it on in Settings.
          </Text>
          <Pressable role="button" onPress={() => Linking.openSettings()} hitSlop={8}>
            <Text style={[styles.action, { color: t.accent }]}>Open Settings</Text>
          </Pressable>
        </View>
      )}
      {uri && <Image source={{ uri }} aria-label="Your photo of the notes" style={styles.photo} resizeMode="contain" />}
    </View>
  );
}

const styles = StyleSheet.create({
  box: { gap: 8, paddingVertical: 8 },
  buttons: { flexDirection: "row", gap: 24 },
  action: { fontSize: 16, fontWeight: "600" },
  photo: { width: "100%", aspectRatio: 4 / 3 },
});
```

`shrink` is asynchronous, so `use` is now `async` too. The picker already says each photo's width and
height, so nothing needs measuring.

## In a browser

Lesson 13's `pick.mjs` handed the picker the 1024-pixel icon. A photo the size of a camera's is easy to
make with Playwright: a page 4000 pixels wide, photographed. Save `big.mjs`:

```javascript
// big.mjs: make a picture the size of a camera's photo, 4000 by 3000 pixels, to pick as one.
//
//   node big.mjs FILE
import { chromium } from "playwright";

const [file] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 4000, height: 3000 } });
await page.setContent('<body style="margin:0;height:100vh;background:linear-gradient(135deg,#1d6f42,#e8c547)">');
await page.screenshot({ path: file });
await browser.close();
```

```
ana@dev:~/planner$ node big.mjs big.png
ana@dev:~/planner$ file big.png
big.png: PNG image data, 4000 x 3000, 8-bit/color RGB, non-interlaced
ana@dev:~/planner$ node pick.mjs http://localhost:8082/course/guitar 'Choose a photo' big.png
file chooser: no capture attribute
photo: 1600×1200, alt="Your photo of the notes"
ana@dev:~/planner$ node pick.mjs http://localhost:8082/course/guitar 'Choose a photo' assets/icon.png
file chooser: no capture attribute
photo: 1024×1024, alt="Your photo of the notes"
```

**The 4000 × 3000 picture arrived as 1600 × 1200**: 7.7 megabytes in memory instead of 48. The icon came
back as it went in. *On a phone the same code runs the phone's own image libraries instead of a canvas; the
arithmetic is the same and was not measured there.*

**`expo-image`** is the other half for an app with many pictures: an `Image` component that caches on disk
and in memory, and decodes to the size it is drawn at. *The planner shows one photo per screen and does not
install it.*
