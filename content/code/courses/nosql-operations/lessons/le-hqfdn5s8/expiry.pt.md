---
title: Expiração, e quando uma chave expirada sai de verdade
version: 1
---

O despejo remove chaves porque a memória encheu. A expiração as remove porque o tempo delas acabou,
qualquer que seja a memória, e as duas se confundem com facilidade porque ambas apagam chaves que
ninguém pediu para apagar. **Uma chave expirada não sai da memória no segundo em que expira.** O Redis a
remove de um de dois jeitos, e até um deles acontecer a chave ainda ocupa memória, e o `DBSIZE` ainda a
conta.

## O que o `TTL` responde

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> CONFIG SET maxmemory 0
OK
127.0.0.1:6379> FLUSHALL
OK
127.0.0.1:6379> SET cart:ana KB-101 EX 600
OK
127.0.0.1:6379> TTL cart:ana
(integer) 600
127.0.0.1:6379> SET product:KB-101 34990
OK
127.0.0.1:6379> TTL product:KB-101
(integer) -1
127.0.0.1:6379> TTL cart:nobody
(integer) -2
127.0.0.1:6379> EXPIRE cart:nobody 600
(integer) 0
127.0.0.1:6379> PERSIST cart:ana
(integer) 1
127.0.0.1:6379> TTL cart:ana
(integer) -1
```

O `TTL` responde os segundos que faltam, **`-1` para uma chave que existe sem expiração, e `-2` para
uma chave que nem existe.** Um código que trata qualquer resposta negativa como "sem expiração"
confunde uma chave ausente com uma permanente. O `EXPIRE` numa chave ausente responde `0` e não cria
nada. O `PERSIST` remove uma expiração, transformando uma chave de cache de novo numa que vive para
sempre, o que sob uma política `volatile-` também a torna impossível de despejar.

## Expiração preguiçosa e ativa

O Redis remove uma chave expirada de forma **preguiçosa**, quando um comando a toca: a chave é
conferida, achada expirada, apagada, e o comando responde como se ela nunca tivesse existido. E remove
chaves de forma **ativa**: dez vezes por segundo, amostra chaves que têm expiração e apaga as expiradas
que encontra, repetindo enquanto continuar achando muitas. Duzentas mil sessões, cada uma com um segundo
de vida, mostram as duas:

```
ana@vm:~$ docker exec redis redis-cli CONFIG RESETSTAT
OK
ana@vm:~$ docker exec redis redis-cli EVAL "for i = 1, 200000 do redis.call('SET', 'session:' .. i, 'x', 'EX', 1) end return redis.call('DBSIZE')" 0
200002
ana@vm:~$ for i in 1 2 3 4 5; do sleep 0.5; echo "$(docker exec redis redis-cli DBSIZE) keys, $(docker exec redis redis-cli INFO stats | grep ^expired_keys | tr -d "\r")"; done
152398 keys, expired_keys:65924
25505 keys, expired_keys:193771
2 keys, expired_keys:200000
2 keys, expired_keys:200000
2 keys, expired_keys:200000
```

O `EVAL` gravou 200.000 chaves com `EX 1`, o que levou um instante, então as primeiras chaves já estavam
perto de expirar quando as últimas foram gravadas. Meio segundo de cada vez, o `DBSIZE` caiu de 152.398 para 25.505 e depois para as 2 chaves sem
expiração, enquanto o `expired_keys` do `INFO stats` subia até 200.000. **A segunda linha foi tirada mais
de um segundo depois de o `EVAL` voltar**, quando toda sessão já tinha passado da expiração, e 25.505
delas continuavam contadas, e na memória, até o ciclo ativo chegar nelas. Um `GET` em qualquer uma delas
nesse meio-tempo teria respondido `(nil)` e a apagado na hora.

## Por que isso importa para quem opera

- **A memória fica atrás da expiração.** Uma rajada de chaves que expiram juntas é liberada ao longo dos
  segundos seguintes, não de uma vez, e sob um `maxmemory` apertado esse atraso pode levar a instância ao
  despejo ou a erros `OOM` enquanto a maior parte das chaves já está morta.
- **O ciclo ativo custa processador**, `expire_cycle_cpu_milliseconds` no `INFO stats`, e milhões de
  chaves expirando juntas tomam uma fatia visível de uma única thread que também atende todos os
  clientes. Espalhar as expirações, somando alguns segundos aleatórios a cada `EX`, evita o pico.
- **Uma réplica não expira chaves por conta própria.** Ela espera o primário mandar a remoção, para que
  todas as cópias concordem. Uma réplica responde a leitura de uma chave expirada como ausente mesmo
  assim, mas a memória dela só é liberada quando a remoção do primário chega.

`expired_keys` e `evicted_keys` são dois contadores diferentes por dois motivos diferentes, e a aula 20
vigia os dois: um cache cujo `evicted_keys` sobe é pequeno demais para o que guarda, enquanto o
`expired_keys` subindo é a expiração fazendo o seu trabalho.
