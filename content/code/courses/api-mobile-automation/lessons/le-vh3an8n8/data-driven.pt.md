---
title: Uma requisição, muitos casos vindos de um arquivo
version: 1
---

**Uma execução orientada a dados manda as mesmas requisições uma vez por linha de um arquivo, com as
colunas da linha como variáveis.** Os limites de `seats` são o caso óbvio: 0, 1, 6, 7, uma fração e
uma string, cada um com o status que o boxoffice deveria responder. Seis requisições que diferem num
número são uma requisição e uma tabela.

Escreva a tabela no seu editor e salve como `postman/seats.csv`:

```
seats,expected
0,422
1,201
6,201
7,422
2.5,422
"""2""",422
```

A primeira linha dá nome às colunas, e cada linha depois dela é um caso. O último valor é a string
`"2"`. Em CSV, uma aspa dentro de um campo entre aspas é escrita duas vezes, então `"""2"""` é um
campo que contém `"2"`, com as aspas. Ele chega ao corpo JSON como string, não como número.

A pasta `seat rules` tem uma requisição, **Order seats**, cujo corpo usa as duas colunas:

```json
{"show_id": "sh-101", "seats": {{seats}}}
```

e cujo teste lê o status esperado da mesma linha:

```js
const expected = Number(pm.variables.get('expected'));
pm.test(`seats ${pm.variables.get('seats')} answers ${expected}`, () => {
  pm.response.to.have.status(expected);
});
```

O nome do teste é montado a partir da linha, então cada caso aparece com o próprio nome. O `sh-101` é
usado porque tem 120 lugares: os casos que deveriam dar certo não podem ficar sem lugar e falhar por
um motivo que não é o do teste.

## A execução

`-d` entrega o arquivo ao Newman, e `--folder` limita a execução a uma pasta:

```
ana@laptop:~/boxoffice$ npx --yes newman@6.2.3 run postman/boxoffice.postman_collection.json -e postman/lab.postman_environment.json --folder 'seat rules' -d postman/seats.csv --disable-unicode
newman

boxoffice

Iteration 1/6

Folder seat rules
Sub-folder Order seats
  POST http://localhost:8080/oauth/token [200 OK, 479B, 31ms]
  POST http://localhost:8080/v1/orders [422 Unprocessable Entity, 308B, 4ms]
  Pass  seats 0 answers 422

Iteration 2/6

Sub-folder Order seats
  POST http://localhost:8080/v1/orders [201 Created, 316B, 3ms]
  Pass  seats 1 answers 201

Iteration 3/6

Sub-folder Order seats
  POST http://localhost:8080/v1/orders [201 Created, 317B, 2ms]
  Pass  seats 6 answers 201

Iteration 4/6

Sub-folder Order seats
  POST http://localhost:8080/v1/orders [422 Unprocessable Entity, 308B, 3ms]
  Pass  seats 7 answers 422

Iteration 5/6

Sub-folder Order seats
  POST http://localhost:8080/v1/orders [422 Unprocessable Entity, 308B, 3ms]
  Pass  seats 2.5 answers 422

Iteration 6/6

Sub-folder Order seats
  POST http://localhost:8080/v1/orders [422 Unprocessable Entity, 308B, 3ms]
  Pass  seats "2" answers 422

---------------------------------------------------------------
|                         |        executed |          failed |
--------------------------+-----------------+------------------
|              iterations |               6 |               0 |
--------------------------+-----------------+------------------
|                requests |               7 |               0 |
--------------------------+-----------------+------------------
|            test-scripts |               6 |               0 |
--------------------------+-----------------+------------------
|      prerequest-scripts |              12 |               0 |
--------------------------+-----------------+------------------
|              assertions |               6 |               0 |
---------------------------------------------------------------
| total run duration: 220ms                                   |
---------------------------------------------------------------
| total data received: 1kB (approx)                           |
---------------------------------------------------------------
| average response time: 7ms [min: 2ms, max: 31ms, s.d.: 9ms] |
---------------------------------------------------------------
```

Seis iterações, uma por linha, e seis aprovações. O token foi buscado uma vez, antes da primeira
iteração, pelo script de pré-requisição da coleção da seção 05. As iterações seguintes o encontraram
ainda válido. No Postman o mesmo arquivo vai no Runner, em *Data*, que então mostra cada iteração.

## Onde moram os valores da linha

O arquivo de dados é o escopo **dados** da seção 04 da lição 4, mais estreito que coleção e
ambiente. A coleção define `seats` como `1` e `expected` como `201`. É por isso que a pasta também
roda numa execução da coleção inteira sem arquivo nenhum, como um pedido comum que deveria dar
certo. Foi a linha de **Order seats** no fim da execução da seção 02. Com um arquivo, os valores da
linha vencem, porque o escopo de dados é mais estreito. Um padrão no escopo mais amplo e um caso no
mais estreito é a regra de precedência da lição 4 trabalhando a seu favor.

**Cada linha é uma afirmação, então escolha-as como escolheria casos.** Estas seis são os limites que
a lição 2 tirou do contrato: o menor valor válido e o de baixo dele, o maior e o de cima dele, e dois
valores do tipo errado. Um arquivo com cem linhas entre 2 e 5 rodaria cem vezes e não testaria nada
novo.
