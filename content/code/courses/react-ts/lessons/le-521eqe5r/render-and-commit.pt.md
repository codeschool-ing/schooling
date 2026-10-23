---
title: Gatilho, renderização, commit
version: 1
---

**O React atualiza a tela em três passos, e só o último toca na página.** A maioria das surpresas com
o React vem de juntar os três num só, então vale dar nome a eles antes de olhar qualquer saída.

```schooling-figure
{"svg": "<svg data-fig=\"three-steps\" viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Três caixas em fila. Gatilho: a primeira renderização, ou um setter de estado sendo chamado. Renderização: o React chama os componentes e junta uma árvore nova, sem nada mudar na página. Commit: o React compara a árvore nova com a anterior e muda a página só onde elas diferem. A página só é tocada na terceira caixa.\"><text x=\"120\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">1 · gatilho</text><rect x=\"20\" y=\"44\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">primeira renderização, ou</text><text x=\"120\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">setMonday(…)</text><line x1=\"222\" y1=\"84\" x2=\"258\" y2=\"84\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"258.0,84.0 250.5,87.2 250.5,80.8\" fill=\"var(--wire)\"></polygon><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">2 · renderização</text><rect x=\"260\" y=\"44\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">chamar App, depois os</text><text x=\"360\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">filhos, árvore abaixo</text><line x1=\"462\" y1=\"84\" x2=\"498\" y2=\"84\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"498.0,84.0 490.5,87.2 490.5,80.8\" fill=\"var(--wire)\"></polygon><text x=\"600\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">3 · commit</text><rect x=\"500\" y=\"44\" width=\"200\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">comparar com a árvore anterior,</text><text x=\"600\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mudar só a diferença</text><line x1=\"20\" y1=\"150\" x2=\"460\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"240\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nada muda na página</text><line x1=\"500\" y1=\"150\" x2=\"700\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"600\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a página muda aqui</text></svg>", "caption": "Só o commit toca na página. Tudo antes dele pode ser repetido ou descartado.", "same": ["3 · commit"]}
```

1. **Gatilho.** Algo pede uma tela nova. Só duas coisas fazem isso: a primeira renderização, que o
   `createRoot(…).render(<App />)` do `main.tsx` inicia, e um setter de estado, como o `setMonday`,
   sendo chamado.
2. **Renderização.** O React chama os seus componentes. Chamar o `App` produz uma árvore dos objetos
   que a aula 2 examinou, e cada elemento de componente nessa árvore é chamado por sua vez, até os
   elementos HTML simples lá embaixo. **Renderizar é chamar funções e juntar o que elas devolvem.**
   Nada na página mudou ainda.
3. **Commit.** O React compara a árvore nova com a da última vez e muda a página onde, e só onde, as
   duas diferem. Na primeira renderização tudo é novo, então tudo é acrescentado.

O navegador então pinta, o que é assunto dele e não do React.

Duas consequências decorrem disso, e as próximas seções mostram as duas acontecendo.

**Uma renderização pode ser jogada fora.** Como o passo 2 não muda nada, o React é livre para chamar
os seus componentes quando quiser, mais de uma vez se quiser, e descartar o resultado. É por isso que
a aula 2 insistiu que um componente não pode mudar nada fora de si: um componente que escrevesse
numa variável, ou nos dados que recebeu, faria isso a cada chamada, inclusive nas chamadas cujo
resultado nunca chegou à tela.

**Uma renderização não é uma atualização da página.** Um componente pode ser chamado e produzir
exatamente o que produziu da última vez, e aí o commit não tem nada a fazer. Se isso sai barato é
pergunta da aula 21; se está correto nunca depende disso.
