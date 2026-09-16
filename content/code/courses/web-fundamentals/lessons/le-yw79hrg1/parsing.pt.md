---
title: De texto para uma árvore
version: 1
---

O que chegou é um fluxo de caracteres. O que o navegador precisa é de uma estrutura à qual ele
consiga fazer perguntas — *o que está dentro disto?*, *isto está dentro do quê?* — e o primeiro
trabalho é transformar uma coisa na outra.

```
<article>
  <h1>Preço</h1>
  <p>Um <em>bom</em> negócio</p>
</article>
```

O aninhamento naquele texto é uma árvore, e o navegador a constrói conforme os caracteres chegam.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"O aninhamento da marcação vira uma árvore: um artigo contendo um título e um parágrafo, com o parágrafo contendo texto e um elemento de ênfase.\"> <rect x=\"270\" y=\"30\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">article</text> <path d=\"M330 72 L200 108\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M390 72 L520 108\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <rect x=\"110\" y=\"114\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"200\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">h1</text> <rect x=\"430\" y=\"114\" width=\"180\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"520\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">p</text> <path d=\"M200 156 L200 190\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M490 156 L420 190\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M550 156 L620 190\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <rect x=\"130\" y=\"196\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"200\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"Preço\"</text> <rect x=\"350\" y=\"196\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"420\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">\"Um \"</text> <rect x=\"550\" y=\"196\" width=\"140\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"620\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">em</text> <text x=\"360\" y=\"254\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">construída conforme os caracteres chegam, não depois de o arquivo acabar</text> </svg>", "caption": "O aninhamento no texto sempre foi uma árvore. O parser é o que a torna uma árvore que o navegador consegue consultar."}
```

Essa árvore é o **DOM** — o modelo de objetos do documento. Ela não é o arquivo HTML; é o que o
arquivo produziu. O arquivo é um conjunto fixo de bytes. A árvore é uma estrutura viva que scripts
mudam, que o navegador conserta quando o arquivo está errado, e que acaba contendo coisas que o
arquivo nunca mencionou.

## Isso acontece conforme os bytes chegam

O parser não espera o arquivo terminar. Ele lê o primeiro pedaço, constrói o que dá, e segue quando
o próximo chega.

É por isso que uma página grande começa a aparecer antes de terminar de baixar, e é por isso que a
**ordem de um arquivo importa** de formas que um formato de arquivo sozinho não sugeriria. Tudo
nesta aula que bloqueia outra coisa bloqueia no ponto do arquivo em que está.

Isso também explica um detalhe que vale conhecer: um servidor que consegue começar a enviar a
primeira parte de uma página antes de o resto estar pronto dá ao navegador trabalho para fazer
durante a espera. É para isso que serve a codificação em pedaços da aula seis, vista da outra ponta.

## O que o navegador faz com marcação quebrada

A leitura de HTML tem uma propriedade que nenhum outro formato deste curso tem: **ela não falha.**

Uma tag de fechamento faltando, uma tag aninhada onde não pode, um atributo sem aspas — nada disso
produz um erro. A especificação diz exatamente o que fazer com cada caso, em detalhe, e todo
navegador faz a mesma coisa. O resultado é uma árvore, sempre.

Essa é uma decisão deliberada com um custo real e um benefício real.

O benefício é o acervo da web. Páginas escritas em 1996 por gente que nunca leu uma especificação
ainda renderizam, e um formato que as recusasse teria feito da web um lugar menor e bem menos
interessante.

O custo é que **nada avisa você quando errou.** A página parece certa, a árvore não é a que você
escreveu, e a surpresa chega depois — em geral quando um script procura um elemento e o encontra em
algum lugar onde você não o pôs. Um validador é a ferramenta que conta o que o parser perdoou em
silêncio, e vale rodar uma vez em qualquer coisa de que você suspeite.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Marcação escrita com um erro e a árvore que o parser produz dela, que é válida e não é o que o arquivo sugeria. Nada reporta um erro.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">o que foi escrito</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"40\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;p&gt;</text> <text x=\"56\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;div&gt;preço&lt;/div&gt;</text> <text x=\"40\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;/p&gt;</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">o que a árvore tem</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"96\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"400\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;p&gt;&lt;/p&gt;</text> <text x=\"400\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">&lt;div&gt;preço&lt;/div&gt;</text> <text x=\"400\" y=\"110\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">o parágrafo foi fechado antes</text> <text x=\"360\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">sem erro, sem aviso, e todo navegador concorda com este resultado</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">que é o que mantém trinta anos de páginas renderizando</text> <text x=\"360\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">e o que faz um script que procura no lugar errado não achar nada</text> </svg>", "caption": "A leitura de HTML não falha. Ela conserta, em silêncio, e a árvore que produz é o que o seu script vai encontrar."}
```

O caso mais claro é o que pega todo mundo: uma linha de tabela fora de uma tabela, ou um parágrafo
contendo um elemento de bloco. O parser move coisas, fecha coisas e insere coisas até a árvore ficar
válida, e o que você recebe está correto pela especificação e não é o que o arquivo sugeria.

## O scanner que corre na frente

Um mecanismo que vale conhecer pelo nome, porque explica algo que de outro modo pareceria
impossível.

Quando o parser para — e a leitura sobre scripts vai mostrar exatamente quando ele para — o navegador
não fica parado. Um segundo leitor, bem mais simples, corre à frente pelos bytes restantes procurando
uma coisa: endereços. Folhas de estilo, scripts, imagens. Ele começa a buscá-los na hora, enquanto o
parser de verdade está bloqueado.

Este é o **scanner de pré-carga**, e é por isso que uma página com um script bloqueante lá em cima
não enfileira todos os downloads atrás dele. As buscas se sobrepõem; só a *leitura* está parada.

Duas consequências práticas. Ele só vê o que está escrito na marcação — um recurso cujo endereço é
montado por um script é invisível para ele, e chega tarde. E é a razão de uma dica explícita,
avisando o navegador sobre algo importante antes de ele descobrir, ser uma técnica real em vez de
superstição.

## E é por isso que a árvore é o que você inspeciona

A conclusão prática, e ela prepara a próxima aula.

Quando uma página não se comporta, ler o arquivo HTML diz o que foi enviado. O **painel de
elementos** das ferramentas do navegador mostra a árvore, que é o que existe. Entre os dois estão os
consertos do parser e tudo que qualquer script fez desde então.

Iniciantes leem o arquivo. O hábito que vale construir agora é ler a árvore.

## Dois nomes para quase a mesma coisa

Um esclarecimento, porque as palavras são usadas de forma solta e a distinção fica importante mais
adiante.

O **documento** é a árvore. A **árvore de renderização** de daqui a duas leituras é outra coisa,
construída a partir dele, contendo apenas o que será desenhado. Um elemento removido do documento
sumiu; um elemento escondido por um estilo continua no documento e está ausente da árvore de
renderização.

Manter os dois separados explica um bocado de comportamento que de outro modo parece arbitrário —
inclusive, naquela leitura, por que dois jeitos de esconder algo se comportam de forma completamente
diferente.
