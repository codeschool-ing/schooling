---
title: Amostragem, ItemCount e live metrics
version: 1
---

**Uma aplicação movimentada não manda toda requisição ao Application Insights; manda uma amostra.** Os SDKs e a
distribuição OpenTelemetry podem ficar com, digamos, uma operação em quatro, e toda linha que mandam passa a levar
**`ItemCount = 4`**: esta linha vale por quatro. A amostragem é decidida por operação, então uma requisição mantida mantém
todas as suas dependências e uma descartada descarta todas, e é isso que mantém corretos os joins da seção anterior.

O custo de esquecer o `ItemCount` é fácil de mostrar. `SampledRequests` é a semana como uma amostra de 25% a teria
guardado, montada a partir da tabela completa ficando com uma operação em quatro:

```kql
// sampled.kql: the same week as a 25% sample would have stored it
.set-or-replace SampledRequests <|
AppRequests
| where abs(hash(OperationId, 4)) == 0
| extend ItemCount = 4
```

```

```

O `count()` na amostra diz 62.764 requisições; o `sum(ItemCount)` diz 251.056, perto das 249.717 verdadeiras. **Toda
contagem sobre dados amostrados é `sum(ItemCount)`, nunca `count()`.** As falhas mostram o outro lado da amostragem: 346 no
total viraram 85 linhas valendo por 340, uma estimativa a 2% aqui. Para um evento raro, um punhado por dia, a
estimativa pode errar feio ou uma falha pode sumir da amostra. Por isso a loja amostra os `GET /products` que deram certo e
guarda toda falha e todo checkout: regras de amostragem na ingestão e as configurações do SDK conseguem tirar tipos de
telemetria da amostragem.

## Live metrics

O **live metrics** é a visão do último minuto no Application Insights: requisições, falhas, chamadas de dependência e CPU,
por segundo, transmitidas do SDK da aplicação direto ao portal **sem passar pelo workspace e sem amostragem**. Não custa
nada em ingestão e não guarda nada: feche a página e os dados se vão. O uso dele é o momento de um deploy ou de uma troca,
os quinze minutos da lição 3, quando você quer ver a taxa de falha no segundo em que ela se mexe, e não alguns minutos
depois numa consulta. Ele precisa de uma aplicação rodando e de um portal, então **não foi executado** para este curso.
