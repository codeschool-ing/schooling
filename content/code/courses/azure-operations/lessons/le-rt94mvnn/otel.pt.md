---
title: OpenTelemetry, e o que a distro do Azure Monitor acrescenta
version: 1
---

**O OpenTelemetry é uma especificação e um conjunto de bibliotecas para produzir traces, métricas e logs num formato
único e neutro em relação a fornecedor.** É um projeto da Cloud Native Computing Foundation, e todo grande fornecedor de
monitoramento, a Microsoft incluída, aceita os dados dele. Tem quatro partes que vale nomear:

- **a API**, o que o código da aplicação chama: iniciar um span, definir um atributo, registrar uma exceção;
- **o SDK**, que implementa a API: decide quais spans manter (amostragem), os agrupa em lotes e os entrega aos
  exportadores;
- **exportadores**, que mandam os dados para algum lugar: o console, um endpoint OTLP, o Azure Monitor;
- **convenções semânticas**, nomes de atributo combinados, como `http.route`, `db.system` e `server.address`, para todo
  backend saber o que um span significa sem ninguém precisar dizer.

Um **span** é uma unidade de trabalho com início, fim, tipo, atributos e status. Spans formam um **trace**: dividem um id
de trace, e cada um menos o primeiro nomeia o pai. O **tipo** (kind) de um span diz o papel que ele teve: `SERVER` para
atender uma requisição que chegou, `CLIENT` para uma chamada para fora, `INTERNAL` para o trabalho no meio.

**O jeito recomendado pela Microsoft de mandar telemetria ao Application Insights hoje é o OpenTelemetry.** Para Python,
.NET, Java e Node.js ela publica uma **distro OpenTelemetry do Azure Monitor**: o SDK do OpenTelemetry com o exportador do
Azure Monitor e um conjunto de instrumentações automáticas já ligados, para uma chamada configurar tudo. Os SDKs antigos
do Application Insights ainda existem e funcionam, e a Microsoft encaminha trabalho novo para o OpenTelemetry.

O que a distro acrescenta é conveniência, não um modelo diferente. Ela lê uma **connection string** que nomeia o recurso
do Application Insights, instrumenta automaticamente bibliotecas comuns (frameworks web, clientes HTTP, drivers de banco)
e mapeia os spans do OpenTelemetry para as tabelas do Application Insights. As duas próximas seções escrevem a
instrumentação à mão, rodam, e então olham esse mapa.
