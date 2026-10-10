---
title: Objetivos, e o orçamento para não cumpri-los
version: 1
---

As métricas respondem "o que a bilheteria está fazendo?". Operá-la exige uma segunda pergunta
respondida de antemão: **o que ela deveria fazer?** Sem uma resposta, todo gráfico é questão de
opinião, e todo alerta é barulhento demais ou tardio demais.

Três termos, da prática de engenharia de confiabilidade de sites do Google:

- Um **SLI**, indicador de nível de serviço, é uma medida do serviço como os usuários o vivem,
  escrita como uma razão: eventos bons divididos por todos os eventos.
- Um **SLO**, objetivo de nível de serviço, é a meta de um SLI numa janela: 99,9% das vendas
  respondidas com sucesso em até 250 ms, em 30 dias.
- O **orçamento de erro** é o que o objetivo permite falhar: 0,1% das vendas na janela.

## O SLI da bilheteria, pelo próprio histograma

A seção 07 disse para pôr um limite de faixa no valor que o objetivo nomeia. A bilheteria tem um em
0,25 s, então a fração de vendas respondidas em até 250 ms é a contagem daquela faixa dividida pela
contagem de todas as vendas, as duas como taxas. Aqui está durante trinta segundos de vendas com 16
trabalhadores:

```
ana@lab:~/tickets$ docker compose exec prometheus promtool query instant http://localhost:9090 'sum(rate(tickets_request_seconds_bucket{route="/events/{id}/tickets", le="0.25"}[30s])) / sum(rate(tickets_request_seconds_count{route="/events/{id}/tickets"}[30s]))'
{} => 1 @[1791612667.816]
```

**1**, toda venda em até 250 ms naquela janela: o objetivo foi cumprido com o orçamento inteiro
sobrando. A mesma consulta em trinta dias, com um dia lento no meio, é como o SLO é conferido, e o
complemento dela é quanto do orçamento já foi gasto.

## Para que serve o orçamento

O orçamento transforma confiabilidade numa quantidade que pode ser gasta de propósito:

| em 30 dias | 99% | 99,9% | 99,99% |
|---|---|---|---|
| vendas que podem falhar, com 1 milhão de vendas | 10 000 | 1 000 | 100 |
| queda completa que ele permite | 7 h 12 min | 43 min | 4 min 19 s |

- **Um orçamento não gasto é espaço para andar mais rápido**: implantações, migrações como as da aula
  6, experimentos.
- **Um orçamento gasto é motivo para desacelerar** e passar as próximas semanas em confiabilidade em
  vez de funcionalidades.
- **Alerte pela velocidade de queima do orçamento, não por todo soluço.** Um alerta que dispara quando
  o orçamento está sendo gasto rápido o bastante para acabar em horas vale acordar alguém; um que
  dispara por um único pedido lento não vale.

**O objetivo deve ser mais baixo do que o sistema consegue.** Ninguém nota a diferença entre 99,99% e
100%, e prometer 100% não deixa orçamento para mudança nenhuma. O SLO certo é aquele abaixo do qual
os usuários começam a reclamar, medido e não chutado, e a aula 11 trata de manter a bilheteria acima
dele à medida que a carga cresce.
