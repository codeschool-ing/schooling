---
title: O que os quatro números não conseguem ver
version: 1
---

Um time pode ter números DORA excelentes e estar fracassando. Não é comum, mas é possível, e saber como é o que mantém as métricas no lugar delas. As quatro medem **o quão bem um time entrega mudanças**. Não dizem nada sobre se as mudanças valiam a pena, se o time consegue manter o ritmo ou se as pessoas que esperam pelo trabalho estão sendo atendidas.

## Cinco pontos cegos

**Valor.** Um time pode fazer vinte pequenos deploys por dia sem que ninguém precisasse de nenhum deles. A frequência de deploy conta deploys, não resultados. Se uma mudança fez alguma diferença para um usuário é uma pergunta de produto, respondida por outras medidas: adoção, retenção, receita, chamados de suporte evitados.

**A espera antes do trabalho.** O lead time de mudanças começa num commit. Tudo o que vem antes, o pedido parado no backlog, o item esperando para ser começado, é invisível. A aula 2 descobriu que em setembro **84% da espera de quem fazia um pedido ao time de Billing estava no backlog**: 27 de 32 dias. O lead time DORA do time naquele mês foi de seis horas. Os dois números são verdadeiros, e só um deles é o que a dona da loja que relatou o bug viveu.

**Qualidade que não causa incidente.** A taxa de falha de mudanças conta os deploys que precisaram de remediação. Um bug que incomoda um pouco todos os usuários, e nunca provoca um rollback, não é uma falha de mudança. Um time pode entregar uma queda lenta de qualidade enquanto sua taxa de falha fica em zero.

**As pessoas.** Nenhuma das quatro distingue um time que entrega bem de um time que entrega bem enquanto se esgota. Um time cujos números melhoraram porque duas pessoas trabalharam todo fim de semana parece, num painel DORA, exatamente igual a um time cujos números melhoraram porque mudou o jeito de trabalhar. A aula 8 apresenta um modelo que inclui como as pessoas estão, e a aula 17 calcula o custo do pager.

**Trabalho que não é um deploy.** Suporte, operação, a integração de um colega novo, uma revisão de arquitetura, a hora gasta desbloqueando outro time. Um time de plataforma cuja função é deixar outros times mais rápidos pode fazer deploy raramente e estar fazendo um trabalho excelente. `BIL-189`, que esperava por outro time, é o rastro desse tipo de trabalho no quadro do time de Billing, e nada num painel DORA jamais o mostraria.

## Com o que combiná-las

Nada disso é um argumento contra as quatro; é um argumento contra apresentá-las sozinhas. Cada ponto cego tem uma medida que enxerga dentro dele, e um relatório que importa traz algumas delas ao lado dos números DORA:

| ponto cego | uma medida que o enxerga |
|---|---|
| valor | um resultado que a mudança deveria mover, escolhido antes da entrega |
| a espera antes do trabalho | lead time do pedido até a produção, aula 2 |
| qualidade aquém de um incidente | chamados de suporte, taxas de erro contra um objetivo, aula 16 |
| as pessoas | uma pesquisa curta e regular, e a carga de plantão, aulas 8 e 17 |
| trabalho que não é um deploy | fluxo de todos os itens de trabalho, não só das mudanças de código, aulas 1 a 4 |

A aula 19 monta um relatório trimestral exatamente com esses pares.
