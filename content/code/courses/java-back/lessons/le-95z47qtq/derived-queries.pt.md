---
title: Consultas a partir do nome do método
version: 1
---

Um método numa interface de repositório, sem anotação e com um nome que o Spring Data entende, é uma
**consulta derivada**: na inicialização o Spring Data lê o nome, descobre o que ele pede e monta a
consulta a partir dele. `findByIsbn(String isbn)` se lê como "encontre os livros cujo `isbn` é igual ao
argumento", e essa é a consulta que ele ganha.

O nome tem duas metades, uma de cada lado do primeiro `By`. Antes dele vem o **sujeito**, o que fazer:
`find`, `read`, `get`, `query`, `search` e `stream` buscam, e `count`, `exists` e `delete` fazem o que
dizem. Depois dele vem o **predicado**: nomes de propriedades da entidade, ligados por `And` ou `Or`,
cada um seguido de uma palavra-chave que diz como comparar, e no fim um `OrderBy` opcional com uma
propriedade e `Asc` ou `Desc`. Os nomes são os campos da entidade, `priceCents` e nunca a coluna
`price_cents`, porque uma consulta derivada é JPQL antes de ser SQL.

| no nome | um exemplo | o que ele compara |
|---|---|---|
| sem palavra-chave | `findByIsbn(String isbn)` | igual ao argumento |
| `Containing` | `findByTitleContaining(String text)` | o texto em qualquer ponto do título |
| `StartingWith` | `findByTitleStartingWith(String text)` | o texto no começo |
| `IgnoreCase` | `findByTitleIgnoreCase(String title)` | igual, sem ligar para maiúsculas |
| `LessThan`, `GreaterThanEqual` | `findByPriceCentsLessThan(int cents)` | uma comparação com o argumento |
| `Between` | `findByPriceCentsBetween(int low, int high)` | do primeiro ao segundo |
| `In` | `findByIsbnIn(Collection<String> isbns)` | qualquer valor da coleção |
| um caminho | `findByAuthorName(String name)` | uma propriedade de uma entidade relacionada, por um join |

A busca da loja usa três delas de uma vez. O `GET /books/search?q=the` chama
`findByTitleContainingIgnoreCaseOrderByTitle`:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books/search?q=the" | python3 -m json.tool
[
    {
        "id": 2,
        "isbn": "9786500000023",
        "title": "The Time Machine",
        "author": "H. G. Wells",
        "priceCents": 2950
    },
    {
        "id": 6,
        "isbn": "9786500000061",
        "title": "The War of the Worlds",
        "author": "H. G. Wells",
        "priceCents": 3200
    }
]
```

e o segundo terminal mostra no que esse nome se transformou:

```
2026-10-22T19:18:08.858-03:00 DEBUG 21638 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id where upper(b1_0.title) like upper(?) escape '\' order by b1_0.title
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 254\" role=\"img\" aria-label=\"O nome de método findByTitleContainingIgnoreCaseOrderByTitle dividido em quatro partes, cada uma ao lado do trecho de SQL que virou: findBy virou select from book; TitleContaining virou um like no título com o texto entre sinais de porcentagem; IgnoreCase virou upper dos dois lados; OrderByTitle virou order by title.\"><defs><marker id=\"l11-nm\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"140\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o nome do método</text><text x=\"500\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o SQL que o Hibernate mandou</text><rect x=\"30\" y=\"34\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">findBy</text><rect x=\"310\" y=\"34\" width=\"380\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">select b1_0.id, … from book b1_0</text><text x=\"500\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma consulta por entidades Book</text><line x1=\"250\" y1=\"56\" x2=\"308\" y2=\"56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-nm)\"></line><rect x=\"30\" y=\"88\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TitleContaining</text><rect x=\"310\" y=\"88\" width=\"380\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">where … b1_0.title like ? escape '\\'</text><text x=\"500\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o texto chega como %the%, escapado</text><line x1=\"250\" y1=\"110\" x2=\"308\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-nm)\"></line><rect x=\"30\" y=\"142\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">IgnoreCase</text><rect x=\"310\" y=\"142\" width=\"380\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">upper(b1_0.title) like upper(?)</text><text x=\"500\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">os dois lados em maiúsculas</text><line x1=\"250\" y1=\"164\" x2=\"308\" y2=\"164\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-nm)\"></line><rect x=\"30\" y=\"196\" width=\"220\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">OrderByTitle</text><rect x=\"310\" y=\"196\" width=\"380\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"500\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">order by b1_0.title</text><text x=\"500\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a ordenação faz parte da consulta</text><line x1=\"250\" y1=\"218\" x2=\"308\" y2=\"218\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-nm)\"></line></svg>", "caption": "Uma consulta derivada é lida do nome do método, uma parte de cada vez. Cada parte virou um trecho do SQL no log."}
```

O **`join author`** não faz parte do nome. Ele vem do `@EntityGraph` do método, que é o assunto da
próxima seção.

## O texto é comparado como texto

**O `escape '\'` está ali para proteger a busca.** O `Containing` envolve o argumento em `%` dos dois
lados e, antes disso, escapa todo `%` e todo `_` que o cliente digitou, porque no `like` esses dois
caracteres são curingas. Uma busca por um sinal de porcentagem, escrito `%25` numa URL, mostra a
diferença:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books/search?q=%25"; echo
[]
```

O segundo terminal mostra o mesmo comando de antes, e nenhum título tem um `%` literal, então nada
voltou. Sem o escape, o argumento seria `%%%`, um padrão que casa com todos os títulos da loja. Isso não
é injeção de SQL, já que o texto chega como um parâmetro vinculado, o `?`, como no `PreparedStatement`
da aula 9; é o erro menor de deixar quem usa a caixa de busca escrever o padrão em vez do texto.

## Adicionar um livro são três chamadas derivadas

O `BookService.add` usa as outras duas consultas derivadas antes de escrever qualquer coisa. Um livro
novo de um autor novo:

```
ana@vm:~/bookshop$ curl -s -i -H 'Content-Type: application/json' -d '{"isbn": "9786500000078", "title": "Triste Fim de Policarpo Quaresma", "author": "Lima Barreto", "priceCents": 3450}' localhost:8080/books; echo
HTTP/1.1 201 
Location: /books/7
Content-Type: application/json
Transfer-Encoding: chunked
Date: Thu, 22 Oct 2026 22:18:10 GMT

{"id":7,"isbn":"9786500000078","title":"Triste Fim de Policarpo Quaresma","author":"Lima Barreto","priceCents":3450}
```

```
2026-10-22T19:18:10.161-03:00 DEBUG 21638 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 where b1_0.isbn=?
2026-10-22T19:18:10.169-03:00 DEBUG 21638 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.name=?
2026-10-22T19:18:10.192-03:00 DEBUG 21638 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : insert into author (name) values (?)
2026-10-22T19:18:10.203-03:00 DEBUG 21638 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : insert into book (author_id,isbn,price_cents,title) values (?,?,?,?)
```

`where b1_0.isbn=?` é o `findByIsbn`, conferindo que o ISBN não está em uso. `where a1_0.name=?` é o
`findByName`, procurando o autor. Os dois inserts são o `save`, chamado uma vez com um `Author` novo e
uma vez com um `Book` novo; os dois tinham id `null`, então os dois foram persistidos.

## Um nome que não casa com nada

**Uma consulta derivada é conferida quando a aplicação sobe, não quando é chamada pela primeira vez.**
Como desvio, acrescente ao `BookRepository`, logo abaixo do `findByIsbn`, uma com uma propriedade
escrita errado:

```java
    List<Book> findByTitel(String titel);
```

O compilador não tem nada contra: para ele, é um método como outro qualquer. Pare a aplicação, faça o
build e suba de novo, desta vez no primeiro terminal, com o log filtrado até a linha que interessa:

```
ana@vm:~/bookshop$ mvn -q package
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep 'Caused by' | tail -n 1
Caused by: org.springframework.data.core.PropertyReferenceException: No property 'titel' found for type 'Book'; Did you mean 'title'
```

A aplicação se recusou a subir, disse qual era a propriedade e adivinhou a certa. É a melhor
qualidade das consultas derivadas: um erro de digitação aparece quando a aplicação sobe uma vez, o que
todo teste que a sobe também faz (aula 19), e não com o primeiro aluno que fizer uma busca. Apague a
linha antes de seguir.

A outra qualidade está à vista no próprio `findByTitleContainingIgnoreCaseOrderByTitle`. **Um nome é uma
boa linguagem de consulta para uma ou duas condições e uma linguagem ruim para cinco.** Passado esse
ponto, a consulta fica mais legível escrita como consulta, que é para isso que serve o `@Query`.
