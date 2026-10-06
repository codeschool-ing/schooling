---
title: Um listener para muitos elementos
version: 1
---

O borbulhamento faz um listener numa lista ouvir todo clique em tudo o que está dentro dela.
**Delegação de eventos é pôr um listener no contêiner e descobrir, a partir de `event.target`, que
item foi clicado**:

```html
<!doctype html>
<ul id="books">
  <li class="book" data-id="7">Iracema <button class="lend">Lend</button></li>
  <li class="book" data-id="12">Dom Casmurro <button class="lend">Lend</button></li>
</ul>
<button id="add">Add a book</button>
<script>
  const list = document.querySelector("#books");

  list.addEventListener("click", (event) => {
    const button = event.target.closest(".lend");
    if (!button) return;
    const row = button.closest(".book");
    console.log("lend book", row.dataset.id);
  });

  document.querySelector("#add").addEventListener("click", () => {
    const li = document.createElement("li");
    li.className = "book";
    li.dataset.id = "19";
    li.append("Macunaíma ");
    const b = document.createElement("button");
    b.className = "lend";
    b.textContent = "Lend";
    li.append(b);
    list.append(li);
  });
</script>
```

```
ana@dev:~/js$ page delegate.html --do 'click li:nth-child(2) .lend' --do 'click #add' --do 'click li:nth-child(3) .lend' --do 'click li:nth-child(1)'
-- click li:nth-child(2) .lend
lend book 12
-- click #add
-- click li:nth-child(3) .lend
lend book 19
-- click li:nth-child(1)
```

A lista tem um listener e nenhum botão tem. Para cada clique:

- `event.target.closest(".lend")` sobe do que foi clicado até o botão de empréstimo mais próximo, o
  método que a aula 11 apresentou exatamente para isso. **Clicar no texto da linha, a última ação, não
  achou botão, e o listener voltou sem fazer nada**;
- a partir do botão, `closest(".book")` achou a linha, e o `data-id` disse qual livro. O livro é
  conhecido pelo id, nunca pelo título nem pela posição na lista.

O terceiro clique é o motivo de a delegação existir. **O livro de id 19 foi acrescentado depois de o
listener ser montado, e o botão dele funcionou.** Um listener preso a cada botão teria de ser preso
ao novo também, por quem o acrescentou, e esquecer é o bug de costume.

## Quando delegar

**Delegue para listas, tabelas e tudo cujos itens vêm e vão.** É um listener em vez de centenas, cobre
itens que ainda não existem, e remover um item não pede limpeza. Para um único botão que está sempre
lá, um listener no botão é mais simples e mais claro. Os frameworks delegam por você por trás da sua
própria sintaxe, e é por isso que um listener escrito em cada linha no React não custa um listener por
linha.
