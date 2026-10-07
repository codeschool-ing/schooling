---
title: Combine os critérios antes das opções
version: 1
---

**Quando dois engenheiros discordam sobre um design, combine o que uma boa resposta precisa fazer
antes de discutir qualquer resposta.** Discutir as opções primeiro faz cada lado defender a opção
com que chegou, e cada argumento vira um julgamento sobre critérios que nunca foram ditos. Combinar
os critérios primeiro transforma a discussão numa comparação.

## A segunda discordância

A cota resolveu uma discussão e revelou outra. A logística queria parar de ler as tabelas do
checkout diretamente e pediu um fluxo de eventos de pedidos novos. Paulo queria um message broker;
Bruna queria que o checkout escrevesse os eventos numa tabela do próprio banco, um *outbox*, que a
logística leria. Os dois designs são razoáveis, os dois têm defensores em todo time de engenharia, e
a conversa caminhava para a mesma thread de antes.

Lívia pediu que os dois escrevessem juntos o que a solução precisa fazer, antes de qualquer design
voltar a ser mencionado:

| critério | peso | por quê |
|---|---|---|
| nenhum evento de pedido se perde, mesmo se um serviço cair | obrigatório | pedido é dinheiro |
| a latência do checkout não sobe no pico | obrigatório | é o objetivo de todo o trabalho deste ano |
| a logística recebe um pedido em até 10 segundos | 3 | o planejamento de rotas roda em lotes; segundos não importam |
| operável pelo time de plataforma atual | 3 | o time tem três pessoas |
| outros times podem consumir os eventos depois | 2 | o time de dados já pediu |
| custo abaixo de R$ 3.000 por mês | 2 | a linha de orçamento aprovada em março |

**Escrever os pesos foi onde a discordância real apareceu**: Paulo vinha dando um peso muito alto a
"outros times podem consumir os eventos", porque esperava mais três consumidores em breve; Bruna
vinha dando o peso maior a "operável pelo time atual", porque quem seria acionado no plantão era o
time dela. Nenhum dos dois tinha dito isso. Com a questão na mesa, puderam discuti-la diretamente, e
o time de dados resolveu o assunto ao dizer que não precisaria de eventos por pelo menos um ano.

## A pontuação, e os limites dela

Pontuado contra a tabela, o outbox saiu na frente em operabilidade e custo, o broker em
consumidores futuros. Com os pesos combinados, o outbox ganhou, e Paulo concordou que ganhava, dados
os pesos.

Uma matriz de decisão é uma ferramenta para tornar a discordância visível, não uma máquina que
produz respostas. **Se os números saem contra uma escolha em que todo mundo acredita, provavelmente
os pesos estão errados, e a conversa útil é sobre qual deles.** E pontuações próximas querem dizer
que as opções são de fato próximas: escolha uma, anote por quê e pare de discutir.

## Registre por escrito

O resultado foi para um registro de decisão, no formato da aula 2: o contexto, os critérios e os
pesos, as opções consideradas, a decisão e o que justificaria revisitá-la ("um terceiro consumidor
de eventos de pedido, ou a tabela do outbox crescendo além do que um banco consegue guardar"). A
preferência de Paulo por um broker ficou registrada como alternativa considerada, com o motivo de
ter perdido **com estes pesos**. Quando os pesos mudarem, ele tem um documento para apontar, e não
uma mágoa.
