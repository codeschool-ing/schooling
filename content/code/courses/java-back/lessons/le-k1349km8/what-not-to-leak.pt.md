---
title: O que um erro não pode dizer
version: 1
---

A crença tentadora é que mais detalhe num erro ajuda todo mundo: o cliente vê exatamente o que quebrou e
pode relatar. Mas o cliente de uma API é um estranho, e os detalhes de uma falha dentro do servidor são
coisas sobre as quais ele não pode fazer nada: um banco que recusou uma conexão, um comando SQL, um nome
de classe, a versão de uma biblioteca. Para um cliente de boa-fé, isso é ruído. Para alguém sondando a
API, é um mapa do lado de dentro, dizendo qual banco roda em qual máquina com qual usuário. **A resposta
diz o que o cliente pode fazer, e o log guarda todo o resto.**

## Uma falha que ninguém previu

A livraria não tem banco de dados até a aula 9, então este desvio planta um substituto para um banco que
falhou. No `InMemoryBookRepository.java`, troque o `findById` por este:

```java
    @Override
    public Optional<Book> findById(long id) {
        throw new IllegalStateException("connection to db-01.bookshop.example:5432 refused for user bookshop");
    }
```

Compile, reinicie e peça o livro 1:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -si localhost:8080/books/1 -w '\n'
HTTP/1.1 500 
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:41:22 GMT
Connection: close

{"timestamp":"2026-10-22T22:41:22.507Z","status":500,"error":"Internal Server Error","path":"/books/1"}
```

Nenhum handler da `ApiErrorHandler` reclama uma `IllegalStateException`, então este é o 500 da primeira
seção desta aula, e o corpo é o do Spring Boot: um timestamp, o status, a frase dele e o caminho. A
mensagem não está ali. O segundo terminal tem tudo:

```
2026-10-22T19:41:22.496-03:00 ERROR 6477 --- [bookshop] [nio-8080-exec-1] o.a.c.c.C.[.[.[/].[dispatcherServlet]    : Servlet.service() for servlet [dispatcherServlet] in context with path [] threw exception [Request processing failed: java.lang.IllegalStateException: connection to db-01.bookshop.example:5432 refused for user bookshop] with root cause

java.lang.IllegalStateException: connection to db-01.bookshop.example:5432 refused for user bookshop
```

Essa divisão é o padrão do Spring Boot, não sorte. A página de erro dele tem propriedades que decidem o
que vai para o corpo, todas desligadas por padrão, e a livraria não mexe nelas. Ligar uma delas mostra o
que o padrão deixa de fora, e mostra uma armadilha no caminho. Respostas escritas para o Spring Boot 3
dão a propriedade como `server.error.include-message`. Iniciada com
`--server.error.include-message=always`, a livraria responde exatamente como antes:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/1 -w '\n'
{"timestamp":"2026-10-22T22:41:27.227Z","status":500,"error":"Internal Server Error","path":"/books/1"}
```

**O Spring Boot 4 renomeou o grupo para `spring.web.error`**, e o nome antigo é aceito e ignorado. O
Spring Boot tem um módulo para achar exatamente isso, o `spring-boot-properties-migrator`, que informa
propriedades renomeadas quando a aplicação sobe. Iniciada com
`--spring.web.error.include-message=always`, a mesma requisição responde:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/1 -w '\n'
{"timestamp":"2026-10-22T22:41:31.962Z","status":500,"error":"Internal Server Error","message":"connection to db-01.bookshop.example:5432 refused for user bookshop","path":"/books/1"}
```

E com `--spring.web.error.include-stacktrace=always`, o corpo ganha um membro `trace`: o stack trace
inteiro numa string só, que o pequeno programa Python abaixo imprime uma linha por vez, parando na
sexta:

```
ana@vm:~/bookshop$ curl -s localhost:8080/books/1 | python3 -c 'import json, sys; print(*json.load(sys.stdin)["trace"].splitlines()[:6], sep="\n")'
java.lang.IllegalStateException: connection to db-01.bookshop.example:5432 refused for user bookshop
	at com.example.bookshop.catalogue.InMemoryBookRepository.findById(InMemoryBookRepository.java:30)
	at com.example.bookshop.catalogue.BookService.get(BookService.java:21)
	at com.example.bookshop.catalogue.BookController.get(BookController.java:33)
	at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:104)
	at java.base/java.lang.reflect.Method.invoke(Method.java:565)
```

O resto continua por todas as classes do Spring e do Tomcat por onde a requisição passou. Nomes de
pacotes, de classes, de arquivos e números de linha são uma descrição do lado de dentro, entregue a
quem perguntar. Nenhuma das duas propriedades pertence a uma configuração implantada, e o log já tem
tudo o que elas acrescentam.

## O pega-tudo que vaza

O jeito comum de trazer o 500 também para o formato de problema é um handler para `Exception`, a mãe de
quase tudo. Escrito às pressas, ele fica assim. Acrescente-o à `ApiErrorHandler` acima da sobrescrita,
como um segundo desvio, depois compile e reinicie:

```java
    @ExceptionHandler(Exception.class)
    public ProblemDetail unexpected(Exception e) {
        return problem(HttpStatus.INTERNAL_SERVER_ERROR, "unexpected", "Unexpected error", e.getMessage());
    }
```

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ curl -si localhost:8080/books/1 -w '\n'
HTTP/1.1 500 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:41:51 GMT
Connection: close

{"detail":"connection to db-01.bookshop.example:5432 refused for user bookshop","instance":"/books/1","status":500,"title":"Unexpected error","type":"https://bookshop.example/problems/unexpected"}
ana@vm:~/bookshop$ curl -si localhost:8080/nope -w '\n'
HTTP/1.1 404 
Content-Type: application/problem+json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:41:51 GMT

{"detail":"No static resource nope.","instance":"/nope","status":404,"title":"Not Found"}
```

Duas falhas num método só. O detail é a própria mensagem da exceção, então a máquina, a porta e o
usuário do banco foram parar no cliente. E o segundo terminal não imprimiu erro nenhum: a exceção contou como
tratada, então nada a registrou, e a única pessoa que podia consertar o banco foi a única que não ficou
sabendo.

A segunda requisição mostra o que o pega-tudo não fez. `/nope` continuou com o seu 404, porque o Spring
escolhe o handler cujo tipo de exceção é o mais próximo do lançado. A `NoResourceFoundException` tem um
handler próprio, e `Exception` só recebe o que nada mais específico reclama.

Apague o método e devolva o `findById` ao que era antes de seguir.

## Por que a livraria não tem pega-tudo

Um pega-tudo pode ser escrito com segurança: ele registra a exceção com o stack trace e responde com uma
frase fixa que não nomeia nada. Muitas aplicações têm um. A livraria não tem, porque "tudo o que nada
mais específico reclama" cresce junto com a aplicação. O Spring Security, que chega na aula 15, recusa
acesso lançando uma exceção própria e a transforma em 401 ou 403 mais adiante, depois que o controller
terminou. Um handler para `Exception` no advice pode pegá-la antes e responder 500. A página de erro do
Spring Boot já faz a metade segura do trabalho, registrando tudo e não dizendo nada. O preço é que o 500
da livraria é a única resposta fora do formato de problema, um preço pago por um erro que não deveria
acontecer.

## O que um detail pode dizer

Todo `detail` da livraria é uma frase que alguém escreveu para o cliente, montada com o que o cliente
mandou. "No book has id 99" devolve o id que foi pedido e nada mais. As mensagens das restrições foram
escritas para quem preenche o formulário. E os handlers do próprio Spring seguem a mesma regra: um corpo
que não é JSON recebe "Failed to read request", enquanto o log do perfil `dev`
em "Os erros do próprio Spring" mostrou as palavras do próprio Jackson, `JSON parse error: Unexpected
end-of-input within/between Object entries`. Essas palavras são inofensivas. As da próxima biblioteca
podem não ser.

**Então `e.getMessage()` só vai para uma resposta quando foi você quem escreveu a exceção.** A mensagem
de uma biblioteca é escrita para o desenvolvedor que vai ler o log, e traz o que desenvolvedores
precisam: SQL, caminhos, nomes de máquinas, valores de outras linhas. A aula 13 de `apis` põe isso ao
lado das outras formas de uma API contar demais a um estranho.
