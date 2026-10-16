---
title: Um cenário, seis linhas
version: 1
---

**Um Scenario Outline é um cenário com lacunas, e uma tabela de Examples que as preenche, uma
execução por linha.** Teste de limites produz exatamente essa forma: a mesma requisição com um valor
diferente a cada vez, e uma resposta esperada diferente. A lição 2 derivou os casos para o número de
lugares a partir da regra "um número inteiro de 1 a 6"; aqui eles viram uma tabela.

Salve como `karate/src/test/java/boxoffice/seats.feature`:

```
Feature: How many seats one order may ask for

  Background:
    * def ci = callonce read('token.feature') { clientId: 'ci-tests', clientSecret: 'ci-secret' }
    * url baseUrl
    * configure headers = { Authorization: '#("Bearer " + ci.token)' }

  Scenario Outline: <seats> seats is answered <status>
    Given path 'v1', 'orders'
    And request { show_id: 'sh-102', seats: <seats> }
    When method post
    Then status <status>

    Examples:
      | seats | status |
      | 0     | 422    |
      | 1     | 201    |
      | 6     | 201    |
      | 7     | 422    |
      | 2.5   | 422    |
      | '2'   | 422    |
```

`<seats>` e `<status>` são preenchidos pelas colunas de mesmo nome. O nome do cenário também os tem,
então cada linha é informada com um nome próprio, `7 seats is answered 422`, em vez de seis falhas
debaixo de um título só. As linhas, e para que serve cada uma:

| seats | esperado | por que está na tabela |
|---|---|---|
| `0` | `422` | logo abaixo do menor permitido |
| `1` | `201` | o menor permitido |
| `6` | `201` | o maior permitido |
| `7` | `422` | logo acima do maior |
| `2.5` | `422` | um número, mas não inteiro |
| `'2'` | `422` | um número inteiro escrito como texto: `"2"` no JSON |

**As aspas da última linha importam.** A célula é colada na requisição do jeito que está escrita,
então `2` mandaria o número e `'2'` manda o texto, e os dois são entradas diferentes para o servidor.
A lição 2 perguntou qual deles o boxoffice deveria aceitar; esta tabela diz o que ele faz.

As linhas usam o `sh-102`, de que nenhuma outra feature compra, então este arquivo e o
`orders.feature` não conseguem esgotar os lugares um do outro. Cada execução compra sete lugares
dele, um e seis, então os 120 lugares duram dezessete execuções e a décima oitava vê um `409` na
linha de seis lugares; reiniciar o boxoffice os devolve.

```
ana@laptop:~/boxoffice/karate$ mvn -q test -Dkarate.options=classpath:boxoffice/seats.feature
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
ana@laptop:~/boxoffice/karate$ echo $?
0
```

```
POST /oauth/token 200
POST /v1/orders 422
POST /v1/orders 201
POST /v1/orders 201
POST /v1/orders 422
POST /v1/orders 422
POST /v1/orders 422
```

Um token, depois seis pedidos, um por linha, com os status da tabela. **O Karate rodou as linhas na
ordem da tabela**, então o log se lê como a tabela lida de cima para baixo, o que facilita casar uma
linha do log do servidor com uma linha de uma execução que falhou.
