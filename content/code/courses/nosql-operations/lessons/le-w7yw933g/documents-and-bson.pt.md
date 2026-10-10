---
title: Documentos, e os tipos que o JSON não tem
version: 1
---

Esta aula precisa de um contêiner, `mongo`, da aula 1. Se ele só está parado, `docker start mongo`
o traz de volta com os dados. Se você o removeu, estas duas linhas o criam de novo; a primeira
responde que a rede já existe, se ela existir, e isso não faz mal nenhum:

```sh
docker network create nosql
docker run -d --name mongo --network nosql mongo:8.0
```

Toda sessão desta aula abre o cliente do mesmo jeito, com o nome do banco no final:
`docker exec -it mongo mongosh --quiet shop`. Nada precisa ser criado antes. A primeira escrita
numa coleção de `shop` cria a coleção e o banco, e a próxima seção mostra quanto esse hábito custa.

## Um documento parece JSON e não é

O mongosh imprime documentos em algo próximo da sintaxe de objetos do JavaScript, e os drivers os
entregam aos programas como mapas e dicionários, então a leitura óbvia é que **o MongoDB guarda
JSON**. Ele guarda **BSON**, uma codificação binária da mesma forma com mais tipos que o JSON. O
JSON conhece strings, números, booleanos, null, arrays e objetos. O BSON acrescenta uma data, um
inteiro de 32 e um de 64 bits ao lado do double, um decimal de 128 bits, dados binários e o
`ObjectId`, entre outros. O tipo é guardado junto com cada valor, em cada documento, então dois
documentos da mesma coleção podem ter o mesmo campo com tipos diferentes, e é para lá que vai a
terceira seção desta aula.

Peça ao servidor o tipo de cada campo de um documento criado na hora. `$documents` alimenta um
pipeline com uma lista literal em vez de uma coleção, e `$type` diz o que cada valor virou:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> ObjectId()
ObjectId('6ac9ed4939db61f1c1336db1')
shop> ObjectId()
ObjectId('6ac9ed4a39db61f1c1336db2')
shop> ObjectId().getTimestamp()
ISODate('2026-10-10T07:46:19.000Z')
shop> new Date("2026-03-14T10:30:00-03:00")
ISODate('2026-03-14T13:30:00.000Z')
shop> db.aggregate([
|   { $documents: [{ n: 12, x: 12.5, big: 12345678901, price: NumberDecimal("349.90"), when: new Date(), id: ObjectId() }] },
|   { $project: { n: { $type: "$n" }, x: { $type: "$x" }, big: { $type: "$big" }, price: { $type: "$price" }, when: { $type: "$when" }, id: { $type: "$id" } } }
| ])
[
  {
    n: 'int',
    x: 'double',
    big: 'double',
    price: 'decimal',
    when: 'date',
    id: 'objectId'
  }
]
shop> exit
```

Leia a última resposta primeiro. **`12` chegou como `int` e `12.5` como `double`**, porque o
mongosh envia um número inteiro que cabe em 32 bits como inteiro e todo o resto como double.
`12345678901` não cabe em 32 bits, e o mongosh não o promoveu a inteiro de 64 bits: ele é um
double, que só guarda números inteiros com exatidão até 2^53. Um contador que precisa continuar
inteiro depois de dois bilhões é escrito `NumberLong("12345678901")`. O driver da sua aplicação tem
as próprias regras para a mesma pergunta, e vale lê-las uma vez para a linguagem que você usa.

## O ObjectId, e o relógio dentro dele

Quando um documento chega sem `_id`, o cliente lhe dá um `ObjectId`: doze bytes, impressos como 24
dígitos hexadecimais. Os dois do começo da sessão acima foram gerados um depois do outro, e são
quase a mesma string:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Os doze bytes de um ObjectId, em três grupos. Os quatro primeiros são um carimbo de tempo em segundos desde 1970; os cinco seguintes são um valor aleatório escolhido uma vez por processo; os três últimos são um contador que sobe um a cada id que o processo gera. Dois ids gerados um depois do outro aparecem abaixo dos grupos: compartilham a parte aleatória, os carimbos de tempo diferem em um segundo e os contadores diferem em um.\"><rect x=\"40\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"92\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"144\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"196\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"40\" y=\"40\" width=\"208\" height=\"30\" rx=\"0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"144.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">4 bytes</text><text x=\"144.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">carimbo de tempo</text><text x=\"144.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">segundos desde 1970</text><rect x=\"248\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"300\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"352\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"404\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"456\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"248\" y=\"40\" width=\"260\" height=\"30\" rx=\"0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"378.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 bytes</text><text x=\"378.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">valor aleatório</text><text x=\"378.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">escolhido uma vez por processo</text><rect x=\"508\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"560\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"612\" y=\"40\" width=\"52\" height=\"30\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"508\" y=\"40\" width=\"156\" height=\"30\" rx=\"0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"586.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">3 bytes</text><text x=\"586.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">contador</text><text x=\"586.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">+1 a cada id</text><rect x=\"44\" y=\"137\" width=\"200\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"144.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6ac9ed49</text><rect x=\"252\" y=\"137\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">39db61f1c1</text><rect x=\"512\" y=\"137\" width=\"148\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"586.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">336db1</text><rect x=\"44\" y=\"177\" width=\"200\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"144.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">6ac9ed4a</text><rect x=\"252\" y=\"177\" width=\"252\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"378.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">39db61f1c1</text><rect x=\"512\" y=\"177\" width=\"148\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"586.0\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">336db2</text><text x=\"352\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">em destaque: o que mudou de um para o outro</text></svg>", "caption": "Um ObjectId tem doze bytes, e os quatro primeiros são um relógio. Dois ids do mesmo mongosh, gerados com um segundo de diferença, só diferem onde ficam o tempo e o contador.", "same": ["4 bytes", "5 bytes", "3 bytes"]}
```

**Os quatro primeiros bytes são o momento em que o id foi gerado, em segundos**, e
`getTimestamp()` os lê de volta: `2026-10-10T07:46:19` era o relógio do laboratório naquele
instante. Daí saem três consequências, e cada uma surpreende alguém:

- Ordenar por `_id` ordena mais ou menos pela hora de criação, até o segundo, e só na medida em que
  os relógios das máquinas que geraram os ids concordam. Dentro de um mesmo segundo, quem decide é o
  contador.
- Quem vê um id sabe quando o documento foi criado. **Um ObjectId não é segredo**: numa URL ele
  conta a um estranho quando cada cliente se cadastrou, e o contador torna fácil adivinhar os ids
  vizinhos. Um link que não pode ser adivinhado leva um token aleatório próprio.
- O id é gerado pelo cliente, não pelo servidor, e é por isso que ele existe antes de o insert ser
  confirmado e que um insert repetido do mesmo documento colide consigo mesmo.

`_id` não precisa ser um ObjectId. Qualquer valor único na coleção serve, e a próxima seção dá a
cada produto o seu SKU como `_id`, porque essa é a chave que todos os outros documentos vão usar
para se referir a ele.

## Uma data é um instante, não uma hora do dia

A data do BSON é uma contagem de milissegundos desde 1970 em UTC, sem fuso horário guardado ao
lado. A sessão acima digitou dez e meia em São Paulo, `-03:00`, e o servidor guardou
`2026-03-14T13:30:00.000Z`: o mesmo instante, escrito em UTC. Converter de volta para a hora local
é trabalho de quem lê, toda vez, e a aula 8 faz isso quando agrupa pedidos por mês. Uma data
guardada como a string `"14/03/2026"` ordena como texto e compara como texto, o que nesse formato
põe abril antes de março.

## Dinheiro, e as duas respostas para três teclados

O teclado custa 349,90. Três deles, calculados como doubles, do jeito que o JavaScript e a maioria
das linguagens calculam por padrão:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet shop
shop> 0.1 + 0.2
0.30000000000000004
shop> 349.90 * 3
1049.6999999999998
shop> db.aggregate([
|   { $documents: [{ double: 349.90, decimal: NumberDecimal("349.90") }] },
|   { $project: { double: { $multiply: ["$double", 3] }, decimal: { $multiply: ["$decimal", 3] } } }
| ])
[ { double: 1049.6999999999998, decimal: Decimal128('1049.70') } ]
shop> NumberDecimal(349.90 * 3)
Warning: NumberDecimal: specifying a number as argument is deprecated and may lead to loss of precision, pass a string instead
Decimal128('1049.6999999999998')
shop> exit
```

**O double erra no décimo quarto dígito, e o double do servidor erra no mesmo lugar**, porque não
é bug de nenhum dos dois: 349,90 não tem representação binária exata, assim como um terço não tem
representação decimal exata. O `Decimal128` guarda os dígitos em base dez e dá `1049.70`, o número
da nota fiscal.

A última linha é a armadilha que sobra. `NumberDecimal(349.90 * 3)` calculou o double primeiro e
depois fez um decimal da resposta errada, e o mongosh avisou. **Um decimal se constrói a partir de
uma string**, `NumberDecimal("349.90")`, ou herda o erro que deveria evitar. `sql-databases` guarda
os preços da mesma loja em `numeric(10,2)`, também um tipo decimal. A outra escolha sensata são
centavos inteiros, `34990`; o que não é escolha é um preço guardado como double.
