---
title: Uma fatura que chegou errada
version: 1
---

**A maioria das faturas que parecem erradas está certa sobre algo que ninguém esperava, e o trabalho é
achar qual linha diz isso.** A fatura rara que está mesmo errada se acha do mesmo jeito, lendo linhas
em vez de totais. **Nada nesta seção foi executado**: ela lê os dados de uma conta de cobrança de
verdade, e o laboratório não tem nenhuma. O que segue é o formato desses dados, segundo a documentação
da Microsoft e a especificação aberta que ela usa, e as perguntas que desmontam um total.

## O que uma linha de dados de custo diz

O Cost Management entrega os custos de uma assinatura linha por linha, uma linha por recurso, medidor
e dia, e a lição 15 os exporta para um arquivo. A Microsoft oferece esse arquivo em **FOCUS**, a
FinOps Open Cost and Usage Specification, um formato aberto que vários provedores de nuvem
compartilham, então os nomes das colunas não são do próprio Azure. Cinco delas respondem a maior parte
das perguntas sobre uma fatura surpreendente:

| coluna | o que diz |
|---|---|
| `ChargeCategory` | que tipo de cobrança é a linha: `Usage`, `Purchase`, `Tax`, `Credit` ou `Adjustment` |
| `ChargeFrequency` | `Usage-Based`, `Recurring` ou `One-Time`: um pagamento mensal de reserva é recorrente, um adiantado acontece uma vez |
| `PricingCategory` | o preço que se aplicou: `Standard` para pagamento conforme o uso, `Committed` para uso coberto por uma reserva ou um savings plan |
| `BilledCost` | o que esta linha soma à fatura, no dia em que foi cobrada |
| `EffectiveCost` | a mesma linha amortizada: a compra de um compromisso espalhada pelo uso que ela cobriu |

**`BilledCost` é o custo real da lição 13 e `EffectiveCost` o amortizado**, como colunas lado a lado.
No dia em que uma reserva adiantada é comprada, uma linha `Purchase` leva o preço inteiro dela em
`BilledCost`; as máquinas que ela cobre então mostram linhas de uso `Committed` cujo `BilledCost` é
zero e cujo `EffectiveCost` é a parte do dia. As horas não usadas de uma reserva aparecem como linhas
próprias, e a especificação tem uma coluna, `CommitmentDiscountStatus`, feita para marcá-las como
`Unused`. A documentação da Microsoft para um dos seus esquemas de exportação diz que essa coluna está
*atualmente vazia*, então confira se o seu arquivo a preenche antes de contar com ela.

## As faturas que só parecem erradas

Quatro surpresas respondem pela maior parte das conversas sobre uma fatura do Azure:

1. **O mês não é o mês do calendário.** Uma assinatura de pagamento conforme o uso é cobrada pelo seu
   próprio período de cobrança, que a documentação da Microsoft diz que pode não coincidir com o mês
   do calendário. A fatura então cobre, digamos, do dia 14 ao dia 13, enquanto a análise de custos
   mostra o mês do calendário por padrão. Os dois totais diferem e os dois estão certos.
2. **Uma compra caiu neste mês.** Uma reserva ou um savings plan pago adiantado põe o preço de um ou de
   três anos numa fatura só. Em `BilledCost` este mês é enorme; em `EffectiveCost` é normal. A lição 13
   aconselhou a visão amortizada exatamente por isso.
3. **Alguma coisa parou de cobrir alguma coisa.** Uma reserva venceu, uma máquina foi redimensionada
   para fora da família de tamanhos da reserva, uma máquina perdeu a marca do Hybrid Benefit numa
   reimplantação. Nada novo foi criado e a fatura subiu: o mesmo uso passou de `Committed` para
   `Standard`, ou ganhou um medidor de licença.
4. **Imposto, crédito e moeda.** A fatura soma impostos que a análise de custos não mostra, subtrai
   créditos, e, para uma conta de cobrança numa moeda diferente da dos preços, converte a uma taxa que
   varia.

## Desmontando um total

Para um total maior que o do mês anterior, a mesma ordem da lição 13, com uma pergunta antes:

1. **Compare igual com igual**: o mesmo período dos dois lados, e real contra real ou amortizado
   contra amortizado.
2. **Agrupe por `ChargeCategory`.** Se a diferença é um `Purchase`, é um compromisso, e a pergunta é
   quem o comprou. Se é `Usage`, continue.
3. **Agrupe o uso por `PricingCategory`.** Uma passagem de `Committed` para `Standard` sem mudança de
   quantidade é um compromisso que deixou de se aplicar, o item 3 acima.
4. **Agrupe por recurso e medidor**, filtrando o que cresceu. Um medidor que não existia no mês
   passado é um tipo novo de cobrança: uma licença do Windows, um endereço IP público, dados saindo da
   região.

E para a fatura que está mesmo errada, uma cobrança por um recurso que nunca existiu, ou um preço que
não é o da lista para a sua data: a prova são as linhas, com os seus ids de recurso e datas, e o lugar
para levá-la é um pedido de suporte de cobrança no portal. Neste formato uma correção de um período
anterior chega como uma linha nova com `ChargeClass` igual a `Correction`, nunca como uma edição da
antiga. **Uma fatura é história, e história se corrige acrescentando.**
