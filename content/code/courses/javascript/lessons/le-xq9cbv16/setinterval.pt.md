---
title: setInterval, e o timeout que se repete
version: 1
---

**`setInterval(fn, ms)` roda `fn` a cada `ms` milissegundos até o `clearInterval` pará-lo.** Ele
mantém o próprio horário, e isso é um problema quando o trabalho leva mais que o intervalo. Cada tick
aqui faz 150 ms de trabalho, a cada 100 ms:

```javascript
const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();
let ticks = 0;

const id = setInterval(() => {
  ticks += 1;
  const busyUntil = performance.now() + 150;
  while (performance.now() < busyUntil) {}
  console.log(`tick ${ticks} ended at about ${round(performance.now() - start)} ms`);
  if (ticks === 4) clearInterval(id);
}, 100);
```

```
ana@dev:~/js$ node interval.js
tick 1 ended at about 300 ms
tick 2 ended at about 400 ms
tick 3 ended at about 600 ms
tick 4 ended at about 700 ms
```

O mesmo trabalho, com cada tick agendando o seguinte quando termina:

```javascript
const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();
let ticks = 0;

function tick() {
  ticks += 1;
  const busyUntil = performance.now() + 150;
  while (performance.now() < busyUntil) {}
  console.log(`tick ${ticks} ended at about ${round(performance.now() - start)} ms`);
  if (ticks < 4) setTimeout(tick, 100);
}
setTimeout(tick, 100);
```

```
ana@dev:~/js$ node chained-timeout.js
tick 1 ended at about 300 ms
tick 2 ended at about 500 ms
tick 3 ended at about 800 ms
tick 4 ended at about 1000 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Duas linhas do tempo de quatro ticks, cada tick fazendo 150 ms de trabalho. Com setInterval a cada 100 ms, o próximo tick já está vencido quando um termina, então os ticks rodam colados, sem intervalo. Com setTimeout agendado de novo no fim de cada tick, há sempre um intervalo de 100 ms entre o fim de um tick e o começo do seguinte.\"><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">setInterval</text><rect x=\"190.0\" y=\"45\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"227.5\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1</text><rect x=\"265.0\" y=\"45\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"302.5\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"340.0\" y=\"45\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"377.5\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3</text><rect x=\"415.0\" y=\"45\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"452.5\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">setTimeout</text><rect x=\"190.0\" y=\"115\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"227.5\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1</text><rect x=\"315.0\" y=\"115\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"352.5\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"440.0\" y=\"115\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"477.5\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3</text><rect x=\"565.0\" y=\"115\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.5\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><path d=\"M140 175 L690.0 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M140.0 170 L140.0 180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"140.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M390.0 170 L390.0 180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"390.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">500 ms</text><path d=\"M640.0 170 L640.0 180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"640.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000 ms</text><text x=\"290.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">folga de 100 ms</text></svg>", "caption": "O setInterval mantém o horário mesmo quando o trabalho é mais longo que o intervalo; um setTimeout encadeado sempre deixa a folga."}
```

**Com o `setInterval`, quatro ticks terminaram por volta de 700 ms**: cada vez que um tick acabava, o
próximo já estava atrasado, então rodaram colados e a página não teve folga entre eles. **Com o
`setTimeout` encadeado, terminaram por volta de 1000 ms**, e sempre houve 100 ms entre o fim de um tick
e o começo do seguinte.

## Qual usar

- **um `setTimeout` encadeado para qualquer coisa cujo trabalho possa ser lento**, e principalmente
  para qualquer coisa que espera uma rede: consultar um servidor a cada poucos segundos com
  `setInterval` manda a próxima requisição enquanto a anterior pode ainda estar esperando resposta;
- o `setInterval` para algo curto e regular, como um relógio batendo uma vez por segundo, em que o
  trabalho é bem mais curto que o intervalo;
- o `requestAnimationFrame` (aula 13) para tudo o que se mexe na tela, nunca um dos dois
  temporizadores: ele roda uma vez por quadro que a tela de fato desenha.

Os navegadores também **desaceleram os temporizadores em abas que ninguém está olhando**, muitas vezes
para uma vez por segundo ou menos, para poupar bateria. Isso não foi capturado aqui, já que um
navegador headless não tem aba escondida; é o motivo de uma contagem regressiva escrita com
`setInterval` escorregar quando o usuário troca de aba, e de um relógio dever ler a hora a cada tick em
vez de contar ticks.
