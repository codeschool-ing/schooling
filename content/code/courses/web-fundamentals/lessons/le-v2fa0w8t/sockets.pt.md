---
title: Endereço mais porta
version: 1
---

Um pacote chega à máquina certa. Atravessou uma dúzia de roteadores, foi embrulhado e desembrulhado
uma dúzia de vezes, e finalmente está onde foi endereçado.

E agora? Aquela máquina está rodando um servidor web, um servidor de e-mail, um banco de dados, um
programa que você deixou aberto ontem e esqueceu, e o próprio sistema operacional. O pacote diz qual
máquina. Ele ainda não disse **qual dentre esses**.

É para isso que serve uma porta.

## O endereço acha a máquina, a porta acha o programa

Uma **porta** é um número que viaja ao lado do endereço, e diz para qual programa daquela máquina os
dados são.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"Uma máquina com um único endereço, desenhada como um painel grande. Dentro dela, quatro programas, cada um numa porta diferente. Uma requisição rotulada com endereço e porta 443 chega apenas ao servidor web, enquanto os outros três programas seguem parados.\"><rect x=\"264\" y=\"26\" width=\"444\" height=\"128\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"486\" y=\"18\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">203.0.113.7 — uma máquina, um endereço</text><rect x=\"282\" y=\"52\" width=\"98\" height=\"82\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect><text x=\"331\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">servidor web</text><text x=\"331\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">:443</text><rect x=\"390\" y=\"52\" width=\"98\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"439\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">SSH</text><text x=\"439\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">:22</text><rect x=\"498\" y=\"52\" width=\"98\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"547\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e-mail</text><text x=\"547\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">:25</text><rect x=\"606\" y=\"52\" width=\"88\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"650\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">banco de dados</text><text x=\"650\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">:5432</text><text x=\"126\" y=\"76\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">203.0.113.7:443</text><text x=\"126\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma requisição</text><path d=\"M196 86 L278 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"360\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o endereço achou a máquina; a porta escolheu qual dos quatro</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">os outros três estavam escutando o tempo todo e isto não era deles</text></svg>", "caption": "Um endereço é um prédio. Uma porta é uma entrada dele, e atrás de cada entrada há alguém diferente.", "same": ["SSH"]}
```

Endereço e porta juntos são escritos com dois-pontos: `203.0.113.7:443`. Esse par tem nome — um
**socket** — e é a resposta completa para *para onde isto está indo*.

## O que "escutar" realmente significa

A palavra *escutar* soa passiva, como se um programa ficasse observando o tráfego passar. Não é nada
disso. É uma reivindicação.

Quando um programa sobe e escuta na porta 443, ele está dizendo ao sistema operacional: **tudo que
chegar aqui é meu.** Daí em diante o sistema operacional entrega àquele programa e a nenhum outro.

Duas consequências decorrem, e as duas são coisas que você vai encontrar.

**Dois programas não podem reivindicar a mesma porta.** O segundo a tentar é recusado, e a mensagem
de erro diz isso — *endereço já em uso*. Se você já subiu um servidor de desenvolvimento e ouviu que
a porta estava ocupada, era isto: outra coisa já a tinha reivindicado, possivelmente uma cópia do
mesmo programa que você esqueceu de parar.

**Nada escutando significa nada a quem entregar.** Se um pacote chega para a porta 8080 e nenhum
programa a reivindicou, a máquina não fica segurando esperançosa. Ela responde na hora: não tem nada
aqui. É aquela recusa rápida que você viu na aula um — *recusado em menos de um milissegundo* — em
oposição a uma requisição que trava, que significa que ninguém sequer disse não.

## Números que as pessoas combinaram

Certos números significam certos serviços, por convenção, para que um cliente saiba onde bater sem
precisar ser avisado.

| porta | o que costuma escutar ali |
|---|---|
| `80` | um servidor web, sem criptografia |
| `443` | um servidor web, criptografado — o que quase tudo usa |
| `22` | SSH, para entrar na própria máquina |
| `25` | e-mail sendo passado entre servidores |
| `53` | DNS, assunto da aula 8 |
| `5432` | um banco de dados PostgreSQL |

São convenções, não leis. Um servidor web pode escutar na 8080, ou na 3000, ou na 61234 — que é
exatamente o que acontece quando você roda algo localmente e abre `localhost:3000`. O número depois
dos dois-pontos é a porta, e você o está digitando porque o seu servidor de desenvolvimento não
pegou a convencional.

## Quatro números, não dois

Agora a parte que explica algo que você já fez cem vezes sem se perguntar.

Abra o mesmo site em duas abas. As duas mandam requisições para o mesmo endereço, na mesma porta, da
mesma máquina. As respostas voltam — e não se misturam.

Elas não se misturam porque uma conexão não é identificada por dois números. É identificada por
**quatro**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 238\" role=\"img\" aria-label=\"Duas linhas comparando duas conexões simultâneas de um notebook para um servidor. As duas compartilham o mesmo endereço de origem, endereço de destino e porta de destino; só a porta de origem difere, 51188 na primeira e 51203 na segunda, e essa diferença está destacada.\"><rect x=\"14\" y=\"56\" width=\"692\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"30\" y=\"44\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">aba um</text><text x=\"30\" y=\"80\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">de 192.168.1.24</text><rect x=\"190\" y=\"62\" width=\"128\" height=\"42\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect><text x=\"254\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">porta 51188</text><text x=\"350\" y=\"80\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">para 203.0.113.7</text><text x=\"530\" y=\"80\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">porta 443</text><rect x=\"14\" y=\"140\" width=\"692\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"30\" y=\"130\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">aba dois</text><text x=\"30\" y=\"164\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">de 192.168.1.24</text><rect x=\"190\" y=\"146\" width=\"128\" height=\"42\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect><text x=\"254\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">porta 51203</text><text x=\"350\" y=\"164\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">para 203.0.113.7</text><text x=\"530\" y=\"164\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">porta 443</text><text x=\"254\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">um número difere, e é só isso</text><text x=\"560\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">três dos quatro são idênticos</text></svg>", "caption": "Duas conexões que concordam em tudo, menos em para onde a resposta volta."}
```

Endereço de origem, porta de origem, endereço de destino, porta de destino. A sua máquina escolhe
uma porta de origem diferente para cada conexão que abre — um número alto e arbitrário que ninguém
precisa combinar — e isso basta para manter distintas quantas conversas simultâneas com o mesmo
servidor existirem.

É também como um servidor sustenta milhares de conexões numa única porta. A porta 443 não é uma fila
em que alguém tira senha. Cada conexão com ela é um conjunto diferente de quatro números, e o
servidor as separa por isso.

## E é disso que uma conexão é feita

E aqui as peças desta aula começam a se fechar.

Um pacote, você leu no começo, não carrega conexão nenhuma. Nada nele diz *isto pertence à conversa
que estamos tendo*. Isso era verdade e continua sendo.

Então onde uma conexão existe? **Na memória das duas máquinas das pontas, e em lugar nenhum mais.**
Cada uma delas guarda um registro: estes quatro números, tantos dados enviados, tantos confirmados,
é isto que estamos esperando. Quando um pacote chega, os quatro números dele são comparados com
esses registros e ele é arquivado no lugar certo.

Nada no meio faz a menor ideia. Os roteadores que você encontrou duas seções atrás não sabem que uma
conexão existe, não seriam avisados se uma terminasse, e estão encaminhando pacotes só pelo destino.
Uma conexão é um acordo entre duas partes conduzido inteiramente por carta, e ela é real apenas
porque as duas estão tomando nota.

É também por isso que um servidor que reinicia derruba todas as conexões que tinha. As notas estavam
na memória. Nada na rede as estava segurando.

## Onde isto te deixa

Um endereço leva um pacote até uma máquina; uma porta o leva até um programa; os dois juntos são um
socket. Escutar é uma reivindicação, não um hábito, então dois programas não podem reivindicar uma
porta e uma porta não reivindicada recusa na hora. Uma conexão são quatro números, que é por que
duas abas não colidem — e ela vive na memória das pontas, porque a rede não guarda nada por você.

O que ainda não foi dito é para que essas notas **servem**. Manter registro do que foi enviado e do
que foi confirmado dá trabalho, e uma das duas maneiras de usar a rede não se dá a esse trabalho.
Essa é a última leitura desta aula.
