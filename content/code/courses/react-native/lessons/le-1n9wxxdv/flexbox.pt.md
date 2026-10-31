---
title: Flexbox, com dois padrões invertidos
version: 1
---

**Toda `View` é um contêiner flex, e o Flexbox é o único layout que existe.** Nada de floats, nada de grid,
nada de `display: block`. As propriedades são as da web, `flexDirection`, `justifyContent`, `alignItems`,
`flex`, `gap`, e quem as calcula é o Yoga, como a aula 1 descreveu. Dois padrões diferem dos da web, e os dois
explicam telas que saem erradas na primeira tentativa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l05-axes\" aria-label=\"Dois contêineres flex. À esquerda, o padrão: flexDirection column, então o eixo principal vai de cima para baixo, o justifyContent move os filhos ao longo dele e o alignItems através dele, e os filhos se esticam na largura por padrão. À direita, flexDirection row, como o cabeçalho do planner usa: o eixo principal vai da esquerda para a direita, e alignItems center centraliza o ícone e o título na vertical.\"><defs><marker id=\"l05-axes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l05-axes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"160\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">flexDirection: column (padrão)</text><rect x=\"60\" y=\"34\" width=\"200\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"76\" y=\"50\" width=\"168\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">filho A</text><rect x=\"76\" y=\"104\" width=\"168\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">filho B</text><rect x=\"76\" y=\"158\" width=\"168\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">filho C</text><path d=\"M40 40 L40 220\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-axes-ah-amber)\"></path><text x=\"30\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">eixo principal · justifyContent</text><path d=\"M60 236 L260 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-axes-ah-paper-dim)\"></path><text x=\"160\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">eixo cruzado · alignItems</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">flexDirection: row</text><rect x=\"400\" y=\"80\" width=\"290\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"416\" y=\"100\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"436.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">ícone</text><rect x=\"468\" y=\"106\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"543.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Study planner</text><path d=\"M400 180 L690 180\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-axes-ah-amber)\"></path><text x=\"545\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">eixo principal · justifyContent</text><path d=\"M706 80 L706 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-axes-ah-paper-dim)\"></path><text x=\"690\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">eixo cruzado · alignItems</text></svg>", "caption": "As mesmas duas propriedades, giradas em ângulo reto: numa coluna, o justifyContent trabalha na vertical; numa linha, na horizontal.", "same": ["Study planner"]}
```

## Uma coluna, não uma linha

**O `flexDirection` é `column` por padrão.** Os filhos se empilham de cima para baixo, que é o que uma tela de
celular faz quase sempre. Então o **eixo principal** é vertical: o `justifyContent` posiciona os filhos para
cima e para baixo, e o `alignItems` os posiciona de lado a lado. A linha do título do planner inverte isso de
propósito, com `flexDirection: "row"`, para pôr o ícone ao lado do título; ali, `alignItems: "center"` os
centraliza na vertical.

## `flex` é um número só, e quer dizer crescer

Na web, `flex: 1` é atalho para três valores. **No React Native, `flex` recebe um único número**: um positivo
quer dizer *dividir o espaço livre ao longo do eixo principal na proporção deste número*. Dois irmãos com
`flex: 1` e `flex: 2` ficam com um terço e dois terços. Um filho sem `flex` fica com o tamanho do conteúdo.

É tudo de que uma barra de progresso precisa. A barra da semana do planner é uma linha cujos dois filhos têm
`flex` igual aos minutos feitos e aos minutos que faltam. Salve-a como `src/WeekBar.tsx`:

```tsx
// src/WeekBar.tsx: the week's minutes as a bar, done against planned, laid out by flex alone.
import { StyleSheet, View } from "react-native";
import { useTheme } from "./theme";

type Props = { done: number; planned: number };

export function WeekBar({ done, planned }: Props) {
  const t = useTheme();
  return (
    <View
      testID="week-bar"
      accessible
      role="progressbar"
      aria-label="Minutes done this week"
      aria-valuemin={0}
      aria-valuemax={planned}
      aria-valuenow={done}
      style={[styles.track, { backgroundColor: t.track }]}
    >
      <View testID="week-done" style={{ flex: done, backgroundColor: t.accent }} />
      <View testID="week-left" style={{ flex: planned - done }} />
    </View>
  );
}

const styles = StyleSheet.create({
  track: { flexDirection: "row", height: 12, borderRadius: 6, overflow: "hidden" },
});
```

O `overflow: "hidden"` corta a parte colorida no trilho arredondado. As props `aria-` dizem a um leitor de
tela que aquilo é uma barra de progresso e o quanto ela avançou, e o `accessible` faz das três views um
elemento só para ele. Nenhuma largura é calculada em lugar nenhum: **a barra tem 75 partes feitas e 50 que
faltam, e o Yoga divide a largura que houver nessa proporção.**

## Medindo

Um teste consegue dizer qual `flex` foi definido; só um motor de layout consegue dizer o que ele produziu.
Este programa abre o build web no tamanho de um celular, 390 por 844, e imprime onde cada elemento com um
`testID` foi parar, com a cor de fundo. Salve-o como `boxes.mjs`, ao lado do `look.mjs`:

```javascript
// boxes.mjs: open a page at a phone's size and print where every element
// with a testID was laid out, and its background colour.
//
//   node boxes.mjs URL [WIDTH HEIGHT] [--dark]
import { chromium } from "playwright";

const args = process.argv.slice(2);
const dark = args.includes("--dark");
const [url, width = "390", height = "844"] = args.filter((a) => a !== "--dark");
const browser = await chromium.launch();
const page = await browser.newPage({
  viewport: { width: Number(width), height: Number(height) },
  colorScheme: dark ? "dark" : "light",
});
await page.goto(url);
await page.waitForLoadState("networkidle");
for (const el of await page.locator("[data-testid]").all()) {
  const id = await el.getAttribute("data-testid");
  const b = await el.boundingBox();
  const bg = await el.evaluate((e) => getComputedStyle(e).backgroundColor);
  const box = [b.x, b.y, b.width, b.height].map((n) => Math.round(n));
  console.log(`${id.padEnd(12)} x=${box[0]} y=${box[1]} w=${box[2]} h=${box[3]}  ${bg}`);
}
await browser.close();
```

Com a barra da semana na tela, como a última seção desta aula a põe:

```
ana@dev:~/planner$ node boxes.mjs 'http://localhost:8082/?today=2026-10-21'
header       x=24 y=64 w=342 h=40  rgba(0, 0, 0, 0)
week-bar     x=24 y=147 w=342 h=12  rgb(230, 235, 240)
week-done    x=24 y=147 w=205 h=12  rgb(47, 111, 78)
week-left    x=229 y=147 w=137 h=12  rgba(0, 0, 0, 0)
row-spanish  x=24 y=175 w=342 h=62  rgba(0, 0, 0, 0)
row-statistics x=24 y=237 w=342 h=62  rgba(0, 0, 0, 0)
row-guitar   x=24 y=299 w=342 h=62  rgba(0, 0, 0, 0)
```

A barra tem 342 de largura, os 390 da janela menos 24 de padding de cada lado. A parte feita tem 205 e a que
falta 137, que é 75 para 50 arredondado ao ponto. O `alignItems` vale `stretch` por padrão, o outro padrão que
vale conhecer, e é por isso que o cabeçalho e as linhas também têm 342 de largura sem ninguém pedir.
