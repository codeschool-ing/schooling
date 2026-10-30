---
title: Uma requisição, de ponta a ponta
version: 1
---

**A primeira coisa a fazer com uma falha é olhar uma delas inteira.** Pegue o primeiro checkout que falhou no incidente,
e tudo com o `OperationId` dele:

```kql
// one-request.kql: everything recorded for the first failed checkout of the incident
let op = toscalar(
    AppRequests
    | where Name == "POST /checkout" and not(Success) and DurationMs > 2000
    | top 1 by TimeGenerated asc
    | project OperationId);
union
    (AppRequests | where OperationId == op | extend Kind = "request", Target = "shop-api"),
    (AppDependencies | where OperationId == op | extend Kind = "dependency")
| project TimeGenerated, OperationId, Kind, Name, Target, ResultCode, DurationMs
```

```

```

`toscalar()` roda a consulta de dentro e transforma o seu valor único numa constante, que o `let` chama de `op`. `union`
empilha linhas de duas tabelas, com `Kind` acrescentado para cada linha dizer o que é; uma coluna que uma tabela não tem,
como `Target` nas requisições, é preenchida para os dois lados se alinharem.

Leia as três linhas como uma linha do tempo. A requisição chegou às 17:05:12 e respondeu 500 depois de 3.130 ms. A única
dependência dela, o `INSERT orders` no banco SQL, levou 3.000 ms disso e devolveu `-2`. Não há chamada de pagamento: o
pedido nunca foi gravado, então o código nunca chegou à etapa de pagamento. **O 500 da requisição é o sintoma; o timeout é
a causa, um nível abaixo.** A *pesquisa de transações* e os *detalhes da transação de ponta a ponta* do Application
Insights no portal desenham exatamente isto, como um gráfico de Gantt; a consulta é o mesmo dado sem o desenho.

Numa aplicação real a linha da requisição também tem o mesmo horário da primeira dependência, ou quase: o `TimeGenerated`
de uma requisição é quando ela começou. A semana gerada as registra no mesmo instante, o que é uma simplificação dos dados
deste curso, e não do Application Insights.
