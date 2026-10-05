---
title: Acrescentando o que só o código sabe
version: 1
---

O remédio para a primeira lacuna não é substituir a instrumentação automática. **É acrescentar ao
span que ela já abriu.** A instrumentação do Flask torna o seu span `SERVER` o span corrente durante
a requisição inteira. Por isso o código dentro do tratador consegue alcançá-lo com
`trace.get_current_span()` e definir um atributo nele, sem span novo e sem configuração. Uma linha
em `create()` faz isso, e a importação ganha um nome:

```
ana@obs:~/shop$ sed -i 's/^    traceparent = request.headers.get("traceparent")/&\n    trace.get_current_span().set_attribute("shop.sku", body["sku"])/; s/^from opentelemetry import propagate/from opentelemetry import propagate, trace/' services/orders/app.py
ana@obs:~/shop$ grep -n 'trace' services/orders/app.py | head -4
5:publish() that carry the trace into the message, because nothing instruments
15:from opentelemetry import propagate, trace
54:    traceparent = request.headers.get("traceparent")
55:    trace.get_current_span().set_attribute("shop.sku", body["sku"])
```

Depois de um reinício e de um checkout, o span automático carrega o atributo que o código
acrescentou:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/e5978340492b8d7ed0b69c7ed6adcab4 | jq -c '.data[0].spans[] | select(.operationName == "POST /orders") | [.tags[] | select(.key | test("^(shop|http.route)")) | {(.key): .value}] | add'
{"http.route":"/orders","shop.sku":"kettle"}
```

**`shop.sku` agora está ao lado de `http.route`** num span que o Flask abriu. A mesma função serve
para tudo o que esta aula achou faltando. Chame `set_attribute` para aquilo de que a requisição tratava,
abra um `start_as_current_span` próprio em volta de um trabalho interno lento, e faça as chamadas de
propagação da aula 4 no cliente que ninguém instrumentou. A linha é barata: sem SDK, o
`get_current_span()` devolve o mesmo span que não faz nada que o `no_sdk.py` imprimiu na aula 2,
então não custa nada onde o rastreamento está desligado.

Esse é o arranjo em que a maioria dos serviços acaba, e o motivo de este curso ensinar as duas
metades: **instrumentação automática para as bordas, algumas linhas escritas à mão para o que as
bordas não sabem.** A edição foi desfeita depois desta captura, então o resto do curso roda o
`orders` do próprio laboratório.
