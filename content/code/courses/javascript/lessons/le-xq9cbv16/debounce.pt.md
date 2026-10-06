---
title: Esperando a digitação parar
version: 1
---

Uma caixa de busca que consulta um servidor a cada evento `input` (aula 12) manda uma requisição por
tecla, e a maioria fica desatualizada antes de chegar. **O debounce espera os eventos pararem por um
tempo, e então age uma vez**:

```html
<!doctype html>
<input id="q" placeholder="Search the shelf">
<script>
  function debounce(fn, ms) {
    let timer;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => fn(...args), ms);
    };
  }

  const search = (text) => console.log(`searching for "${text}"`);
  const searchSoon = debounce(search, 300);
  let keystrokes = 0;

  document.querySelector("#q").addEventListener("input", (event) => {
    keystrokes += 1;
    searchSoon(event.target.value);
  });
  window.report = () => console.log("keystrokes:", keystrokes);
</script>
```

```
ana@dev:~/js$ page search.html --do 'focus #q' --do 'press i' --do 'press r' --do 'press a' --do 'press c' --do 'press e' --do 'wait 400' --do 'press m' --do 'press a' --do 'wait 400' --do 'eval report()'
-- focus #q
-- press i
-- press r
-- press a
-- press c
-- press e
-- wait 400
searching for "irace"
-- press m
-- press a
-- wait 400
searching for "iracema"
-- eval report()
keystrokes: 7
```

O `page` digitou `irace`, parou 400 ms, digitou `ma`, e parou de novo. **Sete teclas, duas buscas**: uma
por `irace`, quando a primeira pausa passou dos 300 ms de espera, e uma por `iracema`.

## Como o `debounce` funciona

Ele é uma closure (aula 6) em volta de uma variável, `timer`. Toda chamada **cancela o temporizador
que a chamada anterior armou e arma um novo**. Enquanto as teclas chegam a menos de 300 ms uma da
outra, cada temporizador é cancelado antes de poder disparar. Só quando uma tecla é seguida de 300 ms
de silêncio um temporizador sobrevive, e ele chama `search` com o último valor. A espera é uma
questão de julgamento: longa o bastante para pular as pausas dentro de uma palavra, curta o bastante
para o usuário não notar.

## O irmão dele, o throttle

**O throttle roda no máximo uma vez por intervalo, por mais eventos que cheguem**, em vez de esperar
eles pararem. Ele serve para eventos que não param enquanto algo acontece, como rolar a página ou
redimensioná-la, em que você quer atualizações regulares durante o movimento, e não uma no fim. Os
dois são um punhado de linhas em volta do `setTimeout`, e os dois existem em bibliotecas utilitárias
com esses nomes.
