---
title: Um painel para quem o abre às três
version: 1
---

Um painel é um documento JSON de widgets, e vale guardá-lo no repositório ao lado do serviço, como os
alarmes da lição 10, para ele mudar quando o serviço mudar. O painel da API da loja, `dashboard.json`:

```json
{
  "widgets": [
    {
      "type": "text", "x": 0, "y": 0, "width": 24, "height": 2,
      "properties": {
        "markdown": "## shop api\nOwner: team shop. When this page is red, start with the latency graph."
      }
    },
    {
      "type": "metric", "x": 0, "y": 2, "width": 12, "height": 6,
      "properties": {
        "title": "Latency, p50 and p99", "region": "sa-east-1", "period": 60,
        "metrics": [
          ["Shop", "Latency", "Service", "api", { "stat": "p50" }],
          ["...", { "stat": "p99" }]
        ]
      }
    },
    {
      "type": "metric", "x": 12, "y": 2, "width": 12, "height": 6,
      "properties": {
        "title": "Orders per minute", "region": "sa-east-1", "period": 60, "stat": "Sum",
        "metrics": [["Shop", "Orders", "Service", "api", "Stage", "prod"]]
      }
    }
  ]
}
```

Cada widget tem uma posição numa grade de 24 unidades de largura e um objeto `properties`. Uma linha de
métrica lista o namespace, o nome e as dimensões em pares; `"..."` repete a linha de cima, então a
linha do p99 é a mesma métrica com outra estatística. O widget de texto é a parte que as pessoas
esquecem e a parte de que mais precisa quem é chamado às três da manhã: **quem é o dono disto, e onde
olhar primeiro**.

```
ana@laptop:~/aws/metrics$ aws cloudwatch put-dashboard --dashboard-name shop-api --dashboard-body file://dashboard.json
{
    "DashboardValidationMessages": []
}
ana@laptop:~/aws/metrics$ aws cloudwatch list-dashboards --query 'DashboardEntries[].[DashboardName,Size]' --output text
shop-api	833
ana@laptop:~/aws/metrics$ aws cloudwatch get-dashboard --dashboard-name shop-api --query DashboardBody --output text | jq '.widgets | length'
3
```

O moto guardou o painel e devolve o corpo dele; não há console aqui para desenhá-lo. Na AWS o console
desenha cada widget a partir das métricas, e `get-metric-widget-image` renderiza um como imagem para
uma mensagem de chat ou um postmortem.

## O que cabe nele

Um painel que mostra tudo não mostra nada. Para um serviço, quatro sinais respondem à maioria das
perguntas, nesta ordem:

1. **latência**, como p50 e p99, porque é o que os clientes sentem primeiro;
2. **tráfego**, requisições ou pedidos por minuto, porque todo outro número é lido contra ele;
3. **erros**, como taxa e não contagem, porque dez erros numa hora parada e numa hora cheia são
   notícias diferentes;
4. **saturação**: o recurso que acaba primeiro, a profundidade de uma fila, as conexões de um pool.

Ponha a métrica de negócio ao lado deles (aqui, os pedidos) e deixe o detalhe de infraestrutura para
painéis próprios. **O painel é para reconhecer o problema; os logs são para explicá-lo**, e a lição 9
é sobre eles.

Painéis são cobrados por painel por mês acima de alguns gratuitos, e essa linha não está na lista de
preços em massa que este curso lê; a página de preços do CloudWatch da AWS a traz.
