---
title: Uma instância ou várias: escopos
version: 1
---

Todo bean até aqui foi criado uma vez, e o log disse isso com as próprias palavras: "Creating shared
instance of singleton bean". Existe um `bookService` no contexto, e toda classe que pede um
`BookService` recebe esse mesmo objeto. Esse é o escopo **singleton**, e é o padrão. O **escopo** de
um bean decide quantas instâncias dele o contêiner faz, e quando.

O nome engana quem conhece o padrão de projeto singleton, em que uma classe garante que só uma
instância dela pode existir. **Um singleton do Spring é um por contexto de aplicação**, e nada impede
outro código de fazer mais: `Wiring.java` chamou `new InMemoryBookRepository()` e obteve uma segunda
instância perfeitamente boa.

## Vendo acontecer

Acrescente esta classe ao pacote `com.example.bookshop` por um momento, como
`src/main/java/com/example/bookshop/ScopeCheck.java`. Ela recebe um `BookService` pelo construtor, pede
mais dois ao contexto e os compara:

```java
package com.example.bookshop;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

import com.example.bookshop.catalogue.BookService;

@Component
public class ScopeCheck implements CommandLineRunner {

    private final BookService injected;
    private final ApplicationContext context;

    public ScopeCheck(BookService injected, ApplicationContext context) {
        this.injected = injected;
        this.context = context;
    }

    @Override
    public void run(String... args) {
        BookService first = context.getBean(BookService.class);
        BookService second = context.getBean(BookService.class);
        System.out.println("asked twice, the same object: " + (first == second));
        System.out.println("the injected one is the same object: " + (injected == first));
    }
}
```

O contexto é ele mesmo um bean, então um construtor pode pedi-lo, e `getBean` pede a ele um bean
diretamente, pelo tipo. Código comum não deveria precisar disso: uma classe que procura as próprias
dependências voltou a ir buscá-las. Aqui é o jeito mais rápido de pedir duas vezes.

```
ana@vm:~/bookshop$ mvn -B -q package && java -jar target/bookshop-0.1.0.jar --spring.main.web-application-type=none | grep -E 'Catalogue|object'
asked twice, the same object: true
the injected one is the same object: true
2026-10-22T19:17:05.652-03:00  INFO 18250 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 3 books
```

Agora faça de `BookService` um **prototype**, um bean criado de novo cada vez que é pedido. Acrescente
`@Scope("prototype")` abaixo de `@Service`, com o import:

```
ana@vm:~/bookshop$ sed -n '6,12p' src/main/java/com/example/bookshop/catalogue/BookService.java
import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Service;

@Service
@Scope("prototype")
public class BookService {

ana@vm:~/bookshop$ mvn -B -q package && java -jar target/bookshop-0.1.0.jar --spring.main.web-application-type=none | grep -E 'Catalogue|object'
2026-10-22T19:17:08.938-03:00  INFO 18369 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 3 books
asked twice, the same object: false
the injected one is the same object: false
```

As duas comparações viraram falsas. Cada `getBean` montou um `BookService` novo, e o parâmetro do
construtor também, uma vez, quando `ScopeCheck` foi criado. Essa última parte é a armadilha: **um
prototype injetado num singleton é criado uma vez**, junto com o singleton, e o singleton guarda esse
objeto pelo resto da vida. Código que esperava um objeto novo a cada chamada recebe um objeto para
sempre. Apague `ScopeCheck.java` e a linha `@Scope`.

## Por que um singleton precisa ser seguro para compartilhar

Um objeto compartilhado por tudo é um objeto usado por todas as threads. A partir da lição 6 a livraria
responde a requisições web, cada uma na sua própria thread, e duas requisições podem chamar
`BookService.add` no mesmo instante. É por isso que `InMemoryBookRepository` guarda os livros num
`ConcurrentSkipListMap` e os numera com um `AtomicLong`. Com um `HashMap` e um `long` incrementado por
`nextId++`, dois livros salvos juntos poderiam, de vez em quando, receber o mesmo id, sob carga e em
nenhum teste que rode uma requisição por vez.

A regra para um singleton é que ele não guarde estado que mude, ou só guarde estado seguro de usar a
partir de várias threads ao mesmo tempo. `BookService` é do primeiro tipo: o seu único campo é `final`
e aponta para um repositório. O repositório é do segundo.

## Escopo de requisição, em resumo

Uma aplicação web acrescenta escopos ligados ao HTTP. Um bean de escopo **request** existe uma vez por
requisição, e um de escopo **session** uma vez por sessão de usuário. Um bean de escopo de requisição
guarda o que pertence a uma única requisição, como quem a enviou. Injetado num singleton ele não pode
ser o objeto simples, já que o singleton vive mais que todas as requisições, então o Spring injeta um
proxy que encontra a instância da requisição atual a cada chamada. A livraria nunca precisa de um.
Quando a lição 16 quer o id da requisição em toda linha de log, ela usa o contexto por thread da
biblioteca de log.
