---
title: Pondo números no risco
version: 1
---

**A conta de um risco deveria caber em poucas linhas, e cada número nela deveria ter uma fonte
sobre a qual o leitor possa perguntar.** Esta é a de Lívia, para o problema de sexta, do jeito que
entrou na proposta em fevereiro. Cada linha diz de onde vem o número, porque Caio vai perguntar.

## A perda crônica

| | valor | fonte |
|---|---|---|
| checkouts tentados, sexta das 18:00 às 21:00 | 9.000 | logs de pedidos, média das últimas oito sextas |
| parcela que falha por timeout | 2% | logs de erro do checkout, mesmas sextas |
| checkouts que falham por sexta | **180** | 9.000 × 2% |
| parcela desses clientes que não consegue tentar de novo com sucesso | 40% | cruzamento das sessões que falharam com pedidos posteriores |
| pedidos perdidos por sexta | **72** | 180 × 40% |
| cesta média | R$ 150 | relatório mensal do financeiro |
| **receita perdida por sexta** | **R$ 10.800** | 72 × R$ 150 |
| receita perdida por ano | R$ 561.600 | × 52 sextas |

Dois detalhes nessa tabela importam mais do que a conta.

**Os 40% são o número com mais chance de ser contestado**, e é o que mais precisava ser medido em
vez de suposto. O primeiro rascunho de Lívia supunha que todo checkout que falhava era um pedido
perdido, o que daria R$ 27.000 por sexta. O time de Bruna cruzou as sessões que falharam com pedidos
feitos depois pelos mesmos clientes e descobriu que 60% voltaram. O número honesto é duas vezes e
meia menor, e **é ele que torna o resto crível**.

**Receita não é lucro.** Caio pensa em margem. A margem bruta da Marola é de cerca de 25%, então os
R$ 561.600 de receita perdida são cerca de R$ 140.400 de margem perdida por ano. A proposta de Lívia
dá os dois, com rótulo. Um diretor que descobre que "R$ 560.000 por ano" era receita apresentada
como se fosse dinheiro no banco deixa de confiar no documento.

## O risco de cauda

| | valor | raciocínio |
|---|---|---|
| checkouts por minuto no pico | 50 | 9.000 em 180 minutos |
| minutos até alguém intervir | cerca de 30 | o tempo entre o alerta e o diagnóstico em incidentes anteriores |
| checkouts afetados | cerca de 1.500 | 50 × 30 |
| pedidos perdidos, com os mesmos 40% | cerca de 600 | 1.500 × 40% |
| receita perdida por evento | cerca de R$ 90.000 | 600 × R$ 150 |
| eventos por ano, no crescimento atual | 2 a 4 | um julgamento: as conexões chegaram a menos de 5% do limite em três sextas desde novembro |
| **perda de receita esperada por ano** | **R$ 180.000 a R$ 360.000** | as duas linhas acima multiplicadas |

A probabilidade é uma faixa e diz que é um julgamento, com a evidência em que se apoia. É o número
mais fraco do documento, e está identificado como tal.

Então, na sexta, 6 de março, o evento aconteceu: o checkout ficou fora por 32 minutos, e 1.350
checkouts falharam. O risco de cauda tinha virado medição. A estimativa de 1.500 checkouts afetados
por cerca de trinta minutos chegou perto, que é o melhor que pode acontecer com uma estimativa
depois do fato, e isso tornou a proposta seguinte mais fácil de acreditar.

## Uma linha para o topo da página

Tudo isso se comprime na frase que vai para o documento de uma página e para o relatório ao
conselho:

> O limite do banco de dados nas sextas custa cerca de R$ 560.000 por ano em receita perdida (cerca
> de R$ 140.000 em margem) e traz o risco de o checkout parar por completo, o que estimamos em duas
> a quatro vezes por ano, a cerca de R$ 90.000 de receita a cada vez.

**As tabelas são a evidência; essa frase é o que é lido.** Sem as tabelas, a frase é uma afirmação.
Sem a frase, as tabelas são lição de casa para o leitor.
