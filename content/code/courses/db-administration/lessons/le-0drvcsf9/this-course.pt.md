---
title: O que as vinte e quatro lições cobrem, e o que deixam para outros
version: 1
---

O curso segue a ordem em que alguém aprende o ofício, e as lições são estreitas de propósito: cada
uma é uma tarefa num servidor de verdade. Lidas em sequência, elas ficam perto de um runbook.

| lições | o que você faz |
|---|---|
| 1 e 2 | entende o trabalho e os quatro motores que vai encontrar; nada para digitar |
| 3 e 4 | monta o seu servidor, carrega o banco do curso e acha os arquivos dele |
| 5 a 10 | configura: o arquivo de configuração, a memória, o write-ahead log, os checkpoints, o disco, as conexões |
| 11 a 13 | decide quem pode fazer o quê: papéis, grants e privilégios padrão |
| 14 a 19 | mantém saudável: autovacuum, bloat, estatísticas, reconstrução de índices, extensões e logs |
| 20 a 23 | muda com segurança: upgrades, troca de motor, mudança numa tabela viva, configuração como código |
| 24 | anota o que fez |

**Da lição 3 em diante, tudo é feito num servidor seu**: uma máquina virtual com Ubuntu e
PostgreSQL 16, montada naquela lição. A plataforma não fornece um, e o curso nunca precisa de nada
que você mesmo não tenha instalado. Você vai precisar de um computador que rode uma máquina virtual
com 4 GB de memória, e a lição 3 diz o que fazer se o seu não rodar.

## O que este curso pressupõe

`sql-databases`, para o SQL em si — tabelas, joins, transações e o que é um índice —, e
`linux-terminal`, para o shell: arquivos e permissões, `sudo`, serviços e `systemd`, pacotes com
`apt`. Os dois são necessários, e este curso não ensina nenhum deles de novo.

## O que deixa para os cursos seguintes

Três cursos se apoiam neste, e cada um é dono de um assunto que este só nomeia:

- **`db-performance`** é dono de deixar consultas rápidas: ler planos de execução em detalhe, os tipos
  de índice, travas e quem bloqueia quem, isolamento sob carga real, pooling de conexões e
  particionamento. Quando uma lição daqui encontra um desses, ela aponta a lição de lá.
- **`db-reliability`** é dono de sobreviver a falhas: backups e restaurações, arquivamento do
  write-ahead log, recuperação a um ponto no tempo, replicação, failover e incidentes.
- **`nosql-operations`** leva as mesmas perguntas operacionais para MongoDB, Redis e Cassandra.

Tudo em que os três se apoiam — onde ficam os arquivos, o que um ajuste faz, para que servem o vacuum
e as estatísticas, quem pode conectar — está aqui.
