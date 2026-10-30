---
title: O que a biblioteca repete, e quando ela desiste
version: 1
---

**Uma requisição que sofre throttling é repetida pela biblioteca antes de o seu código saber dela.** A
política da biblioteca Python para um 429 é curta o bastante para ler no próprio código dela, em
`azure/cosmos/_resource_throttle_retry_policy.py`: esperar o que o `x-ms-retry-after-ms` pediu, tentar
de novo, e parar depois de um número de tentativas ou quando a espera somar um limite, o que vier
primeiro. Os padrões estão na própria biblioteca, e perguntar a ela é o jeito honesto de conhecê-los:

```
ana@laptop:~/azure$ python -c 'from azure.cosmos.documents import RetryOptions; r = RetryOptions(); print(r.MaxRetryAttemptCount, r.MaxWaitTimeInSeconds, r.FixedRetryIntervalInMilliseconds)'
9 30 None
```

**Nove tentativas e trinta segundos, e nenhum intervalo fixo**, então a espera é a que o serviço pediu
a cada vez. Os dois podem ser mudados quando o cliente é criado. Uma requisição interativa, um cliente
esperando a página, deve desistir antes de trinta segundos, e uma carga em lote às três da manhã pode
se dar ao luxo de esperar mais. Sejam quais forem os números, a requisição que sobrevive a eles chega
como uma exceção com status 429, e o programa tem de decidir o que isso quer dizer.

O programa abaixo grava um pedido com um cliente que repete três vezes e espera no máximo cinco
segundos, e mostra os dois lugares em que um programa fica sabendo do throttling. Salve como
`writer.py`:

```schooling-example
{"language": "python", "file": "writer.py", "parts": [
{"code": "from azure.cosmos import CosmosClient, exceptions\n\nKEY = \"C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==\"\nclient = CosmosClient(\"http://localhost:8081\", KEY,\n                      retry_throttle_total=3,\n                      retry_throttle_backoff_max=5)\norders = client.get_database_client(\"quitanda\").get_container_client(\"promo\")\n", "note": "As duas opções que importam para um 429. `retry_throttle_total` é quantas vezes a biblioteca repete uma requisição que sofreu throttling, e `retry_throttle_backoff_max` quantos segundos de espera ela soma antes de desistir. Sem elas, são 9 e 30."},
{"code": "\n\ndef save(order):\n    try:\n        orders.upsert_item(order)\n    except exceptions.CosmosHttpResponseError as e:\n        if e.status_code != 429:\n            raise\n        wait = int(e.headers.get(\"x-ms-retry-after-ms\", 1000))\n        print(f\"{order['id']} still throttled after the retries; told to wait {wait} ms\")\n        return False\n", "note": "Um 429 que sobrevive às repetições chega como `CosmosHttpResponseError`. Qualquer outra coisa é relançada, porque um 409 ou um 412 é outro problema. A espera que o serviço pediu está em `x-ms-retry-after-ms`, e a função a informa em vez de dormir, para quem chamou decidir: pôr o pedido numa fila, ir mais devagar ou avisar a pessoa."},
{"code": "    answer = orders.client_connection.last_response_headers\n    print(order[\"id\"], \"saved;\", answer.get(\"x-ms-throttle-retry-count\", \"0\"), \"throttled attempts,\",\n          answer.get(\"x-ms-throttle-retry-wait-time-ms\", \"0\"), \"ms waited\")\n    return True\n", "note": "Depois de um sucesso, a biblioteca acrescenta dois cabeçalhos dela à resposta: quantas tentativas sofreram throttling e quanto tempo ela esperou no total. Um programa que os registra vê o throttling começando, como lentidão, bem antes da primeira exceção."},
{"code": "\n\nsave({\"id\": \"o-90001\", \"customerId\": \"c-7\", \"totalCents\": 4890})\n", "note": "Um pedido, gravado no contêiner que o `flood.py` criou."}
]}
```

```
ana@laptop:~/azure$ python writer.py
o-90001 saved; 0 throttled attempts, 0 ms waited
```

**Zero tentativas com throttling e zero milissegundos**, que no emulador é toda resposta que vai
existir, então o ramo `except` não rodou aqui: o 429 que ele trata nunca foi produzido, e nenhum 429 do
Azure aparece em lugar nenhum deste curso. O código foi escrito contra o formato que a Microsoft
documenta e o código da própria biblioteca, e a primeira vez que ele rodar de verdade vai ser contra
uma conta.

## Repetir não é um plano de capacidade

**As repetições escondem o throttling até não conseguirem mais.** Um contêiner que sofre throttling em
1% do tempo responde um pouco mais devagar e ninguém nota; com 30% as próprias repetições são um terço
a mais de requisições, cada uma gastando unidades de requisição que o contêiner não tinha, e a latência
sobe até as requisições estourarem o tempo. Três coisas mudam isso, e nenhuma delas é um número maior
de tentativas:

- **mais vazão, ou autoescala com um máximo maior**, quando o contêiner inteiro está ocupado;
- **uma chave de partição melhor**, quando uma partição está ocupada e as outras não, como mostrou a
  seção anterior;
- **menos trabalho por requisição**: uma leitura pontual em vez de uma consulta, uma consulta que
  nomeia a chave de partição, menos propriedades indexadas num contêiner que é mais gravado que lido.

A lição 24 volta às repetições pelo outro lado: uma escrita repetida que na verdade tinha dado certo é
um duplicado, e só uma escrita com um id que quem escreve escolheu torna o segundo inofensivo.
