---
title: De onde vem um número diário para a fatura
version: 1
---

Os alertas da lição 14 vigiam o que os clientes sentem. Alguns incidentes os clientes nunca sentem: um nível de debug
esquecido ligado que escreve quarenta gibibytes de logs por dia, um teste de carga que ninguém parou, uma credencial
roubada rodando máquinas numa região que o time nunca usa. O serviço funciona, e **a fatura é a única coisa que se
mexe**. Ela se mexe no fim do mês, a menos que algo a leia todo dia. Esta lição faz da fatura um sinal como qualquer
outro, e a primeira pergunta é de onde vem um número diário. Nenhuma das duas fontes roda aqui: as duas exigem uma
conta de faturamento.

## A exportação de faturamento, por dia

A exportação da lição 23 tem uma linha por recurso, por SKU, por hora de uso, então o custo diário de cada serviço é
uma consulta. No BigQuery, contra a tabela da exportação padrão, com os nomes de dataset e tabela que a sua exportação
recebeu:

```sql
SELECT DATE(usage_start_time) AS day, service.description AS service, ROUND(SUM(cost), 2) AS usd
FROM `planner-billing.billing_export.gcp_billing_export_v1_XXXXXX_XXXXXX_XXXXXX`
WHERE usage_start_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 45 DAY)
GROUP BY day, service
ORDER BY day, service
```

**A exportação não é ao vivo.** As linhas chegam depois do uso que as produziu, e o total de um dia continua crescendo
por um tempo depois que o dia acabou, então hoje e ontem estão sempre incompletos. Um detector que comparasse um hoje
inacabado com dias completos antes dele relataria uma queda toda manhã. O programa da próxima etapa julga cada dia
contra os catorze anteriores, e deve rodar sobre dias terminados.

Agendada toda manhã, como uma consulta agendada do BigQuery ou um job pequeno, a consulta escreve as 45 linhas por
serviço que a próxima etapa lê, num arquivo CSV.

## O fluxo do orçamento, como ritmo

O tópico da lição 24 é a outra fonte. Cada atualização traz `costAmount`, o gasto até agora no período, e as
atualizações chegam em intervalos regulares. Duas atualizações com um dia de distância dão o gasto do dia; uma função
que guarde a última que viu pode comparar essa diferença com o usual. É mais grosseiro que a exportação, já que é um
número só para o orçamento inteiro, mas não precisa de BigQuery e chega no tópico onde você já tem uma função ouvindo.

| fonte | granularidade | atraso | precisa de |
|---|---|---|---|
| exportação de faturamento | serviço, SKU, projeto, rótulo, por hora | horas, e um dia continua crescendo | BigQuery e uma consulta agendada |
| tópico do orçamento | um número por orçamento | o mesmo atraso do orçamento | o orçamento e uma função |

**A exportação diz qual serviço se mexeu; o tópico diz que algo se mexeu.** A loja roda a exportação toda manhã pelo
detalhe e deixa a regra de previsão da lição 24 pegar um mês que está dando errado entre duas manhãs.
