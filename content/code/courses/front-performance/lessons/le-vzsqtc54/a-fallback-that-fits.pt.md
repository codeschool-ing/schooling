---
title: Uma fonte reserva que ocupa o mesmo espaço
version: 1
---

**Um swap mexe o texto porque a fonte reserva e a fonte têm tamanhos diferentes.** A mesma frase em duas
tipografias tem duas larguras, e onde uma linha quebra depende da largura. Se a reserva tivesse a mesma
largura da fonte, o swap trocaria as letras e não mexeria nada.

O `tools/fallback.ts` mede isso. Ele abre uma página, compõe a frase do aviso em IBM Plex Sans e numa fonte
que este computador tem, e diz quanto a segunda teria de ser escalada para igualar a primeira. Salve-o em
`tools/`:

```typescript
// tools/fallback.ts: how wide the notice's sentence is in IBM Plex Sans, in a font
// this computer has, and in the page's adjusted fallback if it defines one: the
// number that makes a fallback take the room the web font will take.
//
//   node tools/fallback.ts URL "FONT"
import { chromium } from "playwright";

const [url, local] = process.argv.slice(2);
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto(url, { waitUntil: "networkidle" });
const widths = await page.evaluate(async (local) => {
  const text = document.getElementById("notice")!.textContent!;
  const measure = (family: string) => {
    const span = Object.assign(document.createElement("span"), { textContent: text });
    span.style.cssText = `font: 16px ${family}; white-space: nowrap`;
    document.body.append(span);
    const width = span.getBoundingClientRect().width;
    span.remove();
    return width;
  };
  await document.fonts.load('16px "Plex fallback"');
  const adjusted = [...document.fonts].some((f) => f.family === '"Plex fallback"' || f.family === "Plex fallback");
  return { plex: measure('"IBM Plex Sans"'), local: measure(`"${local}"`), adjusted: adjusted ? measure('"Plex fallback"') : null };
}, local);
await browser.close();
console.log(`IBM Plex Sans    ${widths.plex.toFixed(1)} px`);
console.log(`${local.padEnd(16)} ${widths.local.toFixed(1)} px: size-adjust ${(100 * widths.plex / widths.local).toFixed(1)}% would match`);
if (widths.adjusted !== null) console.log(`Plex fallback    ${widths.adjusted.toFixed(1)} px`);
```

Meça as duas fontes para as quais os visitantes do planner provavelmente caem. A DejaVu Sans é o que muitos
sistemas Linux dão ao `sans-serif`; a Arial está em todo computador Windows e macOS, e no Linux o nome Arial
costuma levar à Liberation Sans, que foi desenhada com as larguras da Arial:

```
ana@dev:~/planner$ node tools/fallback.ts http://localhost:3000/ "DejaVu Sans"
IBM Plex Sans    467.8 px
DejaVu Sans      529.8 px: size-adjust 88.3% would match
ana@dev:~/planner$ node tools/fallback.ts http://localhost:3000/ "Arial"
IBM Plex Sans    467.8 px
Arial            470.5 px: size-adjust 99.4% would match
```

**A DejaVu Sans é cerca de um oitavo mais larga que a Plex**, o bastante para mexer numa quebra de linha
na maioria dos parágrafos. **A Arial fica a menos de um por cento.** Então a primeira correção é nomeá-la:
uma lista de fontes que diz Arial ganha um encaixe quase exato na maioria dos computadores, onde o
`sans-serif` sozinho ganha o que o sistema preferir.

## size-adjust

O último por cento é um descritor. **Uma regra `@font-face` pode dar a uma fonte local um nome novo e uma
correção**: o `size-adjust` escala cada glifo, e o `ascent-override`, o `descent-override` e o
`line-gap-override` corrigem a altura da linha, o que importa quando as duas fontes se assentam de modo
diferente na linha. Acrescente esta regra no fim do `src/style.css`, com o número que a ferramenta
imprimiu:

```css
@font-face { font-family: "Plex fallback"; src: local("Arial"), local("Liberation Sans"); size-adjust: 99.4%; }
```

e ponha-a na lista do body, entre a fonte e a família genérica, trocando a primeira linha:

```css
body { font: 16px/1.5 "IBM Plex Sans", "Plex fallback", sans-serif; margin: 0 auto; max-width: 40rem; padding: 1rem; }
```

O `system-ui` saiu da lista: é a fonte da interface do próprio sistema operacional, de um formato diferente
em cada sistema, o contrário de uma reserva escolhida para combinar. Faça o build, reinicie e meça de novo:

```
ana@dev:~/planner$ node tools/fallback.ts http://localhost:3000/ "Arial"
IBM Plex Sans    467.8 px
Arial            470.5 px: size-adjust 99.4% would match
Plex fallback    467.3 px
```

**A reserva ajustada tem a largura da fonte com diferença de uma fração de pixel.** Um visitante cuja fonte
atrasa vê a Arial, escalada, exatamente no espaço que a Plex vai ocupar, e o swap não mexe nada.

## O número é por fonte

O `size-adjust` é uma razão entre duas fontes específicas, então está certo para a reserva em que foi
medido e errado para qualquer outra. É por isso que a regra nomeia `local("Arial")` e não `sans-serif`, e
por que os frameworks que fazem isso por você, na seção "O que os frameworks fazem", também escolhem Arial
ou Times New Roman: são as fontes que quase todo visitante tem. A razão também depende do texto; uma
ferramenta que a calcula a partir dos arquivos da fonte, em vez de uma frase, faz a média sobre o alfabeto.
