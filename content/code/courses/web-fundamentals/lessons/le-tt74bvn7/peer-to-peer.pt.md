---
title: Onde o modelo não vale
version: 1
---

Um modelo ganha confiança sendo claro sobre onde ele para. Cliente e servidor não é a única
maneira de máquinas conversarem, e conhecer a alternativa afia o original em vez de complicá-lo.

## Peer-to-peer

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Dois arranjos lado a lado. À esquerda um servidor e muitos clientes, com todas as setas se encontrando no servidor. À direita, máquinas trocando pedaços diretamente umas com as outras, cada máquina pedindo e respondendo.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <text x=\"14\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"700\" letter-spacing=\"1\" fill=\"var(--paper-dim)\">CLIENTE E SERVIDOR</text>\n  <rect x=\"76\" y=\"52\" width=\"120\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"136.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">um servidor</text>\n  <g stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" opacity=\".65\" fill=\"none\">\n    <path d=\"M136 106 L44 176\"></path><path d=\"M136 106 L82 182\"></path><path d=\"M136 106 L120 188\"></path>\n    <path d=\"M136 106 L160 188\"></path><path d=\"M136 106 L198 182\"></path><path d=\"M136 106 L236 176\"></path>\n  </g>\n  <text x=\"136\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--phosphor-dim)\">capacidade ÷ 1000</text>\n  <text x=\"136\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mais popular, pior atendido</text>\n\n  <line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"220\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n\n  <text x=\"404\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"700\" letter-spacing=\"1\" fill=\"var(--paper-dim)\">PEER TO PEER</text>\n  <g fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\">\n    <circle cx=\"452\" cy=\"76\" r=\"17\"></circle><circle cx=\"556\" cy=\"60\" r=\"17\"></circle>\n    <circle cx=\"656\" cy=\"94\" r=\"17\"></circle><circle cx=\"470\" cy=\"160\" r=\"17\"></circle>\n    <circle cx=\"574\" cy=\"168\" r=\"17\"></circle><circle cx=\"662\" cy=\"176\" r=\"17\"></circle>\n  </g>\n  <g stroke=\"var(--phosphor)\" stroke-width=\"1\" opacity=\".6\" fill=\"none\">\n    <path d=\"M469 76 L539 61\"></path><path d=\"M573 60 L639 92\"></path><path d=\"M452 93 L470 143\"></path>\n    <path d=\"M487 160 L557 167\"></path><path d=\"M591 168 L645 176\"></path><path d=\"M556 77 L574 151\"></path>\n    <path d=\"M466 91 L559 155\"></path><path d=\"M649 108 L580 156\"></path>\n  </g>\n  <text x=\"556\" y=\"214\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--phosphor)\">capacidade × 1000</text>\n  <text x=\"556\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada quem baixa também é uma fonte</text>\n</svg>", "caption": "A inversão é todo o apelo. De um lado a popularidade divide a carga; do outro, multiplica."}
```

Numa rede **peer-to-peer** não há quem sempre pede nem quem sempre responde. Toda máquina é um
**peer**: ela tem parte do que a rede tem, pede aos outros o que lhe falta, e serve aos outros o
que tem.

O BitTorrent é o exemplo que todo mundo conhece. Quando você baixa um arquivo grande, você não
está puxando de uma máquina — você está puxando pedaços de muitas máquinas que já têm esses
pedaços, e, enquanto faz isso, está distribuindo os pedaços que já pegou. Ninguém está no comando,
e não existe uma única máquina cuja falha encerre a transferência.

A aritmética é o que torna isso atraente. No formato cliente e servidor, mil pessoas baixando um
arquivo significam uma máquina mandando o arquivo mil vezes, com a capacidade dividida em mil —
**quanto mais popular, pior o atendimento**. No peer-to-peer, cada nova pessoa que baixa é também
uma nova fonte, então mil pessoas são mil máquinas ajudando. **Quanto mais popular, melhor o
atendimento.** Essa inversão é todo o apelo, e é por isso que esse formato é usado exatamente para
as coisas que ficam muito populares de repente: lançamentos de filmes, imagens de sistema
operacional, atualizações de jogos.

## Os papéis sobrevivem mesmo assim

Aqui está a parte que importa para esta aula, e é fácil de passar batido.

**Peer-to-peer não abole os dois papéis. Ele abole as duas *funções*.** Olhe qualquer troca isolada
entre dois peers e um deles pediu e o outro respondeu — cliente e servidor, naquela troca. O que
muda é que nenhuma máquina guarda um papel permanentemente: um peer é cliente para um pedaço que
quer e servidor para um pedaço que tem, milhares de vezes por minuto.

Que é exatamente o ponto de `roles`: o papel é a posição em uma troca. **O P2P é o caso que prova
isso**, porque é onde o papel muda mais rápido. Se os papéis fossem propriedades das máquinas,
peer-to-peer seria ininteligível. Como posições em uma troca, é banal.

## Como um peer encontra outros peers?

Esta é a pergunta que o formato tem de responder, e a resposta honesta é desconfortável para quem
gosta da ideia de nada central.

**Alguém tem de fornecer o primeiro endereço.** Uma máquina que acabou de entrar não conhece nada
nem ninguém. Ela não pode perguntar à rede onde a rede está.

Três respostas são usadas, e nenhuma é tão pura quanto o slogan:

- **Um tracker** — um servidor, no sentido mais simples, cuja função é manter a lista de quem tem o
  quê. Você pergunta, ele responde. É um ponto único de falha sentado no meio de uma arquitetura
  cujo argumento de venda é não ter um.
- **Uma tabela distribuída** — a própria lista é espalhada entre os peers, de modo que nenhuma
  máquina a detém. Melhor, e ainda assim exige **nós de bootstrap**: um punhado de endereços
  conhecidos, embutidos no software, que um recém-chegado contata para ser apresentado. Menos
  pontos centrais. Não zero.
- **Descoberta local** — gritar na rede local para ver quem está por perto. Funciona só para peers
  na mesma rede, que raramente é onde o arquivo está.

Então sistemas peer-to-peer reais são **híbridos**, e vale dizer isso com todas as letras: as
partes que descobrem, coordenam e autenticam tendem a parecer servidores, e as partes que carregam
o volume de dados tendem a parecer peers. Pouquíssimos sistemas em funcionamento são uma coisa só
até o fim.

## Por que a web não é peer-to-peer

A web poderia ter sido construída assim e não foi, por razões que são sobretudo de **confiança e
de encontrabilidade** em vez de tecnologia:

- **Alguém tem de ser a autoridade.** Quando você pergunta o seu saldo ao banco, você precisa que a
  resposta venha do banco, não de qualquer peer que afirme ter uma cópia. Peer-to-peer é excelente
  para distribuir um arquivo que é igual para todo mundo e não tem resposta para a pergunta "quem
  pode ver isto?"
- **Alguém tem de ser encontrável.** Um peer que está offline simplesmente não existe. Isso é
  tolerável para um filme, em que você espera ou procura outra fonte, e intolerável para uma loja,
  que precisa estar aberta quando o cliente chega.
- **A publicação tem de ser controlável.** No peer-to-peer, o que se espalha é o que as pessoas
  escolhem continuar copiando. Ninguém pode retirar, corrigir ou atualizar aquilo — e "ninguém pode
  retirar" é uma virtude e uma catástrofe, dependendo do que foi publicado.
- **A maior parte do conteúdo não é popular.** A aritmética acima só funciona quando muita gente
  quer a mesma coisa ao mesmo tempo. Para uma página que onze pessoas leem por mês não há peers
  para compartilhar, e um servidor é simplesmente a resposta certa.

## O meio-termo que você usa todo dia

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um desenho em duas zonas. Acima, dentro de uma caixa marcada como o papel de servidor, um tracker num endereço conhecido. Abaixo, dentro de uma caixa marcada como troca entre peers, quatro peers trocando pedaços de um arquivo entre si em todas as direções. Setas pontilhadas sobem de cada peer até o tracker.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <rect x=\"14\" y=\"14\" width=\"692\" height=\"96\" rx=\"4\" fill=\"var(--phosphor-dim)\" fill-opacity=\".13\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></rect>\n  <text x=\"28\" y=\"34\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--phosphor-dim)\">DESCOBERTA · o papel de servidor, seja qual for o nome</text>\n  <text x=\"28\" y=\"62\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">todo peer pergunta a ele, uma vez, ao entrar:</text>\n  <text x=\"28\" y=\"78\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">quem está aqui, e quem tem o quê?</text>\n  <rect x=\"430\" y=\"40\" width=\"168\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"514.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">tracker</text><text x=\"514.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um endereço conhecido</text>\n\n  <path d=\"M84 176 L470 100\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#ahv)\"></path>\n  <path d=\"M268 176 L500 100\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#ahv)\"></path>\n  <path d=\"M452 176 L528 100\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#ahv)\"></path>\n  <path d=\"M636 176 L558 100\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#ahv)\"></path>\n\n  <rect x=\"14\" y=\"140\" width=\"692\" height=\"126\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect>\n  <text x=\"28\" y=\"160\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--phosphor)\">TRANSFERÊNCIA · peers, e é isto que faz dele peer-to-peer</text>\n  <rect x=\"16\" y=\"178\" width=\"136\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"84.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">peer A</text><rect x=\"200\" y=\"178\" width=\"136\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">peer B</text><rect x=\"384\" y=\"178\" width=\"136\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"452.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">peer C</text><rect x=\"568\" y=\"178\" width=\"136\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"636.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">peer D</text>\n  \n  <path d=\"M154 192 L194 192\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M194 208 L154 208\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M338 192 L378 192\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M378 208 L338 208\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M522 192 L562 192\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M562 208 L522 208\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M84 224 Q268 258 446 224\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M268 226 Q452 262 630 226\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <text x=\"360\" y=\"290\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o tracker não guarda arquivo nenhum, e continua sendo perguntado e respondendo</text>\n</svg>", "caption": "O híbrido, que é o que quase tudo é na prática. Descobrir quem existe é uma troca com um servidor; mover os dados não é. Perguntas diferentes, então têm direito a formatos diferentes."}
```

Entre os dois formatos existe um arranjo que toma emprestado dos dois, e é o que está rodando por
baixo da maior parte da internet que você toca: a **rede de distribuição de conteúdo**, a CDN.

A ideia é manter o formato cliente e servidor — uma origem autoritativa, encontrável, no comando —
e copiar as partes populares e imutáveis do que ela serve para máquinas colocadas perto de todo
mundo. Quando você pede um vídeo, quem lhe responde é uma máquina talvez a cinquenta quilômetros,
em vez da origem a nove mil.

Isso resolve o mesmo problema que o peer-to-peer resolve — uma máquina não consegue atender todo
mundo — e resolve mantendo alguém autoritativo e encontrável. Você continua sendo um cliente, e
ela continua sendo um servidor. Só que há muitíssimos servidores, dispostos de propósito, todos sob
um único dono.

A aula 9 entra no que isso custa e quando vale a pena.

## "Descentralizado" é uma afirmação diferente

Um cuidado, porque as palavras andam juntas e significam coisas diferentes.

Peer-to-peer é uma afirmação sobre **quem tem os dados e quem responde**. Descentralização é
normalmente uma afirmação sobre **quem manda** — quem pode mudar as regras, remover algo, ou
desligar tudo.

Um sistema pode ser peer-to-peer e efetivamente controlado por quem escreve o software que todo
mundo roda. Um sistema pode ser construído inteiramente com servidores comuns e ser genuinamente
difícil de qualquer parte controlar, porque há milhares de operadores independentes — que é mais ou
menos a história do e-mail. Quando você encontrar a afirmação de que algo é descentralizado, a
pergunta útil não é que formato o tráfego tem. É **quem poderia parar aquilo, e quantos deles
existem.**

## O formato, em uma linha

**Cliente pede, servidor responde, o papel pertence à troca.**

Todo o resto deste curso — pacotes, HTTP, DNS, hospedagem, o navegador — é resposta a alguma parte
da pergunta *como esses dois se encontram e entendem o que foi dito?*
