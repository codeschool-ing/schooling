---
title: Os erros do próprio Spring, no mesmo formato
version: 1
---

Alguns erros acontecem antes de qualquer código da livraria rodar: o corpo não é JSON, o caminho não
corresponde a nenhum controller, o método é um que o caminho não aceita. O Spring MVC lança exceções
próprias para esses casos, e a livraria da aula 6 respondia a elas com a página de erro do Spring Boot,
num formato só dela:

@@CAP before-spring@@

Dois formatos numa mesma API é pior que qualquer um dos dois sozinho. Um cliente que lê `type` e
`detail` de um 400 e encontra `timestamp` e `error` no seguinte precisa tratar os dois, e nada diz a ele
qual esperar.

A **`ResponseEntityExceptionHandler`** é a correção, e é por isso que a `ApiErrorHandler` a estende. A
classe é do Spring. Ela traz um `@ExceptionHandler` para as exceções que o próprio Spring MVC lança, e
cada um responde com uma `ProblemDetail`. Estendê-la põe todos eles dentro do advice da livraria, ao
lado dos handlers da própria livraria. Peça à livraria recompilada o mesmo tipo de coisa, e um pouco
mais:

@@CAP spring@@

Toda resposta é `application/problem+json` agora, e cada status é o que o HTTP tem para o caso:

| o que o cliente mandou | status | a exceção que o Spring MVC lançou |
|---|---|---|
| um corpo que não é JSON, ou um valor do tipo errado | 400 | `HttpMessageNotReadableException` |
| uma variável de caminho que não converte, `/books/abc` | 400 | `MethodArgumentTypeMismatchException` |
| um caminho que nenhum controller mapeia | 404 | `NoResourceFoundException` |
| um método que o caminho não aceita | 405 | `HttpRequestMethodNotSupportedException` |
| um `Content-Type` que nada consegue ler | 415 | `HttpMediaTypeNotSupportedException` |

O 405 e o 415 trazem também um cabeçalho, porque o HTTP pede um. `Allow: GET` lista os métodos que
`/books/1` aceita, e `Accept` lista os media types que `/books` consegue ler. O 404 de `/nope` fala em
recurso estático por causa de como o Spring MVC procura: um caminho que nenhum controller mapeia é
oferecido por último ao handler que serve arquivos de `src/main/resources/static`, e a exceção desse
handler é o jeito de informar "não há nada aqui".

Nenhum desses problemas tem `type`. O Spring o deixa em `about:blank` e o omite ao escrever o JSON, e a
RFC diz o que isso significa: o problema é exatamente o que o código de status diz, e o `title` é a
própria frase do status, "Bad Request" ou "Not Found". Para um corpo que não é JSON, não há mesmo nada
mais específico que a livraria pudesse dizer a um cliente.

A coluna da direita da tabela não é palpite. O perfil `dev` da aula 4 registra as classes web do Spring
em `debug`, e entre essas linhas está a exceção por trás de cada resposta de erro, que é o primeiro lugar
para olhar quando uma resposta surpreende. Iniciada com `--spring.profiles.active=dev`, na porta 8081, a
aplicação deixou estas linhas no segundo terminal para as cinco primeiras requisições acima:

@@CAP resolved@@

@@RESOLVED-NOTE@@

Então uma exceção agora encontra três camadas no caminho de saída, e a primeira que a reclama responde:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Três faixas empilhadas que uma exceção atravessa de cima para baixo. Primeiro, os handlers da própria livraria: BookNotFoundException dá 404 e DuplicateIsbnException dá 409. Segundo, os handlers herdados de ResponseEntityExceptionHandler: HttpMessageNotReadableException 400, MethodArgumentTypeMismatchException 400, NoResourceFoundException 404, HttpRequestMethodNotSupportedException 405, HttpMediaTypeNotSupportedException 415, e MethodArgumentNotValidException 400, que a livraria sobrescreve. Terceiro, a página de erro do Spring Boot, que responde a qualquer outra com 500 e um formato próprio: timestamp, status, error, path.\"><defs><marker id=\"lyr-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"80\" y=\"20\" width=\"600\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"96\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">os handlers da livraria</text><text x=\"330\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">BookNotFoundException</text><text x=\"578\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 404</text><text x=\"330\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">DuplicateIsbnException</text><text x=\"578\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 409</text><rect x=\"80\" y=\"100\" width=\"600\" height=\"128\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"96\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">herdados de</text><text x=\"96\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">ResponseEntityExceptionHandler</text><text x=\"330\" y=\"119.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HttpMessageNotReadableException</text><text x=\"578\" y=\"119.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 400</text><text x=\"330\" y=\"137.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MethodArgumentTypeMismatchException</text><text x=\"578\" y=\"137.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 400</text><text x=\"330\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">NoResourceFoundException</text><text x=\"578\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 404</text><text x=\"330\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HttpRequestMethodNotSupportedException</text><text x=\"578\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 405</text><text x=\"330\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HttpMediaTypeNotSupportedException</text><text x=\"578\" y=\"191.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 415</text><text x=\"330\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">MethodArgumentNotValidException</text><text x=\"578\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 400</text><text x=\"616\" y=\"209.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">(sobrescrito)</text><rect x=\"80\" y=\"244\" width=\"600\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"96\" y=\"276.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a página de erro do Spring Boot</text><text x=\"330\" y=\"267.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">qualquer outra</text><text x=\"330\" y=\"285.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">→ 500, timestamp, status, error, path</text><line x1=\"40\" y1=\"24\" x2=\"40\" y2=\"300\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\" marker-end=\"url(#lyr-a)\"></line><text x=\"30\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" transform=\"rotate(-90 30 160)\">uma exceção</text></svg>", "caption": "As duas primeiras camadas respondem no formato de problema. O que passa pelas duas chega ao Spring Boot, que responde 500 num formato só dele."}
```
