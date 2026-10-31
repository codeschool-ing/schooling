---
title: O seletor num navegador, e uma imagem sem descrição
version: 1
---

**Na web, o `expo-image-picker` é um input de arquivo.** Apertar qualquer um dos botões faz a biblioteca
acrescentar um `<input type="file">` invisível à página e clicar nele, o que abre o seletor de arquivos do
navegador; o *Take a photo* acrescenta `capture="camera"`, que o navegador de um celular entende como um
pedido de câmera. Também não há permissões do lado da web: o `requestCameraPermissionsAsync` responde
*granted* lá, e o navegador decide por conta própria.

O Playwright consegue responder a um seletor de arquivos como uma pessoa faria, então o caminho inteiro
pode ser executado. Este programa aperta um botão, entrega um arquivo ao seletor e relata a imagem que a
tela desenha em seguida. Salve-o como `pick.mjs`:

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

O arquivo que ele entrega é o próprio ícone do planner, `assets/icon.png`, que todo projeto Expo tem. Suba
o servidor, exporte o build web e sirva-o, como na aula 10, e depois escolha uma foto no curso de guitar:

```
ana@dev:~/planner$ node pick.mjs http://localhost:8082/course/guitar 'Choose a photo' assets/icon.png
file chooser: no capture attribute
photo: 1024×1024, alt=""
```

**A foto chegou, com 1024 pixels de lado, e o `alt` dela está vazio.** Para um leitor de tela, isso é uma
imagem anunciada como nada, ou pulada. O componente diz `alt="Your photo of the notes"`, e o teste da
seção anterior achou a imagem por esse mesmo rótulo, então o rótulo não falta no código; falta na página.

**O `react-native-web` não lê a prop `alt`.** Num celular, o React Native transforma o `alt` no rótulo de
acessibilidade da imagem, e o Jest, que renderiza como um celular, viu esse rótulo. O renderizador da web
tira a descrição do `aria-label` e a escreve no `<img>`. No `src/NotesPhoto.tsx`, troque o `alt=` da imagem
por `aria-label=`, para a linha ficar assim:

```tsx
{uri && <Image source={{ uri }} aria-label="Your photo of the notes" style={styles.photo} resizeMode="contain" />}
```

O `aria-label` é o que o planner já dá aos botões e à barra, e o React Native o lê nos dois celulares
também. Exporte de novo e rode os dois botões:

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

**Os testes continuam passando, e agora o navegador concorda com eles.** Essa é a lição desta seção, e ela
é maior que uma prop: o Jest renderiza uma plataforma. Ele respondeu à pergunta que lhe fizeram, se o
componente dá um rótulo à imagem, e não tinha como responder se todo renderizador o lê. O *Take a photo*
abriu o mesmo seletor com `capture="camera"`; num navegador de computador isso não muda nada, e no
navegador de um celular abre a câmera.
