---
title: Como o React Native desenha uma tela
version: 1
---

**O React Native roda o seu JavaScript, e pede à plataforma que desenhe controles nativos de verdade
para o que ele descreve.** Não há motor de navegador, nem HTML, nem CSS no app. Um `<Text>` no seu código
vira uma `TextView` no Android e um `UILabel` no iOS; um `<Pressable>` vira uma view nativa que recebe
toques. A tela que a pessoa vê é a que qualquer app Kotlin ou Swift mostraria.

A imagem comum é que o React Native "compila JavaScript em código nativo". Ele não compila. **O seu
JavaScript continua rodando, dentro do app, num motor JavaScript**, e o que atravessa para o lado nativo é
uma descrição da tela, não o seu programa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l07-layers\" aria-label=\"As camadas de um app React Native num celular. Os seus componentes e o planner.ts são JavaScript, rodado pelo motor Hermes. O React calcula o que a tela deve ser. O renderizador, o Fabric, com o motor de layout Yoga, cria e posiciona views nativas. Essas são os controles da própria plataforma: uma TextView ou um UILabel para Text, uma view nativa para Pressable. A JSI liga o JavaScript ao lado nativo. Não há WebView em lugar nenhum.\"><defs><marker id=\"l07-layers-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--phosphor)\">JavaScript, no Hermes</text><rect x=\"40\" y=\"52\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"68.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os seus componentes,</text><text x=\"170.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">e o src/planner.ts</text><rect x=\"40\" y=\"120\" width=\"260\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"136.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">React: o que a</text><text x=\"170.0\" y=\"149.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tela deve ser</text><path d=\"M170 98 L170 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-layers-ah-paper-dim)\"></path><rect x=\"360\" y=\"82\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"100.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Fabric e Yoga:</text><text x=\"430.0\" y=\"113.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">views e layout</text><path d=\"M300 143 L360 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-layers-ah-paper-dim)\"></path><text x=\"330\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">JSI</text><text x=\"610\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">as views da própria plataforma</text><rect x=\"530\" y=\"52\" width=\"160\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"68.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;Text&gt; → TextView,</text><text x=\"610.0\" y=\"81.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UILabel</text><rect x=\"530\" y=\"120\" width=\"160\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"136.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;Pressable&gt; → uma</text><text x=\"610.0\" y=\"149.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">view nativa de toque</text><path d=\"M500 100 L530 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-layers-ah-paper-dim)\"></path><path d=\"M500 115 L530 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-layers-ah-paper-dim)\"></path><text x=\"360\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">sem WebView, sem HTML, sem CSS</text></svg>", "caption": "O seu código continua rodando como JavaScript. O que chega à tela é uma descrição, transformada nas views que um app Kotlin ou Swift teria.", "same": ["JSI"]}
```

## As partes

- **Hermes** é o motor JavaScript que vem com o React Native, feito para celulares: ele compila o seu
  JavaScript em bytecode quando o app é construído, para o celular não precisar interpretá-lo a cada
  abertura.
- **React** decide o que a tela deve ser, a partir dos seus componentes e do estado deles, e calcula o
  que mudou desde a última vez. Essa metade é o mesmo React que roda num navegador.
- **O renderizador**, chamado Fabric na arquitetura atual, pega a resposta do React e cria, atualiza e
  posiciona as views nativas. O **Yoga**, um motor de layout escrito em C++, calcula onde cada view fica, a
  partir de regras de flexbox, igual nas duas plataformas.
- **A JSI**, JavaScript Interface, é como o JavaScript chama código nativo diretamente, sem transformar
  cada chamada numa mensagem. Ela substituiu a "ponte" assíncrona das primeiras versões do React Native,
  que é a palavra que você ainda vai encontrar em artigos antigos.

## O que isso quer dizer para o planner

**As regras em `src/planner.ts` rodam como estão**: são JavaScript sem DOM, e o Hermes roda JavaScript.
**As views em `src/view.ts` não vêm junto**: não há `document`, nem `createElement`, nem `<button>`. As
telas são escritas de novo com os componentes do React Native, que é o preço que o caminho nativo pede, e
a aula 6 disse que ele só vale a pena quando o app precisa do que as views nativas dão.
