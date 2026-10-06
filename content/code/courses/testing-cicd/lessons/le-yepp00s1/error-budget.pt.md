---
title: Orçamento de erros, ou quando parar de liberar
version: 1
---

Tudo até aqui decidiu quando parar **um** release. Há um segundo critério de parada, um nível acima:
quando parar de liberar **de vez**, por um tempo.

## Um objetivo, e o que ele permite

Um **objetivo de nível de serviço** (SLO) é uma meta de quão confiável um serviço deve ser, medida do
lado do cliente: por exemplo, "99,9% das requisições de cotação dão certo, em 30 dias". O **orçamento
de erros** é o que o objetivo deixa de sobra: 0,1% das requisições podem falhar. Em tempo, para um
serviço que está no ar ou fora dele:

| objetivo | tempo fora do ar permitido em 30 dias |
| --- | --- |
| 99% | 7 horas e 12 minutos |
| 99,9% | 43 minutos e 12 segundos |
| 99,99% | 4 minutos e 19 segundos |

Cada nove a mais divide o orçamento por dez, e multiplica o custo de ficar dentro dele.

## O orçamento como regra

O orçamento transforma uma discussão em conta:

- **Enquanto sobra orçamento**, os releases saem no ritmo de sempre. Alguns vão falhar; o orçamento
  existe para isso. Uma equipe que nunca gasta o orçamento está liberando devagar demais, ou mirando
  alto demais.
- **Quando o orçamento acaba**, os releases de funcionalidades param, e o trabalho vai para a
  confiabilidade: os testes, os critérios do canário, o rollback, o que os postmortems pediram. Eles
  voltam quando o orçamento se recupera.

Aplicado a esta aula: a troca do blue-green da aula 10 custou 77 requisições falhas. A 99,9% sobre,
digamos, dois milhões de requisições por mês, o orçamento é de 2.000 requisições falhas. Aquele
incidente gastou uns 4% dele. Um bug que falhasse uma requisição em vinte durante uma hora, sem
ninguém notar, teria gastado o orçamento várias vezes.

## Por que isso cabe num curso sobre pipelines

Tudo neste curso, os testes, a matriz, os estágios, o canário e o rollback, existe para deixar uma
equipe liberar com frequência sem gastar o orçamento. O orçamento é como a equipe sabe se isso está
funcionando. Quando ele acaba, é o pipeline que recebe a atenção.
