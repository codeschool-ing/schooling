---
title: Escutando eventos
version: 1
---

**`addEventListener(tipo, listener)` pede ao navegador que chame `listener` a cada vez que um evento
desse tipo acontecer naquele elemento.** O listener recebe um **objeto de evento** descrevendo o que
aconteceu:

```html
<!doctype html>
<button id="lend">Lend</button>
<script>
  const button = document.querySelector("#lend");

  function onLend(event) {
    console.log(event.type, event.target.id, event.currentTarget === button);
  }
  button.addEventListener("click", onLend);
  button.addEventListener("click", () => console.log("second listener"), { once: true });
</script>
```

```
ana@dev:~/js$ page listen.html --do 'click #lend' --do 'click #lend'
-- click #lend
click lend true
second listener
-- click #lend
click lend true
```

- `event.type` é o tipo do evento, `click`. **`event.target` é o elemento onde ele aconteceu**, aqui
  o botão; `event.currentTarget` é o elemento cujo listener está rodando, que agora é o mesmo botão e
  nem sempre vai ser, como a próxima seção mostra;
- um elemento pode ter **quantos listeners quiser para o mesmo evento**, e eles rodam na ordem em que
  foram acrescentados. O segundo só rodou no primeiro clique, porque `{ once: true }` remove um
  listener depois da primeira chamada.

## Removendo um listener

```html
<!doctype html>
<button id="lend">Lend</button>
<script>
  const button = document.querySelector("#lend");
  let clicks = 0;
  function onLend() {
    clicks += 1;
    console.log("click", clicks);
    if (clicks === 2) button.removeEventListener("click", onLend);
  }
  button.addEventListener("click", onLend);
</script>
```

```
ana@dev:~/js$ page remove.html --do 'click #lend' --do 'click #lend' --do 'click #lend'
-- click #lend
click 1
-- click #lend
click 2
-- click #lend
```

`removeEventListener` com **a mesma função** interrompeu o terceiro clique. Essa é a regra a que a
aula 7 dedicou uma seção: o navegador compara a função que você passa com `===`, então um listener
escrito na hora como arrow, ou feito com `bind` na chamada, não pode ser removido depois. Guarde-o num
nome, como `onLend` está aqui, se você vai precisar removê-lo.

## `onclick` e companhia

Você também vai ver `button.onclick = fn` e `onclick="…"` escrito no HTML. Os dois são mais antigos.
**Uma propriedade `on…` guarda um listener**, então atribuir um segundo substitui o primeiro, e a forma
em HTML põe código numa string dentro da marcação. O `addEventListener` não tem nenhum dos dois
limites, e é o que este curso usa; a seção de teclado usa a forma em HTML uma vez, de propósito, para
mostrar algo sobre uma `<div>`.
