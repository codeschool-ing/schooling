---
title: O store do planner, como padrão
version: 1
---

**Desde a aula 11 o planner guarda o estado num serviço de signals, e a forma em que ele se assentou
tem nome em toda biblioteca de estado: os dados correm num sentido só.** Um componente lê signals;
quando algo acontece, ele chama um método; o método muda o estado; os signals que dependem do estado
acompanham; o template os desenha de novo. Nada escreve o estado além dos métodos do próprio store, e
nada o lê senão pelo que o store entrega.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um laço de quatro caixas, os dados correndo num sentido só. O template de um componente lê signals. Um evento no componente chama um método do store. O método troca o estado privado do store. Os signals computed que dependem do estado acompanham, e o template os lê de novo.\"><rect x=\"40\" y=\"40\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">componente</text><text x=\"150\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o template lê signals</text><rect x=\"460\" y=\"40\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">método</text><text x=\"570\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">toggle(), add()</text><rect x=\"460\" y=\"150\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estado</text><text x=\"570\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">private data</text><rect x=\"40\" y=\"150\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">computed</text><text x=\"150\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sessions(), weekTotals()</text><line x1=\"262\" y1=\"65\" x2=\"456\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"456.0,65.0 448.6,68.1 448.6,61.9\" fill=\"var(--wire)\"></polygon><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um evento chama</text><line x1=\"570\" y1=\"92\" x2=\"570\" y2=\"146\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"570.0,146.0 566.9,138.6 573.1,138.6\" fill=\"var(--wire)\"></polygon><text x=\"578\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">troca</text><line x1=\"456\" y1=\"175\" x2=\"264\" y2=\"175\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"264.0,175.0 271.4,171.9 271.4,178.1\" fill=\"var(--wire)\"></polygon><text x=\"360\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">acompanham</text><line x1=\"150\" y1=\"148\" x2=\"150\" y2=\"94\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"150.0,94.0 153.1,101.4 146.9,101.4\" fill=\"var(--wire)\"></polygon><text x=\"158\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lidos de novo</text><text x=\"360\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nada mais escreve o estado</text></svg>", "caption": "Os dados correm num sentido: eventos viram chamadas de método, métodos trocam o estado, e o que depende dele acompanha."}
```

Cada parte do `PlannerStore` tem o nome que as bibliotecas dão a ela:

| no `PlannerStore` | o nome geral | o que faz funcionar |
|---|---|---|
| `private readonly data` | o **estado** | um lugar, privado, para nada mais escrevê-lo |
| `courses`, `sessions`, `weekTotals` | **seletores** | `computed`, só de leitura, recalculados só quando o estado muda |
| `minutesThisWeek(courseId)` | um seletor com argumento | um método que lê signals, rastreado onde quer que seja chamado |
| `toggle`, `add` | **actions**, e o código que as trata | uma entrada com nome, a única, que também conversa com o servidor |
| `saveError` | estado sobre o estado | um signal como os outros |

**Duas regras o mantêm de pé.** O estado é trocado, nunca mudado no lugar, como a aula 6 disse e os
pipes puros da aula 19 confirmaram: o `update` retorna um objeto novo, então todo `computed` e todo
componente `OnPush` vê um valor novo. E um componente nunca guarda uma cópia: ele lê o signal do store
onde precisa, então não há nada para sair de sincronia, que foi o defeito que a aula 11 removeu.

Nem todo estado vai num store. O valor de um formulário enquanto é digitado pertence ao formulário; se
um painel está aberto pertence ao componente que o desenha. Um store é para estado que mais de um lugar
lê, ou que precisa sobreviver ao componente que o mostra. A próxima seção acrescenta uma dessas coisas.
