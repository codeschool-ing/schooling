---
title: A árvore, ao vivo
version: 1
---

O painel de elementos mostra o DOM da aula dez — não o arquivo que foi enviado, mas a árvore que
existe agora, incluindo cada conserto que o parser fez e tudo que qualquer script fez desde então.

Essa distinção é toda a razão de usá-lo, e vale provar isso a você mesmo uma vez: abra qualquer
página, veja o código-fonte, depois abra este painel, e ache algo que difira.

## O que está na tela

Três áreas, e cada uma responde uma pergunta diferente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"O painel de elementos em três áreas: a árvore de nós, as regras que casaram com o elemento selecionado com as perdedoras riscadas, e o valor computado de cada propriedade.\"> <rect x=\"20\" y=\"34\" width=\"220\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"130\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">a árvore</text> <text x=\"130\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;article&gt;</text> <text x=\"130\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;h1&gt; ... &lt;/h1&gt;</text> <text x=\"130\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&lt;p class=\"sale\"&gt;</text> <text x=\"130\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o selecionado fica destacado</text> <rect x=\"252\" y=\"34\" width=\"216\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o que casou com ele</text> <text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">#price color: green</text> <text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">.sale color: red</text> <text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">p color: black</text> <text x=\"360\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os perdedores ficam riscados</text> <rect x=\"480\" y=\"34\" width=\"220\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"590\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o valor computado</text> <text x=\"590\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">color: rgb(0 128 0)</text> <text x=\"590\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">margin-left: 17px</text> <text x=\"590\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">display: block</text> <text x=\"590\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a resposta, não as regras</text> <text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a cascata da aula dez, tornada visível</text> <text x=\"360\" y=\"246\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e quando algo fica a 17 pixels da esquerda, a coluna da direita é onde está o 17</text> </svg>", "caption": "Três áreas, três perguntas: o que há aqui, o que casou com isso, e qual acabou sendo a resposta."}
```

**A árvore**, de um lado, expansível, com o elemento sob o seu ponteiro destacado na própria página.
Selecionar um nó é como todo outro painel desta aula descobre de qual elemento você está falando.

**Os estilos**, do outro, mostrando cada regra que casou com o elemento selecionado, em ordem de
cascata, com as perdedoras riscadas. Esta é a cascata da aula dez tornada visível, e resolve num
olhar o que ler uma folha de estilo resolve em vinte minutos.

**Os valores computados**, em geral numa aba ao lado dos estilos, mostrando o número final de cada
propriedade — não as regras, a resposta. Quando uma coisa fica a 17 pixels da esquerda e ninguém
sabe dizer por quê, é aqui que está o 17.

## As quatro coisas que vale aprender a fazer

**Inspecionar.** Clique com o botão direito em qualquer coisa de qualquer página e escolha
inspecionar, e o painel abre com aquele elemento selecionado. É o caminho mais rápido de *o que é
isto?* até uma resposta, e funciona em sites que você não construiu, que é como boa parte do
conhecimento de front-end é de fato adquirida.

**Editar, temporariamente.** Todo valor no painel de estilos é editável, e a página se atualiza
conforme você digita. Mude uma cor, um tamanho, uma margem; veja na hora. Nada é salvo — recarregar
descarta tudo — que é exatamente o que torna isso seguro.

**Alternar um estado.** Um controlezinho deixa você forçar um elemento a hover, foco ou ativo, para
inspecionar um menu que de outro modo sumiria no instante em que você tirasse o ponteiro. Este é o
que as pessoas não descobrem sozinhas e depois usam todo dia.

**Ler a caixa.** Um diagrama dos quatro anéis da aula dez — conteúdo, preenchimento, borda, margem —
com os números reais dentro. Ele responde *de onde vem este espaço?* mais rápido que qualquer
quantidade de leitura.

## O painel muda a página que ele está mostrando

Uma consequência que vale ter em mente de propósito, porque produz tardes confusas.

Abrir o painel deixa a janela mais estreita. Num site responsivo isso muda qual layout está em uso,
o que quer dizer que a coisa que você está inspecionando não é bem a coisa que um visitante vê. O
painel pode ser movido para baixo ou para uma janela separada, e numa questão de layout isso vale a
pena.

Editar um valor muda a página ao vivo e mais nada. Não é uma correção e não alcança seus arquivos —
o que é óbvio escrito assim e ainda assim é a origem da hora perdida ocasional.

## Duas outras abas no mesmo painel

Vale nomear porque as duas vêm direto de aulas anteriores.

**Acessibilidade**, que mostra o que um leitor de tela faria do elemento selecionado: o papel dele,
o nome, se ele está na árvore que softwares assistivos leem. É aqui que o problema do `opacity: 0`
da aula dez fica visível em vez de teórico.

**Ouvintes de eventos**, que lista o código ligado ao elemento. Quando um botão não faz nada, isso
responde se há algo escutando — que é uma pergunta diferente de se o código está errado, e bem mais
rápida.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Quatro coisas para aprender a fazer neste painel: inspecionar qualquer coisa em qualquer site, editar valores temporariamente, forçar um estado de hover ou foco, e ler o modelo de caixa com números reais.\"> <rect x=\"20\" y=\"34\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"188\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">inspecionar qualquer coisa, em qualquer site</text> <rect x=\"20\" y=\"84\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"188\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">editar um valor e ver na hora</text> <rect x=\"364\" y=\"34\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"532\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">forçar hover, para um menu ficar aberto</text> <rect x=\"364\" y=\"84\" width=\"336\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"532\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">ler a caixa, com números reais</text> <rect x=\"20\" y=\"140\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nada aqui é salvo: recarregar descarta tudo, e é isso que torna seguro</text> <text x=\"360\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o terceiro é o que ninguém descobre sozinho e depois todo mundo usa todo dia</text> </svg>", "caption": "Quatro movimentos. As edições são temporárias de propósito, e é por isso que experimentar aqui não custa nada."}
```

## Onde estão os cookies e os caches

Mais um painel que vale nomear aqui, porque ele guarda tudo da aula sete e as pessoas o procuram no
lugar errado.

O painel de armazenamento — *aplicação* em alguns navegadores — lista os cookies deste site com os
atributos deles como colunas: o valor, o domínio, o caminho, a expiração, e marcações para `Secure`,
`HttpOnly` e `SameSite`. Três marcações, cada uma das quais fecha um ataque que já levou a conta de
alguém.

Ele também guarda o armazenamento local, os caches que um service worker está mantendo, e um botão
que limpa tudo. Esse botão é o jeito honesto de testar o que um visitante de primeira viagem
experimenta, e vale saber que limpar dados do site é coisa diferente de desativar o cache no painel
de rede: um remove o que está guardado, o outro se recusa a usar.

## O hábito

Quando uma página não se comporta, a sequência é: inspecione a coisa, olhe o que de fato casou com
ela, e leia o valor computado.

Quase toda discussão sobre estilo termina ali. A regra que você esperava está presente e riscada
porque algo mais específico venceu; ou está ausente porque o seletor não casa com o que o parser
produziu; ou está se aplicando perfeitamente e o elemento que você está olhando não é o elemento que
você pensa.

Os três ficam visíveis em uns quatro segundos, e os três são invisíveis no arquivo.
