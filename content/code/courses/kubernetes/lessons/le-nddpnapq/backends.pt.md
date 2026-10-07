---
title: Três sinais, e o que os guarda
version: 1
---

Os componentes do cluster expõem métricas; a loja não:

```
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- shop/metrics
shop 1.0 on shop-774b84ff8c-5tnl8
```

**`/metrics` na loja devolve a página comum dela**, porque ela responde todo caminho do mesmo jeito. Ela
não publica contadores próprios, então um sistema de monitoramento saberia quanta CPU ela usa, mas não
quantos pedidos recebeu nem quantos falharam. Essa metade é escrita na aplicação, com uma biblioteca de
cliente, e nada no Kubernetes consegue fornecê-la.

| sinal | responde | coletado por | guardado e buscado em, comumente |
|---|---|---|---|
| métricas | quanto, com que frequência, com que velocidade, ao longo do tempo | raspagem de `/metrics` | Prometheus, e serviços feitos sobre ele |
| logs | o que exatamente aconteceu, linha a linha | um coletor em todo nó | Loki, Elasticsearch |
| traces | onde uma requisição gastou o tempo entre serviços | a aplicação, pelo OpenTelemetry | Jaeger, Tempo |

**O OpenTelemetry é o fio comum**: um conjunto de bibliotecas e um coletor que conseguem produzir os
três sinais em formatos padrão, para que a escolha de onde guardá-los continue aberta. Nada disto foi
instalado para este curso, então esta seção descreve e não roda.

::: track devops
O curso `observability`, mais adiante na sua trilha, monta essa pilha: o Prometheus na lição 5,
instrumentar um serviço com OpenTelemetry na lição 2, e tracing na lição 11.
:::

::: track *
O curso `observability` monta essa pilha: o Prometheus na lição 5, instrumentar um serviço com
OpenTelemetry na lição 2, e tracing na lição 11.
:::
