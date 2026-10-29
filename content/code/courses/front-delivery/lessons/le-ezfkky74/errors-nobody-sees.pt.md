---
title: Erros que ninguém vê
version: 1
---

**Um erro num front-end acontece no computador de outra pessoa, e, a menos que a página o relate, a única
pessoa que fica sabendo é aquela com quem ele aconteceu.** Um servidor que falha escreve num log, numa
máquina que a equipe dele mantém. Uma página que falha escreve no console de um navegador, num celular que
você nunca vai segurar, e a pessoa que o segura vê um botão que não fez nada, fecha a aba e não conta para
ninguém.

O planner já tem três lugares onde isso acontece:

| onde | o que dá errado | o que o planner faz hoje |
|---|---|---|
| `saveDone` no `main.ts` | o servidor recusa o *Mark done*, ou não pode ser alcançado | `console.error("Could not save", …)` |
| `watch` no `main.ts` | o primeiro carregamento falha | `console.error("Could not load", …)` |
| `watchPlanner` no `apollo.ts` | uma consulta responde com erro | `console.error("Could not load", …)` |

E um lugar que ele não consegue ver de jeito nenhum: **tudo aquilo para o que ninguém escreveu um
`catch`.** Um `TypeError` num handler de clique, uma promise rejeitada sem ninguém esperando por ela, um bug
numa biblioteca. Esses param o código que estava rodando, imprimem uma linha vermelha no console e deixam a
página como estava naquele momento.

## O que é monitoramento

**Monitoramento de erros no cliente** é a página mandar um relatório curto de cada erro para um servidor
que você mantém, ou paga, para que a equipe veja as falhas quando elas acontecem, com detalhe suficiente
para achar a linha que as causou. **Crash reporting** é a mesma coisa, com o nome que os apps nativos lhe
deram.

O resto da aula constrói a cadeia inteira à mão, pequena o bastante para ler de uma vez:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A cadeia que esta aula constrói. No navegador, os listeners de error e unhandledrejection e os catches do próprio planner chamam report, que manda um beacon para /errors. O proxy do Vite o repassa ao coletor, que grava uma linha de JSON por relatório em errors.jsonl. Depois, o symbolicate.mjs lê a pilha de um relatório com os source maps da release, guardados em maps/, fora do host público, e imprime as linhas originais.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o navegador de alguém</text><rect x=\"20\" y=\"32\" width=\"230\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"error\"</text><text x=\"36\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"unhandledrejection\"</text><text x=\"36\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">saveDone · load · Planner</text><rect x=\"36\" y=\"120\" width=\"198\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">report()</text><line x1=\"250\" y1=\"134\" x2=\"300\" y2=\"134\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,134.0 292.6,137.1 292.6,130.9\" fill=\"var(--phosphor)\"></polygon><text x=\"275\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">/errors</text><text x=\"310\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o lado da equipe</text><rect x=\"302\" y=\"110\" width=\"170\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"387\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">collector.mjs</text><line x1=\"472\" y1=\"134\" x2=\"520\" y2=\"134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"520.0,134.0 512.6,137.1 512.6,130.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"522\" y=\"110\" width=\"178\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"611\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">errors.jsonl</text><rect x=\"522\" y=\"34\" width=\"178\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"611\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">maps/&lt;release&gt;/</text><text x=\"611\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nunca no host</text><rect x=\"302\" y=\"176\" width=\"398\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">symbolicate.mjs</text><text x=\"690\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">src/main.ts:16:45</text><line x1=\"611\" y1=\"160\" x2=\"611\" y2=\"174\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"611.0,174.0 607.9,166.6 614.1,166.6\" fill=\"var(--paper-dim)\"></polygon><line x1=\"700\" y1=\"82\" x2=\"708\" y2=\"82\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><path d=\"M 708 82 L 708 196 L 702 196\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path></svg>", "caption": "Capturar, mandar, guardar, e depois ler a pilha com os maps da mesma release."}
```

1. a página captura o que escapou e o que os próprios `catch` viram;
2. ela manda um relatório para um coletor;
3. o coletor o guarda;
4. um source map transforma a pilha minificada do relatório de volta nas linhas do próprio planner;
5. todo relatório diz de qual release veio.

Serviços hospedados como o Sentry fazem os cinco, e mais, e a seção sobre eles mostra como se configura
um. Construir antes é saber o que eles fazem com os seus dados, que é a pergunta da seção sobre a LGPD.
