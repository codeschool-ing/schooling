---
title: Quatro formatos de que todo app é feito
version: 1
---

**As telas de um app se organizam em poucos formatos fixos, e todo app que você já usou é alguma
combinação deles: uma pilha, abas, uma gaveta e uma folha por cima.** A imagem que a maioria das
pessoas traz da web é uma linha única de histórico, em que *voltar* desfaz o último clique. Um app de
celular tem mais estrutura que isso. Algumas telas ficam em cima de outras, algumas ficam lado a lado,
e algumas só existem por um momento, e *voltar* significa uma coisa diferente em cada caso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l10-shapes\" aria-label=\"Quatro formatos de navegação, cada um desenhado como uma tela de celular. Uma pilha: três telas empilhadas, courses na raiz, um curso por cima e um formulário de nova sessão no topo; só a de cima aparece, abrir empilha e voltar desempilha. Abas: duas pilhas lado a lado, Courses e Week, com uma barra embaixo para trocar entre elas; cada uma guarda a própria pilha. Uma gaveta: um painel de destinos que desliza da esquerda por cima da tela. Uma folha: um painel que sobe de baixo por cima da tela atual, para uma tarefa, com a tela de baixo intacta.\"><defs><marker id=\"l10-shapes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"90\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">pilha</text><rect x=\"20\" y=\"32\" width=\"140\" height=\"230\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">abas</text><rect x=\"200\" y=\"32\" width=\"140\" height=\"230\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">gaveta</text><rect x=\"380\" y=\"32\" width=\"140\" height=\"230\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">folha</text><rect x=\"560\" y=\"32\" width=\"140\" height=\"230\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"34\" y=\"150\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"86.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">courses</text><rect x=\"42\" y=\"116\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"94.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">course:sql</text><rect x=\"50\" y=\"82\" width=\"104\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"102.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">new-session</text><text x=\"86\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">(raiz)</text><text x=\"90\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">empilha · voltar desempilha</text><rect x=\"210\" y=\"120\" width=\"60\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"7.5\" fill=\"var(--paper)\">courses</text><rect x=\"210\" y=\"90\" width=\"60\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"7.5\" fill=\"var(--paper)\">course:sql</text><rect x=\"276\" y=\"120\" width=\"54\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"303.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"7.5\" fill=\"var(--paper)\">week</text><text x=\"270\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cada aba guarda</text><text x=\"270\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a própria pilha</text><rect x=\"206\" y=\"222\" width=\"128\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"238\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">Courses</text><text x=\"302\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Week</text><text x=\"270\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">barra de abas</text><rect x=\"382\" y=\"34\" width=\"92\" height=\"226\" rx=\"10\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"392\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">destino 1</text><text x=\"392\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">destino 2</text><text x=\"392\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">destino 3</text><text x=\"428\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">desliza por</text><text x=\"428\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">cima da tela</text><path d=\"M440 200 L466 200\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-ah-phosphor)\"></path><text x=\"630\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a tela por baixo</text><rect x=\"564\" y=\"120\" width=\"132\" height=\"140\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma tarefa curta</text><text x=\"630\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">fechar não muda</text><text x=\"630\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">nada embaixo</text><path d=\"M630 116 L630 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-shapes-ah-phosphor)\"></path></svg>", "caption": "Quatro formatos, e o que voltar significa em cada um: a pilha desempilha a tela do topo, as abas desempilham dentro da aba que aparece, e uma gaveta ou uma folha se fecha.", "same": ["Courses", "Week"]}
```

## A pilha

**Uma pilha é um monte de telas em que só a de cima aparece.** Abrir uma tela a *empilha* por cima;
voltar a *desempilha* e mostra a de baixo, do jeito que foi deixada. A lista Courses do planner é o
fundo de uma pilha; tocar num curso empilha a tela de detalhe dele, e tocar em "nova sessão" ali
empilha um formulário por cima. São três telas na pilha, e a aluna vê uma.

O nome da tela do fundo é **raiz**, ou *start destination* na biblioteca de navegação do Android. É a
tela que a pilha nunca desempilha, porque não haveria nada embaixo para mostrar. Quais telas estão na
pilha faz parte do estado de um app, o tipo de estado que a aula 5 guarda para o momento em que o
sistema leva o processo embora.

## Abas

**Abas são algumas pilhas lado a lado, com uma barra para trocar entre elas.** O planner tem duas,
Courses e Week. O erro comum é pensar numa aba como uma tela. Ela é uma pilha inteira, e trocar de aba
a deixa exatamente onde estava: a aluna que estava três telas para dentro de Courses, toca em Week e
toca em Courses de novo, encontra o formulário que estava preenchendo. As Human Interface Guidelines
da Apple descrevem as barras de abas como um jeito de trocar de seção "preservando o estado de
navegação atual dentro de cada seção", e a biblioteca de navegação do Android chama a mesma coisa de
*multiple back stacks*, várias pilhas de volta.

**Tocar na aba que já está aparecendo também significa alguma coisa.** Por convenção, isso leva aquela
aba de volta à raiz, e assim quem se perdeu lá no fundo de uma aba tem um toque para voltar ao começo. A
documentação da Apple sobre o controlador de barra de abas diz que um toque numa aba mostra a view raiz
dela "mesmo que a aba já estivesse selecionada". As abas inferiores do React Navigation fazem o mesmo por
padrão, desempilhando uma pilha aninhada até a primeira tela num segundo toque. Abas servem para um punhado de
seções principais que a pessoa usa sempre, e num celular as duas empresas põem a barra que troca entre
elas embaixo, ao alcance do polegar: a tab bar da Apple e a navigation bar do Material.

## A gaveta

**Uma gaveta é um painel de destinos que desliza pela lateral, por cima do conteúdo.** O Material
Design tem uma, a navigation drawer, aberta por um botão de menu ou por um deslize a partir da borda.
Ela comporta mais destinos que uma barra de abas, e os esconde, que é o custo dela: uma seção que
ninguém vê é uma seção que menos gente encontra. As diretrizes da Apple não têm gaveta. O mais
próximo é uma barra lateral, a sidebar, para as telas largas de um iPad ou de um Mac, e num iPhone elas
apontam para a barra de abas. Cada destino de uma gaveta é a raiz de uma pilha, assim como cada aba.

## A folha, e outras coisas modais

**Uma folha, ou tela modal, sobe por cima de todo o resto para uma tarefa curta e depois vai embora.**
Ela não entra na pilha que cobre: fechá-la devolve a aluna exatamente aonde estava, e nada embaixo se
mexeu. As diretrizes da Apple descrevem uma folha, a sheet, como uma tarefa delimitada "intimamente
relacionada ao contexto atual", e dizem que as pessoas esperam fechá-la com um botão na barra de cima ou
deslizando para baixo. O formulário de nova sessão do planner poderia ser uma folha em vez de uma tela
empilhada. Isso é uma decisão de design. Empilhado, ele é um passo mais fundo dentro de um curso;
como folha, é uma coisa rápida feita por cima do que estiver aparecendo.

| formato | o que a aluna vê | o que *voltar* faz | o exemplo no planner |
|---|---|---|---|
| pilha | a tela do topo de um monte | desempilha uma tela | Courses, um curso, uma nova sessão |
| abas | uma barra de seções, cada uma uma pilha | desempilha dentro da aba atual | Courses e Week |
| gaveta | uma lista escondida de seções | fecha a gaveta, se estiver aberta | nenhum; duas seções cabem em abas |
| folha | um painel por cima da tela atual | fecha a folha | o formulário de nova sessão, se desenhado assim |

O resto desta aula é sobre a coluna do meio, porque é nela que as duas plataformas se separam.
