---
title: De uma falha para todas
version: 1
---

Uma requisição é uma história; uma causa precisa valer para o incidente. **Junte cada requisição que falhou na hora às
chamadas que ela fez**, e agrupe pelo que essas chamadas responderam:

```kql
// cause.kql: what the failed requests' calls answered, during the incident
AppRequests
| where TimeGenerated between (datetime(2026-10-15 17:00) .. 1h) and not(Success)
| join kind=inner AppDependencies on OperationId
| summarize failed_requests = dcount(OperationId) by DependencyType, Target, DependencyResult = ResultCode1
```

```

```

`join kind=inner` fica só com as requisições que falharam e fizeram chamadas; uma coluna que as duas tabelas têm,
`ResultCode`, volta do lado direito como `ResultCode1`, que a consulta renomeia. `dcount()` conta operações distintas,
então uma requisição com duas chamadas conta uma vez.

**103 requisições que falharam, todas com uma chamada SQL que estourou o tempo.** Nenhuma falha daquela hora envolveu o
provedor de pagamentos, e nenhuma foi uma requisição que falhou com uma chamada SQL saudável. Essa é a causa, dita como
contagem e não como impressão. A segunda consulta amplia para a semana, e ensina algo sobre percentis no caminho: **o percentil 95
diário da dependência SQL quase não se mexeu**, 61 ms na quinta contra 60 nos outros dias, porque 103 chamadas lentas
entre 8.872 são pouco mais de uma em cem. A coluna de falhas é a que enxerga a quinta. A lição 15 pergunta o que mudou às
14:02 daquela tarde.

O método é o que vale guardar: **comece pela tabela do sintoma, junte à tabela da causa pela operação, e deixe o
agrupamento dizer se a explicação cobre tudo.** Uma explicação que cobre 80 de 103 é parcial, e as outras 23 são a
próxima pergunta.
