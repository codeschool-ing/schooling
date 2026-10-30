---
title: Alocação de custos, e dividir o que ninguém pode possuir
version: 1
---

**Alguns custos são compartilhados de verdade**, e pôr a tag de uma equipe neles seria mentir. O Front Door da loja serve o site da loja
e os links de download da equipe de exportação; o workspace do Log Analytics guarda os logs das duas equipes; a reserva da lição 22 cobre
as VMs compatíveis que estiverem rodando. Três jeitos de lidar com eles:

- **deixar num balde compartilhado**, com tag `team: platform`, e reportar como custo indireto. Honesto, e esconde quem puxa o custo;
- **dividir por uma fração fixa**, combinada antes: Front Door 80% loja, 20% exportação. Simples, e errado assim que o uso muda;
- **dividir pelo uso medido**: o custo do workspace pela fração de ingestão de cada equipe, que a tabela `Usage` da lição 9 mede por
  tabela, e cada tabela pertence aos recursos de uma equipe.

As **regras de alocação de custos do Cost Management** fazem o segundo e o terceiro dentro da conta: uma regra pega o custo de fontes
nomeadas, como uma assinatura, um grupo de recursos ou uma tag, e o distribui para alvos na proporção do custo deles, em porcentagens
fixas, ou por igual. O custo alocado aparece então nas visões dos alvos como se eles o tivessem gastado. As regras são configuradas no
escopo de cobrança e **não foram executadas** aqui; a divisão medida é uma consulta sobre a exportação de custos, no mesmo formato das
desta lição.

Seja qual for o método, **escreva e mantenha**. Uma divisão que muda todo trimestre transforma a comparação de cada mês numa discussão,
e o ponto da alocação é que cada equipe veja o custo das próprias decisões, mês após mês, pela mesma regra.
