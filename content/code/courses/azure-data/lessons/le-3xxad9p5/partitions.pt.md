---
title: Partições lógicas e físicas
version: 1
---

**Há dois tipos de partição no Cosmos DB, e confundi-los é como um desenho dá errado.** Uma partição
lógica é todo item que compartilha um valor da chave de partição: todos os pedidos do cliente `c-17`.
Uma partição física é uma peça da maquinaria do Azure, armazenamento e computação que guarda muitas
partições lógicas. Você escolhe a chave, e com ela as partições lógicas; o Azure decide as físicas, e
acrescenta mais conforme o contêiner cresce, dividindo as partições lógicas entre elas por um hash do
valor da chave.

**Esta seção é ensinada a partir da documentação da Microsoft, e nada nela foi rodado.** O emulador tem
uma partição física, como a próxima seção mostra, então nada do que segue pode ser visto nele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Itens com os valores de chave de partição c-17, c-18, c-19, c-40 e c-41 passam pelo hash do valor da chave, e cada partição lógica, todos os itens de um cliente, cai inteira numa partição física: c-18 e c-41 na partição física 1, c-19 na partição física 2, c-17 e c-40 na partição física 3. Cada partição física guarda até 50 GB e 10.000 RU/s; cada partição lógica, no máximo 20 GB. A vazão do contêiner é dividida igualmente entre as partições físicas.\" data-fig=\"l11-partitions\"><defs><marker id=\"arr-l11-partitions-wire\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M 0 0 L 10 5 L 0 10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"90\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-17</text><line x1=\"110\" y1=\"55\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"20\" y=\"88\" width=\"90\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-18</text><line x1=\"110\" y1=\"103\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"20\" y=\"136\" width=\"90\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-19</text><line x1=\"110\" y1=\"151\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"20\" y=\"184\" width=\"90\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-40</text><line x1=\"110\" y1=\"199\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"20\" y=\"232\" width=\"90\" height=\"30\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"247\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">c-41</text><line x1=\"110\" y1=\"247\" x2=\"196\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"200\" y=\"125\" width=\"130\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hash do valor da chave</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"76\" rx=\"6\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"412\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição física 1</text><rect x=\"412\" y=\"48\" width=\"88\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c-18</text><rect x=\"512\" y=\"48\" width=\"88\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c-41</text><line x1=\"330\" y1=\"150\" x2=\"396\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"400\" y=\"110\" width=\"300\" height=\"76\" rx=\"6\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"412\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição física 2</text><rect x=\"412\" y=\"138\" width=\"88\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c-19</text><line x1=\"330\" y1=\"150\" x2=\"396\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><rect x=\"400\" y=\"200\" width=\"300\" height=\"76\" rx=\"6\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"412\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">partição física 3</text><rect x=\"412\" y=\"228\" width=\"88\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"456\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c-17</text><rect x=\"512\" y=\"228\" width=\"88\" height=\"34\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"556\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">c-40</text><line x1=\"330\" y1=\"150\" x2=\"396\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#arr-l11-partitions-wire)\"></line><text x=\"400\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">até 50 GB, 10.000 RU/s</text><text x=\"20\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">partições lógicas: cada uma com no máximo 20 GB</text></svg>", "caption": "Você escolhe a chave, e com ela as partições lógicas; o Azure as distribui pelo hash nas partições físicas e divide essas conforme o contêiner cresce. Uma partição lógica nunca é dividida."}
```

## Os limites que decorrem disso

**Uma partição lógica guarda no máximo 20 GB.** Ela mora inteira dentro de uma partição física e nunca
é dividida, então o limite documentado é rígido: um cliente cujos pedidos chegam a 20 GB não aceita
mais escritas. A cerca de 1 KB por pedido, são vinte milhões de pedidos de um cliente, o que os
clientes da Quitanda não vão alcançar; uma chave com poucos valores chega lá muito antes, como a seção
depois da próxima conta.

**Uma partição física tem teto de armazenamento e de vazão**, documentado como 50 GB e 10.000 request
units por segundo, a unidade de que a lição 13 trata. A vazão que um contêiner recebe é dividida por
igual entre as partições físicas dele. Essa é a aritmética por trás da palavra que todo mundo no Cosmos
DB aprende a temer:

**Uma partição quente é uma partição lógica que recebe mais carga do que a partição física dela
consegue dar.** Um contêiner com 40.000 request units por segundo em quatro partições físicas dá 10.000
a cada uma. Se metade de todas as escritas vai para um valor de chave, todas caem numa partição física,
essa partição se esgota em 10.000 enquanto as outras três ficam paradas, e as requisições acima da
parte dela são recusadas e tentadas de novo. O contêiner parece subutilizado na média e sofre
throttling na prática. Nada na fatura nem na média do portal diz por quê; a chave diz.

## O que uma boa chave faz

O conselho da documentação se resume a três propriedades, e a seção depois da próxima as mede para a
Quitanda:

- **muitos valores distintos**, para que o hash tenha o que espalhar e nenhuma partição lógica se
  aproxime de 20 GB;
- **uma distribuição uniforme da carga**, leituras e escritas, entre esses valores a cada momento, não
  só ao longo do ano;
- **o valor que a consulta mais comum já nomeia**, para que essa consulta seja respondida por uma
  partição e não por todas.

A próxima seção mostra a terceira propriedade por dentro: o que uma leitura custa quando nomeia a
chave, e o que custa quando não nomeia.
