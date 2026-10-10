---
title: Quem recebe as escritas
version: 1
---

Todo sistema replicado tem de responder uma pergunta: **quando as cópias mudam, qual cópia muda
primeiro?** Há três respostas, e todo banco que você vai usar escolhe uma delas.

| arranjo | como funcionam as escritas | exemplos | o que custa |
| --- | --- | --- | --- |
| **líder único** | uma cópia, o líder ou primário, recebe toda escrita e a transmite aos seguidores | PostgreSQL, MySQL, MongoDB, cada partição do Kafka | o líder é um limite de escritas; quando ele falha, um seguidor tem de ser promovido |
| **vários líderes** | várias cópias recebem escritas, em geral uma por região, e as trocam | MySQL e PostgreSQL com extensões, CouchDB, tabelas globais do DynamoDB | dois líderes podem mudar a mesma linha ao mesmo tempo, e os conflitos da aula 9 vêm atrás |
| **sem líder** | o cliente escreve em várias cópias e lê de várias, com quóruns | Cassandra, ScyllaDB, o Dynamo original | os quóruns da aula 8, e cópias que são reparadas em segundo plano |

**Líder único é o padrão**, e o resto desta aula o usa. O momento fraco dele é o failover, quando o
líder morre e um seguidor assume. Duas coisas podem dar errado ali. Um seguidor que estava atrasado vira
líder, e as escritas que ele não tinha recebido se perdem, o que a aula 8 mostrou ser o atraso de
replicação no momento da falha. Ou o líder antigo não estava morto, só inalcançável, e agora há dois
líderes recebendo escritas: **split brain**, a falha que o raciocínio do resto da aula sobre "três nós"
existe para impedir.

## Síncrono, assíncrono, e o meio

A aula 8 comparou um standby síncrono, em que o commit espera a cópia, com um assíncrono, em que não
espera. Sistemas em produção ficam, na maioria, no meio. O PostgreSQL pode esperar **qualquer um entre
vários** standbys (`synchronous_standby_names = 'ANY 1 (s1, s2)'`), então um standby lento ou morto não
para as escritas. O Kafka espera um número de **réplicas em dia** (*in-sync replicas*), que o cluster
mais adiante nesta aula mostra. Os dois mantêm uma propriedade: uma escrita confirmada existe em pelo
menos duas máquinas.
