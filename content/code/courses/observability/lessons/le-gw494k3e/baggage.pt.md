---
title: Baggage, e o que nunca pode viajar nela
version: 1
---

O contexto que viaja tem uma segunda parte além do rastro. A **baggage** é um conjunto de pares de
chave e valor que um serviço põe no contexto e que todo serviço adiante consegue ler, levado num
cabeçalho próprio ao lado do `traceparent`. O `baggage.py` define uma entrada e faz o inject, como
um serviço faria antes de chamar o seguinte:

```python
from opentelemetry import baggage, context, propagate, trace
from opentelemetry.sdk.trace import TracerProvider

trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer("baggage")

ctx = baggage.set_baggage("shop.channel", "mobile-app")
token = context.attach(ctx)
with tracer.start_as_current_span("checkout"):
    headers = {}
    propagate.inject(headers)
    for name, value in headers.items():
        print(f"{name}: {value}")
context.detach(token)
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python baggage.py 2>/dev/null
traceparent: 00-0c531134f2a06a5c7c096165b02bd3c7-c44dc70726c00067-03
baggage: shop.channel=mobile-app
```

O segundo cabeçalho é a baggage: `shop.channel=mobile-app`. Um serviço três saltos adiante consegue
lê-la com `baggage.get_baggage("shop.channel")` e, por exemplo, registrá-la nos seus próprios spans,
para que *os checkouts do aplicativo estão mais lentos?* possa ser perguntado a um serviço que nunca
viu o aplicativo.

Duas propriedades da baggage passam despercebidas com facilidade, e as duas dão problema:

- **Ela não é um atributo.** Nada registra a baggage num span automaticamente. Ela viaja, e um
  serviço que a queira nos seus spans tem de copiá-la para lá, ou configurar um span processor que o
  faça.
- **Ela viaja para todo lugar aonde o contexto vai**, e o contexto vai com toda chamada de saída que
  a instrumentação vê: para os seus próprios serviços, e também para um provedor de pagamento, uma
  API de mapas ou qualquer outro terceiro que a loja chame por HTTP. O que estiver na baggage é
  enviado a todos eles, em texto puro, a cada requisição.

Essa segunda propriedade é a regra: **nada pessoal nem secreto vai na baggage**. Nem o e-mail ou o
CPF de um cliente, nem um token de sessão, nem um nome de máquina interno que você não publicaria.
Um canal, uma região, um id de cliente corporativo que não significa nada fora da empresa: é para isso
que ela serve. E como cada entrada é enviada em toda chamada, ela também custa bytes; algumas poucas
entradas curtas são o teto, não o começo.
