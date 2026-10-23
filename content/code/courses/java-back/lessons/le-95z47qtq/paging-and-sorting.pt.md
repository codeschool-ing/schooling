---
title: Paginação e ordenação
version: 1
---

O `GET /books` não devolve mais o catálogo inteiro: ele devolve **uma página** dele. O método do
controller recebe um `Pageable`, montado pelo suporte web do Spring Data, que o Boot liga como liga os
repositórios. Ele vem de três parâmetros da query: **`page`**, contado a partir de 0; **`size`**,
quantos por página; e **`sort`**, uma propriedade e uma direção opcional, `sort=title,desc`, que pode se
repetir para uma segunda chave. `@PageableDefault(size = 20, sort = "id")` é o que recebe uma requisição
que não nomeia nenhum deles. O serviço passa o `Pageable` ao `findAllBy`, e o Hibernate o transforma em
SQL.

A segunda página de dois, por título de Z a A:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books?size=2&page=1&sort=title,desc" | python3 -m json.tool
{
    "content": [
        {
            "id": 2,
            "isbn": "9786500000023",
            "title": "The Time Machine",
            "author": "H. G. Wells",
            "priceCents": 2950
        },
        {
            "id": 5,
            "isbn": "9786500000054",
            "title": "Quincas Borba",
            "author": "Machado de Assis",
            "priceCents": 3690
        }
    ],
    "page": {
        "size": 2,
        "number": 1,
        "totalElements": 7,
        "totalPages": 4
    }
}
```

```
2026-10-22T19:19:56.369-03:00 DEBUG 24170 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id order by b1_0.title desc offset ? rows fetch first ? rows only
2026-10-22T19:19:56.391-03:00 DEBUG 24170 --- [bookshop] [nio-8080-exec-1] org.hibernate.SQL                        : select count(*) from book b1_0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 242\" role=\"img\" aria-label=\"Sete livros ordenados pelo título, em ordem decrescente, cortados em páginas de dois, a última com um. A página 1 tem The Time Machine e Quincas Borba: a consulta pula duas linhas e busca duas. Uma segunda consulta conta as sete linhas, o que dá totalElements 7 e totalPages 4.\"><defs><marker id=\"l11-pg\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"185\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ordenados pelo título, decrescente</text><rect x=\"75\" y=\"26\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"36.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Triste Fim de Policarpo Quaresma</text><rect x=\"75\" y=\"52\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"62.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">The War of the Worlds</text><rect x=\"75\" y=\"88\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"98.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">The Time Machine</text><rect x=\"75\" y=\"114\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"124.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Quincas Borba</text><rect x=\"75\" y=\"150\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"160.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Persuasion</text><rect x=\"75\" y=\"176\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"186.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Frankenstein</text><rect x=\"75\" y=\"212\" width=\"220\" height=\"21\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"185\" y=\"222.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Dom Casmurro</text><text x=\"36\" y=\"49.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">página 0</text><text x=\"36\" y=\"111.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">página 1</text><text x=\"36\" y=\"173.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">página 2</text><text x=\"36\" y=\"222.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">página 3</text><rect x=\"345\" y=\"89.5\" width=\"230\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"460\" y=\"103.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">offset 2 rows</text><text x=\"460\" y=\"119.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">fetch first 2 rows only</text><line x1=\"295\" y1=\"111.5\" x2=\"343\" y2=\"111.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l11-pg)\"></line><rect x=\"345\" y=\"170\" width=\"230\" height=\"52\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"460\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select count(*) from book</text><text x=\"460\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">7 rows: totalElements 7, totalPages 4</text><text x=\"460\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a segunda consulta</text></svg>", "caption": "size=2&page=1&sort=title,desc: uma consulta pula duas linhas e busca duas, e uma segunda consulta conta as sete, porque a página não tem como saber o total a partir de duas linhas."}
```

**Paginar custa dois comandos.** O primeiro busca as linhas da página: `order by b1_0.title desc` para a
ordenação, e `offset ? rows fetch first ? rows only` para a página, com o 2 e o 2 vinculados como
parâmetros, como qualquer outro valor. O segundo conta, porque `totalElements` e `totalPages` não têm
como ser conhecidos a partir de duas linhas. No JSON, `content` é a página e `page` são os quatro números
de que um cliente precisa para desenhar os botões de próxima e de anterior.

**E às vezes custa um.** O primeiro `GET /books` da seção sobre o relacionamento pediu uma página de 20, o padrão, e o
segundo terminal mostrou um comando só, com `fetch first ? rows only` e sem contagem. A consulta trouxe
menos linhas do que a página comportava, então aquela era a última página, e as linhas dela eram o
total: o Spring Data fez a conta em vez de perguntar.

## Ordenando pelo relacionamento

Uma propriedade de ordenação pode ser um caminho, como numa consulta derivada. Ordenando pelo nome do
autor:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books?size=3&sort=author.name" | python3 -m json.tool | grep -E "title|author|total"
            "title": "The Time Machine",
            "author": "H. G. Wells",
            "title": "The War of the Worlds",
            "author": "H. G. Wells",
            "title": "Persuasion",
            "author": "Jane Austen",
        "totalElements": 7,
        "totalPages": 3
```

```
2026-10-22T19:19:57.051-03:00 DEBUG 24170 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id order by a1_0.name fetch first ? rows only
2026-10-22T19:19:57.060-03:00 DEBUG 24170 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select count(*) from book b1_0
```

`order by a1_0.name`, no autor que o entity graph já tinha juntado.

## O que os parâmetros não conseguem

Um cliente escolhe o tamanho, e o Spring Data põe um teto. Pedindo cinco mil livros por página:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books?size=5000" | python3 -m json.tool | tail -n 7
    "page": {
        "size": 2000,
        "number": 0,
        "totalElements": 7,
        "totalPages": 1
    }
}
```

A página voltou com `size` 2000, o teto padrão do Spring Data, então uma requisição não consegue pedir
um milhão de linhas ao banco. A propriedade `spring.data.web.pageable.max-page-size` do Boot muda esse
valor.

Um cliente também escolhe a ordenação, e ela não é colada no SQL como texto: o Spring Data primeiro a
resolve contra as propriedades da entidade. Uma propriedade que o `Book` não tem:

```
ana@vm:~/bookshop$ curl -s "localhost:8080/books?sort=price"; echo
{"timestamp":"2026-10-22T22:19:58.619Z","status":500,"error":"Internal Server Error","path":"/books"}
```

Nada chegou ao banco; o segundo terminal não imprimiu nenhum comando para essa requisição. Mas **a
resposta erra no status.** O erro é do cliente, e um 400 diria isso. O 500 é a
`PropertyReferenceException` do Spring Data chegando ao handler da aula 7, que não tem um caso para ela,
e por isso o corpo é o padrão do Boot em vez de um problem detail. A loja deixa assim, e uma API sua merece o
`@ExceptionHandler` a mais que a transforma num 400.

## Por que `PagedModel` e não `Page`

O `books.list(pageable)` devolve um `Page` do Spring Data, e o controller o embrulha num `PagedModel`
antes de retornar. **`Page` é uma interface para código Java**, com métodos como `getPageable`,
`isFirst` e `hasNext`, e nunca foi pensada como formato JSON. **`PagedModel` é o formato JSON**,
`content` e os quatro números, e o Spring Data o trata como um formato a manter estável. Devolvê-lo diz,
no tipo do método, exatamente o que um cliente recebe.

## Páginas fundas

O `offset` é simples e tem um custo que cresce: para responder `page=5000&size=20`, o PostgreSQL acha,
ordena e descarta as primeiras 100.000 linhas antes de devolver vinte. Para um catálogo de sete livros
isso não é nada; para um feed sem fim é a consulta mais lenta da aplicação. A resposta de costume ali é
a **paginação por chave** (*keyset*), que pede as linhas depois da última vista (`where title > ?`) em vez
de depois de um número de linhas, e o Spring Data a oferece como rolagem, com `Window` e
`ScrollPosition`. Este curso fica nas páginas.
