---
title: Um vazamento, feito de propósito
version: 2
---

Vazamentos raramente são alguém decidindo registrar uma senha. **São uma linha de depuração prestativa
que registra um objeto inteiro**, escrita enquanto se caçava um bug e esquecida. Eis uma, acrescentada
à vitrine do jeito que costuma acontecer, logo depois de o corpo da requisição ser lido.
Guarde antes uma cópia do código da vitrine, para devolvê-lo no fim da aula:

```sh
cp services/storefront/app.py /tmp/storefront.app.py
```

Depois, a linha:

```
ana@obs:~/shop$ sed -i 's/^        body = request.get_json()$/&\n        log.debug("request", extra={"fields": {"headers": dict(request.headers), "body": body}})/' services/storefront/app.py && grep -n 'log.debug' services/storefront/app.py
35:        log.debug("request", extra={"fields": {"headers": dict(request.headers), "body": body}})
```

A linha registra todo cabeçalho e o corpo inteiro em `DEBUG`, que a aula 8 mostrou estar desligado por
padrão. Alguém então liga o `DEBUG` para investigar, no arquivo de override que já aponta o Collector para o Loki
e o Elasticsearch. Troque o `compose.override.yaml` por este:

```yaml
services:
  otel-collector:
    volumes: ["./otel/collector-logs.yaml:/etc/otelcol/config.yaml:ro"]
  storefront:
    environment:
      LOG_LEVEL: DEBUG
```

E um cliente faz um checkout. O aplicativo dele manda um token de acesso no cabeçalho `Authorization`, como um cliente de API
faz; ele é inventado e não funciona em lugar nenhum:

```
ana@obs:~/shop$ docker compose up -d storefront 2>&1 | tail -1
 Container shop-storefront-1 Started 
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -H 'Authorization: Bearer sk_live_9f8e7d6c5b4a' -d @checkout.json
{"id":2701,"qty":1,"sku":"kettle","status":"paid"}
```

O checkout funcionou; nada falhou e nada avisou. E no Loki, achado buscando a palavra `Bearer`:

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="storefront"} |= "Bearer"' --data-urlencode since=5m | jq -r '.data.result[].values[][1]' | jq -c '{message, card: .body.card, auth: .headers.Authorization}'
{"message":"request","card":"4111 1111 1111 1111","auth":"Bearer sk_live_9f8e7d6c5b4a"}
```

**O número completo do cartão e o token, guardados, indexados e legíveis por qualquer pessoa com acesso
aos logs**, e copiados para o Elasticsearch na mesma viagem. Cada linha entre este momento e alguém
perceber acrescenta o cartão de mais um cliente. O cartão de teste não cobra ninguém; um real no mesmo
lugar é um incidente de segurança a ser comunicado, e a LGPD e as regras do setor de cartões têm, cada
uma, algo a dizer sobre ele.

Repare no que tornou isso possível: não a linha de depuração sozinha, mas **a linha de depuração mais um
nível que a liga em produção**. É por isso que as defesas a seguir não dependem de o nível estar
certo.
