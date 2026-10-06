---
title: box-sizing: o que width quer dizer
version: 1
---

A seção 02 mediu um cartão com `width: 300px` desenhado com 348 pixels de largura. Esse é o padrão, e se chama **`content-box`**: `width` define a área de conteúdo, e padding e borda são somados por fora. Isso transforma todo layout em conta: uma coluna que devia ter um terço da página, com padding, fica maior que um terço, e três delas deixam de caber numa linha.

**`box-sizing: border-box`** muda o que `width` quer dizer. Aqui está o mesmo cartão com essa única declaração a mais:

```
ana@laptop:~/site$ probe border-box.html box .card box '.card p'
article.card  x 30     y 30     width 300    height 84
p  x 54     y 54     width 252    height 36
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 206\" role=\"img\" aria-label=\"O mesmo cartão duas vezes, os dois com width 300px, padding 20 e borda de 4 pixels. Com box-sizing content-box, o padrão, o conteúdo tem 300 de largura e o cartão é desenhado com 348. Com border-box, o cartão é desenhado com 300 e o conteúdo fica com os 252 que sobram.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">content-box</text><rect x=\"20\" y=\"34\" width=\"313.2\" height=\"76\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"4\"></rect><rect x=\"41.6\" y=\"54\" width=\"270\" height=\"36\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"176.6\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conteúdo 300</text><line x1=\"20\" y1=\"124\" x2=\"333.2\" y2=\"124\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"20\" y1=\"119\" x2=\"20\" y2=\"129\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"333.2\" y1=\"119\" x2=\"333.2\" y2=\"129\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"176.6\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desenhada com 348</text><text x=\"380\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">border-box</text><rect x=\"380\" y=\"34\" width=\"270\" height=\"76\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"4\"></rect><rect x=\"401.6\" y=\"54\" width=\"226.8\" height=\"36\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"515\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conteúdo 252</text><line x1=\"380\" y1=\"124\" x2=\"650\" y2=\"124\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"380\" y1=\"119\" x2=\"380\" y2=\"129\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"650\" y1=\"119\" x2=\"650\" y2=\"129\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"515\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desenhada com 300</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">As duas dizem width: 300px. content-box soma padding e borda por fora;</text><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">border-box os encaixa por dentro, e o conteúdo fica com o que sobra.</text></svg>", "caption": "border-box faz width querer dizer a largura que você vê."}
```

Agora o cartão tem **300 de largura**, como está escrito, e o padding e a borda são encaixados por dentro: a área de conteúdo fica com o que sobra, **252**. A altura não mudou, 84, porque a altura nunca foi definida; ela vem do conteúdo, e padding e borda continuam sendo somados em volta.

## A regra com que quase toda folha de estilos começa

Como `border-box` é tão mais fácil de raciocinar, quase toda folha de estilos moderna o liga para tudo, logo no topo:

```css
*, *::before, *::after {
  box-sizing: border-box;
}
```

O seletor é o seletor universal e os dois pseudo-elementos da aula 5, que o seletor universal sozinho não alcança. A partir daí, um `width` é a largura que você vai ver, e uma coluna de um terço com padding tem um terço.

O padrão é `content-box` por motivo histórico, não por ser útil: o CSS foi especificado assim em 1996, um navegador da época fazia o contrário, e quando veio o modo padrão o padrão venceu. `box-sizing` foi acrescentado depois para os autores poderem escolher.
