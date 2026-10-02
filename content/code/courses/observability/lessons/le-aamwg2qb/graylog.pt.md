---
title: Graylog: um produto de logs sobre o mesmo tipo de índice
version: 1
---

O Graylog guarda as linhas no OpenSearch, um fork de código aberto do Elasticsearch, então o índice
dele funciona do jeito que a seção anterior descreveu. **O que ele acrescenta é o produto em volta**:
inputs que recebem muitos formatos, *streams* que roteiam linhas por regras, usuários e permissões por
stream, alertas sobre buscas, e uma interface feita para quem lê logs o dia inteiro. O MongoDB dele
guarda essa configuração; as linhas em si ficam no OpenSearch.

A input criada antes está escutando, na porta que o OTLP por gRPC usa:

```
ana@obs:~/shop$ curl -s -u admin:$(cat .graylog-password) -H 'X-Requested-By: ana' localhost:9000/api/system/inputs | jq -r '.inputs[] | [.title, .attributes.port] | @tsv'
shop logs (OTLP)	4317
```

O Graylog arquiva cada campo que recebe sob um nome próprio, prefixado pela origem: o `order_id` da
loja aqui é `otel_attributes_order_id`, e o serviço é `otel_resource_attributes_service_name`. A
sintaxe de busca dele é campo e valor, e a API consegue responder em CSV:

```
ana@obs:~/shop$ curl -s -u admin:$(cat .graylog-password) -H 'X-Requested-By: ana' -H 'Accept: text/csv' 'localhost:9000/api/search/universal/relative?query=otel_attributes_message:%22card%20network%20unavailable%22&range=600&limit=2&fields=timestamp,otel_attributes_order_id,otel_attributes_trace_id'
"timestamp","otel_attributes_order_id","otel_attributes_trace_id"
"2026-10-02T15:41:33.000Z","300.0","cbb05aede41b48fa7c79060630ba8a52"
"2026-10-02T15:41:38.000Z","320.0","ac2e32e38ebc87cd1c31c2630275fe46"
```

As mesmas falhas, duas delas, com ids de pedido e de rastro. **Os prefixos merecem atenção antes de
escrever qualquer coisa contra eles**: todo armazenamento renomeia campos na entrada, o Elasticsearch
os aninha sob `attributes.`, o Graylog os achata com `otel_attributes_`, o Loki os deixa na linha, e
uma consulta, um painel ou um alerta copiado de um armazenamento para outro falha nos nomes antes de
falhar em qualquer outra coisa.
