---
title: Escolhendo elementos: tipo, classe, id e atributo
version: 1
---

Um seletor é um padrão, e o navegador o testa contra cada elemento da página. Cinco tipos de seletor simples cobrem a maior parte do que você escreve:

| seletor | exemplo | encontra |
| --- | --- | --- |
| tipo | `h2` | todo elemento com esse nome |
| classe | `.featured` | todo elemento cujo `class` contém essa palavra |
| id | `#events` | o único elemento com esse `id` |
| atributo | `[href]`, `[type="email"]` | elementos com esse atributo, ou esse valor |
| universal | `*` | todo elemento |

Aqui estão quatro deles testados contra a página de eventos, `events.html`, com `probe match`, que lista o que um seletor escolhe e o começo do texto de cada elemento:

```
ana@laptop:~/site$ probe events.html match h2 match .featured match '#events' match '[href]'
h2  matches 3
  h2  "Poetry reading: Hilda Hilst"
  h2  "Book swap"
  h2  "Bookbinding class"
.featured  matches 1
  article.event.featured  "Book swap Saturday 10 October, from…"
#events  matches 1
  main#events  "Events Everything here is free unle…"
[href]  matches 2
  link  ""
  a.more  "How the swap works"
```

`h2` encontrou os três títulos de evento. `.featured` encontrou o único article que tem `featured` entre as classes: `class="event featured"` guarda duas classes, separadas por espaço, e o elemento casa com `.event` e com `.featured` igualmente. `#events` encontrou o `<main>`.

**`[href]` encontrou dois elementos, e um deles não está na página.** O `<link>` do head também tem `href`. Um seletor encontra o que diz e não o que você quis dizer, e esta é a primeira lição de lê-lo ao pé da letra: para dizer "links na página", escreva `a[href]`.

## Classes são o cavalo de batalha

A maior parte do CSS seleciona por classe. Uma classe é um nome que você escolhe para um tipo de coisa, `event`, `note`, `featured`, e ela pode ir em qualquer elemento, quantas vezes quiser, e se combinar com outras no mesmo elemento. Um id nomeia exatamente um elemento por página; ele serve para o alvo de um link como `#events` e é forte demais para estilo, pelos motivos que a seção 08 conta.

Dois seletores escritos juntos, sem espaço, precisam casar com o mesmo elemento: `p.note` é um parágrafo com a classe `note`, e `.event.featured` é um elemento com as duas classes. Dois seletores com uma vírgula entre eles são dois seletores dividindo um bloco: `h1, h2 { … }` estiliza os dois. O espaço é a próxima seção, e significa algo bem diferente.
