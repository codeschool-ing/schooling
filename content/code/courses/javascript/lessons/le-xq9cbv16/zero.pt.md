---
title: O que zero quer dizer de verdade
version: 1
---

`setTimeout(fn, 0)` não quer dizer "agora". **Quer dizer: como uma tarefa nova, depois de tudo o que
está rodando e de todo microtask** (aula 13). As pessoas o usam para empurrar trabalho para "logo
depois disto", por exemplo para deixar o navegador desenhar uma mudança antes de um passo lento. Há
mais uma coisa que zero não quer dizer, e só uma medição mostra:

```html
<!doctype html>
<script>
  const gaps = [];
  let last = performance.now();
  function step() {
    const now = performance.now();
    gaps.push(now - last);
    last = now;
    if (gaps.length < 8) setTimeout(step, 0);
    else gaps.forEach((g, i) => console.log(`level ${i + 1}: ${g < 4 ? "under 4 ms" : "4 ms or more"}`));
  }
  setTimeout(step, 0);
</script>
```

```
ana@dev:~/js$ page nested.html --wait 500
level 1: under 4 ms
level 2: under 4 ms
level 3: under 4 ms
level 4: under 4 ms
level 5: under 4 ms
level 6: under 4 ms
level 7: 4 ms or more
level 8: 4 ms or more
```

Cada `step` agenda o seguinte com espera zero, então cada temporizador fica aninhado dentro do
anterior. **Os seis primeiros voltaram em menos de 4 ms; do sétimo em diante, cada um levou 4 ms ou
mais.** Isso é proposital: o padrão HTML manda os navegadores limitarem a espera de temporizadores
profundamente aninhados a pelo menos 4 ms, para que uma página que se agenda sem parar com espera zero
não consiga manter o processador a toda velocidade. O programa imprime uma categoria em vez de
milissegundos, porque a categoria é o que se mantém entre execuções.

## O que levar disso

- **zero é "logo", e "logo" depende do que mais está na fila.** Código que precisa de algo antes do
  próximo quadro usa `requestAnimationFrame`; código que precisa antes de qualquer outra tarefa usa um
  microtask, `queueMicrotask` ou `await`;
- **uma corrente de temporizadores de espera zero é mais lenta do que parece**: mil deles levam pelo
  menos quatro segundos num navegador. O fatiamento da aula 13 os usou pelo motivo oposto, para dar à
  página espaço entre as fatias, e esse é o uso honesto deles;
- o Node tem o seu próprio mínimo de um milissegundo para temporizadores, e nenhuma regra de 4 ms.
  **A linguagem não diz nada sobre temporizadores**: o `setTimeout` faz parte do que cada hospedeiro
  acrescenta, e é por isso que os dois diferem aqui.
