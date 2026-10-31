---
title: A memória que uma foto ocupa
version: 1
---

**O tamanho do arquivo de uma foto não diz nada sobre a memória dela.** Um JPEG de 3 megabytes é
comprimido; para desenhá-lo, o celular decodifica cada pixel em quatro bytes, vermelho, verde, azul e
transparência. Então a memória é largura × altura × 4, seja qual for o peso do arquivo:

| foto | pixels | decodificada |
|---|---|---|
| a da câmera de um celular, 4000 × 3000 | 12 milhões | 48 MB |
| a mesma, 1600 × 1200 | 1,9 milhão | 7,7 MB |
| o ícone do planner, 1024 × 1024 | 1 milhão | 4,2 MB |

Uma tela de fotos de cursos em tamanho cheio são centenas de megabytes, e um app que segura tanto é o
primeiro que o sistema fecha. O `quality: 0.7` da aula 13 deixou o arquivo menor e os pixels exatamente
tantos quanto antes. **O planner deveria guardar uma foto não maior do que uma tela consegue mostrar.** O
`expo-image-manipulator` redimensiona imagens no celular, e num navegador com um canvas:

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

Salve o `src/shrink.ts`:

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

O `manipulate` começa uma cadeia de mudanças, o `resize` com um lado só mantém as proporções, o
`renderAsync` faz o trabalho, e o `saveAsync` escreve um JPEG e devolve o endereço dele. Uma foto já pequena
o bastante volta intocada, então o ícone não piora. No `src/NotesPhoto.tsx`, o `use` reduz antes de
guardar:

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

O `shrink` é assíncrono, então o `use` agora é `async` também. O seletor já diz a largura e a altura de cada
foto, então não há nada a medir.

## Num navegador

O `pick.mjs` da aula 13 entregava ao seletor o ícone de 1024 pixels. Uma foto do tamanho da de uma câmera é
fácil de fazer com o Playwright: uma página de 4000 pixels de largura, fotografada. Salve o `big.mjs`:

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

**A imagem de 4000 × 3000 chegou como 1600 × 1200**: 7,7 megabytes de memória em vez de 48. O ícone voltou
como entrou. *Num celular, o mesmo código usa as bibliotecas de imagem do próprio celular em vez de um
canvas; a conta é a mesma e não foi medida lá.*

**O `expo-image`** é a outra metade para um app com muitas imagens: um componente `Image` que guarda cache
em disco e em memória, e decodifica no tamanho em que é desenhado. *O planner mostra uma foto por tela e não
o instala.*
