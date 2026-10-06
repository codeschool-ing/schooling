---
title: Andando de um elemento para outro
version: 1
---

O código costuma começar de um elemento e precisar de outro perto dele: **um botão foi clicado, e o
programa precisa do livro a que esse botão pertence**. A árvore tem propriedades para toda direção:

```html
<!doctype html>
<ul id="books">
  <li class="book" data-id="7"><span class="title">Iracema</span> <button class="lend">Lend</button></li>
  <li class="book" data-id="12"><span class="title">Dom Casmurro</span> <button class="lend">Lend</button></li>
</ul>
<script>
  const button = document.querySelectorAll(".lend")[1];
  const row = button.closest(".book");
  console.log(row.dataset.id, row.querySelector(".title").textContent);
  console.log(button.parentElement === row, row.parentElement.id);
  console.log(row.previousElementSibling.dataset.id, row.nextElementSibling);
  console.log(button.matches(".lend"), button.closest("table"));
  console.log(row.childNodes.length, row.children.length);
</script>
```

```
ana@dev:~/js$ page traverse.html
12 Dom Casmurro
true books
7 null
true null
3 2
```

- **`closest(".book")` sobe a partir do botão**, pelos ancestrais, até o primeiro que bate. Ele achou
  a linha, e o `data-id` da linha disse qual livro era. Esta é a linha que a aula 12 usa para todo
  clique;
- `parentElement` é um passo para cima, e `previousElementSibling` e `nextElementSibling` são um passo
  para o lado. A segunda linha não tinha irmão seguinte, então a resposta foi `null`;
- `matches(".lend")` pergunta se um elemento bate com um seletor, e um `closest` que não acha nada,
  aqui `closest("table")`, devolve `null`;
- a linha tem **três** `childNodes` e **dois** `children`: o espaço entre o título e o botão é um nó
  de texto.

## Guarde os dados na página ou ao lado dela

O `data-id` na linha é o que tornou a caminhada útil: **o elemento levava o id da coisa que mostra**,
então o código não precisou comparar títulos nem contar posições. A posição de uma linha muda quando a
lista é ordenada, e o título muda quando alguém corrige um erro de digitação; um id não faz nenhuma
das duas coisas. Esse é o motivo de pôr um id no elemento que você constrói, como `create.html`
poderia ter feito com `dataset.id = b.id`.
