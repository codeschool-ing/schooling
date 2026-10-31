---
title: Um arquivo por plataforma
version: 1
---

**Quando o Metro resolve um import, ele procura primeiro um arquivo cujo nome traz a plataforma para a qual
está empacotando.** `import { savedWhere } from "./savedWhere"` encontra o `savedWhere.ios.ts` num bundle de
iOS, o `savedWhere.android.ts` num de Android, e o `savedWhere.ts`, o arquivo sem plataforma no nome, em
qualquer outro, a web inclusive. O import não muda. O arquivo a que ele chega, sim.

## Três arquivos pequenos

O planner vai dizer, no pé da tela, onde o plano fica guardado: no celular, ou no navegador. Cada frase é um
arquivo. Salve estes três, com os nomes que estão nas primeiras linhas:

```typescript
// src/savedWhere.ios.ts: Metro picks this file when it bundles for iOS.
export const savedWhere = "Saved on this iPhone";
```

```typescript
// src/savedWhere.android.ts: Metro picks this file when it bundles for Android.
export const savedWhere = "Saved on this Android device";
```

```typescript
// src/savedWhere.ts: every other platform, which here means the web.
export const savedWhere = "Saved in this browser";
```

**Eles precisam exportar os mesmos nomes, com os mesmos tipos.** O TypeScript confere o import contra o
`savedWhere.ts`, o que não tem plataforma, e não sabe nada dos outros dois; um `.ios.ts` que esqueceu um
export compila aqui e falha no bundle de iOS. Manter os arquivos minúsculos, como aqui, e testar cada
plataforma, como faz a última seção desta aula, é a defesa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l06-resolve\" aria-label=\"Um import, ./savedWhere, resolvido pelo Metro uma vez por plataforma. O bundle de iOS recebe o savedWhere.ios.ts, o de Android o savedWhere.android.ts, e o bundle web o savedWhere.ts simples. Cada bundle carrega só o próprio arquivo.\"><defs><marker id=\"l06-resolve-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-resolve-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o import, sem mudança</text><rect x=\"20\" y=\"80\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">from \"./savedWhere\"</text><text x=\"290\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">o Metro, na hora do bundle</text><path d=\"M220 102 L350 48\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-amber)\"></path><rect x=\"350\" y=\"30\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">savedWhere.ios.ts</text><path d=\"M540 48 L580 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-paper-dim)\"></path><rect x=\"580\" y=\"30\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bundle de iOS</text><path d=\"M220 102 L350 104\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-amber)\"></path><rect x=\"350\" y=\"86\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">savedWhere.android.ts</text><path d=\"M540 104 L580 104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-paper-dim)\"></path><rect x=\"580\" y=\"86\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bundle de Android</text><path d=\"M220 102 L350 160\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-amber)\"></path><rect x=\"350\" y=\"142\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">savedWhere.ts</text><path d=\"M540 160 L580 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-resolve-ah-paper-dim)\"></path><rect x=\"580\" y=\"142\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bundle web</text></svg>", "caption": "A escolha é feita quando o bundle é construído: a frase do iPhone nem está no app Android."}
```

## Provado nos bundles

Exporte o app para duas plataformas e procure cada frase em cada bundle. As strings sobrevivem no bytecode,
como a aula 1 mostrou:

```
ana@dev:~/planner$ npx expo export --platform android --output-dir out-android > /dev/null 2>&1
ana@dev:~/planner$ npx expo export --platform web --output-dir out-web > /dev/null 2>&1
ana@dev:~/planner$ grep -c "this Android device" out-android/_expo/static/js/android/*.hbc
1
ana@dev:~/planner$ grep -c "this iPhone" out-android/_expo/static/js/android/*.hbc
0
ana@dev:~/planner$ grep -c "in this browser" out-web/_expo/static/js/web/*.js
1
ana@dev:~/planner$ rm -r out-android out-web
```

**O bundle de Android traz a frase do Android e não a do iPhone, e o bundle web traz a dele.** A escolha foi
feita pelo Metro, quando o bundle foi construído, não por um desvio em tempo de execução; a frase do iOS nem
está no app Android. O bundle web é JavaScript em vez de bytecode, e traz o terceiro arquivo.

## Quando usar qual

| a diferença é | use |
|---|---|
| um valor: um tamanho, uma cor, uma palavra | `Platform.select` |
| um componente inteiro, com código diferente dentro | `.ios.tsx` e `.android.tsx` |
| algo que só uma plataforma tem | um `.ios.tsx` que o faz e um `.tsx` simples que não renderiza nada |
| uma API nativa | uma biblioteca que já fez isso, ou a aula 17 |

O `.native.ts` é um quarto sufixo, que casa com os dois celulares e não com a web, para o caso em que o
navegador é o diferente.
