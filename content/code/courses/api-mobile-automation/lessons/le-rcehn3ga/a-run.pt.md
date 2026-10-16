---
title: Uma execução, lida linha por linha
version: 1
---

**Uma execução do Newman imprime três coisas, em ordem: cada requisição com os seus testes, uma
tabela que os conta e as falhas em detalhe.** A primeira parte serve para acompanhar a execução
enquanto acontece, a tabela serve para saber de relance se algo deu errado, e a última parte é onde
você descobre o quê. Com o boxoffice rodando no terminal dele:

```
ana@laptop:~/boxoffice$ npm run test:api

> boxoffice@1.0.0 test:api
> newman run postman/boxoffice.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode

newman

boxoffice

Folder shows
Sub-folder List shows
  POST http://localhost:8080/oauth/token [200 OK, 479B, 39ms]
  GET http://localhost:8080/v1/shows [200 OK, 569B, 4ms]
  Pass  status is 200
  Pass  the body is JSON
  Pass  every show has a whole number of seats left

Sub-folder One show
  GET http://localhost:8080/v1/shows/sh-103 [200 OK, 312B, 4ms]
  Pass  status is 200
  Pass  it is the show asked for
  Pass  it carries an etag

Sub-folder HEAD one show
  HEAD http://localhost:8080/v1/shows/sh-103 [405 Method Not Allowed, 171B, 5ms]
  1. HEAD answers like GET

Folder auth
Sub-folder Get token
  POST http://localhost:8080/oauth/token [200 OK, 479B, 5ms]
  Pass  status is 200
  Pass  a bearer token comes back
  Pass  nobody may keep a copy of it

Folder orders
Sub-folder Create order
  POST http://localhost:8080/v1/orders [201 Created, 316B, 3ms]
  Pass  status is 201
  Pass  the order is for the show and the seat asked for
  Pass  location says where it lives

Sub-folder Read order
  GET http://localhost:8080/v1/orders/ord-1001 [200 OK, 280B, 3ms]
  Pass  status is 200
  Pass  it is the order just created

Sub-folder Cancel order
  DELETE http://localhost:8080/v1/orders/ord-1001 [204 No Content, 111B, 3ms]
  Pass  status is 204

Sub-folder Read cancelled order
  GET http://localhost:8080/v1/orders/ord-1001 [200 OK, 280B, 4ms]
  Pass  the order now says cancelled

Folder seat rules
Sub-folder Order seats
  POST http://localhost:8080/v1/orders [201 Created, 316B, 4ms]
  Pass  seats 1 answers 201

----------------------------------------------------------------
|                         |         executed |          failed |
--------------------------+------------------+------------------
|              iterations |                1 |               0 |
--------------------------+------------------+------------------
|                requests |               10 |               0 |
--------------------------+------------------+------------------
|            test-scripts |                9 |               0 |
--------------------------+------------------+------------------
|      prerequest-scripts |               11 |               0 |
--------------------------+------------------+------------------
|              assertions |               18 |               1 |
----------------------------------------------------------------
| total run duration: 309ms                                    |
----------------------------------------------------------------
| total data received: 1.55kB (approx)                         |
----------------------------------------------------------------
| average response time: 7ms [min: 3ms, max: 39ms, s.d.: 10ms] |
----------------------------------------------------------------

  #  failure         detail                                                
                                                                           
 1.  AssertionError  HEAD answers like GET                                 
                     expected response to have status code 200 but got 405 
                     at assertion:0 in test-script                         
                     inside "shows / HEAD one show"                        
```

## As requisições

As duas linhas que começam com `>` vêm do npm, não do Newman: o nome do script e o comando que ele
roda. Depois o Newman nomeia a coleção e a percorre na ordem do arquivo, como a seção 06 da lição 4
disse que faria. Cada requisição é uma linha de fatos, como o `GET` embaixo de **List shows**: o
método, o endereço depois de as variáveis serem trocadas e, entre colchetes, o status, o tamanho da
resposta e quanto ela demorou. Uma linha acima dela sem requisição própria, o `POST` para
`/oauth/token` embaixo de **List shows**, é o script de pré-requisição da coleção buscando um token,
que a seção 05 da lição 5 explicou. Embaixo de cada requisição vêm os testes dela: `Pass` e o nome,
ou um número e o nome, para uma falha.

## A tabela

| linha | conta | aqui |
|---|---|---|
| `iterations` | passagens pela coleção inteira; mais de uma só com arquivo de dados | 1 |
| `requests` | toda requisição mandada, inclusive a do `pm.sendRequest` | 10 |
| `test-scripts` | scripts de pós-resposta que rodaram | 9 |
| `prerequest-scripts` | scripts de pré-requisição que rodaram: o da coleção antes de cada uma das 9 requisições, mais 2 das próprias requisições | 11 |
| `assertions` | chamadas a `pm.test`, que é o que as pessoas chamam de testes | 18, 1 falhou |

**A coluna `failed` de `requests` conta requisições que nem puderam ser mandadas**, uma conexão
recusada ou um endereço quebrado, e não requisições que receberam status de erro. Um `405` é uma
resposta, então **HEAD one show** conta como requisição que funcionou e asserção que falhou. Uma
tabela com zero em toda célula `failed`, menos em `assertions`, diz que o servidor respondeu tudo e
discordou dos testes em algum ponto; uma linha `requests` diferente de zero diz que algo mais básico
está errado, como o boxoffice não estar rodando.

As três linhas embaixo da tabela são tempos e um tamanho. `total run duration` é a execução inteira, e
`average response time` é sobre as requisições, com a mais rápida, a mais lenta e o desvio padrão ao
lado. Mudam a cada execução e em cada máquina, então pertencem a um relatório, não a uma asserção.

## As falhas

O último bloco repete cada asserção que falhou com o que o Newman sabe sobre ela: o tipo de erro, o
nome do teste, a mensagem e onde aconteceu, `inside "shows / HEAD one show"`, como pasta e
requisição. É esse bloco que você lê primeiro quando uma execução falha, e é o que o log de um
pipeline mostra no fim, que é onde as pessoas olham.
