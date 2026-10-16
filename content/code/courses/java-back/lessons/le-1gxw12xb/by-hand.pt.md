---
title: Os objetos, montados à mão
version: 1
---

A livraria ganha suas primeiras classes de verdade nesta lição: um livro, um lugar para guardar
livros, um serviço sobre esse lugar e um relatório que roda na inicialização. Elas dependem umas das
outras, então alguém precisa criá-las na ordem certa e entregar a cada uma os objetos que ela pede. O
Spring vai fazer isso. Esta seção faz à mão primeiro, para que nada do que o Spring fizer depois seja
mistério.

Uma imagem comum do Spring é que as anotações nessas classes é que as fazem funcionar: que `@Service`
transforma uma classe em serviço. **Uma anotação não faz nada sozinha.** Ela é uma etiqueta que algum
outro código pode ler, e um programa que nunca a lê roda exatamente como se ela não estivesse lá. O
programa no fim desta seção é esse programa.

## Os seis arquivos

Crie estes arquivos em `~/bookshop`, ao lado do que a lição 4 deixou lá. Cinco ficam no pacote
`com.example.bookshop.catalogue`, e o sexto em `com.example.bookshop.config`.

`src/main/java/com/example/bookshop/catalogue/Book.java`:

```java
package com.example.bookshop.catalogue;

public record Book(long id, String isbn, String title, String author, int priceCents) {

    public Book withId(long newId) {
        return new Book(newId, isbn, title, author, priceCents);
    }
}
```

Um **record** carrega os cinco valores de um livro, com o preço em centavos para que nenhuma conta com
ele arredonde. `withId` devolve uma cópia com um novo id, e é assim que o repositório abaixo numera um
livro que guarda.

`src/main/java/com/example/bookshop/catalogue/BookRepository.java`:

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

public interface BookRepository {

    List<Book> findAll();

    Optional<Book> findById(long id);

    Optional<Book> findByIsbn(String isbn);

    Book save(Book book);
}
```

O que qualquer armazenamento de livros precisa responder. É uma interface, então o código que a usa
depende das perguntas e não de onde as respostas ficam guardadas; a lição 9 põe o PostgreSQL atrás
dos mesmos quatro métodos.

`src/main/java/com/example/bookshop/catalogue/InMemoryBookRepository.java`:

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentSkipListMap;
import java.util.concurrent.atomic.AtomicLong;

import org.springframework.stereotype.Repository;

@Repository
public class InMemoryBookRepository implements BookRepository {

    private final Map<Long, Book> books = new ConcurrentSkipListMap<>();
    private final AtomicLong nextId = new AtomicLong(1);

    public InMemoryBookRepository() {
        save(new Book(0, "9786500000016", "Dom Casmurro", "Machado de Assis", 3990));
        save(new Book(0, "9786500000023", "The Time Machine", "H. G. Wells", 2950));
        save(new Book(0, "9786500000030", "Frankenstein", "Mary Shelley", 3500));
    }

    @Override
    public List<Book> findAll() {
        return List.copyOf(books.values());
    }

    @Override
    public Optional<Book> findById(long id) {
        return Optional.ofNullable(books.get(id));
    }

    @Override
    public Optional<Book> findByIsbn(String isbn) {
        return books.values().stream().filter(b -> b.isbn().equals(isbn)).findFirst();
    }

    @Override
    public Book save(Book book) {
        Book stored = book.id() == 0 ? book.withId(nextId.getAndIncrement()) : book;
        books.put(stored.id(), stored);
        return stored;
    }
}
```

O armazenamento que esta lição usa: um mapa em memória, preenchido com três livros quando o objeto é
criado e esquecido quando a aplicação para. O mapa é um `ConcurrentSkipListMap` e o contador um
`AtomicLong`, ambos seguros para usar a partir de várias threads ao mesmo tempo, e a seção sobre
escopos explica por que isso importa.

`src/main/java/com/example/bookshop/catalogue/BookService.java`:

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

@Service
public class BookService {

    private final BookRepository books;

    public BookService(BookRepository books) {
        this.books = books;
    }

    public List<Book> list() {
        return books.findAll();
    }

    public Optional<Book> find(long id) {
        return books.findById(id);
    }

    public Book add(String isbn, String title, String author, int priceCents) {
        return books.save(new Book(0, isbn, title, author, priceCents));
    }
}
```

A classe que o resto da aplicação vai chamar. **Ela não cria o seu repositório.** Ela pede um, como
parâmetro do construtor, e guarda o que receber.

`src/main/java/com/example/bookshop/catalogue/CatalogueReport.java`:

```java
package com.example.bookshop.catalogue;

import java.time.Clock;
import java.time.LocalDateTime;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

@Component
public class CatalogueReport implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(CatalogueReport.class);

    private final BookService books;
    private final Clock clock;

    public CatalogueReport(BookService books, Clock clock) {
        this.books = books;
        this.clock = clock;
    }

    @Override
    public void run(String... args) {
        log.info("Catalogue opened on {} with {} books",
                LocalDateTime.now(clock).toLocalDate(), books.list().size());
    }
}
```

Um `CommandLineRunner` é o gancho do Spring Boot para "rode isto assim que a aplicação tiver
iniciado". O relatório precisa do serviço, para contar os livros, e de um relógio, para saber a data.

`src/main/java/com/example/bookshop/config/ClockConfig.java`:

```java
package com.example.bookshop.config;

import java.time.Clock;
import java.time.ZoneId;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class ClockConfig {

    @Bean
    public Clock clock() {
        return Clock.system(ZoneId.of("America/Sao_Paulo"));
    }
}
```

O diferente do grupo. Não faz parte da livraria: é uma receita de um objeto de que a livraria precisa,
e a seção sobre `@Bean` explica.

## Ligando tudo você mesmo

Nenhuma dessas classes chama `new` em algo de que depende. Alguém ainda precisa chamar, e na ordem
que os construtores impõem: o repositório antes do serviço que o recebe, o serviço e o relógio antes
do relatório. Salve isto como `~/Wiring.java`, no seu diretório pessoal e fora do projeto:

```java
// Wiring.java: the bookshop's objects, built and connected by hand.
import com.example.bookshop.catalogue.BookService;
import com.example.bookshop.catalogue.CatalogueReport;
import com.example.bookshop.catalogue.InMemoryBookRepository;
import com.example.bookshop.config.ClockConfig;

void main() {
    var repository = new InMemoryBookRepository();
    var service = new BookService(repository);
    var clock = new ClockConfig().clock();
    var report = new CatalogueReport(service, clock);
    report.run();
}
```

É um programa de um arquivo só, que o Java 25 executa direto do código-fonte, e o seu `void main()`
não precisa de classe em volta. Ele precisa das classes compiladas da livraria no class path, e das
bibliotecas que elas usam. `mvn -B -q package` compila o projeto: `-B` roda o Maven sem cores nem
saída de progresso, e `-q` o mantém calado a menos que algo falhe. Depois, o objetivo
`build-classpath` do plugin de dependências escreve num arquivo o caminho do jar de cada dependência,
e o comando `java` o lê de volta com `$(cat ...)`:

```
!!! MISSING BLOCK by-hand
```

O relatório rodou e contou três livros. Os jars do Spring estavam no class path e o Spring nunca
iniciou: ninguém leu as anotações, e elas não mudaram nada. A linha de log tem outra cara que a de uma
aplicação Spring Boot porque o Boot nunca configurou o log; este é o formato padrão simples do
Logback.

Cada classe recebeu os seus colaboradores de fora, pelo construtor, e **injeção de dependência** é só
isso. Qual objeto é criado, em que ordem e entregue a quem foi decidido num lugar só, o `main`, e não
dentro de cada classe.

**Inversão de controle** é a ideia mais ampla da qual essas linhas são um exemplo. Uma classe não vai
buscar o que precisa e não decide quando roda: algo de fora a constrói e a chama. `CatalogueReport.run`
é o caso mais claro na livraria, porque nada no código da própria livraria o chama. Em `Wiring.java`
quem está de fora é o `main`. Na aplicação é o Spring, e a próxima seção o observa fazer as mesmas
chamadas na mesma ordem.
