---
title: Criando elementos novos
version: 1
---

Elementos novos se fazem com `document.createElement`, são preenchidos e presos na árvore. **Até um
elemento ser preso, ele existe só na memória e nada é desenhado.** Para uma linha com várias partes,
um `<template>` guarda a marcação uma vez, e cada cópia é preenchida a partir dos dados:

```html
<!doctype html>
<ul id="books"></ul>
<template id="row">
  <li class="book"><span class="title"></span> <small class="year"></small></li>
</template>
<script>
  const books = [
    { title: "Iracema", year: 1865 },
    { title: "Dom Casmurro", year: 1899 },
    { title: "Macunaíma", year: 1928 },
  ];
  const list = document.querySelector("#books");
  const template = document.querySelector("#row");

  const rows = books.map((b) => {
    const row = template.content.cloneNode(true);
    row.querySelector(".title").textContent = b.title;
    row.querySelector(".year").textContent = b.year;
    return row;
  });
  list.replaceChildren(...rows);

  list.querySelector("li:nth-child(2)").remove();
  console.log(list.children.length);
</script>
```

```
ana@dev:~/js$ page create.html --dom '#books'
2
<ul id="books">
  <li class="book"><span class="title">Iracema</span> <small class="year">1865</small></li>

  

  <li class="book"><span class="title">Macunaíma</span> <small class="year">1928</small></li>
</ul>
```

## Os passos, na ordem em que rodaram

- um elemento `<template>` **não é desenhado**; o `content` dele é um pedaço de árvore pronto,
  esperando para ser copiado. `cloneNode(true)` o copia com tudo o que tem dentro;
- cada cópia foi preenchida com `textContent`, então os títulos e os anos são texto, pareçam o que
  parecerem;
- **`replaceChildren(...rows)`** esvaziou a lista e pôs as três linhas, numa única mudança na página
  em vez de três. O `append` acrescenta no fim, e o `prepend` no começo;
- `remove()` tirou a segunda linha, e `list.children.length` disse 2.

A lista impressa mantém o espaço em branco que o template tinha, e as linhas vazias são onde ficaram
os nós de texto em volta da linha removida. O navegador não desenha esse espaço; são de novo os
`childNodes` da primeira seção.

## Montando listas a partir de dados

**Dados entram, elementos saem** é o formato da maior parte do código de interface: um array de
objetos de um servidor vira uma lista na página. Os frameworks dos próximos cursos existem em grande
parte para fazer esse passo por você, e para refazê-lo com eficiência quando os dados mudam.
Escrevê-lo uma vez à mão é como você vai entender o que eles fazem.
