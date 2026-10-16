---
title: Dois jeitos de se comprometer, e o que cada um compra
version: 1
---

Sob demanda é o preço de estar livre para parar. Uma equipe que sabe que vai rodar **pelo menos** uma
certa quantidade de computação no próximo ano ou nos próximos três pode vender essa liberdade de volta à
AWS, e o desconto é o maior que a AWS oferece em computação: até uns 60% para as instâncias da loja, como a
próxima seção lê na lista de preços. Há dois instrumentos, e eles convergiram no preço sem deixar de ser
diferentes no que cobrem.

Reserved Instances, RIs, são um compromisso com um **tipo de instância numa região**: uma `m7g.large`,
Linux, em São Paulo, por um ou três anos. A cada hora, se uma instância dessas está rodando, ela é cobrada
na taxa reservada. Uma RI **standard** é a mais barata e não pode ser trocada por outra família; uma
convertible pode ser trocada por outra de valor igual ou maior, e custa mais. RIs existem para o EC2, e
numa forma própria para RDS, ElastiCache, OpenSearch e Redshift.

Savings Plans são um compromisso com **um número de dólares por hora**, por um ou três anos: *vamos
gastar pelo menos 2,50 USD por hora em computação*. A cada hora, o uso elegível é cobrado nas taxas do plano
até o compromisso se esgotar, e o resto sob demanda. Dois tipos importam:

| | cobre | flexibilidade |
|---|---|---|
| **Compute Savings Plan** | EC2 de qualquer família, tamanho, região e sistema operacional; Fargate; Lambda | acompanha a carga, para Graviton, para contêineres, para outra região |
| **EC2 Instance Savings Plan** | uma família de instâncias numa região, `m7g` em São Paulo, qualquer tamanho | como uma RI standard, mas tamanhos e sistemas operacionais mudam livremente |

Cada tipo é comprado **sem adiantamento**, com adiantamento parcial ou com pagamento total
adiantado; pagar antes compra um pouco mais de desconto.

## O que não muda

Todos eles são **construções de cobrança**. Nada é reservado no data center; nenhuma instância muda; a
frota em execução é exatamente a que era, e a conta aplica uma taxa menor às horas que o compromisso
cobre. E todos são **pagos usados ou não**: um compromisso de 2,50 USD por hora são 2,50 USD a cada hora do
prazo, inclusive nas horas em que a frota é menor do que o planejado. Esse é o risco, e a seção sobre
dimensionamento trata dele.
