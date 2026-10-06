---
title: Uma coisa por vez
version: 1
---

**O JavaScript de uma página roda numa thread só**: uma sequência de instruções, uma por vez.
Enquanto uma função roda, nada mais do JavaScript daquela página consegue rodar, e isso inclui os
handlers dos cliques do usuário. Um botão que começa um trabalho longo mostra isso:

```html
<!doctype html>
<button id="sort">Sort 2 seconds' worth</button>
<button id="ping">Ping</button>
<script>
  const round = (ms) => Math.round(ms / 100) * 100;
  let busyFrom = 0;

  document.querySelector("#sort").addEventListener("click", () => {
    busyFrom = performance.now();
    while (performance.now() - busyFrom < 2000) {
      // pretend to sort a very large list
    }
    console.log("sorting finished after about", round(performance.now() - busyFrom), "ms");
  });

  document.querySelector("#ping").addEventListener("click", () => {
    console.log("ping handled about", round(performance.now() - busyFrom), "ms after sorting began");
  });
</script>
```

```
ana@dev:~/js$ page freeze.html --do 'eval setTimeout(() => document.querySelector("#sort").click()); setTimeout(() => document.querySelector("#ping").click(), 100); undefined' --wait 2600
-- eval setTimeout(() => document.querySelector("#sort").click()); setTimeout(() => document.querySelector("#ping").click(), 100); undefined
sorting finished after about 2000 ms
ping handled about 2000 ms after sorting began
```

O `page` clicou em Sort e, um décimo de segundo depois, em Ping. **O Ping só foi tratado quando a
ordenação terminou, dois segundos depois.** O clique em si aconteceu na hora; o navegador o anotou e o
pôs numa fila. O handler dele não podia rodar até o código que já estava rodando terminar, porque só
existe uma thread para rodá-lo. Durante esses dois segundos a página não conseguia reagir a nada, e um
navegador de verdade também teria parado de desenhá-la.

## Por que uma thread

Duas threads mexendo na mesma página ao mesmo tempo precisariam de travas em volta de cada elemento,
e todo script da web teria de ser escrito pensando nelas. **Uma thread significa que uma função, uma
vez começada, roda até o fim sem nada mudar a página por baixo dela.** Essa garantia se chama
**run-to-completion**, rodar até o fim, e é ela que torna simples o código comum de página:

```javascript
console.log("1. the program starts");

setTimeout(() => console.log("4. the timer's callback"), 0);

for (let i = 0; i < 3; i++) {
  console.log(`2. loop, turn ${i}`);
}

console.log("3. the program's last line");
```

```
ana@dev:~/js$ node run-to-completion.js
1. the program starts
2. loop, turn 0
2. loop, turn 1
2. loop, turn 2
3. the program's last line
4. the timer's callback
```

O temporizador foi armado para 0 milissegundos, antes do laço, e **o callback dele ainda assim rodou
por último**. Nada interrompe código que está rodando; o callback esperou o programa inteiro terminar.
O resto desta aula é sobre essa espera: onde os callbacks esperam, em que ordem saem, e o que o
navegador faz entre uma coisa e outra.
