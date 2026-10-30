---
title: Um ícone, todos os tamanhos
version: 1
---

**Todo pacote da seção anterior precisa de um ícone, e cada sistema o quer nos seus tamanhos e formatos.** O
Android quer um conjunto de PNGs em cinco densidades, com uma versão redonda para os launchers que recortam
ícones em círculos; o iOS quer uma imagem de 1024 pixels num catálogo de assets; o Windows quer um `.ico` com
vários tamanhos num arquivo só; o macOS quer um `.icns`; o Linux quer PNGs. Ninguém desenha isso à mão.
**Você desenha um ícone, grande e quadrado, e uma ferramenta corta o resto.**

O ícone do planner é um SVG, então pode mudar para qualquer tamanho sem borrar: uma folha de calendário num
quadrado verde-escuro, com um tique num dos dias. Salve-o como `icon.svg`, em `~/planner`:

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

**Um ícone é desenhado para dezesseis pixels tanto quanto para mil.** Um launcher o mostra com uns 48 pixels e
uma barra de tarefas com 16 a 32, onde uma linha de texto dentro dele seria um borrão cinza. É por isso que este
tem quatro quadrados e um tique, e por isso os cantos já vêm arredondados: a forma sobrevive a ser pequena.

## Os tamanhos do desktop, pelo Tauri

A CLI do Tauri da aula 12 tem um comando que faz o recorte, e ele lê SVG:

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

**O `tauri icon` escreveu todos os arquivos que o `tauri.conf.json` pede**: os PNGs, `icon.ico` para o Windows
e `icon.icns` para o macOS, além dos arquivos `Square…Logo.png` que a loja do Windows usa. Ele também escreveu
pastas `android/` e `ios/` dentro de `src-tauri/icons`, para os builds de celular do próprio Tauri, que este
curso não faz. O `icon.png` de 512 pixels é o que os pacotes do Electron da próxima seção também usam, então os
dois apps de desktop levam o mesmo ícone.

## Os tamanhos do celular, pelo Capacitor

Os projetos Android e iOS da aula 3 ainda levam o ícone padrão do Capacitor. O **`@capacitor/assets`** lê uma
pasta chamada `assets` e escreve os ícones, e as telas de abertura mostradas enquanto o app inicia, nos dois
projetos nativos. Recebendo só um `logo.svg`, ele põe o logo sobre um fundo liso em todos os tamanhos:

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

**81 arquivos escritos, e 62 deles novos ou diferentes nos dois projetos nativos**, pela conta do git:
cada um é um tamanho ou uma tela que algum aparelho pede, e esse é o motivo de existir uma ferramenta. As telas de abertura vêm em claro e escuro, porque um celular no modo escuro piscaria branco a
cada abertura. Se você quiser mais controle, a ferramenta também lê `icon-only.png`, `icon-foreground.png` e
`icon-background.png`, de 1024 pixels de lado, para os ícones adaptativos do Android, cujo primeiro plano se
move sobre o fundo quando o launcher o anima. *Os ícones nunca foram vistos num celular neste curso, já que os
projetos Android e iOS nunca foram compilados; o que a transcrição mostra são os arquivos que o build levaria.*
