---
title: Quando a tela é desenhada
version: 1
---

A figura da seção anterior tinha um passo entre os microtasks e a próxima tarefa: **talvez desenhar um
quadro**. O navegador atualiza a tela no máximo uma vez por volta do laço, entre tarefas, tipicamente
sessenta vezes por segundo, e nunca enquanto JavaScript está rodando. Duas consequências decorrem, e
as duas são úteis:

```html
<!doctype html>
<div id="bar" style="width: 0; height: 10px; background: teal"></div>
<script>
  const bar = document.querySelector("#bar");
  let frames = 0;

  function grow() {
    frames += 1;
    bar.style.width = `${frames * 10}px`;
    if (frames < 5) requestAnimationFrame(grow);
    else console.log("5 frames drawn, width", bar.style.width);
  }
  requestAnimationFrame(grow);

  bar.style.width = "100px";
  bar.style.width = "200px";
  bar.style.width = "0px";
  console.log("three widths set in one task; the screen only ever saw the last");
</script>
```

```
ana@dev:~/js$ page frames.html --wait 500
three widths set in one task; the screen only ever saw the last
5 frames drawn, width 50px
```

- **Mudanças feitas dentro de uma tarefa são desenhadas juntas.** O script definiu a largura da barra
  três vezes seguidas; a tela nunca foi desenhada entre elas, então ninguém viu 100 nem 200 pixels. É
  por isso que um script consegue reconstruir uma lista inteira (aula 11) sem a página piscar a cada
  passo;
- **`requestAnimationFrame(fn)` roda `fn` logo antes do próximo quadro ser desenhado.** `grow` o pediu
  cinco vezes, uma por quadro, e a barra cresceu dez pixels por quadro. Código de animação o usa para
  cada mudança cair em exatamente um quadro.

## Consertando a página congelada

A página da primeira seção congelou porque uma tarefa levou dois segundos, e nenhum quadro e nenhum
clique podiam acontecer até ela acabar. **O conserto é cortar o trabalho longo em tarefas curtas**,
para o laço ter a vez entre elas:

```html
<!doctype html>
<button id="ping">Ping</button>
<script>
  const round = (ms) => Math.round(ms / 100) * 100;
  const started = performance.now();
  let done = 0;

  function work() {
    const sliceStart = performance.now();
    while (performance.now() - sliceStart < 50) {
      // one 50 ms slice of a long job
    }
    done += 1;
    if (done < 40) setTimeout(work, 0);
    else console.log("job finished after about", round(performance.now() - started), "ms");
  }
  setTimeout(work, 0);

  document.querySelector("#ping").addEventListener("click", () => {
    console.log("ping handled about", round(performance.now() - started), "ms in, after", done, "slices");
  });
</script>
```

```
ana@dev:~/js$ page chunks.html --do 'eval setTimeout(() => document.querySelector("#ping").click(), 100); undefined' --wait 2600
-- eval setTimeout(() => document.querySelector("#ping").click(), 100); undefined
ping handled about 300 ms in, after 6 slices
job finished after about 2200 ms
```

Os mesmos dois segundos de trabalho, feitos em quarenta fatias de 50 ms, cada fatia agendando a
próxima com `setTimeout`. **O ping foi respondido enquanto o trabalho rodava, depois de 6 fatias**, e
não depois das 40: entre as fatias, o laço rodou a tarefa do clique. O trabalho levou um pouco mais no
total, porque o laço fez outras coisas no meio, e essa é a troca. Para trabalho pesado de cálculo, um
**Web Worker** o roda numa thread separada, sem acesso à página, que é a outra resposta; a aula 15 traz
mais sobre temporizadores, e a aula 22 mostra como achar qual função é a lenta.
