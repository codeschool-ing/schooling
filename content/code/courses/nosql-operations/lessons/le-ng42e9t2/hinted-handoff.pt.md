---
title: Hinted handoff, a escrita guardada para um nó que está fora
version: 1
---

A aula 17 parou um nó e gravou em `QUORUM`, e a escrita deu certo com duas réplicas de três. A
pergunta óbvia é o que acontece com a terceira cópia. **O Cassandra não a esquece: o coordenador guarda
a escrita, como um hint, e a entrega quando o nó volta.** Esse é o primeiro de três mecanismos que
trazem as réplicas de volta a um acordo, e o mais barato.

Esta aula usa os três nós da aula 16 com o keyspace da aula 17 em três cópias e a tabela `stock` dela,
com os quatro produtos. Se você remontou o cluster, as aulas 16 e 17 têm os comandos; quaisquer quatro
linhas em `stock` servem.

## Antes de qualquer falha

```
ana@vm:~$ docker exec c1 nodetool statushandoff
Hinted handoff is running
ana@vm:~$ docker exec c1 nodetool getmaxhintwindow
Current max hint window: 10800000 ms
```

O hinted handoff vem ligado por padrão, e o `max_hint_window` é `10800000` ms, **três horas**: um
coordenador guarda hints para um nó durante as primeiras três horas em que ele está fora. Depois disso
para de guardar, e um nó que volta mais tarde precisa ser atualizado pelo repair.

## Um nó fora, duas escritas

```
ana@vm:~$ docker stop c3
c3
ana@vm:~$ docker exec -it c1 cqlsh
Connected to lab at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> CONSISTENCY QUORUM
Consistency level set to QUORUM.
cqlsh> UPDATE shop.stock SET units = 11 WHERE sku = 'MS-204';
cqlsh> UPDATE shop.stock SET units = 39 WHERE sku = 'CB-012';
cqlsh> exit
ana@vm:~$ docker exec c1 ls -l /var/lib/cassandra/hints
total 4
-rw-r--r-- 1 cassandra cassandra 188 Oct 10 20:22 1fe37605-9cd6-4057-a79a-381f1eefc367-1791663760093-2.hints
ana@vm:~$ docker exec c1 nodetool listpendinghints
This node does not have any pending hints
ana@vm:~$ docker exec c1 nodetool status shop | grep -E "^(UN|DN)"
UN  172.18.0.3  85.08 KiB   16      100.0%            c91ac31c-cf75-4667-8186-4bce70e70e37  rack1
UN  172.18.0.2  108.01 KiB  16      100.0%            d2afca73-800d-4bc6-8139-86a18d5f752d  rack1
DN  172.18.0.4  119.66 KiB  16      100.0%            1fe37605-9cd6-4057-a79a-381f1eefc367  rack1
```

Duas escritas em `QUORUM` com o `c3` parado, as duas confirmadas pelo `c1` e pelo `c2`. **O diretório
de hints do `c1` agora tem um arquivo**, e o nome dele começa com `1fe37605-9cd6-…`, que é o host ID
que o `nodetool status` mostra para o nó `DN`, o `c3`. Cada nó mantém uma série de arquivos de hint
por nó para o qual está guardando escritas, e esses 188 bytes são os dois updates.

O `nodetool listpendinghints` respondeu que não havia nenhum, enquanto o arquivo estava no diretório.
Ele não relatou nada pendente durante toda esta execução; **o diretório é a testemunha mais
confiável**, e os nomes dos arquivos de hint dizem para quem são. Vale saber disso antes de um
incidente, quando uma ferramenta que diz "nada" é fácil de acreditar.

## O nó volta

```
ana@vm:~$ docker start c3
c3
ana@vm:~$ until docker exec c3 cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
ana@vm:~$ docker logs c1 2>&1 | grep -E "Finished hinted handoff|Deleted hint file"
INFO  [HintsDispatcher:1] 2026-10-10T20:23:10,502 HintsStore.java:232 - Deleted hint file 1fe37605-9cd6-4057-a79a-381f1eefc367-1791663760093-2.hints
INFO  [HintsDispatcher:1] 2026-10-10T20:23:10,503 HintsDispatchExecutor.java:300 - Finished hinted handoff of file 1fe37605-9cd6-4057-a79a-381f1eefc367-1791663760093-2.hints to endpoint /172.18.0.4:7000: 1fe37605-9cd6-4057-a79a-381f1eefc367
ana@vm:~$ docker exec c1 ls -l /var/lib/cassandra/hints
total 0
```

Assim que o `c3` passou a responder, o log do `c1` mostra **`Finished hinted handoff of file … to
endpoint /172.18.0.4:7000`** e o arquivo apagado, e o diretório está vazio de novo. O `c3` agora tem os
dois updates que perdeu, sem ninguém rodar nada.

## O que os hints não cobrem

Hints são uma conveniência, não uma garantia, e quatro limites dizem por quê:

- **A janela.** Um nó fora por mais que `max_hint_window` não recebe hints do tempo depois dela.
- **O coordenador.** Os hints moram no nó que coordenou a escrita. Se esse nó também se perder, os
  hints dele vão junto.
- **Desligado.** `nodetool disablehandoff`, como a aula 18 usou, ou `hinted_handoff_enabled: false` no
  `cassandra.yaml`, quer dizer que nenhum é guardado.
- **Uma réplica lenta que não está fora.** Uma réplica de pé que descarta uma escrita sob carga não é
  marcada como fora, então não recebe hint dessa escrita.

Cada um deixa uma réplica para trás sem ninguém planejando avisá-la. As duas próximas seções são os
mecanismos que acham essas diferenças: um por acaso, durante uma leitura, e um de propósito.
