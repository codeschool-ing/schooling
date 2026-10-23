---
title: O que é o Capacitor, e a ponte no meio
version: 1
---

**O Capacitor pega uma aplicação web construída e a coloca dentro de um projeto Android de verdade e
de um projeto Xcode de verdade**, cuja única função é abrir uma WebView em tela cheia e carregar os
seus arquivos nela. Os projetos são comuns: o Android Studio e o Xcode os abrem, constroem e assinam
como fariam com qualquer app. O Capacitor acrescenta duas coisas a cada um, um jeito de servir os seus
arquivos e um jeito de o seu JavaScript chamar código nativo.

É fácil imaginar o Capacitor como um servidor, ou como um conversor. Ele não é nenhum dos dois.
**Nada roda num computador seu depois que o app está construído**: os arquivos viajam dentro do app, e
a WebView os lê do armazenamento do próprio celular.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l02-bridge\" aria-label=\"Dentro de um app Capacitor num celular. A WebView mostra o seu site construído, servido pelo Capacitor a partir dos arquivos do próprio app em https://localhost no Android e capacitor://localhost no iOS. Quando o seu código chama um plugin, a chamada atravessa a ponte como uma mensagem para uma classe nativa, em Java ou Kotlin no Android e em Swift no iOS, que fala com a câmera, os arquivos ou as notificações, e a resposta volta como o resultado de uma Promise.\"><defs><marker id=\"l02-bridge-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-bridge-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"214\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"36\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o app, no celular</text><rect x=\"40\" y=\"52\" width=\"250\" height=\"162\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"165\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">a WebView</text><rect x=\"60\" y=\"86\" width=\"210\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"165.0\" y=\"102.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">o seu site construído, dist/,</text><text x=\"165.0\" y=\"115.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">servido em https://localhost</text><rect x=\"60\" y=\"150\" width=\"210\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"165.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Preferences.set(…)</text><text x=\"345\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">a ponte</text><path d=\"M270 160 L420 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-bridge-ah-amber)\"></path><path d=\"M420 186 L270 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l02-bridge-ah-paper-dim)\"></path><text x=\"345\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a resposta: uma Promise se resolve</text><rect x=\"420\" y=\"146\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">uma classe nativa:</text><text x=\"480.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Java ou Kotlin, ou Swift</text><path d=\"M540 171 L565 171\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-bridge-ah-paper-dim)\"></path><rect x=\"565\" y=\"146\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"625.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">os arquivos, a câmera e</text><text x=\"625.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">as notificações do celular</text></svg>", "caption": "Os seus arquivos viajam dentro do app e são servidos por ele. A ponte é a única saída da WebView, e cada plugin é uma classe do outro lado dela."}
```

## Os seus arquivos, servidos de dentro do app

A WebView não abre os seus arquivos como caminhos `file://`. O próprio Capacitor responde aos pedidos
dela, num endereço que parece um servidor web: `https://localhost` no Android e
`capacitor://localhost` no iOS. Para o seu código, o app é um site servido da própria origem, então
`fetch("courses.json")` funciona, cookies e `localStorage` funcionam, e o planner roda sem uma linha
mudada. O custo é que **essa origem pertence ao celular**: nada na internet é `localhost` a partir de
lá, e uma chamada para a sua própria API precisa do endereço real dela.

## A ponte

Uma página web não alcança a interface nativa da câmera, os arquivos do aparelho nem o sistema de
notificações dele. A **ponte** do Capacitor é o caminho do seu JavaScript até código nativo que
alcança. Chamar um plugin pelo TypeScript parece chamar qualquer função assíncrona:

```typescript
import { Preferences } from "@capacitor/preferences";
await Preferences.set({ key: "plan", value: JSON.stringify(plan) });
```

Por baixo, a chamada vira uma mensagem, é entregue ao lado nativo, respondida por uma classe escrita em
Java ou Kotlin no Android e em Swift no iOS, e a resposta volta como o resultado da `Promise`. A aula 4
usa cinco desses plugins no planner, e a aula 5 escreve um.

**A mesma chamada tem uma terceira implementação, para a web.** A maioria dos plugins oficiais traz
uma, então o planner continua funcionando num navegador comum: lá o `Preferences` escreve no
`localStorage`. É isso que deixa este curso rodar a maior parte do comportamento de um plugin no
Chromium, e também o que esconde uma diferença até o app rodar num celular, que é o assunto da aula 6.

## O que o Capacitor não é

- **Ele não é o Cordova**, embora carregue a maioria dos plugins do Cordova. O Cordova regerava os
  projetos nativos a cada build, então uma mudança feita no Xcode se perdia; o Capacitor os gera uma
  vez e depois os trata como o seu código-fonte, no git, que é o assunto da aula 3.
- **Ele não é um framework.** Não importa para ele se a `dist/` veio de React, Angular, Vue, Svelte ou
  de cinco arquivos de TypeScript. Ele precisa de uma pasta com um `index.html` dentro.
- **Ele não é o Ionic**, embora a mesma empresa faça os dois. O Ionic é um conjunto de componentes
  com cara de celular para a web; a aula 10 olha para ele.
