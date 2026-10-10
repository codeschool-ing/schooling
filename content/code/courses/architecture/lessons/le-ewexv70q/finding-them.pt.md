---
title: Achando-os
version: 1
---

Cada correção desta aula tinha poucas linhas. Nenhum dos problemas teria sido achado lendo o código,
porque cada página estava certa e cada consulta, sozinha, era rápida. Eles são achados medindo, e três
medições acham a maior parte deles:

| medição | o que mostra | acha |
| --- | --- | --- |
| **consultas por requisição** | quantas vezes uma página fala com o banco | I/O tagarela; uma página com 40 consultas é um N+1 |
| **bytes por requisição** | quantos dados uma página move | busca desnecessária |
| **tempo do banco por consulta, no total** | em que comandos o banco gasta o tempo | o banco ocupado; `pg_stat_statements` |

As duas primeiras vêm de **rastreamento** (*tracing*): um agente de APM ou a instrumentação do
OpenTelemetry registra cada chamada ao banco como um span dentro do trace da requisição, e um N+1 aparece
como um pente de spans iguais. A aula 7 do curso `scale` configura isso. Muitos ORMs também conseguem
contar consultas por requisição em desenvolvimento e falhar um teste que passa de um orçamento, o que pega
o N+1 antes de ele ir para produção.

O catálogo tem mais itens do que esta aula construiu, e cada um é o mesmo tipo de hábito:

| antipadrão | o hábito |
| --- | --- |
| instanciação imprópria | um cliente HTTP ou um pool de conexões novo a cada requisição, pagando a abertura de conexão toda vez |
| I/O síncrono | uma thread bloqueada esperando um I/O que ela poderia ter largado, o pool de threads da aula 12 de novo |
| sem cache | a mesma resposta que não muda recalculada a cada requisição |
| tempestade de retries | retries que multiplicam a carga num serviço com dificuldades, aula 11 |
| vizinho barulhento | um cliente ou uma carga consumindo um recurso que os outros dividem, os bulkheads da aula 12 |
| persistência monolítica | um banco para todo tipo de dado, seja qual for o padrão de acesso |

Quando terminar, pare o laboratório:

```sh
docker compose down -v
```
