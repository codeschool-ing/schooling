---
title: Lendo um trace
version: 1
---

**Um trace do clique lento da aula 5**, no plano de cinco mil cursos, com o processador quatro vezes
mais lento: abra uma página de curso e clique em *All courses*, que desenha a página inicial no
navegador.

```
ana@dev:~/planner$ node gen.ts 5000 && node tools/trace.ts http://localhost:3000/courses/course-1 --cpu 4 --click "text=All courses"
5000 courses
long task at 49 ms, 64 ms: other 64
long task at 241 ms, 83 ms: Evaluate module 72, other 6
long task at 1225 ms, 79 ms: Evaluate script 65, other 14
long task at 1381 ms, 102 ms: Event (click) 71, Layout 14, other 8
```

Quatro tarefas longas, e **nem todas são da página**. Leia-as em ordem:

- **a primeira**, poucos milissegundos depois de a navegação começar, não tem nada com nome dentro: nem
  HTML, nem script, nem estilo. É trabalho do próprio navegador, mensagens entre os processos dele,
  feito na thread da página antes de a página existir. O painel também a desenha, e ela não é de
  ninguém para corrigir.
- **Evaluate module** é o script do planner: o `main.ts` e tudo o que ele importa, rodado uma vez. A um
  quarto da velocidade leva uns 70 milissegundos.
- **Evaluate script**, logo antes do clique, não é do planner. É o Playwright, avaliando o próprio
  script dentro da página para achar o elemento chamado *All courses*. A ferramenta que mede está na
  medida.
- **Event (click)** é o tratador do planner: conta as sessões dos cinco mil cursos e desenha a página
  inicial, e depois o navegador faz o layout. A aula 5 trouxe este clique para um INP bom, e ele ainda é
  uma tarefa longa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"As tarefas longas do clique registrado, ao longo do tempo. Aos 49 ms, 64 ms: other. Aos 241 ms, 83 ms: Evaluate module. Aos 1225 ms, 79 ms: Evaluate script. Aos 1381 ms, 102 ms: Event (click). A primeira é do próprio navegador, a terceira é o Playwright achando o elemento, e a segunda e a quarta são do planner.\"><rect x=\"59.6\" y=\"120\" width=\"25.6\" height=\"30\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><line x1=\"72.4\" y1=\"68\" x2=\"72.4\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"72.4\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nada com nome</text><text x=\"72.4\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">64 ms · o navegador</text><rect x=\"136.4\" y=\"120\" width=\"33.2\" height=\"30\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><line x1=\"153.0\" y1=\"118\" x2=\"153.0\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"153.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Evaluate module</text><text x=\"153.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">83 ms · o planner</text><rect x=\"530.0\" y=\"120\" width=\"31.6\" height=\"30\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><line x1=\"545.8\" y1=\"68\" x2=\"545.8\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"545.8\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Evaluate script</text><text x=\"545.8\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">79 ms · Playwright</text><rect x=\"592.4\" y=\"120\" width=\"40.800000000000004\" height=\"30\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><line x1=\"612.8\" y1=\"118\" x2=\"612.8\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"612.8\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Event (click)</text><text x=\"612.8\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">102 ms · o planner</text><line x1=\"40\" y1=\"166\" x2=\"680\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"680.0,166.0 672.6,169.1 672.6,162.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"40.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"200.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">400</text><text x=\"360.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">800</text><text x=\"520.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1200</text><text x=\"680.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1600</text></svg>", "caption": "Duas das quatro tarefas longas não são da página.", "same": ["79 ms · Playwright"]}
```

## Testando um palpite

**Um trace convida a palpites, e os baratos dá para testar.** Dois deles aqui.

O Evaluate script logo antes do clique é do Playwright: então ele some sem o clique.

```
ana@dev:~/planner$ node tools/trace.ts http://localhost:3000/courses/course-1 --cpu 4
long task at 24 ms, 73 ms: other 72
long task at 156 ms, 62 ms: Layout 29, Recalculate style 24, other 5
long task at 251 ms, 81 ms: Evaluate module 71, other 4
```

Sumiu. No lugar apareceu, perto do começo, uma tarefa de estilo e layout que a rodada anterior não
tinha: as primeiras centenas de milissegundos variam um pouco de uma rodada para outra, o que é mais um
motivo para rodar duas vezes e confiar só nas tarefas que ficam. E um segundo palpite, o que quase todo mundo tem ao ler *Evaluate module*: o script é lento
porque lê da página um plano de cinco mil cursos. Então ele é rápido com o plano de três cursos. Ponha o
plano real de volta e olhe:

```
ana@dev:~/planner$ cp public/courses.json dist/ && node tools/trace.ts http://localhost:3000/courses/git --cpu 4
long task at 143 ms, 64 ms: Evaluate module 56, other 4
```

**56 milissegundos contra 72, então o palpite estava quase todo errado.** A maior parte da tarefa continua
lá com três cursos: o tamanho do plano é no máximo uma parte pequena do que ela custa, e avaliar o script
do planner é o resto, sejam quais forem os dados. Para onde esses milissegundos vão está
dentro da tarefa, no painel: abra o `trace.json`, ache a tarefa, e o flame chart embaixo dela diz que
função levou o tempo.

## Para que serve um trace

**O Lighthouse achou a página pesada; o trace diz o que foi cada pedaço de um momento lento.** Uma tarefa
longa no painel é o momento em que um toque teria esperado, e o flame chart dela nomeia o código. É o
passo entre "a página está lenta" e uma mudança que alguém pode fazer, e sempre vale conferir que a coisa
lenta é da página e não da ferramenta.
