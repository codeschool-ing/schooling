---
title: Lendo os cinco números
version: 1
---

Clicar numa requisição e abrir o tempo dela produz um gráfico pequeno que quase todo mundo pula. É a
coisa mais útil desta aula, porque pega o número único *isto levou 5,4 segundos* e divide em pedaços
que apontam cada um para uma pessoa diferente.

## As cinco barras

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"O tempo de uma requisição dividido em cinco barras: na fila, DNS, conexão e TLS, esperando o servidor, e baixando. Só a barra de espera pertence ao servidor.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">uma requisição, 5,4 segundos, dividida no que ela de fato fazia</text> <rect x=\"20\" y=\"38\" width=\"60\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"50\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">na fila</text> <rect x=\"86\" y=\"38\" width=\"54\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"113\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DNS</text> <rect x=\"146\" y=\"38\" width=\"90\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"191\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">conexão, TLS</text> <rect x=\"242\" y=\"38\" width=\"380\" height=\"34\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"432\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">esperando — o servidor pensando</text> <rect x=\"628\" y=\"38\" width=\"72\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"664\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">download</text> <text x=\"20\" y=\"110\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o mesmo total, com as barras trocadas, é um problema completamente diferente</text> <rect x=\"20\" y=\"122\" width=\"60\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"50\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">na fila</text> <rect x=\"86\" y=\"122\" width=\"54\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"113\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DNS</text> <rect x=\"146\" y=\"122\" width=\"90\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"191\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">conexão, TLS</text> <rect x=\"242\" y=\"122\" width=\"80\" height=\"34\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"282\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">esperando</text> <rect x=\"328\" y=\"122\" width=\"372\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"514\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">baixando — o arquivo é simplesmente grande</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">o total é o mesmo e quem conserta não é</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">que é toda a razão de abrir o detalhamento em vez de ler o total</text> </svg>", "caption": "Um número, cinco pedaços, e cada pedaço aponta para uma correção diferente. Pular isto é como se gastam semanas."}
```

**Na fila, ou travada** — a requisição estava esperando a vez. Em HTTP/1.1 isso é o limite de seis
conexões da aula seis; se esta barra é grande e há muitas linhas, a versão do protocolo é a história.

**DNS** — a consulta de nome da aula oito. Presente na primeira requisição a um host e ausente
depois, porque a resposta ficou em cache. Uma barra grande aqui quer dizer um resolvedor lento ou um
nome frio, e ela está na frente de todo o resto.

**Conexão, e TLS** — as idas e voltas das aulas cinco e seis: a conexão, depois a negociação. São
pagas uma vez por conexão, e é por isso que uma página espalhada por seis hosts paga seis vezes.

**Esperando** — a requisição foi enviada e nada voltou. Este é o servidor pensando, e é o único
número desta lista que pertence ao servidor sozinho.

**Baixando** — bytes chegando. Isto é banda e tamanho, e é a única barra que diminui quando o
arquivo diminui.

## O que cada uma manda fazer

A razão de dividi-las é que a correção é diferente para cada barra, e escolher a errada é como se
gastam semanas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Cada barra e o que ela manda fazer: esperar quer dizer a aplicação, baixar quer dizer o arquivo, conectar quer dizer hosts demais, DNS quer dizer consulta fria e fila quer dizer disputa.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"140\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">esperando</text> <text x=\"300\" y=\"49\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a aplicação ou o banco — nenhuma CDN toca nisso</text> <rect x=\"20\" y=\"76\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"140\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">baixando</text> <text x=\"300\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">o arquivo: comprima, redimensione, ou mande menos</text> <rect x=\"20\" y=\"122\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">conexão, TLS</text> <text x=\"300\" y=\"141\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">hosts demais, ou um servidor longe</text> <rect x=\"20\" y=\"168\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DNS</text> <text x=\"300\" y=\"187\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">uma consulta fria, na frente de tudo</text> <rect x=\"20\" y=\"214\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">na fila</text> <text x=\"300\" y=\"233\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">disputa: muitas de uma vez, numa versão que enfileira</text> </svg>", "caption": "Cinco barras, cinco pessoas diferentes. Leia qual delas é grande antes de decidir qualquer coisa."}
```

Uma barra de **espera** grande é a aplicação ou o banco de dados. Nenhuma quantidade de compressão,
nenhuma CDN, nenhuma imagem menor toca nisso.

Uma barra de **download** grande é o arquivo. Comprima, redimensione, escolha um formato melhor, ou
mande menos.

Barras de **conexão** e **TLS** grandes querem dizer hosts demais, ou um servidor longe. Menos
hosts, ou uma CDN, que é a correção de distância da aula nove.

Uma barra de **DNS** grande quer dizer uma consulta fria, e as ferramentas para isso — uma dica para
resolver cedo, ou uma corrente de nomes mais curta — estão na aula oito.

Uma barra de **travamento** grande quer dizer disputa: requisições demais de uma vez, numa versão de
protocolo que as enfileira.

## Lendo o gráfico inteiro em vez de uma linha

A coluna da cascata mostra cada requisição numa linha do tempo só, e o formato dela diz coisas que
nenhuma linha isolada diz.

**Uma escada** — cada requisição começando quando a anterior terminou — quer dizer que as coisas
estão sendo descobertas uma de cada vez. Uma folha de estilo que importa uma folha de estilo, um
script que busca um script, uma corrente de redirecionamentos. Este é o formato a procurar primeiro,
porque uma corrente em série é a coisa mais cara que uma página consegue fazer e em geral não é
intencional.

**Um paredão** — tudo começando junto — é o que se quer, e se a página ainda está lenta com esse
formato o problema está numa das barras e não no arranjo.

**Um intervalo longo com nada dentro** é o navegador ocupado e não a rede: parsing, um script
rodando, um layout. O painel de rede fica em silêncio e o painel de desempenho é onde o tempo foi.

## As três linhas ao longo do gráfico

Marcadores verticais, e são os momentos que a aula dez nomeou.

O primeiro é **DOMContentLoaded** — a árvore está pronta. O segundo é **load** — tudo terminou.
Numa página saudável o intervalo entre os dois é pequeno; um largo quer dizer que muita coisa está
chegando depois que o visitante já poderia ter começado a ler, o que pode estar tudo bem e vale
saber.

Alguns navegadores também marcam a **primeira pintura**. Tudo à esquerda dessa linha é a tela em
branco da aula dez, e se ela é larga, a seção sobre bloqueio de renderização daquela aula é onde
procurar.

## Para onde o total de fato foi

Mais uma leitura do gráfico, porque ela responde a pergunta que um gestor faz.

O rodapé do painel informa o número de requisições, os bytes transferidos e os tempos dos dois
eventos acima. Esses quatro números são o resumo, e cada um tem um dono diferente: a contagem é o
desenho da página, os bytes são os arquivos, e os eventos são tudo de que este curso tratou.

A frase que vale conseguir dizer é a que separa os três. *O servidor respondeu em quarenta
milissegundos; a primeira pintura foi aos dois segundos; a diferença é uma folha de estilo e um
script bloqueante.* Cada parte disso sai deste gráfico, e é uma conversa diferente de *o site está
lento*.

## Três hábitos

**Recarregue com o painel aberto**, limitado a algo que um visitante real possa ter.

**Leia a maior barra primeiro**, e leia qual barra é ela antes de decidir qualquer coisa.

**Compare com um segundo carregamento**, sem desativar o cache, porque essa é a experiência que a
maioria dos visitantes tem e a medição que ninguém faz.

Esses três, em qualquer site, respondem mais perguntas em cinco minutos do que uma tarde de
adivinhação. E é isto a aula inteira: os números sempre estiveram ali, e agora você sabe qual deles
está lendo.
