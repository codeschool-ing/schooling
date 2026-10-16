---
title: Por que o construtor
version: 1
---

O Spring consegue entregar a um bean as suas dependências de três jeitos: como argumentos do
construtor, escrevendo direto num campo ou chamando um setter. A livraria usa o primeiro em todo lugar.
Esta seção é o argumento a favor dele, e parte do argumento é um desvio pelo segundo.

```schooling-example
{"language": "java", "file": "BookService.java", "parts": [{"code": "package com.example.bookshop.catalogue;\n\nimport java.util.List;\nimport java.util.Optional;\n\nimport org.springframework.stereotype.Service;\n"}, {"code": "@Service\npublic class BookService {", "note": "`@Service` é a etiqueta que a varredura de componentes procura. Nada mais na classe menciona o Spring."}, {"code": "\n    private final BookRepository books;", "note": "`final`: depois que o construtor roda, o campo guarda um repositório e nada consegue esvaziá-lo nem trocá-lo. O tipo é a interface, então o serviço não sabe qual armazenamento recebeu."}, {"code": "\n    public BookService(BookRepository books) {\n        this.books = books;\n    }\n", "note": "É o único construtor, então o Spring o usa sem que ninguém peça. Um `@Autowired` nele seria aceito e não mudaria nada; ele só é necessário para escolher entre vários construtores."}, {"code": "    public List<Book> list() {\n        return books.findAll();\n    }\n\n    public Optional<Book> find(long id) {\n        return books.findById(id);\n    }\n\n    public Book add(String isbn, String title, String author, int priceCents) {\n        return books.save(new Book(0, isbn, title, author, priceCents));\n    }\n}", "note": "O resto é código comum chamando `books`, que o construtor já garantiu que existe."}]}
```

Quatro propriedades vêm de receber as dependências no construtor, e a livraria já depende de cada uma
delas:

- o objeto está completo quando o `new` retorna, e não existe momento em que `books` seja `null`;
- o campo pode ser `final`, então nada troca o repositório no meio da vida da aplicação;
- as dependências são a lista de parâmetros do construtor, então uma classe que precisa de sete coisas
  diz isso na assinatura, onde quem revisa vê;
- qualquer código consegue montar o objeto sem contêiner nenhum. `Wiring.java` montou, e a lição 19
  monta o serviço de pedidos com `new`, dois repositórios substitutos e um relógio fixo.

## Um desvio pela injeção em campo

**Injeção em campo não é só um jeito mais curto de escrever a mesma coisa**, embora seja mais curta,
apareça em muito código e tutorial antigos e funcione. Troque `BookService.java` por esta versão por
um momento:

```java
package com.example.bookshop.catalogue;

import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class BookService {

    @Autowired
    private BookRepository books;

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

O Spring cria o objeto com o construtor que o Java escreve quando a classe não declara nenhum, e depois
preenche `books` por reflexão, mesmo sendo privado. A aplicação sobe como antes. `Wiring.java` deixa
de compilar:

```
!!! MISSING BLOCK field-a
```

A classe não tem mais um construtor que receba um repositório. O conserto óbvio, `new
BookService()`, compila e falha em outro lugar:

```
!!! MISSING BLOCK field-b
```

Esse `NullPointerException` é o custo. O objeto existe sem a sua dependência, e nada fora do Spring
consegue lhe dar uma a não ser mais reflexão, então um teste de `BookService` precisaria do contêiner
inteiro ou de uma ferramenta que escreve em campos privados. Com um construtor, o compilador se recusa
a montar o objeto incompleto; com um campo, o programa descobre quando roda. O campo também não pode
ser `final`, porque é escrito depois da construção.

Desfaça o desvio: volte `BookService.java` para como a primeira seção o mostra e rode
`mvn -B -q package` de novo.

## Setters, e a interface

A **injeção por setter**, um método `setBooks` que o Spring chama depois da construção, serve para uma
dependência de fato opcional: a classe funciona sem ela e faz mais com ela. A livraria não tem
nenhuma.

`BookService` depende da interface `BookRepository`, não de `InMemoryBookRepository`, e o Spring não
exige isso. Um construtor pode pedir uma classe, e o Spring injeta o bean dessa classe. A interface
compensa aqui por um motivo particular deste curso: a lição 9 apaga `InMemoryBookRepository`,
acrescenta um repositório que lê do PostgreSQL, e `BookService` não muda uma linha. Uma interface
inventada para uma classe que só vai ter uma implementação compra um segundo arquivo e mais nada; esta
tem a segunda implementação a quatro lições de distância.
