---
title: Janelas por chave
version: 1
---

**Na prática uma janela quase nunca é sobre o stream inteiro: ela é por chave**, então cada loja,
cliente ou livro tem o próprio conjunto de janelas. "Vendas a cada cinco minutos" é um painel que
ninguém lê; "vendas a cada cinco minutos por loja" é o que o gerente regional abre.

Janelas por chave são a mesma regra aplicada separadamente dentro de cada chave. Uma janela tumbling
por loja tem as mesmas bordas para todas as lojas, porque as bordas vêm do relógio:

```
ubuntu@stream:~/work$ python windows.py tumbling 5 --by-shop
window               sales   cents
caruaru
09:10:00-09:15:00      1    6200
natal
09:00:00-09:05:00      1    5490
09:05:00-09:10:00      2   13480
olinda
09:00:00-09:05:00      1    2990
09:10:00-09:15:00      1    2990
recife
09:00:00-09:05:00      1    3990
09:05:00-09:10:00      1    7900
09:10:00-09:15:00      1    3500
09:20:00-09:25:00      1    5490
```

As dez vendas agora se espalham por nove linhas. Recife tem venda em quatro janelas diferentes e
Caruaru em uma. A janela das 09:05 às 09:10 de Natal tem duas vendas, a 5 e a 8, e é a única com mais
de uma; a venda atrasada 8 caiu na janela de Natal e na de mais ninguém. **O total sobre todas as
chaves continua dez**, porque janelas tumbling não se sobrepõem, com chave ou sem.

Para sessões a chave muda mais a resposta, porque uma sessão por loja é feita só das vendas daquela
loja:

```
ubuntu@stream:~/work$ python windows.py session 5 --by-shop
window               sales   cents
caruaru
09:12:30-09:12:30      1    6200
natal
09:02:10-09:08:50      3   18970
olinda
09:03:55-09:03:55      1    2990
09:14:10-09:14:10      1    2990
recife
09:00:40-09:05:00      2   11890
09:13:05-09:13:05      1    3500
09:21:00-09:21:00      1    5490
```

Sete sessões em vez de duas, e nenhuma fusão. A venda 8 juntou duas sessões do stream inteiro, mas
dentro de Natal ela é simplesmente a terceira de três vendas a menos de cinco minutos uma da outra.
As duas primeiras vendas de Recife, 09:00:40 e 09:05:00, estão a 4 minutos e 20 segundos e dividem uma
sessão; a venda das 09:13:05 vem oito minutos depois e começa outra. Uma sessão por chave é o que "uma
visita" realmente quer dizer, já que a visita de um cliente não diz nada sobre a de outro.

## De onde vem a chave

O Kafka já tem a resposta. As vendas são produzidas com a loja como chave, o que a lição 3 mostrou
mandar todas as vendas de uma loja para a mesma partição. É isso que torna barato rodar janelas por
chave em paralelo: **todos os eventos de uma chave estão numa partição, então um trabalhador guarda
todas as janelas daquela chave**, e nenhum outro trabalhador precisa vê-las. Uma janela por algo que
não é a chave da mensagem, livros por exemplo quando as vendas têm a loja como chave, precisa antes
que o stream seja reordenado pela nova chave. O Kafka Streams faz isso com um tópico de
reparticionamento, que a lição 13 lista entre os tópicos que uma aplicação cria para si mesma.

## O estado que ela guarda

Cada janela aberta por chave é estado que o motor guarda até a janela terminar. Cinco lojas e janelas
de cinco minutos são um punhado de contadores. Um milhão de clientes com sessões de trinta minutos é
um milhão de entradas. É por isso que os motores põem o estado das janelas num armazenamento
embutido em disco em vez de na memória, e por isso que a lição 13 dedica uma seção a onde esse estado
fica quando um trabalhador morre. O número a estimar antes de escolher uma janela é **chaves × janelas
abertas por chave**, e os dois fatores vêm das escolhas desta lição.
