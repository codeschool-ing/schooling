---
title: Cost Explorer, uma pergunta feita à fatura
version: 1
---

**O Cost Explorer é uma consulta sobre a fatura: um período, uma granularidade, o que medir e como
dividir.** O console o desenha como um gráfico, o que o faz parecer um medidor ao vivo do gasto. Não
é ao vivo. A documentação da AWS diz que os dados dele são atualizados pelo menos uma vez a cada 24
horas, e que na primeira vez que o Cost Explorer é ligado numa conta, preparar o mês corrente e os
doze anteriores pode levar até um dia. Ele responde "quanto gastamos, e em quê", de forma confiável e
atrasada.

## A forma de uma consulta, contra uma fatura vazia

As mesmas perguntas que o console faz são um comando, `aws ce get-cost-and-usage`. O moto o
responde, e a resposta é a primeira coisa a entender nesta seção:

```
ana@laptop:~/aws$ aws ce get-cost-and-usage --time-period Start=2026-09-01,End=2026-10-01 --granularity MONTHLY --metrics UnblendedCost AmortizedCost NetUnblendedCost --group-by Type=TAG,Key=team
{
    "ResultsByTime": [],
    "DimensionValueAttributes": []
}
ana@laptop:~/aws$ aws ce get-cost-and-usage --time-period Start=2026-09-01,End=2026-10-01 --granularity DAILY --metrics UnblendedCost --group-by Type=DIMENSION,Key=SERVICE Type=DIMENSION,Key=LINKED_ACCOUNT
{
    "ResultsByTime": [],
    "DimensionValueAttributes": []
}
```

**As duas respostas estão vazias, porque o moto não tem gasto para informar.** Ele registra recursos
e nunca os cobra, então não há setembro para ele somar. Nenhum número desta seção veio do moto, e
nenhum foi posto nele para a saída parecer mais cheia. O que os comandos mostram é a forma da
pergunta, que é a mesma contra a AWS:

- **`--time-period`** é um início e um fim, e o fim é **exclusivo**: `End=2026-10-01` é setembro
  inteiro e nada de outubro. Escrever `End=2026-09-30` perde o último dia do mês, sem erro.
- **`--granularity`** é `MONTHLY`, `DAILY` ou `HOURLY`; dados por hora precisam ser ligados na conta
  antes, e são cobrados à parte.
- **`--metrics`** diz o que somar; as três acima são as que um leitor de fatura confunde, e a próxima
  parte diz como diferem.
- **`--group-by`** divide o total, por uma **dimensão** como `SERVICE`, `LINKED_ACCOUNT` ou
  `REGION`, ou por uma **tag** que o faturamento ativou. O segundo comando agrupa por duas dimensões
  de uma vez, que é o máximo que uma consulta pode pedir.

Agrupando pela tag `team`, a AWS responde com chaves como `team$web` e `team$data`, e com uma chave
que é só `team$`: **os custos de tudo o que não tinha tag `team`**, que é o resto sem tag de que a
seção sobre tags avisou.

## Três jeitos de contar o mesmo mês

As métricas diferem em **quando** um custo é contado e **se** um desconto é tirado dele. A diferença
só aparece quando algo foi pago adiantado, e a lição 14 é exatamente sobre essas compras; a tabela dá a forma:

| métrica | o que ela conta |
|---|---|
| `UnblendedCost` | cada cobrança no dia em que foi cobrada, pela tarifa cobrada: um pagamento adiantado de um ano cai inteiro no dia em que foi pago |
| `AmortizedCost` | pagamentos adiantados espalhados pelas horas que eles pagam, então o mesmo ano aparece como um doze avos em cada mês |
| `NetUnblendedCost` | o não combinado, depois de subtraído qualquer desconto que a conta recebeu; sem desconto, igual ao não combinado |

**O não combinado responde "o que foi cobrado este mês"; o amortizado responde "quanto custou o uso
deste mês".** Um time que comprou um ano de capacidade em janeiro parece caríssimo em janeiro e de
graça por onze meses quando lido sem combinar, e estável quando lido amortizado. Um orçamento conta
o não combinado a menos que lhe digam outra coisa, que é o que o `UseAmortized: false` da seção sobre
orçamentos dizia. `BlendedCost` é um quarto, uma tarifa média entre as contas de uma fatura
consolidada, e pertence ao assunto da lição 3.

## O preço de perguntar

As telas do Cost Explorer no console são de uso gratuito. **A API não é**, e o preço dela está na
lista:

```
ana@laptop:~/aws$ python3 price.py AWSCostExplorer 20260911124538 us-east-1 USE1-APIRequest
AWSCostExplorer 20260911124538, published 2026-09-11, USD
USE1-APIRequest
          0 to       Inf Request 0.0100
```

Na lista que a AWS publicou em **11 de setembro de 2026**, cada requisição custa 0,01 dólar. Um
comando digitado à mão é um centavo. Um script que pergunta a cada minuto, o mês todo, são 60 × 24 ×
30 = 43.200 requisições, o que dá **432 dólares por mês** gastos vigiando a fatura. Pergunte uma vez
por dia; os dados não mudam mais rápido que isso.

## Detecção de anomalias

Um orçamento dispara quando um total cruza uma linha. Um custo que **dobrou** num serviço, enquanto o
total ficou abaixo da linha, é algo que ele nunca vê. O **Cost Anomaly Detection** é o outro
instrumento: um **monitor** vigia custos divididos por serviço, por conta, por categoria de custo ou
por uma tag de alocação de custos, aprende o padrão de costume a partir do histórico, e informa um
dia que foge dele. Uma **assinatura de alerta** diz quem fica sabendo e como: cada anomalia na hora
por um tópico SNS, ou um resumo diário ou semanal por e-mail, acima de um impacto que você define em
dólares ou em porcentagem. Tudo isso vem da documentação da AWS; o moto não o tem:

```
ana@laptop:~/aws$ aws ce get-anomaly-monitors 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the GetAnomalyMonitors operation (reached max retries: 2): <!doctype html>
```

Os três instrumentos desta lição respondem a três perguntas. Um orçamento diz que o mês está
passando. A detecção de anomalias diz que um padrão mudou. O Cost Explorer, agrupado pelas tags que o
faturamento conhece, diz de quem foi. A lição 14 lê o que são as linhas da fatura, e a lição 15 abre
o arquivo por baixo dos três, o Cost and Usage Report.
