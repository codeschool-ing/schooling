---
title: Conflito entre times, e como escalar juntos
version: 1
---

Conflito entre times tem outra cara e muitas vezes faz mais estrago que conflito entre pessoas, porque
cada lado defende os objetivos do próprio time, que são legítimos. **A falha habitual não é a
discordância em si, mas o jeito como ela circula**: reclamações no canal de cada time, escaladas pelas
costas do outro time, e um gestor acima dos dois que ouve duas histórias incompatíveis em momentos
diferentes.

## O Agenda e Pagamentos

A contagem da aula 7 mostrou que dependências de Pagamentos apareciam nas notas de cinco de sete pessoas.
O problema específico era o novo trabalho de confirmações: o Agenda precisava que Pagamentos expusesse
um endpoint dizendo se a assinatura de uma clínica permitia confirmações automáticas, e Pagamentos
continuava mudando a data. As pessoas do Agenda reclamavam entre si que Pagamentos não ligava para os
planos de ninguém.

A Renata se encontrou com a Bia, gestora de engenharia de Pagamentos, e ouviu o outro lado. Pagamentos
estava no meio de uma migração que o time financeiro tinha transformado em prioridade legal: novas regras
de faturamento da Receita, com data fixa. **De dentro de Pagamentos, o pedido do Agenda era um de seis
pedidos de outros times, e a única coisa fixa no roadmap deles era a lei.**

## Os jeitos errados de escalar

Duas coisas que a Renata poderia ter feito, e não fez:

- **Escalar sozinha.** Ir ao Otávio, o gestor dela, e pedir que ele pressionasse Pagamentos. Pagamentos
  se reportava a outra diretora, a Cláudia, então o Otávio levaria o assunto à Cláudia, que ouviria a
  versão do Agenda primeiro e a da Bia depois, da própria liderada, na defensiva. Uma disputa escalada por
  um lado só chega como acusação.
- **Contornar.** Pedir a alguém do Agenda que fizesse a verificação direto no banco de dados de
  Pagamentos. Funcionaria por um mês e quebraria quando a migração mudasse o esquema, e pioraria a relação
  entre os times por um ano.

## Escalar juntos

O que a Renata e a Bia fizeram foi escrever juntas uma página, descrevendo a discordância como um
problema comum, com as restrições dos dois times:

| seção | conteúdo |
|---|---|
| a decisão necessária | quando Pagamentos consegue entregar o endpoint de assinatura de que as confirmações do Agenda precisam |
| a restrição do Agenda | as confirmações estão prometidas à associação das clínicas para março |
| a restrição de Pagamentos | as mudanças de faturamento têm data legal em fevereiro; o time está inteiro nelas até lá |
| as opções | (a) o endpoint depois de fevereiro; (b) um endpoint mais simples e temporário em janeiro, ao custo de uma semana de Pagamentos; (c) o Agenda entrega confirmações sem a verificação de assinatura, para todas as clínicas, e a acrescenta depois |
| o que cada uma recomenda | Renata: (b). Bia: (a), com (c) como alternativa |

Elas levaram a página juntas a quem cabia decidir entre as prioridades dos dois times: o Otávio e a
Cláudia, numa reunião só. **A página deixou os dois diretores decidirem pelos fatos, e não por qual gestora
falou primeiro.** Escolheram (c) para março e (a) depois de fevereiro, e os dois times ouviram a decisão
ao mesmo tempo, das mesmas pessoas.

## Escalar não é fracasso

Muitas gestoras tratam escalar como admitir que não conseguiram resolver um problema. Entre times, muitas
vezes é o movimento correto, porque nenhuma das gestoras tem autoridade para trocar as prioridades de um
time pelas de outro. **O que torna a escalada saudável é os dois lados a fazerem juntos, com a
discordância escrita de forma justa**, para que as pessoas acima decidam em vez de arbitrar.

No dia seguinte à decisão, a Renata contou ao time do Agenda o que tinha sido decidido e por quê,
inclusive a data legal contra a qual Pagamentos vinha trabalhando. As reclamações no canal pararam,
porque o motivo tinha deixado de ser invisível.
