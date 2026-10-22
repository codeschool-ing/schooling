---
title: Javadoc, os comentários que uma ferramenta transforma em páginas
version: 1
---

Dois tipos de pessoa precisam saber como a livraria funciona sem ler tudo. Um trabalha dentro do
código: um colega que chama `BookService` ou `Isbn` de uma classe dele e quer saber o que um método
faz antes de chamá-lo. O outro nunca vê o código e chama a API pelo HTTP. Esta seção é para o
primeiro leitor. O resto da aula é para o segundo.

**Javadoc** é a resposta do Java para o primeiro leitor. Toda página da documentação do próprio JDK,
inclusive a de `java.util.List`, foi produzida pela ferramenta `javadoc` a partir de comentários no
código-fonte do JDK. A sua IDE mostra os mesmos comentários quando você passa o mouse sobre um
método.

## Que comentários contam

Uma ideia comum é que o Javadoc lê todo comentário de um arquivo. Ele lê um tipo só: o comentário
que abre com **`/**`** e fica logo antes de uma classe, um campo, um construtor ou um método. `//` e
`/* */` são ignorados, e também um comentário `/**` que não esteja logo antes de uma declaração.
Anotações podem ficar entre os dois, como ficam abaixo.

Dentro dele, a primeira frase é o **resumo**, que a ferramenta copia para as tabelas que listam os
métodos. O que vem depois é a descrição. Em seguida vêm as **tags de bloco**, uma por linha, e em
qualquer ponto do texto você pode usar **tags em linha**, entre chaves:

| tag | o que documenta |
|---|---|
| `@param nome` | um parâmetro, com o nome exatamente como no código |
| `@return` | o que o método devolve |
| `@throws Tipo` | uma exceção, e quando ela é lançada |
| `{@code texto}` | código no meio de uma frase, em fonte monoespaçada e nunca lido como HTML |
| `{@link Tipo#membro}` | um link para outro elemento documentado |

## O controller, documentado

Substitua `src/main/java/com/example/bookshop/catalogue/BookController.java` por esta versão. O
código é o da aula 11; o que há de novo são os comentários, e um import a menos:

```schooling-example
{
  "language": "java",
  "file": "BookController.java",
  "parts": [
    {
      "code": "package com.example.bookshop.catalogue;\n\nimport java.net.URI;\nimport java.util.List;\n\nimport jakarta.validation.Valid;\n\nimport org.springframework.data.domain.Pageable;\nimport org.springframework.data.web.PageableDefault;\nimport org.springframework.data.web.PagedModel;\nimport org.springframework.http.ResponseEntity;\nimport org.springframework.web.bind.annotation.GetMapping;\nimport org.springframework.web.bind.annotation.PathVariable;\nimport org.springframework.web.bind.annotation.PostMapping;\nimport org.springframework.web.bind.annotation.RequestBody;\nimport org.springframework.web.bind.annotation.RequestMapping;\nimport org.springframework.web.bind.annotation.RequestParam;\nimport org.springframework.web.bind.annotation.RestController;\n",
      "note": "Os imports da aula 11, menos `Sort`, que a classe importava e nunca usava."
    },
    {
      "code": "/**\n * The catalogue over HTTP: reading it is open to anyone, adding to it needs\n * the {@code catalogue:write} scope.\n */\n@RestController\n@RequestMapping(\"/books\")\npublic class BookController {\n",
      "note": "O comentário da classe: uma frase de resumo, com `{@code}` em volta do nome do escopo para ele sair formatado como código. As anotações ficam entre o comentário e a classe, e isso é permitido."
    },
    {
      "code": "    private final BookService books;\n\n    public BookController(BookService books) {\n        this.books = books;\n    }\n",
      "note": "Nenhum comentário no construtor. Quem o chama é o Spring, e mais ninguém; o fim desta seção conta quanto custa deixar coisas assim de fora."
    },
    {
      "code": "    /**\n     * One page of the catalogue, in the order the {@code sort} parameter asks for.\n     *\n     * @param pageable page number, page size and sort, from the query string\n     * @return the page, with the total count in its metadata\n     */\n    @GetMapping\n    public PagedModel<BookResponse> list(@PageableDefault(size = 20, sort = \"id\") Pageable pageable) {\n        return new PagedModel<>(books.list(pageable));\n    }\n",
      "note": "`@param` dá o nome do parâmetro e depois diz o que ele traz. `@return` diz o que volta, inclusive a parte que quem lê não adivinharia pelo tipo: o total está nos metadados da página."
    },
    {
      "code": "    /**\n     * Books whose title contains the text, ignoring case.\n     *\n     * @param q the text to look for\n     * @return the matching books, by title\n     */\n    @GetMapping(\"/search\")\n    public List<BookResponse> search(@RequestParam String q) {\n        return books.search(q);\n    }\n\n    /**\n     * Titles and prices of one author's books.\n     *\n     * @param name the author's name, exactly as stored\n     * @return title and price of each book, by title\n     */\n    @GetMapping(\"/by-author\")\n    public List<TitleAndPrice> byAuthor(@RequestParam String name) {\n        return books.titlesBy(name);\n    }\n",
      "note": "Cada `@param` dá o nome do seu parâmetro exatamente como o código, `q` e `name`. O doclint confere essa correspondência, e a próxima parte desta seção a quebra de propósito."
    },
    {
      "code": "    /**\n     * One book.\n     *\n     * @param id the book's id\n     * @return the book\n     * @throws BookNotFoundException when no book has that id\n     */\n    @GetMapping(\"/{id}\")\n    public BookResponse get(@PathVariable long id) {\n        return books.get(id);\n    }\n",
      "note": "`@throws` documenta uma exceção que a assinatura não declara. `BookNotFoundException` estende `RuntimeException`, então nada mais no arquivo diz que ela pode acontecer."
    },
    {
      "code": "    /**\n     * Adds a book to the catalogue, creating its author if the name is new.\n     *\n     * @param request the book, validated before this method runs\n     * @return 201 with the new book and its address in {@code Location}\n     * @throws DuplicateIsbnException when the ISBN is already in the catalogue\n     */\n    @PostMapping\n    public ResponseEntity<BookResponse> add(@Valid @RequestBody BookRequest request) {\n        BookResponse book = books.add(request);\n        return ResponseEntity.created(URI.create(\"/books/\" + book.id())).body(book);\n    }",
      "note": "Duas coisas que só um comentário diz aqui: o 201 com o cabeçalho `Location`, e a exceção para um ISBN que já está no catálogo."
    },
    {
      "code": "}"
    }
  ]
}
```

Vale escrever o que a assinatura ainda não diz. `get(long id)` diz que recebe um número; não diz que
um número desconhecido lança uma exceção, porque `BookNotFoundException` não é checada e o
compilador nunca a vê sair. "Devolve o livro" num método chamado `get` que devolve um `BookResponse`
seria um comentário que não acrescenta nada, e quem lê aprende a pular comentários assim.

## O plugin

A ferramenta `javadoc` vem com o JDK, e o Maven a executa pelo `maven-javadoc-plugin`. O parent do
Spring Boot já gerencia a versão dele; o que este projeto acrescenta é a configuração. Substitua o
elemento `<build>` no fim do `pom.xml` por este:

```xml
  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <configuration>
          <show>public</show>
          <doclint>all,-missing</doclint>
        </configuration>
      </plugin>
    </plugins>
  </build>
```

**`<show>public</show>`** documenta só o que é público. Um auxiliar visível só no pacote não é API
de ninguém, e páginas sobre ele convidariam alguém a depender dele. **`<doclint>`** é a parte do
`javadoc` que confere os próprios comentários, e a próxima parte desta seção trata dela.

O plugin não está ligado a nenhuma fase neste pom, então `mvn package` não o executa. Você o chama
pelo goal:

```
ana@vm:~/bookshop$ mvn javadoc:javadoc
[INFO] Scanning for projects...
[INFO] 
[INFO] ------------------------< com.example:bookshop >------------------------
[INFO] Building bookshop 0.1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] >>> maven-javadoc-plugin:3.12.0:javadoc (default-cli) > generate-sources @ bookshop >>>
[INFO] 
[INFO] <<< maven-javadoc-plugin:3.12.0:javadoc (default-cli) < generate-sources @ bookshop <<<
[INFO] 
[INFO] 
[INFO] --- maven-javadoc-plugin:3.12.0:javadoc (default-cli) @ bookshop ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.800 s
[INFO] Finished at: 2026-10-22T20:07:50-03:00
[INFO] ------------------------------------------------------------------------
```

As duas linhas com `>>>` e `<<<` são o plugin pedindo ao Maven para rodar o ciclo de vida até
`generate-sources` antes, para que código gerado também fosse documentado; este projeto não tem
nenhum. As páginas vão para `target/reports/apidocs`:

```
ana@vm:~/bookshop$ ls target/reports/apidocs
allclasses-index.html
allpackages-index.html
com
element-list
help-doc.html
index-all.html
index.html
legal
member-search-index.js
module-search-index.js
overview-summary.html
overview-tree.html
package-search-index.js
resource-files
script-files
search.html
serialized-form.html
tag-search-index.js
type-search-index.js
ana@vm:~/bookshop$ ls target/reports/apidocs/com/example/bookshop/catalogue
Author.html
AuthorRepository.html
Book.html
BookController.html
BookNotFoundException.html
BookRepository.html
BookRequest.html
BookResponse.html
BookService.html
CatalogueReport.html
DuplicateIsbnException.html
Isbn.html
IsbnValidator.html
OutOfStockException.html
TitleAndPrice.html
ValidIsbn.html
class-use
package-summary.html
package-tree.html
package-use.html
```

Abra `target/reports/apidocs/index.html` num navegador. É um site sem servidor por trás: a lista de
pacotes, uma página por classe com a tabela de resumo, um índice de todos os nomes e uma caixa de
busca. `BookController.html` traz os comentários que você acabou de escrever, com
`{@code catalogue:write}` em fonte monoespaçada.

## O doclint, e uma verificação que não rodou

O doclint lê todo comentário que a ferramenta documenta e reclama do que encontra de errado: HTML
que não fecha, um `{@link}` para lugar nenhum, um `@param` que não nomeia parâmetro algum. Alguns
desses são **erros**, e um erro derruba o build. Experimente um. No comentário acima de `search`,
troque `@param q` por `@param query`, um nome que o método não tem, e rode o goal de novo:

```
ana@vm:~/bookshop$ mvn -q javadoc:javadoc
```

Nada, e isso está errado. O plugin guarda um registro da linha de comando que passou ao `javadoc` da
última vez, em `target/maven-javadoc-plugin-stale-data.txt`, e **pula a execução quando essa linha
de comando não mudou**. Editar um comentário não a muda, então a verificação que você pediu nunca
rodou. O `clean` apaga o `target`, registro incluído:

```
ana@vm:~/bookshop$ mvn -q clean javadoc:javadoc | head -6
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-javadoc-plugin:3.12.0:javadoc (default-cli) on project bookshop: An error has occurred in Javadoc report generation: 
[ERROR] Exit code: 1
[ERROR] /home/ana/bookshop/src/main/java/com/example/bookshop/catalogue/BookController.java:48: error: @param name not found
[ERROR]      * @param query the text to look for
[ERROR]               ^
[ERROR] 1 error
```

`-q` esconde tudo menos os erros, e `head -6` fica com o erro e deixa de fora os conselhos do Maven
logo abaixo. A linha 48 é o `@param` que você trocou. Volte para `@param q` antes de seguir.

O `clean` também apaga o jar, então o próximo `mvn package` o gera de novo. Sempre que uma
verificação de Javadoc precisar valer alguma coisa, num script ou antes de uma versão, rode-a depois
de um `clean`.

## Por que `-missing`

`all` liga todos os grupos de verificação, e `-missing` tira um de volta: o grupo que avisa sobre
todo elemento público sem comentário nenhum. Religue-o trocando a linha por
`<doclint>all</doclint>`, e conte o que ele encontra. O pom mudou, então desta vez o plugin roda:

```
ana@vm:~/bookshop$ mvn javadoc:javadoc | grep 'warning: no comment' > ~/missing.txt
ana@vm:~/bookshop$ wc -l < ~/missing.txt
92
ana@vm:~/bookshop$ head -3 ~/missing.txt
[WARNING] /home/ana/bookshop/src/main/java/com/example/bookshop/web/ApiErrorHandler.java:24: warning: no comment
[WARNING] /home/ana/bookshop/src/main/java/com/example/bookshop/web/ApiErrorHandler.java:32: warning: no comment
[WARNING] /home/ana/bookshop/src/main/java/com/example/bookshop/web/ApiErrorHandler.java:27: warning: no comment
```

Noventa e dois elementos públicos sem comentário. Os três primeiros são os tratadores do
`ApiErrorHandler` da aula 7, e o construtor do controller também está na lista, na linha 30. Eles
são públicos porque o Spring os chama, e ninguém que leia uma página de Javadoc vai chamá-los
diretamente. Uma frase em cada um seria exatamente o tipo de comentário contra o qual a parte
anterior alertou. `-missing` mantém todas as verificações sobre os comentários que existem e tira a
exigência de comentário em tudo. Volte para `<doclint>all,-missing</doclint>`.

Uma biblioteca é o caso oposto. Código de que outros projetos dependem é lido pelo Javadoc, o Maven
Central exige um jar dele, gerado por `mvn javadoc:jar`, ao lado de toda biblioteca que publica, e
ali o `missing` deve ficar ligado.
