---
title: O que vai ser desenhado
version: 1
---

Duas árvores existem agora: o documento e os estilos. Nenhuma pode ser desenhada sozinha — uma não
tem aparência e a outra não tem conteúdo — então o navegador constrói uma terceira juntando as duas.

Essa terceira é a **árvore de renderização**, e ela contém exatamente o que vai para a tela.

## O que fica de fora

A junção não é uma cópia. Várias coisas do documento não aparecem na árvore de renderização, e saber
quais é mais útil do que parece.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"O documento à esquerda e a árvore de renderização à direita. O head, um elemento com display none e um comentário estão ausentes da árvore de renderização, e uma caixa gerada por uma regra de estilo está presente nela sem existir no documento.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">no documento</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">head, title, meta, link</text> <rect x=\"20\" y=\"78\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">um elemento com display: none</text> <rect x=\"20\" y=\"120\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">o artigo e o texto dele</text> <rect x=\"20\" y=\"162\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect> <text x=\"180\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">nada para o ícone gerado</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">na árvore de renderização</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"540\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">ausente</text> <rect x=\"380\" y=\"78\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"4 3\"></rect> <text x=\"540\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">ausente, e sem ocupar espaço</text> <rect x=\"380\" y=\"120\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">presente, com uma caixa</text> <rect x=\"380\" y=\"162\" width=\"320\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">uma caixa sem elemento por trás</text> <text x=\"360\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">não é uma cópia filtrada: coisas saem e coisas entram</text> <text x=\"360\" y=\"256\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e é por isso que um ícone gerado está na tela e invisível para um script</text> </svg>", "caption": "A última linha é a que surpreende: uma caixa que é desenhada e à qual nenhum elemento corresponde."}
```

**Coisas sem aparência por natureza.** Tudo no head do documento — o título, as meta tags, os links
para folhas de estilo, os scripts. Elas importam enormemente e nenhuma é desenhada.

**Coisas que um estilo removeu.** Um elemento com `display: none` está no documento e ausente aqui.
Ele não ocupa espaço, porque para o layout ele não existe.

**Coisas que o navegador não exibe**, como um comentário deixado na marcação.

E uma adição, que é a razão de esta ser uma árvore própria em vez de um documento filtrado: **coisas
que o documento nunca teve.** Uma regra que gera conteúdo antes ou depois de um elemento põe uma
caixa na árvore de renderização sem elemento correspondente no documento — e é por isso que um ícone
gerado está visível na tela e ausente quando um script o procura.

## Os dois jeitos de esconder, que não são o mesmo

Esta é a distinção que a leitura sobre a árvore prometeu, e é a coisa mais útil na prática desta
seção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Três jeitos de tornar algo invisível comparados: display none o tira do layout por completo, visibility hidden mantém o espaço dele, e opacity zero mantém o espaço e ainda recebe cliques.\"> <rect x=\"20\" y=\"34\" width=\"216\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">display: none</text> <text x=\"128\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">fora da árvore de renderização</text> <text x=\"128\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">não ocupa espaço</text> <text x=\"128\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sem cliques, não anunciado</text> <text x=\"128\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mostrá-lo é um layout</text> <rect x=\"252\" y=\"34\" width=\"216\" height=\"130\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">visibility: hidden</text> <text x=\"360\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">na árvore de renderização</text> <text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o espaço dele é mantido</text> <text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">sem cliques, não anunciado</text> <text x=\"360\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mostrá-lo é uma repintura</text> <rect x=\"484\" y=\"34\" width=\"216\" height=\"130\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"592\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">opacity: 0</text> <text x=\"592\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">na árvore de renderização</text> <text x=\"592\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o espaço dele é mantido</text> <text x=\"592\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">ainda clicável, ainda lido</text> <text x=\"592\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mostrá-lo é uma composição</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">três jeitos de ficar invisível, três comportamentos diferentes</text> <text x=\"360\" y=\"240\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">e o da direita é como alguém tabula para coisas que não consegue ver</text> </svg>", "caption": "Quem conhece a árvore de renderização prevê os três em vez de decorá-los."}
```

`display: none` tira o elemento da árvore de renderização. Ele não ocupa espaço, nada flui ao redor
dele, e o layout é calculado como se ele não existisse. Mostrá-lo de novo é um layout.

`visibility: hidden` o mantém na árvore de renderização e desenha nada. O espaço segue ocupado, tudo
ao redor fica onde estava, e mostrá-lo de novo é uma repintura em vez de um layout.

`opacity: 0` é diferente ainda: totalmente desenhado, totalmente disposto, invisível, e — importante —
ainda recebendo cliques.

Três jeitos de tornar algo invisível, três comportamentos diferentes, e quem conhece a árvore de
renderização prevê os três em vez de decorá-los.

Há um quarto que fica ao lado deles e não é sobre aparência: o atributo `hidden` na marcação, que é o
mesmo que `display: none` por padrão e diz algo sobre o conteúdo em vez de sobre o estilo dele. Quando
uma coisa genuinamente não faz parte da página agora, esse é o jeito honesto de dizer.

## E o que pega quem usa leitor de tela

Vale um parágrafo, porque é um defeito real e invisível.

`display: none` e `visibility: hidden` tiram um elemento do que um leitor de tela anuncia, além de
tirá-lo da tela. `opacity: 0` não: o elemento continua lá, continua focável, continua sendo lido — que
é como um menu escondido vira uma armadilha em que alguém tabula para coisas que não consegue ver.

A regra que segue: **se não está disponível, tire da árvore de renderização.** Tornar algo invisível e
deixá-lo interativo é uma escolha, e deveria ser uma que você fez de propósito.

## Caixas, que é do que a árvore é feita

Uma nota de vocabulário, porque as palavras aparecem em toda ferramenta e em toda folha de estilo.

Cada entrada da árvore de renderização é uma **caixa**, e toda caixa tem quatro anéis: o conteúdo,
depois o preenchimento dentro da borda, depois a borda, depois a margem por fora. Esse é o modelo de
caixa, e a discussão que ele causa é sobre qual desses uma largura declarada inclui.

Pela regra original, `width` é o conteúdo sozinho, e preenchimento e borda são somados a ele — então
uma caixa declarada com 300 de largura e 20 de preenchimento ocupa 340. É a fonte de mais aritmética
que qualquer outra regra isolada desta área.

O hábito moderno é mudar isso uma vez, no topo de uma folha de estilo, para que uma largura declarada
signifique a largura visível incluindo preenchimento e borda. Essa linha única remove uma categoria
inteira de surpresas de layout, e vale saber o que ela faz em vez de copiá-la.

## Por que esta árvore é refeita mais vezes do que você imagina

A árvore de renderização não é construída uma vez. Qualquer mudança no documento ou num estilo que
afete o que é desenhado produz uma nova, ou uma parte remendada de uma.

Uma classe acrescentada por um script. Um elemento inserido. Uma folha de estilo aplicada tarde. Uma
janela redimensionada.

Na maior parte do tempo isso é barato e invisível. A razão para saber que acontece é a próxima
leitura: o que vem depois de uma mudança na árvore de renderização é layout e pintura, e é ali que
está o custo. Uma página que refaz essa estrutura sessenta vezes por segundo é uma página fazendo
sessenta layouts por segundo, e esse é um número que dá para ver numa ferramenta.
