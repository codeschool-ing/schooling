---
title: Cotas, e os tetos que o Google não tem
version: 1
---

**O Google Cloud não tem uma configuração que diga "pare de gastar em 300 dólares".** As pessoas procuram
por ela no primeiro dia e ela não está lá, porque um teto rígido teria de decidir, em nome do cliente, que
sistemas desligar e que dados apagar. O Google deixa essa decisão com o cliente, e oferece três
ferramentas que limitam o gasto, cada uma de um jeito. Nada nesta seção rodou: cotas são contadores do
Google e o laboratório não tem nenhum.

| ferramenta | o que limita | quanto custa quando morde |
|---|---|---|
| **um orçamento com desvínculo automatizado**, seção anterior | tudo nos projetos que ele cobre | tudo para, e dados guardados podem ser apagados |
| **uma cota baixada** | os pedidos de uma API, ou um tipo de recurso | pedidos a essa API são recusados; nada mais muda |
| **um projeto separado com orçamento pequeno** | um experimento, longe da produção | só o experimento |

## Uma cota como teto

A lição 3 disse que uma cota é um teto que o Google põe e que o cliente pode **baixar**. Isso faz da cota o
teto preciso: uma API que cobra por pedido, como uma API de tradução ou de mapas, pode ter a cota de taxa
posta no que a aplicação precisa, e um bug que a chama em loop é recusado na cota em vez de cobrado pelo
preço. **Este é o teto a buscar primeiro**, porque ele falha a única coisa que deu errado e deixa o resto do
sistema em paz.

As cotas também limitam o que pode **existir**. Um projeto cuja cota de CPUs virtuais em
`southamerica-east1` é 24 não roda cem máquinas por engano, diga o que disser o Terraform. Projetos novos
começam com cotas pequenas exatamente por isso, e um pedido de aumento é um momento em que alguém é
obrigado a pensar.

## O que um orçamento não vê

Duas lacunas fazem dos orçamentos um alarme imperfeito, e vale conhecer as duas antes que um incidente as
ensine:

- **O atraso.** Os custos chegam aos dados de faturamento horas depois do uso, então um orçamento mede onde
  o dinheiro estava, não onde está. Um sistema descontrolado pode gastar boa parte de um dia antes de o
  orçamento passar de um limite.
- **O escopo.** Um orçamento vê os custos que o filtro dele nomeia. Um projeto criado semana que vem e
  vinculado à mesma conta de faturamento fica fora de um orçamento que lista projetos pelo nome, a não ser
  que o orçamento seja da conta inteira ou que o projeto novo seja acrescentado. Um orçamento na conta de
  faturamento sem filtro de projeto, num valor mais alto, é a reserva que pega o que os orçamentos mais
  estreitos deixam passar.

## A ordem que funciona

Para o planner, o arranjo é aquele a que a maioria das equipes chega: **cotas baixadas nas APIs que cobram
por chamada**, um **orçamento por ambiente** com limites previstos e reais que chegam a uma pessoa, um
**orçamento na conta de faturamento inteira** como reserva, e um **desvínculo automatizado só nos projetos
sandbox**, onde perder tudo é um preço aceitável por nunca ter surpresa.
