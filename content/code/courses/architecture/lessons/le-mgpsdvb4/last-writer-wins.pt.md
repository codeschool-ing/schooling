---
title: O último a escrever vence, e a escrita que some
version: 1
---

O estoque tem um dono, então as mudanças dele têm uma ordem. Alguns dados não têm um dono só. A cesta de
um cliente pode ser mudada pelo celular e pelo notebook ao mesmo tempo, por duas cópias da loja, e se
cada cópia aceita a mudança e avisa a outra depois, as duas cópias receberam cada uma uma escrita que a
outra não viu. A aula 8 chamou isso de canto AP: os dois lados continuam respondendo, e as cópias têm de
ser reconciliadas depois.

As lojas do laboratório fazem exatamente isso com as cestas. Cada uma publica a cesta inteira quando ela
muda, carimbada com o próprio relógio, e com `MERGE=lww` uma loja fica com a cesta que **mudou por
último**. A ana põe chá pela loja `a`, e café pela loja `b` um instante depois:

```
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8002/basket/ana/tea; curl -s -X PUT localhost:8003/basket/ana/coffee
shop-a: basket ana = tea
shop-b: basket ana = coffee
ana@vm:~/lab/eventual$ sleep 5; curl -s localhost:8002/basket/ana; curl -s localhost:8003/basket/ana
shop-a: basket ana = coffee
shop-b: basket ana = coffee
```

As duas cópias concordam, e **o chá sumiu**. Nenhum erro, nenhuma linha de log dizendo que uma escrita
foi descartada: a loja `a` recebeu uma cesta com carimbo mais recente e substituiu a sua. Isso é o
**último a escrever vence** (*last writer wins*), e é o padrão em mais lugares do que se imagina: o
Cassandra resolve assim escritas concorrentes numa coluna, e as tabelas globais do DynamoDB também, no seu modo
usual eventualmente consistente, entre regiões.

É uma boa regra quando a escrita mais recente de fato substitui a anterior: o endereço de entrega de um
cliente, a foto do perfil. Perde dados sempre que as duas escritas **eram para valer**. E "último" é
decidido por relógios em máquinas diferentes, que se afastam; em dois servidores de verdade, a mudança
feita em segundo lugar pode carregar o carimbo mais antigo e perder.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A cesta da ana em duas lojas ao mesmo tempo. A loja a põe chá; a loja b, uma fração de segundo depois, põe café. Cada uma publica a cesta inteira com um carimbo de tempo. Com o último a escrever vence, as duas terminam só com café, porque o carimbo do café é mais tarde, e o chá some sem erro. Com união, as duas terminam com café e chá, mas um item tirado numa loja volta da próxima vez que a outra publica.\"><defs><marker id=\"l9-lww-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"30\" width=\"280\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">loja a: + chá  (10:00:00.1)</text><rect x=\"400\" y=\"30\" width=\"280\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">loja b: + café  (10:00:00.3)</text><path d=\"M180 76 L180 146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-lww-ah-wire)\"></path><path d=\"M540 76 L540 146\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-lww-ah-wire)\"></path><path d=\"M322 52 L398 52\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-lww-ah-wire)\" marker-start=\"url(#l9-lww-ah-wire)\"></path><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada uma publica a cesta inteira</text><text x=\"40\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">último a escrever vence</text><rect x=\"40\" y=\"148\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a: café</text><rect x=\"400\" y=\"148\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">b: café</text><text x=\"40\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">união</text><rect x=\"40\" y=\"226\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a: café, chá</text><rect x=\"400\" y=\"226\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">b: café, chá</text><text x=\"360\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">chá perdido</text></svg>", "caption": "Duas escritas que não se viram. O último a escrever vence fica com uma e descarta a outra; a união fica com as duas e não distingue uma remoção de um item que o outro lado nunca teve."}
```

## Ficando com as duas

Para uma cesta, o jeito natural de juntar é ficar com todo item que qualquer uma das cópias tem. Isso é
`MERGE=union`:

```
ana@vm:~/lab/eventual$ MERGE=union CHECK_VERSION=1 docker compose up -d
 Container eventual-rabbitmq-1 Running 
 Container eventual-stock-1 Running 
 Container eventual-shop-a-1 Recreate 
 Container eventual-shop-b-1 Recreate 
 Container eventual-shop-b-1 Recreated 
 Container eventual-shop-a-1 Recreated 
 Container eventual-shop-b-1 Starting 
 Container eventual-shop-a-1 Starting 
 Container eventual-shop-b-1 Started 
 Container eventual-shop-a-1 Started 
ana@vm:~/lab/eventual$ curl -s -X PUT localhost:8002/basket/ana/tea; curl -s -X PUT localhost:8003/basket/ana/coffee
shop-a: basket ana = tea
shop-b: basket ana = coffee
ana@vm:~/lab/eventual$ sleep 5; curl -s localhost:8002/basket/ana; curl -s localhost:8003/basket/ana
shop-a: basket ana = coffee, tea
shop-b: basket ana = coffee, tea
```

As duas escritas sobreviveram. Agora tire o chá pela loja `a`, e ponha pão pela loja `b` meio segundo
depois, antes de a `b` ficar sabendo da remoção:

```
ana@vm:~/lab/eventual$ curl -s -X DELETE localhost:8002/basket/ana/tea; sleep 0.5; curl -s -X PUT localhost:8003/basket/ana/bread
shop-a: basket ana = coffee
shop-b: basket ana = bread, coffee, tea
ana@vm:~/lab/eventual$ sleep 5; curl -s localhost:8002/basket/ana; curl -s localhost:8003/basket/ana
shop-a: basket ana = bread, coffee, tea
shop-b: basket ana = bread, coffee, tea
```

**O chá voltou.** A loja `b` ainda o tinha quando publicou, e uma união não distingue "a o tirou" de "b
nunca o teve". Esse é o "item que ele tirou reaparece" da tabela da aula 8, e é o que o próprio artigo da
Amazon sobre o Dynamo, em 2007, relatou para o seu carrinho de compras: itens apagados podiam
ressurgir, o que eles julgaram melhor do que um item adicionado e perdido.

## As saídas

| abordagem | o que faz | onde é usada |
| --- | --- | --- |
| o último a escrever vence | fica com uma escrita, descarta as outras | Cassandra, tabelas globais do DynamoDB; dados em que o valor novo substitui o velho |
| juntar por união | fica com tudo; remoções podem voltar | o carrinho de compras do Dynamo |
| guardar as duas e perguntar | guarda toda versão concorrente e as entrega à aplicação para juntar | os *siblings* do Riak; o código que lê tem de ser escrito para isso |
| um CRDT | um tipo de dado cuja junção está sempre certa para o seu tipo: um conjunto que registra remoções com uma marca, um contador por nó | os tipos de dados do Riak, o Redis Enterprise entre regiões, editores colaborativos |
| um dono, afinal | mandar toda mudança de uma cesta para um lugar só | a maioria das lojas; de longe o mais simples |

A última linha é a resposta honesta para a maioria dos sistemas. **Escritas concorrentes na mesma coisa
são um custo que você escolhe pagar**, e o jeito mais barato de não pagá-lo é dar a cada coisa um dono,
para as mudanças dela terem uma ordem, e deixar as cópias para leitura. Projetos com vários escritores
justificam a complexidade onde os escritores realmente não alcançam um lugar só: várias regiões que
precisam continuar aceitando escritas quando o link entre elas cai, ou aparelhos que funcionam offline.
