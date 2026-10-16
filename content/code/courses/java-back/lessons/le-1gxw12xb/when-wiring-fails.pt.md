---
title: Quando a ligação falha
version: 1
---

O Spring resolve todos os parâmetros de construtor na inicialização, antes que a aplicação faça
qualquer trabalho, então um erro de ligação a interrompe na hora com um relatório, em vez de aparecer
mais tarde como um `null`. Existem três erros assim e cada um tem o seu relatório, com o título
`APPLICATION FAILED TO START`. Cada caso abaixo é um desvio: faça a mudança, leia o relatório,
desfaça. O `tail` guarda o relatório e descarta as linhas de inicialização acima dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 320\" role=\"img\" aria-label=\"Três linhas. Dois candidatos: BookService aponta para emptyBookRepository e para inMemoryBookRepository, e o relatório diz required a single bean, but 2 were found; o conserto é @Primary ou @Qualifier. Nenhum: CatalogueReport aponta para uma caixa tracejada vazia, nada para injetar, e o relatório diz could not be found; o conserto é um estereótipo, num pacote abaixo do da aplicação. Um ciclo: bookService e catalogueReport apontam um para o outro, e o relatório diz form a cycle; o conserto é uma mudança de projeto.\"><defs><marker id=\"f5-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"f5-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">Dois candidatos</text><text x=\"20\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">required a single bean, but 2 were found</text><text x=\"20\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">@Primary ou @Qualifier</text><text x=\"20\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">Nenhum</text><text x=\"20\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">could not be found</text><text x=\"20\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">um estereótipo, num pacote</text><text x=\"20\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">abaixo do da aplicação</text><text x=\"20\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">Um ciclo</text><text x=\"20\" y=\"262\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">form a cycle</text><text x=\"20\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">uma mudança de projeto</text><rect x=\"300\" y=\"30\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"375\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">BookService</text><rect x=\"510\" y=\"12\" width=\"230\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">emptyBookRepository</text><rect x=\"510\" y=\"56\" width=\"230\" height=\"32\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">inMemoryBookRepository</text><line x1=\"450\" y1=\"46\" x2=\"508\" y2=\"30\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f5-am)\"></line><line x1=\"450\" y1=\"54\" x2=\"508\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f5-am)\"></line><rect x=\"300\" y=\"135\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"375\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">CatalogueReport</text><rect x=\"510\" y=\"135\" width=\"230\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"625\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada para injetar</text><line x1=\"450\" y1=\"155\" x2=\"508\" y2=\"155\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f5-am)\"></line><rect x=\"300\" y=\"240\" width=\"150\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"375\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">bookService</text><rect x=\"510\" y=\"240\" width=\"230\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"625\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">catalogueReport</text><line x1=\"450\" y1=\"252\" x2=\"508\" y2=\"252\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f5-am)\"></line><line x1=\"510\" y1=\"268\" x2=\"452\" y2=\"268\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f5-am)\"></line></svg>", "caption": "Os três relatórios, como formas. Cada um nomeia o parâmetro de construtor que não conseguiu preencher, e cada um tem um conserto diferente."}
```

## Dois candidatos

Acrescente uma segunda implementação de `BookRepository`, uma vazia, do tipo que alguém escreve para
uma demonstração, como `src/main/java/com/example/bookshop/catalogue/EmptyBookRepository.java`:

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Repository;

@Repository
public class EmptyBookRepository implements BookRepository {

    @Override
    public List<Book> findAll() {
        return List.of();
    }

    @Override
    public Optional<Book> findById(long id) {
        return Optional.empty();
    }

    @Override
    public Optional<Book> findByIsbn(String isbn) {
        return Optional.empty();
    }

    @Override
    public Book save(Book book) {
        return book;
    }
}
```

```
!!! MISSING BLOCK two
```

Leia a descrição a partir da primeira linha. O **parâmetro 0** do construtor de `BookService` quer um
`BookRepository` e encontrou dois, listados pelo nome do bean e pelo arquivo de classe de onde cada um
veio. Casar pelo tipo já não basta para decidir, e o Spring não chuta.

O `Action` lista os consertos, e dois deles são anotações. `@Primary` num dos candidatos faz dele o
escolhido sempre que se quer um único bean do seu tipo. Acrescente-a a `InMemoryBookRepository`, acima
da classe, com o import:

```
!!! MISSING BLOCK primary
```

`@Qualifier` vai no ponto de injeção e nomeia o bean que aquele consumidor quer, e ganha de
`@Primary`. Tire `@Primary` de novo e qualifique o parâmetro no lugar:

```
!!! MISSING BLOCK qualifier
```

As duas diferem em **quem decide**. `@Primary` é decidida pelo candidato e vale para todos os
consumidores; `@Qualifier` é decidida por um consumidor e vale só ali. Um segundo armazenamento usado
por duas classes de trinta é um `@Qualifier` nessas duas; um substituto feito para valer em todo lugar
é um `@Primary`. O terceiro conserto da lista, aceitar vários beans, quer dizer um parâmetro do tipo
`List<BookRepository>`, no qual o Spring põe todos os candidatos. Serve para uma classe feita para
usar todos eles, e esta não é.

As três últimas linhas do relatório apontam para algo mais discreto. O último critério de desempate do
Spring é o **nome do parâmetro**: quando ele coincide com o nome de bean de um candidato, esse
candidato ganha. O compilador só guarda os nomes dos parâmetros nos arquivos de classe quando recebe
`-parameters`, e o POM pai do Spring Boot liga isso. Tire o qualificador e renomeie o parâmetro com o
nome de um dos beans:

```
!!! MISSING BLOCK paramname
```

Sobe, sem anotação nenhuma, e é justamente por isso que não se deve contar com isso. Renomear um
parâmetro é uma edição que parece inofensiva em qualquer revisão, e aqui mudaria qual bean a classe
recebe. Uma anotação diz a mesma coisa de propósito.

Desfaça o desvio: apague `EmptyBookRepository.java` e devolva ao construtor o parâmetro `books`.

## Nenhum

A falha oposta é um tipo que ninguém fornece. Apague a linha `@Repository` de
`InMemoryBookRepository`:

```
!!! MISSING BLOCK missing
```

Sem o estereótipo, a classe fica invisível para a varredura de componentes, então não existe bean do
tipo `BookRepository`. A classe ainda compila e ainda implementa a interface, e nunca é criada. Ponha
a linha de volta.

O mesmo relatório aparece quando a anotação está lá e a classe fica fora dos pacotes varridos. Mova
`ClockConfig` de `com.example.bookshop.config` para um pacote ao lado do da livraria, em vez de dentro
dele:

```
!!! MISSING BLOCK outside
```

**Parâmetro 1** desta vez, o relógio de `CatalogueReport`. `ClockConfig` ainda carrega
`@Configuration` e a sua classe está no jar, mas `com.example.clock` não fica abaixo de
`com.example.bookshop`, então a varredura nunca olhou ali. Mova de volta invertendo os três comandos.
Quando este relatório citar um bean que você tem certeza de ter escrito, confira o pacote antes de
qualquer outra coisa.

## Um ciclo

A terceira falha precisa de dois beans que querem um ao outro. Dê ao construtor de `BookService` também
um `CatalogueReport`, como se acrescentar um livro devesse atualizar o relatório:

```
!!! MISSING BLOCK cycle
```

O desenho é o ciclo: `bookService` precisa de `catalogueReport`, que precisa de `bookService`. Com
construtores não existe ordem que funcione, porque nenhum dos dois objetos pode ser criado antes que o
outro exista. O `Action` cita uma propriedade que permite referências circulares. Ela ajuda com
injeção em campo e por setter, em que o Spring consegue entregar um objeto pela metade e terminá-lo
depois; com construtores ela não consegue, e o relatório diz isso:

```
!!! MISSING BLOCK cycle-flag
```

O conserto está no projeto. Aqui é fácil, porque a dependência foi inventada e o serviço não precisa do
relatório. Em código real, um ciclo costuma querer dizer que uma classe faz dois trabalhos, e a saída é
levar a parte de que as duas precisam para uma terceira classe, da qual ambas dependem. Volte o
construtor para como estava.
