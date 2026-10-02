---
title: O que dá para ver de fora
version: 1
---

Comece de onde o cliente está. O `checkout.json` é um checkout: uma chaleira, uma unidade, e um
número de cartão que os sistemas de pagamento reservam para testes e que não cobra ninguém:

```json
{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}
```

Mandado à vitrine, ele volta como um pedido:

```
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json
{"id":1,"qty":1,"sku":"kettle","status":"paid"}
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code} in %{time_total} s\n' -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json
201 in 0.036398 s
```

O `-w` pede ao `curl` que imprima o código de status e o tempo total em vez do corpo: `201 Created`,
em 36 milissegundos. Agora o payments é instruído a ficar lento. O laboratório lê
`faults/payments.json` a cada cobrança, e este arquivo faz cada uma esperar um segundo e meio antes
de responder:

```
ana@obs:~/shop$ echo '{"latency_ms": 1500}' > faults/payments.json
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code} in %{time_total} s\n' -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json
201 in 1.536103 s
```

**Ainda um `201`, e agora 1,54 segundo.** Nada falhou: o pedido foi guardado, o cartão foi cobrado,
a confirmação saiu. Uma verificação que pergunta *respondeu, e com um código de sucesso?* aprova
esta requisição exatamente como aprovou a primeira. Um cliente esperando um segundo e meio para
saber que pagou não a aprova.

Isso é tudo o que o lado de fora consegue dizer. O checkout atravessou quatro serviços, um banco de
dados e uma fila, e daqui ele é um número só. **Qual deles gastou o tempo não está na resposta**, e
nenhuma quantidade de atenção à resposta vai pôr isso lá. O que vem a seguir é o mesmo checkout
visto por três sinais que a loja foi construída para emitir, e cada um existe porque algumas linhas
de código da loja o produzem. Em seguida o laboratório rodou um minuto de clientes simulados, duas
requisições por segundo, para que os sinais tenham mais de uma requisição dentro.
