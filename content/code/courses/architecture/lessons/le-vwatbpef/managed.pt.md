---
title: O que você compraria em vez disso
version: 1
---

Quase ninguém faz mais sharding à mão, como o laboratório fez. As opções ficam numa linha que vai de "o
banco que você conhece, com cópias" até "um banco feito para ser dividido":

| o quê | replicação | sharding | o que muda para a aplicação |
| --- | --- | --- | --- |
| PostgreSQL ou MySQL gerenciado (Amazon RDS, Cloud SQL, Azure Database) | réplicas de leitura e um standby, configurados com algumas opções | nenhum | nada; leituras das réplicas são eventualmente consistentes |
| Amazon Aurora, AlloyDB | armazenamento copiado entre zonas pelo provedor | nenhum para escritas | nada; um escritor, com failover muito rápido |
| Citus (extensão do PostgreSQL), Vitess (MySQL) | cada shard é um banco replicado | por uma chave que você escolhe por tabela | consultas que incluem a chave são rápidas; o resto funciona, e custa mais |
| CockroachDB, Google Spanner, YugabyteDB, TiDB | cada faixa de chaves é replicada com Raft | automático, por faixas que se dividem e se movem | SQL como antes; transações entre faixas são mais lentas e podem ser repetidas |
| MongoDB, Cassandra, DynamoDB | embutida | por uma chave de partição que você escolhe por coleção ou tabela | a chave decide que consultas são baratas, desde o primeiro dia |

Os bancos da quarta linha costumam ser chamados de **SQL distribuído**. Eles mantêm transações e SQL
entre shards rodando consenso para cada faixa de chaves, que é a regra da maioria desta aula aplicada
milhares de vezes, e pagam por isso em latência: uma escrita espera uma maioria, muitas vezes entre
zonas.

## Onde a Quitanda está

Um servidor PostgreSQL, com um standby para falhas e, quando as páginas do catálogo precisarem, uma
réplica de leitura. É a primeira linha da tabela, e vai carregar a Quitanda por muito tempo. **Sharding é
uma resposta a uma medição**: a maior máquina está cheia, ou
as escritas não cabem mais, e as cópias não ajudam porque toda cópia guarda tudo. Até um número dizer
isso, o custo da segunda metade desta aula é só custo.

Pare os shards antes de sair:

```sh
docker compose down -v
```
