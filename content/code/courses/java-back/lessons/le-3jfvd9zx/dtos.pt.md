---
title: DTOs, porque o formato da API não é o do domínio
version: 1
---

Ponha `BookResponse` ao lado de `Book` e eles parecem um record escrito duas vezes: os mesmos cinco
componentes, os mesmos tipos, e um método que copia um no outro. O movimento óbvio é devolver `Book`
do controlador e apagar `BookResponse`, e hoje o JSON não mudaria um byte.

Mudaria depois, porque os dois records mudam por motivos diferentes. Um **DTO**, um objeto de
transferência de dados, é um tipo cuja única função é ser o formato dos dados que atravessam uma
fronteira, aqui a API HTTP. `Book` é o **domínio**: o que a loja sabe sobre um livro, e muda sempre que
a loja muda. A API é um **contrato** com programas que você não controla, um aplicativo de celular
instalado no ano passado ou o script noturno de um parceiro, e deve mudar só quando você decide.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Duas regiões tracejadas: à esquerda o contrato da API, que só muda quando você decide, com BookRequest (isbn, title, author, priceCents, sem id) e BookResponse (id, isbn, title, author, priceCents); à direita o domínio, que muda quando a loja muda, com Book. O JSON do cliente vira um BookRequest, BookService.add cria um Book, BookResponse.from transforma o Book num BookResponse, e ele volta ao cliente como JSON. O cliente nunca toca em Book.\"><defs><marker id=\"l6t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"140\" y=\"14\" width=\"200\" height=\"262\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><rect x=\"450\" y=\"14\" width=\"235\" height=\"262\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"240\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o contrato da API</text><text x=\"240\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só muda quando você decide</text><text x=\"567\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o domínio</text><text x=\"567\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">muda quando a loja muda</text><rect x=\"10\" y=\"115\" width=\"100\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"60\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o cliente</text><rect x=\"155\" y=\"62\" width=\"170\" height=\"80\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BookRequest</text><text x=\"240\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">isbn title author</text><text x=\"240\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">priceCents</text><text x=\"240\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sem id: o servidor escolhe</text><rect x=\"155\" y=\"182\" width=\"170\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"240\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">BookResponse</text><text x=\"240\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">id isbn title author</text><text x=\"240\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">priceCents</text><rect x=\"475\" y=\"112\" width=\"185\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"567\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Book</text><text x=\"567\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">id isbn title author</text><text x=\"567\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">priceCents</text><path d=\"M 110 128 L 127 128 L 127 100 L 153 100\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6t-ah)\"></path><text x=\"85\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">JSON entra</text><path d=\"M 325 100 L 395 100 L 395 132 L 473 132\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6t-ah)\"></path><text x=\"395\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">BookService.add</text><path d=\"M 475 162 L 395 162 L 395 215 L 327 215\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6t-ah)\"></path><text x=\"395\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">BookResponse.from</text><path d=\"M 155 215 L 127 215 L 127 152 L 112 152\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l6t-ah)\"></path><text x=\"85\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">JSON sai</text></svg>", "caption": "Os records da esquerda são o que os clientes veem. Book pode mudar de forma sem nenhum cliente perceber, porque nenhum cliente o recebe."}
```

Este curso faz os dois tipos de mudança, então o argumento pode ser conferido nele:

- **A aula 10 transforma `Book` numa entidade JPA**, uma classe com getters cujo autor não é mais uma
  `String`, e sim um objeto `Author` lido do banco de dados. `BookResponse.from` muda para
  `book.getAuthor().getName()`, e o JSON que um cliente recebe continua dizendo
  `"author": "Machado de Assis"`.
- **A aula 14 dá a `Book` uma contagem de estoque.** Ela chega à API porque a aula 14 acrescenta um
  componente a `BookResponse`: uma decisão, escrita num diff que alguém lê. Se o controlador
  devolvesse `Book`, todo campo que o domínio ganhasse seria publicado no dia em que fosse
  acrescentado, inclusive os que nunca foram feitos para um cliente.

## A requisição não tem id

O lado da requisição importa mais. Quem escolhe o id de um livro novo é o servidor, então o record que
um cliente envia **não tem componente `id`**: uma requisição que traz um não tem onde guardá-lo. A
seção sobre POST envia `"id": 1` para provar isso.

Crie `src/main/java/com/example/bookshop/catalogue/BookRequest.java`:

```java
package com.example.bookshop.catalogue;

public record BookRequest(String isbn, String title, String author, int priceCents) {
}
```

Quatro componentes e nenhuma regra ainda. O preço é um `int` por enquanto; a seção sobre validação o
muda, por um motivo que uma falha capturada deixa claro. As regras sobre o que um cliente pode enviar,
como um título que não seja vazio, também vão neste record e não em `Book`, porque descrevem a entrada
desta API, e não o que um livro é.

## O que custa

Dois records a mais e um método de mapeamento por tipo, o que para uma API de três campos é um custo
real. Projetos maiores costumam gerar o mapeamento, e em Java a ferramenta habitual para isso é o
MapStruct. Os nomes seguem uma convenção que vale manter: `BookRequest` entra, `BookResponse` sai, e o
sufixo diz para que lado os dados viajam.
