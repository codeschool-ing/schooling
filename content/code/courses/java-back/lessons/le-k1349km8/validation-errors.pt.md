---
title: O mapa de erros de validação
version: 1
---

Um 400 que diz "requisição inválida" e para por aí é meia resposta. O cliente mandou vários campos e
alguns estavam errados, e o que ele precisa saber é quais e por quê: um formulário põe cada mensagem ao
lado do seu campo, e um script registra o campo que errou. A Bean Validation sabe tudo isso quando
rejeita uma requisição (aula 6). O trabalho da livraria é repassar.

Quando o `@Valid` falha num `@RequestBody`, o Spring MVC lança **`MethodArgumentNotValidException`**, que
carrega um resultado de binding com um erro para cada restrição que falhou. A
`ResponseEntityExceptionHandler` responde a essa exceção num método próprio,
`handleMethodArgumentNotValid`, e a `ApiErrorHandler` o sobrescreve:

```java
    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException e, HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        Map<String, String> errors = new TreeMap<>();
        e.getBindingResult().getFieldErrors()
                .forEach(f -> errors.put(f.getField(), f.getDefaultMessage()));
        ProblemDetail body = problem(HttpStatus.BAD_REQUEST, "invalid-request", "Invalid request",
                errors.size() + " field(s) failed validation");
        body.setProperty("errors", errors);
        return ResponseEntity.badRequest().body(body);
    }
```

O `getFieldErrors()` dá um `FieldError` por restrição que falhou. O `getField()` é o nome do componente do
record, que também é a propriedade JSON que o cliente mandou, e o `getDefaultMessage()` é a mensagem da
restrição. O **`setProperty`** acrescenta um membro que a RFC não define, uma extensão, e o Jackson o
escreve ao lado dos cinco padrão. O método devolve uma `ResponseEntity` em vez de uma `ProblemDetail`
pura só porque o método que ele sobrescreve foi declarado assim.

## Por que sobrescrever, e não escrever um handler próprio

A alternativa óbvia é mais um `@ExceptionHandler` na `ApiErrorHandler`. Experimente como desvio:
acrescente este método acima da sobrescrita, compile e reinicie.

```java
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ProblemDetail invalid(MethodArgumentNotValidException e) {
        return problem(HttpStatus.BAD_REQUEST, "invalid-request", "Invalid request", "the request is not valid");
    }
```

Compila. A aplicação não sobe, e a última causa no segundo terminal diz por quê:

```
Caused by: java.lang.IllegalStateException: Ambiguous @ExceptionHandler method mapped for [ExceptionHandler{exceptionType=org.springframework.web.bind.MethodArgumentNotValidException, mediaType=*/*}]: {public org.springframework.http.ProblemDetail com.example.bookshop.web.ApiErrorHandler.invalid(org.springframework.web.bind.MethodArgumentNotValidException), public final org.springframework.http.ResponseEntity org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler.handleException(java.lang.Exception,org.springframework.web.context.request.WebRequest) throws java.lang.Exception}
```

A classe agora tem dois handlers para uma exceção, o herdado e o novo, e o Spring se recusa a escolher
entre eles em vez de deixar uma escolha que ninguém escreveu decidir a resposta. Apague o método de
novo. Toda exceção que a classe base trata tem um método `protected` como o
`handleMethodArgumentNotValid`, chamado pelo handler herdado, e sobrescrever esse método é o jeito de
mudar a resposta.

## O que o cliente recebe

Compile, reinicie e mande de novo o livro ruim da aula 6. O `python3 -m json.tool` imprime o JSON com um
membro por linha:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000017", "title": "", "priceCents": -1}' | python3 -m json.tool
{
    "detail": "4 field(s) failed validation",
    "instance": "/books",
    "status": 400,
    "title": "Invalid request",
    "type": "https://bookshop.example/problems/invalid-request",
    "errors": {
        "author": "must not be blank",
        "isbn": "must be a valid ISBN-13",
        "priceCents": "must be greater than or equal to 0",
        "title": "must not be blank"
    }
}
```

Quatro campos, quatro mensagens, e um cliente que consegue agir sobre cada uma. As chaves chegam em
ordem alfabética porque o mapa é um **`TreeMap`**. A Bean Validation informa as violações sem ordem
definida, então um `HashMap` poderia listar os mesmos quatro campos em ordens diferentes em duas
execuções. Um programa não se importaria. Uma pessoa comparando duas respostas se importaria, e um teste
que compara o corpo inteiro também.

As mensagens são as das próprias restrições, e três delas vêm do Hibernate Validator, a implementação que
o starter de validação traz. Elas seguem o idioma que a requisição pede:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books -H 'Content-Type: application/json' -H 'Accept-Language: pt-BR' -d '{"isbn": "9786500000017", "title": "", "priceCents": -1}' | python3 -m json.tool
{
    "detail": "4 field(s) failed validation",
    "instance": "/books",
    "status": 400,
    "title": "Invalid request",
    "type": "https://bookshop.example/problems/invalid-request",
    "errors": {
        "author": "n\u00e3o deve estar em branco",
        "isbn": "must be a valid ISBN-13",
        "priceCents": "deve ser maior ou igual a 0",
        "title": "n\u00e3o deve estar em branco"
    }
}
```

`must be a valid ISBN-13` ficou em inglês porque a `@ValidIsbn` declara a mensagem como uma frase pronta.
As restrições padrão declaram as suas como chaves entre chaves, como
`{jakarta.validation.constraints.NotBlank.message}`, que o Hibernate Validator procura num arquivo por
idioma, e o Spring passa a ele o `Accept-Language` da requisição.

## Uma mensagem por campo

Um mapa de um campo para uma mensagem guarda uma mensagem por campo. Um título de 201 espaços está em
branco e longo demais ao mesmo tempo, e o resto deste livro é válido:

```
ana@vm:~/bookshop$ python3 -c 'import json; print(json.dumps({"isbn": "9786500000078", "title": " " * 201, "author": "Jane Austen", "priceCents": 2500}))' | curl -s localhost:8080/books -H 'Content-Type: application/json' -d @- | python3 -m json.tool
{
    "detail": "1 field(s) failed validation",
    "instance": "/books",
    "status": 400,
    "title": "Invalid request",
    "type": "https://bookshop.example/problems/invalid-request",
    "errors": {
        "title": "must not be blank"
    }
}
```

Duas restrições falharam e uma mensagem chegou ao cliente; o `detail` diz um campo, porque conta as
entradas do mapa. Qual das duas mensagens vence não está definido. Para um formulário isso
basta: a pessoa corrige o título, manda de novo e encontra a outra mensagem se ela ainda valer. Um
cliente que precisa mostrar todos os motivos de uma vez precisa de uma lista por campo,
`Map<String, List<String>>`, uma mudança pequena de que a livraria não precisa.
