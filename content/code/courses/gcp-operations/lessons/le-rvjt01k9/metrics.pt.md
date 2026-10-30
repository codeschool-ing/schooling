---
title: Contadores e distribuições, declarados
version: 1
---

**Um contador diz quantas linhas casaram; uma distribuição diz como um número dentro delas se espalhou.** O
segundo tipo lê um valor de cada entrada que casa, `total_cents` aqui, e guarda um histograma dos valores por
minuto, para que percentis possam ser lidos dele do jeito que a lição 8 leu a latência. É como "quanto vale o
pedido típico, e isso está mudando" vira um gráfico sem uma linha de código nova.

Antes de declarar os buckets do histograma, olhe os valores que o log tem:

```
ana@laptop:~/gcp$ jq -r 'select(.message == "order placed") | .total_cents' checkout.log | sort -n | uniq -c
    272 1890
    296 2490
    271 4380
    255 6870
```

Quatro preços, em números mais ou menos iguais. Buckets com limites em 1000, 2000, 3000, 5000 e 10000 centavos
põem cada preço num bucket próprio (1890 no segundo, 2490 no terceiro, 4380 no quarto, 6870 no quinto), então o
histograma mantém o formato dos dados. **Os buckets são fixados quando a métrica é criada e não podem mudar
depois sem uma métrica nova**, então escolha-os pelos dados, não por um palpite.

As duas métricas, em `~/gcp/tf/logmetrics/main.tf`:

```hcl
# tf/logmetrics/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_logging_metric" "payment_retries" {
  name   = "shop/payment_retries"
  filter = "resource.labels.service_name=\"shop-api\" AND jsonPayload.message=\"payment retried\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    labels {
      key        = "provider"
      value_type = "STRING"
    }
  }
  label_extractors = {
    provider = "EXTRACT(jsonPayload.provider)"
  }
}

resource "google_logging_metric" "order_value" {
  name            = "shop/order_value_cents"
  filter          = "resource.labels.service_name=\"shop-api\" AND jsonPayload.message=\"order placed\""
  value_extractor = "EXTRACT(jsonPayload.total_cents)"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "1"
  }
  bucket_options {
    explicit_buckets {
      bounds = [1000, 2000, 3000, 5000, 10000]
    }
  }
}
```

Três coisas para ler nele:

- **`label_extractors`** tira `provider` do payload de cada entrada, que é a divisão que a seção anterior fez
  com `jq`. O rótulo também é declarado no descritor; um rótulo extraído e não declarado é erro na criação.
- **`value_extractor`** é o que faz de `order_value` uma distribuição: o número que ele extrai é o valor
  registrado, e `bucket_options` diz como fazer o histograma dele.
- **`metric_kind = "DELTA"`**: uma métrica baseada em log conta o que casou em cada intervalo. Nunca é
  cumulativa, porque nada guarda um total corrente.

O plano deste arquivo, junto com o alerta da próxima seção, está no fim daquela seção.

## Quanto custam

Uma métrica baseada em log é cobrada como qualquer métrica que um programa escreve, pelo volume de pontos que
produz, ao preço que a lição 8 citou. Um contador com um rótulo de dois valores são duas séries e custa muito
pouco; o mesmo contador com um id de pedido como rótulo é uma série por pedido. **As entradas que ele conta
também precisam ser guardadas**: uma métrica conta entradas conforme elas são escritas num bucket, e uma entrada
excluída pela exclusão da lição 9 nunca é contada. Excluir os health checks e contá-los no mesmo projeto é uma
contradição que o plano não pega.
