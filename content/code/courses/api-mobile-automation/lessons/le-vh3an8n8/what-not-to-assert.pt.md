---
title: O que não afirmar
version: 1
---

**Um teste deve falhar quando a API está errada, e só então.** Um teste que também falha quando o
relógio anda, quando outro teste rodou antes ou quando o servidor acrescenta um campo inofensivo é
um teste que as pessoas aprendem a ignorar. Um teste ignorado não pega nada. A causa de costume é
afirmar algo que a API nunca prometeu.

Esta coleção erra de propósito, três vezes. Salve como `postman/brittle.postman_collection.json`:

```json
{
  "info": {
    "name": "brittle",
    "description": "Three assertions that pass once and never again.",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "auth": {"type": "bearer", "bearer": [{"key": "token", "value": "{{token}}", "type": "string"}]},
  "item": [
    {
      "name": "Get token",
      "event": [
        {
          "listen": "test",
          "script": {
            "type": "text/javascript",
            "exec": ["pm.collectionVariables.set('token', pm.response.json().access_token);"]
          }
        }
      ],
      "request": {
        "method": "POST",
        "url": "{{baseUrl}}/oauth/token",
        "body": {
          "mode": "urlencoded",
          "urlencoded": [
            {"key": "grant_type", "value": "client_credentials"},
            {"key": "client_id", "value": "{{clientId}}"},
            {"key": "client_secret", "value": "{{clientSecret}}"}
          ]
        },
        "auth": {"type": "noauth"}
      }
    },
    {
      "name": "Create order",
      "event": [
        {
          "listen": "test",
          "script": {
            "type": "text/javascript",
            "exec": [
              "pm.test('the order is ord-1001', () => {",
              "  pm.expect(pm.response.json().id).to.equal('ord-1001');",
              "});",
              "pm.test('the body is exactly this', () => {",
              "  pm.expect(pm.response.json()).to.eql({",
              "    id: 'ord-1001', show_id: 'sh-103', seats: 1, total_cents: 6500,",
              "    status: 'confirmed', payment: 'ch-local-ord-1001',",
              "  });",
              "});",
              "pm.test('it was answered today', () => {",
              "  pm.expect(pm.response.headers.get('Date')).to.include('10 Oct 2026');",
              "});"
            ]
          }
        }
      ],
      "request": {
        "method": "POST",
        "url": "{{baseUrl}}/v1/orders",
        "header": [{"key": "Content-Type", "value": "application/json"}],
        "body": {
          "mode": "raw",
          "raw": "{\"show_id\": \"sh-103\", \"seats\": 1}",
          "options": {"raw": {"language": "json"}}
        }
      }
    }
  ]
}
```

Reinicie o boxoffice no terminal dele, para que fique sem pedidos, e rode duas vezes:

```
ana@laptop:~/boxoffice$ npx --yes newman@6.2.3 run postman/brittle.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode
newman

brittle

Root Get token
  POST http://localhost:8080/oauth/token [200 OK, 479B, 36ms]

Root Create order
  POST http://localhost:8080/v1/orders [201 Created, 316B, 5ms]
  Pass  the order is ord-1001
  Pass  the body is exactly this
  1. it was answered today

-----------------------------------------------------------------
|                         |         executed |           failed |
--------------------------+------------------+-------------------
|              iterations |                1 |                0 |
--------------------------+------------------+-------------------
|                requests |                2 |                0 |
--------------------------+------------------+-------------------
|            test-scripts |                2 |                0 |
--------------------------+------------------+-------------------
|      prerequest-scripts |                0 |                0 |
--------------------------+------------------+-------------------
|              assertions |                3 |                1 |
-----------------------------------------------------------------
| total run duration: 110ms                                     |
-----------------------------------------------------------------
| total data received: 408B (approx)                            |
-----------------------------------------------------------------
| average response time: 20ms [min: 5ms, max: 36ms, s.d.: 15ms] |
-----------------------------------------------------------------

  #  failure         detail                                                            
                                                                                       
 1.  AssertionError  it was answered today                                             
                     expected 'Sun, 11 Oct 2026 01:39:17 GMT' to include '10 Oct 2026' 
                     at assertion:2 in test-script                                     
                     inside "Create order"                                             
```

```
ana@laptop:~/boxoffice$ npx --yes newman@6.2.3 run postman/brittle.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode
newman

brittle

Root Get token
  POST http://localhost:8080/oauth/token [200 OK, 479B, 19ms]

Root Create order
  POST http://localhost:8080/v1/orders [201 Created, 316B, 5ms]
  1. the order is ord-1001
  2. the body is exactly this
  3. it was answered today

----------------------------------------------------------------
|                         |         executed |          failed |
--------------------------+------------------+------------------
|              iterations |                1 |               0 |
--------------------------+------------------+------------------
|                requests |                2 |               0 |
--------------------------+------------------+------------------
|            test-scripts |                2 |               0 |
--------------------------+------------------+------------------
|      prerequest-scripts |                0 |               0 |
--------------------------+------------------+------------------
|              assertions |                3 |               3 |
----------------------------------------------------------------
| total run duration: 85ms                                     |
----------------------------------------------------------------
| total data received: 408B (approx)                           |
----------------------------------------------------------------
| average response time: 12ms [min: 5ms, max: 19ms, s.d.: 7ms] |
----------------------------------------------------------------

  #  failure         detail                                                                     
                                                                                                
 1.  AssertionError  the order is ord-1001                                                      
                     expected 'ord-1002' to equal 'ord-1001'                                    
                     at assertion:0 in test-script                                              
                     inside "Create order"                                                      
                                                                                                
 2.  AssertionError  the body is exactly this                                                   
                     expected { id: 'ord-1002', …(5) } to deeply equal { id: 'ord-1001', …(5) } 
                     at assertion:1 in test-script                                              
                     inside "Create order"                                                      
                                                                                                
 3.  AssertionError  it was answered today                                                      
                     expected 'Sun, 11 Oct 2026 01:39:18 GMT' to include '10 Oct 2026'          
                     at assertion:2 in test-script                                              
                     inside "Create order"                                                      
```

A primeira execução passa em tudo. A segunda, instantes depois contra o mesmo servidor, falha em duas
das três, e a API não fez nada de errado no meio.

## O id do pedido

`ord-1001` é o id do primeiro pedido depois de reiniciar, e nada mais. O boxoffice promete que um
pedido recebe um id e que o `location` diz onde ele mora; nunca prometeu qual id. A segunda execução
recebeu `ord-1002`, porque o pedido da primeira existe. Todo teste que roda depois de outro, na mesma
execução ou no mesmo servidor, vê um número diferente. **Afirme o formato, e leia o valor da
resposta**: um id que case com `/^ord-\d+$/`, e a requisição seguinte usando o `location`, como faz a
seção 04.

## O corpo inteiro

`eql` contra o corpo inteiro repete o problema do id em cada campo, e acrescenta um problema
próprio. Ele falha no dia em que o boxoffice acrescenta um campo, como um `created_at`, que nenhum
cliente lê. **Afirme os campos de que o teste trata.** O Create order da coleção confere `show_id`,
`seats` e `status`, porque é isso que a requisição pediu. `total_cents` e `payment` merecem testes
também, mas testes próprios, com nomes que digam que regra conferem: o preço vezes os lugares, a
referência do pagamento.

## O cabeçalho Date

O terceiro teste passou nas duas vezes, e é o pior dos três. Ele confere que o cabeçalho `Date`
contém `10 Oct 2026`, o que é verdade no dia em que as transcrições foram gravadas e falso em
qualquer outro. **Quem rodar hoje vai vê-lo falhar já na primeira execução.** `Date` é quando o
servidor respondeu. Um teste pode conferir que ele existe e que é uma data válida; o valor pertence
ao relógio.

## A mesma regra, em quatro linhas

| não afirme | porque | afirme no lugar |
|---|---|---|
| um id gerado pelo servidor | depende do que rodou antes | o formato, e depois use-o |
| o corpo inteiro com `eql` | qualquer campo novo o quebra | os campos de que o teste trata |
| `Date`, ou qualquer horário | depende do relógio | que existe, ou um intervalo |
| uma contagem de tudo, como todos os pedidos | outros testes aumentam a contagem | o que este teste criou |

A coleção ainda afirma que há espetáculos e que todos trazem um número inteiro de lugares restantes. Ela não afirma que são
exatamente três, o que é verdade no boxoffice hoje e falharia no dia em que o teatro acrescentasse um
espetáculo, sem nada quebrado.
