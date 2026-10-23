---
title: Entidades
version: 1
---

Uma **entidade** é uma classe cujos objetos são linhas. Você a marca, diz qual campo é a chave e como
ela se relaciona com outras entidades, e o Hibernate deduz o resto a partir dos próprios campos. O
bookshop tem duas: `Author`, e `Book`, que aponta para ela.

A aula 5 fez de `Book` um record, e ele não pode continuar assim. Um record é final, não tem construtor
sem argumentos e nunca muda, e o mapeador precisa do contrário de cada uma dessas coisas: ele gera
subclasses das entidades para os seus proxies, cria um objeto vazio, preenche os campos a partir de
uma linha e depois percebe quando algum deles mudou. Por isso as duas entidades são classes comuns.
Crie `src/main/java/com/example/bookshop/catalogue/Author.java`:

```java
package com.example.bookshop.catalogue;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Author {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;

    protected Author() {
    }

    public Author(String name) {
        this.name = name;
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }
}
```

Depois substitua `Book.java`, no mesmo diretório. Cada pedaço vem explicado ao lado:

```schooling-example
{
  "language": "java",
  "file": "Book.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport jakarta.persistence.Column;\nimport jakarta.persistence.Entity;\nimport jakarta.persistence.FetchType;\nimport jakarta.persistence.GeneratedValue;\nimport jakarta.persistence.GenerationType;\nimport jakarta.persistence.Id;\nimport jakarta.persistence.ManyToOne;\n",
      "note": "Todas as anotações vêm de `jakarta.persistence`, a especificação. Nada aqui menciona o Hibernate."
    },
    {
      "code": "@Entity\npublic class Book {\n",
      "note": "`@Entity` diz ao mapeador que esta classe é guardada numa tabela. Sem `@Table`, a tabela tem o nome da classe: `book`. É uma classe e não um record porque o mapeador cria o objeto vazio e preenche os campos depois."
    },
    {
      "code": "    @Id\n    @GeneratedValue(strategy = GenerationType.IDENTITY)\n    private Long id;\n",
      "note": "`@Id` marca a chave primária, e a posição dela num campo decide que o Hibernate lê e escreve os CAMPOS diretamente, sem precisar de setters. `IDENTITY` diz que quem inventa o número é o banco, que é o que o `bigserial` faz. É `Long` e não `long` porque um livro ainda não gravado não tem id nenhum, e `null` diz isso."
    },
    {
      "code": "    private String isbn;\n\n    private String title;\n",
      "note": "Campos simples não precisam de anotação: todo campo de uma entidade é uma coluna, a não ser que seja marcado de outro jeito. `isbn` vira `isbn`, `title` vira `title`."
    },
    {
      "code": "    @ManyToOne(fetch = FetchType.LAZY, optional = false)\n    private Author author;\n",
      "note": "O relacionamento. Muitos livros, um autor: a coluna é `author_id`, o nome do campo mais a chave para onde ele aponta. `LAZY` quer dizer que carregar um livro não carrega o autor; `optional = false` corresponde ao `NOT NULL` da tabela."
    },
    {
      "code": "    @Column(name = \"price_cents\")\n    private int priceCents;\n",
      "note": "A estratégia de nomes do Spring Boot transformaria `priceCents` em `price_cents` sozinha. A anotação escreve isso onde quem lê este arquivo consegue ver."
    },
    {
      "code": "    protected Book() {\n    }\n",
      "note": "O Hibernate precisa de um construtor sem argumentos para criar o objeto vazio que depois preenche. `protected` deixa o Hibernate entrar e mantém todo o resto do lado de fora, então o código da aplicação não consegue montar um livro sem título."
    },
    {
      "code": "    public Book(String isbn, String title, Author author, int priceCents) {\n        this.isbn = isbn;\n        this.title = title;\n        this.author = author;\n        this.priceCents = priceCents;\n    }\n",
      "note": "O construtor que o código da aplicação usa. Ele não recebe id: o banco atribui um quando o livro é inserido."
    },
    {
      "code": "    public Long getId() {\n        return id;\n    }\n\n    public String getIsbn() {\n        return isbn;\n    }\n\n    public String getTitle() {\n        return title;\n    }\n\n    public Author getAuthor() {\n        return author;\n    }\n\n    public int getPriceCents() {\n        return priceCents;\n    }\n}",
      "note": "Só getters. Nada fora da classe altera um livro, o que mantém toda alteração neste arquivo."
    }
  ]
}
```

## Lazy, e por que isso não é o padrão

O relacionamento merece uma segunda olhada, porque decide quantas consultas cada tela da aplicação
vai custar. `@ManyToOne` sozinho quer dizer `EAGER`: o padrão do JPA para uma referência simples é
carregá-la junto com o objeto que a guarda. Parece útil e é uma armadilha. Todo livro carregado em
qualquer lugar traria o seu autor junto, em toda consulta, quer o código que o lê peça o nome ou não.

**`LAZY` inverte o padrão.** Um livro é carregado sozinho, e o campo `author` guarda um **proxy**: um
objeto de uma subclasse que o Hibernate gerou, que conhece o id do autor e mais nada. Na primeira vez
que o código chama nele um método que precisa de dados, como `getName()`, o proxy pede a linha ao
banco.

Essa decisão está por trás dos dois problemas do resto desta aula. Um proxy que se carrega sozinho é
uma consulta que ninguém escreveu, e é daí que vem o problema N+1. E um proxy que tenta se carregar
depois que a ligação com o banco acabou lança uma exceção em vez disso, que é a última seção.

## O que não está aqui

Não há `@Table`, não há `@Column` em `isbn` nem em `title`, e não há lista de livros em `Author`. As
duas ausências são de propósito.

- Os nomes de tabela e de coluna saem dos nomes da classe e dos campos, então escrevê-los só criaria
  dois lugares para mudar numa renomeação. `price_cents` é a única exceção, e a nota dele diz por quê.
- Um autor poderia guardar `@OneToMany(mappedBy = "author") List<Book> books`, o outro lado do mesmo
  relacionamento. Nada na aplicação precisa ir de um autor aos livros dele por enquanto, e uma coleção
  que ninguém lê é mais uma coisa que pode ser carregada sem querer. A aula 11 volta aos
  relacionamentos.
