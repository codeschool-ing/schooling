---
title: Achando elementos
version: 1
---

**O `querySelector` recebe um seletor CSS e devolve o primeiro elemento que bate**, ou `null`. O
`querySelectorAll` devolve todos. O seletor é a mesma linguagem de uma folha de estilo, então
`.book`, `#books .read` e `li:nth-child(2)` funcionam:

```html
<!doctype html>
<h1>My shelf</h1>
<ul id="books">
  <li class="book">Iracema</li>
  <li class="book read">Dom Casmurro</li>
</ul>
<script>
  console.log(document.querySelector(".book").textContent);
  console.log(document.querySelector("#books .read").textContent);
  console.log(document.querySelector(".missing"));

  const all = document.querySelectorAll(".book");
  const live = document.getElementsByClassName("book");
  console.log(all.length, live.length);

  const li = document.createElement("li");
  li.className = "book";
  li.textContent = "Macunaíma";
  document.getElementById("books").append(li);
  console.log(all.length, live.length);
</script>
```

```
ana@dev:~/js$ page select.html
Iracema
Dom Casmurro
null
2 2
2 3
```

## Três coisas que a saída mostra

- **Um seletor que não bate com nada dá `null`**, não erro. A próxima linha que o usa, como
  `.textContent`, é onde o erro aparece, e a mensagem é o `Cannot read properties of null` da aula 4.
  Quando você vir essa mensagem em código de página, o seletor é o primeiro suspeito: um erro de
  digitação, ou um script que rodou antes de o elemento existir;
- o `querySelectorAll` devolve uma `NodeList` **estática**: uma foto tirada quando rodou. Depois de um
  terceiro livro ser acrescentado, ela ainda dizia 2;
- o `getElementsByClassName` devolve uma `HTMLCollection` **viva**, que se atualiza sozinha conforme a
  página muda, e disse 3. Uma lista viva mudando enquanto um laço a percorre é um bug clássico, e
  esse é um motivo de a maior parte do código hoje usar `querySelectorAll`.

O `getElementById` é o jeito antigo e rápido de achar um elemento pelo `id`, e você vai vê-lo em toda
parte. `document.querySelector("#books")` faz o mesmo.

## Procurando dentro de um elemento

Todo elemento tem `querySelector` e `querySelectorAll` também, e **procurar a partir de um elemento
olha só dentro dele**. `row.querySelector(".title")` acha o título daquela linha e de nenhuma outra,
que é como a seção de percorrer desta aula alcança as partes de um item. A aula 7 mostrou a outra
coisa a lembrar sobre o resultado: uma `NodeList` tem `forEach` e não tem `map`, então
`Array.from(lista, fn)` a transforma em array quando você precisa dos métodos de array.
