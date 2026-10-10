---
title: Ids de caso, e o rastreio de um caso até um requisito
version: 1
---

Todo caso desta aula tem um id e aponta um requisito. Os dois parecem burocracia, e os dois
respondem perguntas que ninguém responde sem eles: **que requisitos ninguém testou, e quando um
requisito muda, que casos mudam junto?**

## Um id é um nome, não uma posição

O jeito óbvio de numerar casos é na ordem em que são escritos: caso 1, caso 2, caso 3. Funciona até
alguém inserir um caso. Coloque um caso novo de cadastro entre o 2 e o 3, renumere, e todo relatório
de defeito, registro de execução e conversa que dizia *o caso 3 falha* agora aponta para outro caso.
Nada avisa ninguém. O relatório continua perfeitamente legível; só que é sobre a coisa errada.

**Um id de caso é dado uma vez e nunca muda, nem passa para outro caso.** O esquema deste curso é
`TC-`, a área da aplicação, e um número dentro dessa área: `TC-SIGNUP-01`, `TC-BOOK-03`. A área diz
ao leitor onde olhar antes de ele abrir o caso. O número só precisa ser único. Quando o TC-BOOK-02
for apagado um dia, o id dele se aposenta junto e o próximo caso de reserva é o TC-BOOK-04, mesmo
ficando um buraco.

O título é para as pessoas, e pode ser reescrito sempre que aparecer um melhor. O id é aquilo a que
todo o resto se refere, e por isso não pode depender do título nem da ordem da lista. As
ferramentas de gestão de casos da aula 18 distribuem ids do mesmo jeito, e pelo mesmo motivo.

## Rastreando casos até requisitos

Cada caso aponta o requisito que confere, e os requisitos também têm ids, do R1 ao R9 na lista da
aula 1. Coloque os dois lado a lado e você tem uma **matriz de rastreabilidade**: que casos conferem
que requisito. Para os casos desta aula ela fica assim:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 350\" role=\"img\" data-fig=\"l02-trace\" aria-label=\"Uma matriz de rastreabilidade desenhada como duas colunas ligadas por linhas. À esquerda os nove requisitos, de R1 a R9; à direita os sete casos desta aula. TC-SIGNUP-01 liga R2 e R3; TC-SIGNUP-02 liga R2 e R7; TC-CONFIRM-01 liga R3; TC-CONFIRM-02 liga R3 e R7; TC-BOOK-01 liga R4 e R5; TC-BOOK-02 liga R4 e R7; TC-BOOK-03 liga R3, R4 e R5. R1, R6, R8 e R9 não têm linha e aparecem tracejados.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requisitos</text><text x=\"480.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">casos</text><path d=\"M270.0 88.0 C370.0 88.0 380.0 72.0 480.0 72.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 120.0 C370.0 120.0 380.0 72.0 480.0 72.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 88.0 C370.0 88.0 380.0 110.0 480.0 110.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 248.0 C370.0 248.0 380.0 110.0 480.0 110.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 120.0 C370.0 120.0 380.0 148.0 480.0 148.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 120.0 C370.0 120.0 380.0 186.0 480.0 186.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 248.0 C370.0 248.0 380.0 186.0 480.0 186.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 152.0 C370.0 152.0 380.0 224.0 480.0 224.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 184.0 C370.0 184.0 380.0 224.0 480.0 224.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 152.0 C370.0 152.0 380.0 262.0 480.0 262.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 248.0 C370.0 248.0 380.0 262.0 480.0 262.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 120.0 C370.0 120.0 380.0 300.0 480.0 300.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 152.0 C370.0 152.0 380.0 300.0 480.0 300.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M270.0 184.0 C370.0 184.0 380.0 300.0 480.0 300.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"20.0\" y=\"44.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">R1</text><text x=\"62.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a lista de espetáculos</text><rect x=\"20.0\" y=\"76.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R2</text><text x=\"62.0\" y=\"88.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cadastro</text><rect x=\"20.0\" y=\"108.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R3</text><text x=\"62.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e-mail de confirmação</text><rect x=\"20.0\" y=\"140.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R4</text><text x=\"62.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reserva</text><rect x=\"20.0\" y=\"172.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R5</text><text x=\"62.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">preços e descontos</text><rect x=\"20.0\" y=\"204.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">R6</text><text x=\"62.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">estados do pedido</text><rect x=\"20.0\" y=\"236.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"30.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">R7</text><text x=\"62.0\" y=\"248.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mensagens de erro</text><rect x=\"20.0\" y=\"268.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30.0\" y=\"280.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">R8</text><text x=\"62.0\" y=\"280.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">celulares e navegadores</text><rect x=\"20.0\" y=\"300.0\" width=\"250.0\" height=\"24.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30.0\" y=\"312.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">R9</text><text x=\"62.0\" y=\"312.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">teclado, leitor de tela</text><rect x=\"480.0\" y=\"60.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-SIGNUP-01</text><rect x=\"480.0\" y=\"98.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-SIGNUP-02</text><rect x=\"480.0\" y=\"136.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-CONFIRM-01</text><rect x=\"480.0\" y=\"174.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-CONFIRM-02</text><rect x=\"480.0\" y=\"212.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-BOOK-01</text><rect x=\"480.0\" y=\"250.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-BOOK-02</text><rect x=\"480.0\" y=\"288.0\" width=\"150.0\" height=\"24.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"555.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TC-BOOK-03</text><rect x=\"480.0\" y=\"322.0\" width=\"22.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"510.0\" y=\"328.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem caso ainda</text></svg>", "caption": "A matriz de rastreabilidade dos casos desta aula. Lida da esquerda, é cobertura; lida da direita, todo caso é evidência sobre um requisito. As caixas tracejadas são o que ninguém testou ainda."}
```

As linhas valem nos dois sentidos, e cada sentido responde a sua própria pergunta.

**De um requisito para os casos dele, para frente**, a matriz mostra cobertura. R2, R3 e R4 têm
pelo menos dois casos cada, e o R7 tem três, porque toda recusa desta aula é uma frase que o R7
pediu. R1, R6, R8 e R9 não têm nenhum, e a matriz diz isso sem que ninguém precise lembrar. Essa
lacuna não é um erro hoje, porque esta aula se propôs a testar do R2 ao R4, e as aulas 4 a 14 testam
do R6 ao R9. Seria um erro no dia da entrega, e a matriz é como alguém perceberia a
tempo.

**De um caso para os requisitos dele, para trás**, a matriz mostra que todo caso é evidência sobre
algo que o teatro pediu. Um caso que não aponta requisito nenhum é uma de duas coisas. Ou ele testa
algo que ninguém quis, e o tempo dele rende mais em outro lugar, ou ele encontrou um requisito que
ninguém escreveu. A Ana uma vez rascunhou um caso conferindo que toda página tem um link de volta
para Shows. Nenhuma linha do R1 ao R9 pede esse link, então ela levou a pergunta ao gerente do
teatro, que quis mantê-lo, e o requisito foi escrito.

## Quando um requisito muda

Suponha que o teatro decida que um pedido pode ter até oito ingressos, e o R4 muda. **A matriz
lista os casos a rever**: todo caso que aponta o R4, que hoje são o TC-BOOK-01, o TC-BOOK-02 e o
TC-BOOK-03, e todo caso que as aulas 4 e 5 acrescentarem ao R4. Sem ela, encontrá-los é ler
todos os casos e adivinhar. Com ela, a resposta é uma linha.

Uma mudança pode quebrar um caso de dois jeitos, e a matriz só encontra os casos, não o estrago.
Alguns casos continuam certos depois da mudança e só precisam rodar de novo. Outros agora esperam a
coisa errada, como um caso que esperava que sete ingressos fossem recusados. Ler os casos que a
matriz lista continua sendo trabalho de testador.

## O que cobertura não quer dizer

**Um requisito com caso está coberto; não está necessariamente bem testado.** O R4 tem três casos,
e os três reservam dois ingressos. Nenhum deles tenta um ingresso, seis, sete ou nenhum, e nenhum
reserva um espetáculo uma hora antes de começar. A matriz mostraria o R4 como coberto com três casos
ou com trinta.

Então a matriz encontra os buracos totalmente vazios, o que vale muito e é tudo o que ela encontra.
Quantos casos um requisito precisa, e quais, é decidido pelas técnicas das aulas 4 e 5. Contar
linhas na matriz não substitui essas técnicas.

## Onde a matriz mora

Para sete casos, a matriz é uma coluna na planilha de casos: cada linha é um caso, e uma célula
lista os requisitos dele. Ordenar por essa coluna dá a visão para frente. Uma ferramenta de gestão
de casos guarda o mesmo vínculo como um campo e desenha a matriz quando pedida, como mostra a aula
18. Seja onde for, a matriz só continua verdadeira se o campo de requisito for preenchido **quando o
caso é escrito**, porque ninguém volta depois para acrescentá-lo.
