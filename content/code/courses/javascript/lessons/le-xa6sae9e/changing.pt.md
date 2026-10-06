---
title: Mudando o que um elemento mostra
version: 1
---

Um objeto-elemento tem propriedades para tudo o que o navegador desenha, e **definir uma muda a
página na hora**. Quatro grupos cobrem a maior parte do que você vai fazer:

```html
<!doctype html>
<h1 id="title">My shelf</h1>
<li id="book" class="book" data-book-id="42" style="color: rebeccapurple">Iracema</li>
<input id="copies" value="1">
<script>
  const title = document.querySelector("#title");
  title.textContent = "Ana's shelf";

  const book = document.querySelector("#book");
  book.classList.add("read");
  book.classList.toggle("lent");
  console.log(book.className, book.classList.contains("read"));

  console.log(book.dataset.bookId, typeof book.dataset.bookId);
  book.dataset.lentTo = "bia";

  book.style.fontWeight = "bold";
  console.log(book.style.color, getComputedStyle(book).color);
</script>
```

```
ana@dev:~/js$ page change.html --dom '#book'
book read lent true
42 string
rebeccapurple rgb(102, 51, 153)
<li id="book" class="book read lent" data-book-id="42" style="color: rebeccapurple; font-weight: bold;" data-lent-to="bia">Iracema</li>
```

O `--dom '#book'` imprimiu o HTML do elemento depois de o script rodar, então a última linha é o
elemento **como o navegador o guarda agora**, não como o arquivo o escreveu.

## Texto, classes, dados e estilo

- **`textContent`** substitui o texto de um elemento. O título dizia `Ana's shelf` depois do script;
- **`classList`** acrescenta, remove, alterna e confere classes uma por vez, sem tocar nas outras. O
  livro manteve `book` e ganhou `read` e `lent`. Mudar classes e deixar a folha de estilo decidir a
  aparência delas é o jeito comum de mudar a aparência;
- **`dataset`** lê e escreve atributos `data-`, o lugar que o HTML reserva para a sua própria
  informação num elemento. `data-book-id` virou `dataset.bookId`, com o hífen trocado por maiúscula,
  e o valor voltou como a string `"42"`: atributos são sempre texto, então a conversão da aula 2 vale;
- **`style`** define estilos inline. Ele só lê o que está escrito no atributo `style`;
  `getComputedStyle` dá o valor que o navegador de fato usou, depois de toda folha de estilo, como
  `rgb(102, 51, 153)`.

## Texto ou marcação

```html
<!doctype html>
<li id="book"><span class="title">Iracema</span> <small>1865</small></li>
<script>
  const book = document.querySelector("#book");
  console.log(JSON.stringify(book.textContent));
  console.log(book.innerHTML);
</script>
```

```
ana@dev:~/js$ page read.html
"Iracema 1865"
<span class="title">Iracema</span> <small>1865</small>
```

Lido do mesmo elemento, **`textContent` dá só o texto e `innerHTML` dá a marcação**, com as tags.
Escrever funciona do mesmo jeito: `textContent` põe o texto exatamente como é, e `innerHTML` pede ao
navegador que leia a string como HTML. **Use `textContent` para qualquer valor que veio de fora do seu
código**, como um campo, um servidor ou a barra de endereço; `innerHTML` é para marcação que você
mesmo escreveu. O curso `front-quality`, na aula 9, explica o que dá errado no outro caso e como as
páginas se defendem.

## Propriedades e atributos não são a mesma coisa

```
ana@dev:~/js$ page change.html --do 'fill #copies 3' --do 'eval [document.querySelector("#copies").value, document.querySelector("#copies").getAttribute("value")].join(" / ")'
book read lent true
42 string
rebeccapurple rgb(102, 51, 153)
-- fill #copies 3
-- eval [document.querySelector("#copies").value, document.querySelector("#copies").getAttribute("value")].join(" / ")
3 / 1
```

**Um atributo é o que o HTML disse; uma propriedade é o estado atual do elemento.** O atributo
`value` do campo era `1` no arquivo. Depois de o `page` digitar `3` nele, a *propriedade* `value` dizia
3 e `getAttribute("value")` ainda dizia 1. O atributo é o valor inicial e a propriedade é o que o
usuário fez desde então. Para um campo de formulário, leia a propriedade.
