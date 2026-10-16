---
title: Referências absolutas, para a célula de que toda linha precisa
version: 1
---

**Alguns endereços precisam ficar onde estão enquanto a fórmula anda.** A participação no total é o
caso mais simples: toda venda é dividida pelo mesmo total, então a referência ao total precisa
apontar para uma célula só, a partir de qualquer linha. O cifrão é o jeito de dizer isso. `$L$2` é
uma **referência absoluta**, e quer dizer "a célula L2" para onde quer que a fórmula seja copiada.

## A participação de cada venda

Ponha o total numa célula só dele, fora dos dados, com um rótulo ao lado para que a próxima pessoa
saiba o que é. Em `Sales`, digite `Total` em **L1**, e em **L2**:

```localised
=SOMA(H2:H109)
```

Depois digite `Share` em **J1**, e em **J2** a fórmula óbvia:

```localised
=H2/L2
```

J2 mostra um decimal um pouco abaixo de 0,03. Selecione a coluna J, clique em **Estilo de
Porcentagem** (o botão **%** da guia **Página Inicial**) e depois uma vez em **Aumentar Casas
Decimais**, e J2 passa a mostrar **2,8%**: a venda S1001 é 2,8% da receita de dezoito meses. Agora
clique duas vezes na alça de preenchimento de J2.

Toda célula de J3 para baixo mostra `#DIV/0!`. Clique em J3 e a barra de fórmulas explica: `=H3/L3`.
A referência ao total desceu uma linha, como toda referência relativa desce, e L3 está vazia, então
J3 divide por zero. J2 só estava certa porque é a única célula em que L2 é o total.

O conserto são dois cifrões. Em J2:

```localised
=H2/$L$2
```

e preencha para baixo de novo. J3 agora tem `=H3/$L$2` e mostra **3,8%**, J109 mostra **0,4%**, e a
conferência que uma coluna de participações merece dá certo:

```localised
=SOMA(J2:J109)
```

responde **1**, que é 100%. A maior participação da coluna é 4,1%, os 20 sacos de `CER1K` que o
`C03` comprou na venda S1083.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l02-anchor\" aria-label=\"Duas cópias da coluna de participação. À esquerda, =H2/L2 preenchida para baixo: J3 tem =H3/L3 e J4 tem =H4/L4, cada seta apontando para a própria linha da coluna L, onde só L2 tem o total, então J3 e J4 mostram #DIV/0!. À direita, =H2/$L$2 preenchida para baixo: toda seta aponta para L2, e as células mostram 2,8%, 3,8% e 0,2%.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">=H2/L2, preenchida</text><text x=\"98.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">J</text><text x=\"36.0\" y=\"74.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"44.0\" y=\"60.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"74.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Share</text><text x=\"36.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"44.0\" y=\"88.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"102.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">=H2/L2</text><text x=\"36.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"44.0\" y=\"116.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"130.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">=H3/L3</text><text x=\"36.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"44.0\" y=\"144.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"158.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">=H4/L4</text><text x=\"245.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">L</text><rect x=\"212.0\" y=\"60.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"272.0\" y=\"74.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Total</text><rect x=\"212.0\" y=\"88.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"272.0\" y=\"102.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">51494</text><rect x=\"212.0\" y=\"116.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"212.0\" y=\"144.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M156.0 102.0 L208.0 102.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M208.0 102.0 L200.0 98.0 L200.0 106.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M156.0 130.0 L208.0 130.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M208.0 130.0 L200.0 126.0 L200.0 134.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><path d=\"M156.0 158.0 L208.0 158.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M208.0 158.0 L200.0 154.0 L200.0 162.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"44.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">J2  2,8%</text><text x=\"44.0\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">J3  #DIV/0!</text><text x=\"44.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">J4  #DIV/0!</text><text x=\"380.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">=H2/$L$2, preenchida</text><text x=\"458.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">J</text><text x=\"396.0\" y=\"74.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"404.0\" y=\"60.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"410.0\" y=\"74.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Share</text><text x=\"396.0\" y=\"102.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"404.0\" y=\"88.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"410.0\" y=\"102.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">=H2/$L$2</text><text x=\"396.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"404.0\" y=\"116.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"410.0\" y=\"130.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">=H3/$L$2</text><text x=\"396.0\" y=\"158.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><rect x=\"404.0\" y=\"144.0\" width=\"108.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"410.0\" y=\"158.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">=H4/$L$2</text><text x=\"605.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">L</text><rect x=\"572.0\" y=\"60.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"632.0\" y=\"74.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Total</text><rect x=\"572.0\" y=\"88.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"632.0\" y=\"102.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">51494</text><rect x=\"572.0\" y=\"116.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"572.0\" y=\"144.0\" width=\"66.0\" height=\"28.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M516.0 102.0 L568.0 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M568.0 102.0 L560.0 98.0 L560.0 106.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><path d=\"M516.0 130.0 L568.0 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M568.0 102.0 L559.1 102.3 L562.9 109.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><path d=\"M516.0 158.0 L568.0 102.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M568.0 102.0 L559.6 105.1 L565.5 110.6 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"404.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">J2  2,8%</text><text x=\"404.0\" y=\"211.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">J3  3,8%</text><text x=\"404.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">J4  0,2%</text></svg>", "caption": "Uma referência relativa ao total anda com cada linha e encontra uma célula vazia. Com cifrões, toda linha aponta para a única célula que o guarda."}
```

## O mesmo erro, sem mensagem de erro

`#DIV/0!` é a falha gentil. Esta é a cruel. Suponha que J2 tivesse sido escrita com o total dentro
dela:

```localised
=H2/SOMA(H2:H109)
```

J2 está certa, 2,8%. Preencha para baixo e **as duas pontas do intervalo andam**: J3 fica com
`=H3/SOMA(H3:H110)`, que deixa de fora a venda S1001, e J109 fica com `=H109/SOMA(H109:H216)`, que
é uma venda dividida por ela mesma. Nenhuma célula mostra erro. J3 diz 3,9% onde a verdade é 3,8%,
J109 diz 100%, e a coluna soma 579%. A única coisa que denuncia é uma conferência como a de cima, e é
por isso que vale escrever uma toda vez que uma fórmula é preenchida.

## Quatro jeitos de escrever um endereço

O cifrão fixa o que vem logo depois dele, a letra da coluna ou o número da linha, então um endereço
tem quatro formas:

| escrito | quando a fórmula é copiada para baixo | quando é copiada para o lado |
|---|---|---|
| `L2` | a linha anda | a coluna anda |
| `$L$2` | continua L2 | continua L2 |
| `L$2` | continua na linha 2 | a coluna anda |
| `$L2` | a linha anda | continua na coluna L |

Você não precisa digitar os cifrões. Clique dentro de um endereço na barra de fórmulas e tecle **F4**
(no Mac, **Cmd+T**): cada toque passa para a forma seguinte, na ordem `$L$2`, `L$2`, `$L2`, `L2`. As
duas formas do meio, com um cifrão cada, são o assunto da próxima seção.
