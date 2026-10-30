---
title: Dois caminhos até a loja
version: 1
---

**Há dois jeitos de levar o trabalho de quem faz web para um celular ou um desktop, e eles diferem em
quem desenha a tela.** No primeiro, sua aplicação web roda como está, dentro de um motor de navegador
que um app nativo carrega. No segundo, você escreve o app de novo, e os controles do próprio sistema
operacional desenham cada botão e cada lista. O resto do curso são esses dois caminhos, lado a lado, e
como saber qual deles um app precisa.

A imagem comum é uma terceira: que uma aplicação web pode ser "convertida" num app nativo e sair do
outro lado como Swift ou Kotlin. **Nada a converte.** Toda ferramenta deste curso ou roda o seu HTML,
CSS e JavaScript num motor de navegador, ou pede que você descreva a tela de novo nos termos dela.
Saber qual das duas uma ferramenta faz já diz quase tudo o que ela consegue e o que não consegue.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l01-two-ways\" aria-label=\"Dois caminhos de uma aplicação web até uma loja. Na linha de cima, o embrulho: o site construído, dist, é copiado para um app nativo cuja tela inteira é uma WebView, e um motor de navegador desenha a tela; o Capacitor faz isso para Android e iOS, o Electron e o Tauri para o desktop. Na linha de baixo, o caminho nativo: as telas são escritas de novo como componentes, o React Native as transforma nas views da própria plataforma, e a plataforma desenha a tela. As regras do planner, src/planner.ts, não têm DOM e entram nos dois.\"><defs><marker id=\"l01-two-ways-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">o embrulho</text><text x=\"20\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">o caminho nativo</text><rect x=\"20\" y=\"36\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"54.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o site construído</text><text x=\"120.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">dist/</text><rect x=\"260\" y=\"36\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"54.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um app nativo cuja</text><text x=\"360.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tela é uma WebView</text><rect x=\"500\" y=\"36\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"54.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um motor de navegador</text><text x=\"600.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">desenha a tela</text><rect x=\"20\" y=\"166\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as telas, escritas de</text><text x=\"120.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">novo como componentes</text><rect x=\"260\" y=\"166\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o React Native as</text><text x=\"360.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">torna views nativas</text><rect x=\"500\" y=\"166\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"600.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os controles da própria</text><text x=\"600.0\" y=\"197.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">plataforma a desenham</text><path d=\"M220 61 L260 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path><path d=\"M460 61 L500 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path><path d=\"M220 191 L260 191\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path><path d=\"M460 191 L500 191\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path><text x=\"360\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">Capacitor · Electron · Tauri</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">React Native · Flutter · Swift e Kotlin</text><rect x=\"20\" y=\"112\" width=\"200\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"120.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">as regras, src/planner.ts:</text><text x=\"120.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem DOM, entram nos dois</text><path d=\"M120 112 L120 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path><path d=\"M120 146 L120 164\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l01-two-ways-ah-paper-dim)\"></path></svg>", "caption": "Nada converte uma aplicação web numa nativa. Ou um motor de navegador ainda a desenha, ou as telas são escritas de novo para a plataforma desenhar.", "same": ["Capacitor · Electron · Tauri", "dist/"]}
```

## O embrulho: seu app, dentro de uma casca nativa

Uma **WebView** é um motor de navegador sem o navegador em volta: sem barra de endereço, sem abas, só
a parte que transforma HTML em pixels, embutida num app comum. O Android tem uma, feita sobre o
Chromium. O iOS tem uma, feita sobre o WebKit, o motor do Safari. Um app embrulhado é um pequeno
programa nativo cuja tela inteira é uma WebView, carregando o seu site construído a partir de arquivos
que vêm dentro do app.

- O **Capacitor** (aulas 2 a 6) embrulha uma aplicação web para Android e iOS. A sua pasta `dist/` é
  copiada para um projeto Android de verdade e um projeto Xcode de verdade, e uma **ponte** deixa o seu
  JavaScript chamar código nativo: a câmera, os arquivos, as notificações.
- O **Electron** (aula 11) embrulha uma aplicação web para Windows, macOS e Linux, e leva uma cópia
  própria do Chromium e do Node.js dentro de cada app.
- O **Tauri** (aula 12) faz o mesmo com a WebView que o sistema operacional já tem, e um núcleo escrito
  em Rust em vez de Node.

**O que você mantém é tudo o que já escreveu.** O planner da seção seguinte vira um app Android na
aula 2 sem que uma linha dele mude. O que você abre mão é de tudo o que a WebView não faz, e a aula 6
é sobre descobrir isso antes que uma loja de apps descubra por você.

## O caminho nativo: a tela desenhada pela plataforma

A tela de um app nativo é feita dos controles da própria plataforma. Escrito em Swift para iOS e em
Kotlin para Android, isso quer dizer dois apps, duas linguagens e duas equipes. O **React Native**
(aulas 7 a 9) é o caminho do meio que este curso segue: você escreve componentes em JavaScript e
TypeScript, com React, e o React Native os transforma em views nativas de verdade em cada plataforma.
Não há DOM nem HTML. Uma `<View>` vira uma `View` do Android e uma `UIView` do iOS.

O que ele compra é a rolagem, os gestos, a digitação e a acessibilidade da própria plataforma, sem
motor de navegador no meio. O que ele custa é reescrever as telas. A lógica atravessa:
`src/planner.ts` não tem DOM, e a aula 7 o importa como está. **As views não atravessam**, porque não
há `document` onde desenhar. A aula 10 olha as outras ferramentas deste caminho, Flutter e
NativeScript, e o Ionic, que fica do lado do embrulho.

## O que o curso faz com eles

| aulas | o quê | onde roda |
|---|---|---|
| 1 | o planner, e o seu computador preparado | o navegador |
| 2 a 6 | Capacitor: o planner como app Android e iOS | um celular ou um emulador |
| 7 a 10 | React Native e Expo, e um olhar sobre os outros | um celular, um emulador ou o navegador |
| 11 e 12 | Electron e Tauri: o planner como app desktop | uma janela no seu computador |
| 13 a 15 | pacotes, assinaturas, lojas e atualizações | em todo lugar |
| 16 | o seu próprio app, lançado | onde você escolher |
