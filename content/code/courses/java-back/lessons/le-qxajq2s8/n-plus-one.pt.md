---
title: O problema N+1, contado e corrigido
version: 1
---

O **problema N+1** é uma consulta para buscar uma lista de N coisas, seguida de mais uma consulta para
cada uma delas buscar algo para onde aponta. Ninguém o escreve de propósito. Ele nasce de um código
que se lê muito bem, um laço sobre livros perguntando a cada um o nome do autor, apoiado num
relacionamento lazy. Cada pergunta é rápida, então um teste com três linhas nunca percebe; uma página
com duzentos livros de duzentos autores faz duzentas e uma idas e voltas ao banco.

## Contando

O bookshop tem esse problema agora mesmo. O `findAll` ainda é a versão da seção sobre o entity manager,
`select b from Book b order by b.id`, e `BookService.list` mapeia cada livro com `BookResponse.from`,
que lê `getAuthor().getName()`. Com a aplicação rodando com o perfil `sql`, peça a lista:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8080/books
200
```

e olhe o segundo terminal:

```
2026-10-22T19:23:06.699-03:00 DEBUG 31528 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 order by b1_0.id
2026-10-22T19:23:06.702-03:00 DEBUG 31528 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:23:06.704-03:00 DEBUG 31528 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:23:06.704-03:00 DEBUG 31528 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:23:06.705-03:00 DEBUG 31528 --- [bookshop] [nio-8080-exec-3] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
```

Um `select` em `book`, com `author_id` entre as colunas e nenhum nome, e depois um `select` em `author`
para cada autor cujo nome foi pedido. **Quatro, não seis.** O autor de Dom Casmurro é carregado quando o
primeiro livro é mapeado; quando Quincas Borba pede Machado de Assis dois livros depois, o contexto de
persistência já o tem e responde sem consulta. O mesmo acontece com H. G. Wells. Então N é o número de
autores distintos na página, o que não consola ninguém: uma página com duzentos livros de duzentos
autores são duzentos e um comandos, cada um uma ida ao banco e uma volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 280\" role=\"img\" aria-label=\"À esquerda: a consulta simples envia um select em book e depois quatro selects em author, um para cada um de Dom Casmurro, The Time Machine, Frankenstein e Persuasion; os outros dois livros encontram os autores já carregados. À direita: com join fetch, um único select junta book e author e devolve seis linhas com os nomes.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">select b from Book b order by b.id</text><text x=\"20\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 livros, 4 autores: 5 comandos</text><rect x=\"20\" y=\"62\" width=\"226\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from book</text><text x=\"256\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6 linhas, só ids de autor</text><text x=\"14\" y=\"75\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><rect x=\"20\" y=\"96\" width=\"226\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from author where id=?</text><text x=\"256\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para Dom Casmurro</text><text x=\"14\" y=\"109\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><rect x=\"20\" y=\"130\" width=\"226\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from author where id=?</text><text x=\"256\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para The Time Machine</text><text x=\"14\" y=\"143\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><rect x=\"20\" y=\"164\" width=\"226\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from author where id=?</text><text x=\"256\" y=\"177\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para Frankenstein</text><text x=\"14\" y=\"177\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><rect x=\"20\" y=\"198\" width=\"226\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from author where id=?</text><text x=\"256\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para Persuasion</text><text x=\"14\" y=\"211\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Quincas Borba e The War of the Worlds: nenhum comando,</text><text x=\"20\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os autores já estão no contexto de persistência.</text><line x1=\"452\" y1=\"12\" x2=\"452\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"470\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">… join fetch b.author …</text><text x=\"470\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6 livros, 4 autores: 1 comando</text><rect x=\"470\" y=\"62\" width=\"214\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">select … from book join author …</text><text x=\"470\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6 linhas, cada uma com o nome do autor</text></svg>", "caption": "Os mesmos seis livros, pedidos duas vezes. Sem join fetch, cada autor novo é mais uma ida e volta; com ele, a lista inteira é uma só."}
```

## A correção que todo mundo tenta primeiro

Trocar o relacionamento para `FetchType.EAGER` parece a cura, e vale ver por que não é. Troque `LAZY`
por `EAGER` em `Book`, recompile, suba de novo e peça a lista outra vez:

```
2026-10-22T19:23:21.710-03:00 DEBUG 32238 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 order by b1_0.id
2026-10-22T19:23:21.716-03:00 DEBUG 32238 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:23:21.720-03:00 DEBUG 32238 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:23:21.723-03:00 DEBUG 32238 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
2026-10-22T19:23:21.728-03:00 DEBUG 32238 --- [bookshop] [nio-8080-exec-2] org.hibernate.SQL                        : select a1_0.id,a1_0.name from author a1_0 where a1_0.id=?
```

Os mesmos cinco comandos. O `EAGER` decide que o autor é carregado *junto* com o livro, mas uma
consulta JPQL é traduzida como foi escrita, e esta não cita autor nenhum. Então o Hibernate a roda,
encontra seis livros cujos autores prometeu carregar e os carrega um a um, na hora em vez de depois.
Onde o `EAGER` ajuda é no `find`, que o próprio Hibernate escreve e pode fazer com join. Um livro agora
é um comando só:

```
2026-10-22T19:23:21.792-03:00 DEBUG 32238 --- [bookshop] [nio-8080-exec-4] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id where b1_0.id=?
```

Volte para `LAZY` antes de seguir. O `EAGER` muda o problema de lugar em vez de resolvê-lo, e faz toda
outra consulta pagar pelos autores, queira ela ou não.

## Pedindo o autor na consulta

A cura é dizer, na consulta que carrega os livros, que os autores também são desejados. O
**`join fetch`** faz isso: ele junta a entidade relacionada e preenche o relacionamento a partir das
mesmas linhas, e não sobra proxy nenhum para se carregar sozinho. Em `JpaBookRepository`, substitua o
método `findAll` por este:

```java
    @Override
    public List<Book> findAll() {
        return em.createQuery("select b from Book b join fetch b.author order by b.id", Book.class)
                .getResultList();
    }
```

Recompile e suba de novo com o perfil `sql`. O relatório do catálogo na inicialização já caiu para um
comando:

```
2026-10-22T19:23:55.971-03:00  INFO 462 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 19.029 seconds (process running for 20.949)
2026-10-22T19:23:57.729-03:00 DEBUG 462 --- [bookshop] [           main] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id order by b1_0.id
2026-10-22T19:23:58.396-03:00  INFO 462 --- [bookshop] [           main] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

e a lista também:

```
2026-10-22T19:24:00.305-03:00 DEBUG 462 --- [bookshop] [nio-8080-exec-5] org.hibernate.SQL                        : select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id order by b1_0.id
```

Um comando. O `join` está no SQL, o `id` e o `name` do autor estão entre as colunas, e cada `Book`
chega com um `Author` de verdade em vez de um proxy, então `BookResponse.from` encontra os nomes já
ali. Seis livros ou seiscentos, a lista é um comando e uma ida e volta. `JpaBookRepository.java` agora
está na forma final desta aula.

## O que levar daqui

- **Leia uma vez o log de SQL de cada tela nova.** O problema N+1 é invisível no código e óbvio no
  log, onde parece uma coluna de comandos idênticos.
- **Decida o que carregar onde a consulta é escrita**, não na entidade. O mapeamento diz o que um
  livro É; a consulta diz do que esta tela precisa.
- O `join fetch` é uma cura entre várias. O Hibernate também consegue carregar juntos, numa consulta
  só, os autores lazy de muitos livros quando o primeiro deles é pedido (*batch fetching*), e a aula 11
  expressa a mesma intenção num repositório do Spring Data com `@EntityGraph`. A aula 11 de
  `sql-databases` olha o problema do lado do banco.
