---
title: Strings, contadores e uma chave que diz não
version: 1
---

O jeito mais comum de usar mal o Redis é tratá-lo como uma caixa de strings: ler um valor para a
aplicação, mudá-lo ali e gravá-lo de volta. **Cada estrutura desta aula existe para que a mudança
aconteça dentro do servidor**, num único comando que nada mais consegue interromper. Esta seção
mostra quanto custa o hábito da caixa de strings e, depois, as três coisas que uma string simples
faz bem: um contador, uma chave que se recusa a ser gravada duas vezes e uma chave que se apaga
sozinha.

Se você fez `servers-cache`, a aula 8 de lá pôs o Redis na frente de um servidor web, como cache.
Esta aula e as três seguintes o tratam como o banco de dados da loja, onde perder um valor é um
incidente, e não uma página mais lenta.

## O contêiner

Esta aula precisa só do contêiner `redis` da aula 1, e fica mais clara começando do zero. Remova o
antigo e suba um novo na mesma rede:

```
ana@vm:~$ docker rm -f redis
redis
ana@vm:~$ docker run -d --name redis --network nosql redis:7.4
194cfe171852b49e160160b99aa35766e36dc7582d7e259173dbec41cc983ea5
```

Todas as sessões abaixo são digitadas no `redis-cli` dentro desse contêiner. Não há mais nada a
instalar.

## Dois clientes, um contador

Dois workers contam 500 visualizações de página cada um. Cada um lê o contador, soma um no shell e
grava o resultado de volta, exatamente o que uma aplicação faz quando trata o Redis como uma caixa:

```
ana@vm:~$ docker exec redis redis-cli SET visits 0
OK
ana@vm:~$ for w in 1 2; do docker exec redis sh -c 'for i in $(seq 500); do v=$(redis-cli GET visits); redis-cli SET visits $((v+1)) >/dev/null; done' & done; wait
```

**Entraram 1.000 incrementos e saíram 554.** Os dois workers leram o mesmo valor, os dois somaram
um e os dois gravaram o mesmo número, então um dos dois incrementos sumiu. Nada acusou erro; as 446
visualizações simplesmente se foram. O Redis não fez nada de errado: executou cada `GET` e cada
`SET` na ordem em que chegaram, e a corrida estava entre eles, nos workers.

Os mesmos dois workers, pedindo ao Redis que faça a soma:

```
ana@vm:~$ docker exec redis redis-cli GET visits
554
ana@vm:~$ docker exec redis redis-cli SET visits 0
```

**O Redis executa um comando de cada vez, numa única thread**, então o `INCR` lê, soma e grava sem
que nada possa rodar no meio. É nessa propriedade que todas as estruturas desta aula se apoiam, e
é também por isso que um único comando lento trava todos os clientes ao mesmo tempo, assunto a que
a seção sobre sets volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 270\" role=\"img\" aria-label=\"Duas linhas do tempo lado a lado. À esquerda, o worker 1 e o worker 2 mandam GET ao Redis e os dois recebem 41; depois cada um manda SET 42, e o contador termina em 42 depois de dois incrementos, um deles perdido. À direita, cada worker manda INCR; o Redis responde 42 ao primeiro e 43 ao segundo, e o contador termina em 43.\"><defs><marker id=\"l12race-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12race-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l12race-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"170\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">ler, somar um, gravar de volta</text><text x=\"50\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 1</text><line x1=\"50\" y1=\"50\" x2=\"50\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Redis</text><line x1=\"170\" y1=\"50\" x2=\"170\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"290\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 2</text><line x1=\"290\" y1=\"50\" x2=\"290\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"50\" y1=\"62\" x2=\"168\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-phosphor)\"></line><text x=\"104.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET</text><line x1=\"170\" y1=\"80\" x2=\"52\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-paper-dim)\"></line><text x=\"104.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">41</text><line x1=\"290\" y1=\"100\" x2=\"172\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-phosphor)\"></line><text x=\"236.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">GET</text><line x1=\"170\" y1=\"118\" x2=\"288\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-paper-dim)\"></line><text x=\"236.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">41</text><line x1=\"50\" y1=\"145\" x2=\"168\" y2=\"153\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-amber)\"></line><text x=\"104.0\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SET 42</text><line x1=\"290\" y1=\"170\" x2=\"172\" y2=\"178\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-amber)\"></line><text x=\"236.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SET 42</text><text x=\"170\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">visits = 42: um incremento perdido</text><text x=\"530\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">INCR, dentro do servidor</text><text x=\"410\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 1</text><line x1=\"410\" y1=\"50\" x2=\"410\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"530\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Redis</text><line x1=\"530\" y1=\"50\" x2=\"530\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"650\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker 2</text><line x1=\"650\" y1=\"50\" x2=\"650\" y2=\"215\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><line x1=\"410\" y1=\"62\" x2=\"528\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-phosphor)\"></line><text x=\"464.0\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">INCR</text><line x1=\"530\" y1=\"80\" x2=\"412\" y2=\"88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-paper-dim)\"></line><text x=\"464.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">42</text><line x1=\"650\" y1=\"100\" x2=\"532\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-phosphor)\"></line><text x=\"596.0\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">INCR</text><line x1=\"530\" y1=\"118\" x2=\"648\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l12race-ah-paper-dim)\"></line><text x=\"596.0\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">43</text><text x=\"530\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">visits = 43: os dois contados</text><text x=\"170\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o contador começa em 41</text><text x=\"530\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o contador começa em 41</text></svg>", "caption": "Ler, somar, gravar de volta: os dois workers leem 41 e os dois gravam 42. Com INCR a soma acontece dentro do Redis, um comando de cada vez, e nenhum incremento se perde.", "same": ["Redis", "worker 1", "worker 2"]}
```

## Contadores para o estoque

Uma string que guarda um inteiro é um contador. O estoque de teclados da loja:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET stock:KB-101 12
OK
127.0.0.1:6379> DECR stock:KB-101
(integer) 11
127.0.0.1:6379> DECRBY stock:KB-101 3
(integer) 8
127.0.0.1:6379> GET stock:KB-101
"8"
127.0.0.1:6379> OBJECT ENCODING stock:KB-101
"int"
127.0.0.1:6379> SET greeting "hello from the lab"
OK
127.0.0.1:6379> INCR greeting
(error) ERR value is not an integer or out of range
```

`DECR` e `DECRBY` respondem com o novo valor, então a aplicação descobre o estoque que restou na
mesma ida e volta em que tirou uma unidade. O `OBJECT ENCODING` mostra que o Redis guardou `12` como
um inteiro de máquina, `int`, e não como dois caracteres. E um contador só conta números: `INCR`
numa string que não é inteira é recusado com erro, em vez de tentar adivinhar.

Um contador de estoque que pode ficar abaixo de zero é um bug esperando a última unidade. O `DECR`
não para no zero; a aplicação confere a resposta e devolve a unidade com `INCR`, ou faz a conferência
e o decremento juntos num pequeno script Lua, que o Redis também executa como um único comando.

## Uma chave que diz não: travas e idempotência

O `SET` aceita duas opções que o transformam numa pergunta. **`NX` grava só se a chave não existe, e
`EX` dá à chave um tempo de vida em segundos.** Juntas, elas fazem a menor trava útil: dois workers
querem processar o pedido 1001, e só um pode.

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET lock:order:1001 worker-a NX EX 30
OK
127.0.0.1:6379> SET lock:order:1001 worker-b NX EX 30
(nil)
127.0.0.1:6379> GET lock:order:1001
"worker-a"
127.0.0.1:6379> TTL lock:order:1001
(integer) 30
```

O `worker-a` recebeu `OK` e o `worker-b` recebeu `(nil)`, que é o Redis dizendo "não gravei". A trava
vive 30 segundos aconteça o que acontecer, então um worker que cai segurando a trava não a segura
para sempre.

Liberar a trava tem uma armadilha. Um `DEL` simples apaga a trava de quem quer que seja o dono, e um
worker que passou dos seus 30 segundos apagaria a trava que outro worker pegou depois que ela
expirou. Por isso a liberação confere o dono e apaga num passo só, em Lua:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> EVAL "if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('DEL', KEYS[1]) else return 0 end" 1 lock:order:1001 worker-b
(integer) 0
127.0.0.1:6379> EVAL "if redis.call('GET', KEYS[1]) == ARGV[1] then return redis.call('DEL', KEYS[1]) else return 0 end" 1 lock:order:1001 worker-a
(integer) 1
```

A liberação do `worker-b` não fez nada (`0`); a do `worker-a` apagou a chave (`1`). O script é um
comando só, então nenhum outro cliente consegue pegar a trava entre a conferência e a remoção.

O mesmo `SET … NX EX` é uma **chave de idempotência**. Um cliente que estoura o timeout tenta de
novo, e o serviço de pagamento recebe o mesmo pedido duas vezes. Ele registra que já cobrou o pedido
1001 e recusa a segunda tentativa:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET done:payment:1001 charged NX EX 86400
OK
127.0.0.1:6379> SET done:payment:1001 charged NX EX 86400
(nil)
```

A primeira chamada gravou a chave e a cobrança segue; a nova tentativa fica sabendo que a chave existe
e recebe o primeiro resultado, em vez de uma segunda cobrança. A chave expira depois de um dia,
quando nenhum cliente ainda está tentando de novo.

Os dois padrões dependem de um único Redis ser o juiz. **A aula 15 perde de propósito uma escrita
confirmada durante um failover**, e uma trava ou uma chave de idempotência é uma escrita como
qualquer outra: se a cópia que a guardava for a que a perde, dois workers podem acreditar, cada um,
que têm a trava.

## O tempo de vida é da chave, e o `SET` o joga fora

`EX` define um tempo de vida, e `TTL` lê quantos segundos faltam. A surpresa é o que um `SET` comum
faz com uma chave que já tem um:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> SET cart:ana KB-101 EX 600
OK
127.0.0.1:6379> TTL cart:ana
(integer) 600
127.0.0.1:6379> SET cart:ana MS-204
OK
127.0.0.1:6379> TTL cart:ana
(integer) -1
127.0.0.1:6379> SET cart:ana KB-101 EX 600
OK
127.0.0.1:6379> SET cart:ana MS-204 KEEPTTL
OK
127.0.0.1:6379> TTL cart:ana
(integer) 600
```

**Um `SET` simples trocou o valor e tirou a expiração**: o `TTL` respondeu `-1`, que quer dizer que a
chave agora vive até alguém apagá-la. Um carrinho que devia sumir depois de dez minutos parado agora
é permanente, e nada falhou. `KEEPTTL` mantém o tempo de vida antigo. A aula 14 trata da expiração
por inteiro: o que `-1` e `-2` querem dizer, e quando uma chave expirada sai mesmo da memória.
