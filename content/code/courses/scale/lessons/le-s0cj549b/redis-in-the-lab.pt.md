---
title: Segurando um lugar no Redis
version: 1
---

O primeiro padrão de acesso da seção 03 era segurar um lugar por dez minutos enquanto o comprador
paga. No PostgreSQL seria uma linha com hora de expiração, uma consulta para pular as reservas
vencidas e uma tarefa para apagá-las, tudo no banco que já é o gargalo da bilheteria. Num
armazenamento chave-valor é um comando.

O Redis roda num contêiner próprio, separado da bilheteria. O `redis-cli`, o cliente dele, está
dentro da imagem, então todo comando passa pelo `docker exec`:

```
ana@lab:~/tickets$ docker run -d --name kv redis:7.4.11
7c8b67f5a3c9ce770a8ad4d1cd6676a78b2cdd2f6fffda28cca66735f703611f
ana@lab:~/tickets$ docker exec kv redis-cli PING
PONG
```

## Um comando, gravado só se não existir

A Ana começa a pagar o lugar 42 do show 1. A chave nomeia o lugar; o valor nomeia a compradora:

```
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw SET hold:show:1:seat:42 ana NX EX 600
OK
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw SET hold:show:1:seat:42 bia NX EX 600
(nil)
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw GET hold:show:1:seat:42
"ana"
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw TTL hold:show:1:seat:42
(integer) 600
```

`SET chave valor NX EX 600` quer dizer: grave esta chave **só se ela não existir** (`NX`), e faça-a
**expirar em 600 segundos** (`EX`). O comando da Ana respondeu `OK`. O da Bia, um instante depois,
respondeu `(nil)`: a chave existia, então nada foi gravado, e o programa da Bia sabe que o lugar
está tomado. `TTL` diz quantos segundos a reserva ainda tem.

Esse único comando é **atômico**. O Redis roda um comando de cada vez, então dois compradores
pedindo o mesmo lugar no mesmo milissegundo ainda recebem um `OK` e um `(nil)`, sem transação e sem
trava escrita por ninguém. **A verificação e a escrita são um passo só**, que é exatamente o que a
linha quente da aula 1 fazia com um `UPDATE`, sem segurar nada por sete milissegundos.

A opção `--no-raw` pede ao `redis-cli` que imprima `(nil)` e `(integer)` como faz num terminal
interativo; sem ela, um nil sai como uma linha vazia.

## Uma reserva que acaba

Se o comprador abandona o pagamento, a reserva precisa se liberar sozinha. Aqui com uma reserva de
dois segundos, para dar para assistir:

```
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw SET hold:show:1:seat:43 carla NX EX 2
OK
ana@lab:~/tickets$ sleep 3
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw GET hold:show:1:seat:43
(nil)
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw SET hold:show:1:seat:43 bia NX EX 600
OK
```

Três segundos depois a chave sumiu, e a reserva da Bia dá certo. **Nenhuma tarefa apagou nada**; a
expiração faz parte da chave.

## Contando

`INCR` soma um ao número sob uma chave, criando-a em zero se não existir, e responde o novo valor.
Ele é atômico pelo mesmo motivo que o `SET NX`:

```
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw INCR views:show:1
(integer) 1
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw INCR views:show:1
(integer) 2
ana@lab:~/tickets$ docker exec kv redis-cli --no-raw INCRBY views:show:1 10
(integer) 12
```

## Quão rápido

O Redis vem com o próprio benchmark. Cem mil `SET`s e cem mil `GET`s, depois o mesmo com dezesseis
comandos mandados por ida e volta (`-P 16`, *pipelining*):

```
ana@lab:~/tickets$ docker exec kv redis-benchmark --csv -t set,get -n 100000
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","110132.16","0.272","0.080","0.239","0.463","0.575","1.079"
"GET","97087.38","0.291","0.080","0.263","0.495","0.719","1.943"
ana@lab:~/tickets$ docker exec kv redis-benchmark --csv -t set,get -n 100000 -P 16
"test","rps","avg_latency_ms","min_latency_ms","p50_latency_ms","p95_latency_ms","p99_latency_ms","max_latency_ms"
"SET","735294.06","1.013","0.264","0.943","1.559","1.679","2.391"
"GET","1408450.62","0.494","0.176","0.479","0.663","0.727","1.007"
```

Cerca de **110 000 `SET`s e 97 000 `GET`s por segundo** um de cada vez, com mediana de um quarto de
milissegundo. Com pipelining, **735 000 e 1 408 000**: quase todo o custo de um comando era a ida e
volta até o servidor, e mandar dezesseis por viagem o dividiu por dezesseis. É a mesma lição da
linha do `app.py` da aula 1 que economiza 40 ms por pedido: **nessa velocidade o gargalo é a rede**,
e agrupar é o jeito de contorná-la.

Esses números não são comparáveis com o pgbench do PostgreSQL na aula 3, que rodava transações de
cinco comandos gravadas em disco. Eles medem trabalhos diferentes, e essa diferença é o ponto: o
Redis guarda tudo na memória e faz quase nada por comando.

## O que custa

O Redis guarda os dados na memória, então **o conjunto de dados precisa caber na memória**, e um
reinício perde o que não foi salvo. Ele consegue salvar retratos e um log de escritas em disco, com
algum custo; para reservas que expiram em dez minutos, perdê-las num reinício costuma ser aceitável,
e para a única cópia de uma venda nunca é. Remova o contêiner quando terminar:

```
ana@lab:~/tickets$ docker rm -f kv
kv
```
