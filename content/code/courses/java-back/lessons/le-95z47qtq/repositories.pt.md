---
title: Um repositório é uma interface
version: 1
---

A aula 10 terminou com duas classes, `JpaBookRepository` e `JpaAuthorRepository`, e a maior parte das
linhas delas entregava uma string JPQL a um `EntityManager` e devolvia o que voltava. Toda aplicação com
banco de dados escreve esse código, e ele quase não muda de uma entidade para a outra. O Spring Data JPA
assume esse trabalho, e o arranjo que ele oferece cabe numa frase: **você declara o repositório como
uma interface, e o Spring Data fornece o objeto que a implementa quando a aplicação sobe.**

A imagem que quase todo mundo traz é a de geração de código: um plugin escreve um
`BookRepositoryImpl.java` em algum lugar dentro de `target/`, e o build o compila. Nada disso é escrito.
Quando a aplicação sobe, o Spring Data procura, dentro do pacote da aplicação, interfaces que estendem
uma das interfaces de repositório dele, e cria um **proxy** para cada uma: um objeto criado em tempo de
execução que implementa a interface e decide o que cada chamada faz. Os métodos que todo repositório tem
vão para uma classe compartilhada, `SimpleJpaRepository`, que chama o mesmo `EntityManager` que a aula 10
chamava. Os métodos que você mesmo declara ganham uma consulta montada para eles uma vez, durante a
inicialização, a partir do nome do método ou de uma anotação `@Query` nele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 750 256\" role=\"img\" aria-label=\"BookService chama BookRepository, que é um proxy criado pelo Spring Data na inicialização. O proxy manda os métodos herdados, como save, findById e count, para o SimpleJpaRepository, e cada método declarado, como findByIsbn, para uma consulta montada na inicialização. Os dois chegam ao EntityManager.\"><defs><marker id=\"l11-px\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"130\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"85\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BookService</text><text x=\"85\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o seu código</text><rect x=\"190\" y=\"100\" width=\"175\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"277\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">BookRepository</text><text x=\"277\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um proxy, criado na inicialização</text><rect x=\"410\" y=\"20\" width=\"190\" height=\"72\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SimpleJpaRepository</text><text x=\"505\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">métodos herdados</text><text x=\"505\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">save, findById, count</text><rect x=\"410\" y=\"164\" width=\"190\" height=\"72\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"505\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">uma consulta por método declarado</text><text x=\"505\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">findByIsbn</text><text x=\"505\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">@Query</text><rect x=\"625\" y=\"100\" width=\"105\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"677\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">EntityManager</text><text x=\"677\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">SQL para o PostgreSQL</text><line x1=\"150\" y1=\"128\" x2=\"188\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-px)\"></line><path d=\"M 365 120 C 385 120, 385 56, 408 56\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-px)\"></path><path d=\"M 365 136 C 385 136, 385 200, 408 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-px)\"></path><path d=\"M 600 56 C 615 56, 610 116, 623 118\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-px)\"></path><path d=\"M 600 200 C 615 200, 610 140, 623 138\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-px)\"></path></svg>", "caption": "A interface que você escreve é implementada por um proxy que o Spring Data cria quando a aplicação sobe. Os métodos herdados vão para uma classe compartilhada; cada método que você declara ganha a sua consulta uma vez, antes da primeira requisição."}
```

Ninguém ligou isso. O `spring-boot-starter-data-jpa` está no pom desde a aula 10, e a autoconfiguração
dele, o mesmo mecanismo que a aula 4 leu no relatório de condições, liga a varredura de repositórios
assim que existe algo para varrer.

O repositório de autores é o menor exemplo, e ele inteiro é isto:

```java
package com.example.bookshop.catalogue;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface AuthorRepository extends JpaRepository<Author, Long> {

    Optional<Author> findByName(String name);
}
```

`JpaRepository<Author, Long>` nomeia a entidade e o tipo do id dela. Isso basta para o Spring Data
saber a tabela, a coluna do id e os tipos de todos os métodos que a interface herda. `findByName` é o
único método de que a loja precisa e que nenhum repositório já tem; o `BookService.add` o chama antes
de criar um autor. O `save`, que a classe da aula 10 escrevia à mão, nem é declarado.

## O que vem junto

O `javap`, que vem com o JDK, imprime os métodos que uma interface compilada declara, e o Maven já pôs
os jars do Spring Data em `~/.m2`. A raiz da família é o `CrudRepository`:

```
ana@vm:~/bookshop$ javap -cp ~/.m2/repository/org/springframework/data/spring-data-commons/4.1.1/spring-data-commons-4.1.1.jar org.springframework.data.repository.CrudRepository
Compiled from "CrudRepository.java"
public interface org.springframework.data.repository.CrudRepository<T, ID> extends org.springframework.data.repository.Repository<T, ID> {
  public abstract <S extends T> S save(S);
  public abstract <S extends T> java.lang.Iterable<S> saveAll(java.lang.Iterable<S>);
  public abstract java.util.Optional<T> findById(ID);
  public abstract boolean existsById(ID);
  public abstract java.lang.Iterable<T> findAll();
  public abstract java.lang.Iterable<T> findAllById(java.lang.Iterable<ID>);
  public abstract long count();
  public abstract void deleteById(ID);
  public abstract void delete(T);
  public abstract void deleteAllById(java.lang.Iterable<? extends ID>);
  public abstract void deleteAll(java.lang.Iterable<? extends T>);
  public abstract void deleteAll();
}
```

Doze métodos, todos genéricos: `T` é a entidade e `ID` o tipo do id dela, que o
`JpaRepository<Author, Long>` preenche. O `JpaRepository` estende três interfaces, e a primeira delas
estende o `CrudRepository`:

```
ana@vm:~/bookshop$ javap -cp ~/.m2/repository/org/springframework/data/spring-data-jpa/4.1.1/spring-data-jpa-4.1.1.jar org.springframework.data.jpa.repository.JpaRepository | head -n 2
Compiled from "JpaRepository.java"
public interface org.springframework.data.jpa.repository.JpaRepository<T, ID> extends org.springframework.data.repository.ListCrudRepository<T, ID>, org.springframework.data.repository.ListPagingAndSortingRepository<T, ID>, org.springframework.data.repository.query.QueryByExampleExecutor<T> {
```

O `ListCrudRepository` devolve uma `List` onde o `CrudRepository` devolve um `Iterable`. O
`ListPagingAndSortingRepository` acrescenta `findAll(Sort)` e `findAll(Pageable)`, o assunto da última
seção desta aula. O `QueryByExampleExecutor` monta consultas a partir de um objeto de exemplo, coisa que
este curso não usa. E o próprio `JpaRepository` acrescenta o que só o JPA tem: `flush`,
`saveAndFlush`, `getReferenceById` e exclusões em lote.

**O `save` escolhe entre duas operações.** Se o Spring Data considera a entidade nova, o que por padrão
quer dizer que o id dela ainda é `null`, ele chama `persist`, e o objeto que você passou é o que o
contexto de persistência passa a gerenciar. Senão, ele chama `merge`, que copia o estado do seu objeto
para uma cópia gerenciada e devolve a cópia, sem mexer no seu. Usar o que o `save` devolve, como o
`BookService` faz, está certo nos dois casos.

Os métodos herdados também trazem as próprias transações: o `SimpleJpaRepository` roda cada leitura numa
transação somente leitura e cada escrita numa de leitura e escrita, então um repositório chamado sozinho
nunca fica fora de uma transação. O `BookService` continua declarando `@Transactional` em todo método,
porque uma chamada ao serviço pode fazer várias chamadas a repositórios que precisam dar certo ou
falhar juntas; a aula 14 trata disso.
