---
title: Um argumento a menos
version: 1
---

A propagação falha em silêncio, e o jeito de reconhecer o sintoma é provocá-lo uma vez. O extract
do payments é mantido, mas o contexto que ele devolve deixa de ser usado para começar o span:

```
ana@obs:~/shop$ grep -n 'context=ctx' services/payments/app.py
46:    with tracer.start_as_current_span("POST /charge", context=ctx, kind=SpanKind.SERVER) as span:
ana@obs:~/shop$ sed -i 's/, context=ctx, kind=SpanKind.SERVER/, kind=SpanKind.SERVER/' services/payments/app.py && docker compose restart payments 2>&1 | tail -1
 Container shop-payments-1 Started 
```

Um checkout, e os ids de rastro que a vitrine e o payments registraram para ele:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix storefront | grep 'checkout finished' | tail -1 | jq -r .trace_id
ae937cc824d4843fbac8e390ddb3cc0c
ana@obs:~/shop$ docker compose logs --no-log-prefix payments | grep 'charge decided' | tail -1 | jq -r .trace_id
ec2f711fe663aea741f0cc263469fb72
```

**Dois ids de rastro para um checkout**, o mesmo sintoma que a aula 3 encontrou na fila, agora em
HTTP comum. O cabeçalho ainda chegou e ainda foi extraído. Sem `context=ctx` o span simplesmente
começou do contexto corrente do próprio payments, que está vazio no começo de uma requisição, e
virou a raiz de um rastro novo. E o rastro do checkout, lido do lado da vitrine:

```
ana@obs:~/shop$ curl -s localhost:16686/api/traces/ae937cc824d4843fbac8e390ddb3cc0c | jq -r '.data[0] as $t | $t.spans | sort_by(.startTime) | .[] | [$t.processes[.processID].serviceName, .operationName] | @tsv'
storefront	POST /checkout
orders	POST /orders
orders	INSERT
orders	POST
orders	UPDATE
mailer	orders.placed process
mailer	send confirmation
```

Sete spans, todos os serviços menos um, e **nada no rastro diz que falta algum**. O `POST` do `orders`
saiu e voltou, então o span dele está completo; o trabalho que ele causou está arquivado sob outro
id. Ninguém recebe erro, o checkout funciona, os dois rastros parecem saudáveis sozinhos. A única
pista é um span de cliente sem span de servidor debaixo dele, e um serviço cujos rastros têm todos
uma raiz só.

Dois hábitos pegam isso. Olhe um rastro de todo serviço novo e confira que o primeiro span tem um
pai vindo de outro serviço. E num serviço instrumentado à mão, **trate o `extract` e o span que o usa
como uma unidade**, nunca duas linhas que podem se afastar numa edição. O `app.py` original foi
devolvido e o payments reiniciado antes da seção seguinte.
