---
title: writable, readable e derived
version: 1
---

**O `svelte/store` oferece três funções que montam stores corretamente, para você não precisar.** O
relógio escrito à mão da seção anterior tem um defeito: dois componentes inscritos nele iniciariam dois
timers. Um store montado com estas funções guarda um valor e uma fonte, seja quantos forem os
assinantes, e inicia a fonte quando chega o primeiro e a para quando sai o último.

| função | cria | você pode |
|---|---|---|
| `writable(initial)` | um store que você define de fora | `.set(value)`, `.update((old) => new)`, se inscrever |
| `readable(initial, start)` | um store que se define sozinho, a partir de uma fonte que você inicia | só se inscrever |
| `derived(stores, fn)` | um store calculado a partir de outros stores | só se inscrever |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A vida de um store readable com dois assinantes, numa linha do tempo. Quando o primeiro assinante, um componente, se inscreve, o store chama a sua função de início, que inicia o intervalo. Um segundo assinante entra e compartilha o mesmo intervalo. O primeiro sai e o intervalo continua para o segundo. Quando o último assinante sai, o store chama a função que o início devolveu, que limpa o intervalo.\"><line x1=\"40\" y1=\"200\" x2=\"690\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,200.0 682.6,203.1 682.6,196.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"690\" y=\"216\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><rect x=\"120\" y=\"30\" width=\"300\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">assinante A</text><rect x=\"260\" y=\"76\" width=\"340\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">assinante B</text><rect x=\"120\" y=\"130\" width=\"480\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um setInterval, compartilhado pelos dois</text><line x1=\"120\" y1=\"200\" x2=\"120\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"120.0,168.0 123.1,175.4 116.9,175.4\" fill=\"var(--amber)\"></polygon><text x=\"120\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">primeiro entra: start()</text><line x1=\"600\" y1=\"200\" x2=\"600\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"600.0,168.0 603.1,175.4 596.9,175.4\" fill=\"var(--amber)\"></polygon><text x=\"600\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">último sai: o que start() devolveu</text><line x1=\"260\" y1=\"196\" x2=\"260\" y2=\"204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"420\" y1=\"196\" x2=\"420\" y2=\"204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line></svg>", "caption": "Um store readable roda a sua fonte só enquanto alguém está inscrito, e uma vez só, seja quantos forem."}
```

Reescreva o `src/lib/timer.js` com elas, e dê a ele um início e um fim:

```schooling-example
{"language": "javascript", "file": "src/lib/timer.js", "parts": [
 {"code": "// timer.js: a study timer, made of three stores.\nimport { readable, writable, derived } from 'svelte/store';\n\nexport const now = readable(Date.now(), (set) => {\n\tconst id = setInterval(() => set(Date.now()), 250);\n\treturn () => clearInterval(id);\n});", "note": "O `readable` recebe o valor inicial e uma função que inicia a fonte. Ela roda quando chega o primeiro assinante; o que ela devolve roda quando o último sai."},
 {"code": "export const startedAt = writable(null);", "note": "O `writable` é um valor que qualquer um pode definir: aqui, quando o timer foi iniciado, ou `null` enquanto está parado."},
 {"code": "export const elapsed = derived([now, startedAt], ([$now, $startedAt]) =>\n\t$startedAt === null ? 0 : Math.floor(($now - $startedAt) / 1000)\n);", "note": "O `derived` recalcula a partir dos stores que lista sempre que qualquer um deles muda. O argumento recebe os valores deles, em ordem."}
]}
```

```schooling-example
{"language": "html", "file": "src/routes/timer/+page.svelte", "parts": [
 {"code": "<script>\n\timport { startedAt, elapsed } from '#lib/timer.js';\n</script>\n\n<main>\n\t<h1>Study timer</h1>\n\t{#if $startedAt === null}\n\t\t<button onclick={() => startedAt.set(Date.now())}>Start</button>\n\t{:else}\n\t\t<button onclick={() => startedAt.set(null)}>Stop</button>\n\t{/if}\n\t<p>{$elapsed} s studied</p>\n</main>", "note": "Dois stores lidos com `$`. Os botões chamam `set` no que é writable."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/timer --click Start --wait 2400
-- click Start
-- wait 2400
at /timer
- main:
  - heading "Study timer" [level=1]
  - button "Stop"
  - paragraph: 2 s studied
```

**O store vive mais que a página.** O `startedAt` mora no módulo, não no componente, então mantém o
valor se a página do timer for deixada e aberta de novo por um link dentro da aplicação; só recarregar
a página inteira o recomeça. Esse é o motivo de os stores serem usados para estado compartilhado, e é
também, no servidor, um problema de que a próxima aula trata.

## Atualizar a partir do valor antigo

O `update` é um `set` com uma função, para quando o valor novo depende do antigo: `count.update((n) =>
n + 1)`. Dentro de um componente, `$count += 1` é atalho exatamente para isso, e `$startedAt = null`
para `startedAt.set(null)`. O atalho só existe onde o `$` existe, nos componentes.
