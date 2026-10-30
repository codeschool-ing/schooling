---
title: Quanto o context custa
version: 1
---

**Quando o valor de um provider muda, todo componente que lê aquele context renderiza de novo**, seja
qual for a parte do valor que ele usa. O context não tem como dizer "este componente só precisa de
`status`". O valor do planejador é o objeto que o `usePlanner` devolve: quando uma sessão é marcada,
`sessions` muda, um objeto novo é criado, e o `App` e o `CourseScreen` renderizam de novo. Aqui isso
está certo, porque os dois usam as sessões. Deixa de ser de graça quando um context carrega muitos
valores sem relação entre si e muitos componentes o leem.

```schooling-figure
{"svg": "<svg data-fig=\"context-cost\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O PlannerProvider guarda um valor com status, courses, sessions e toggleDone. O App lê status, courses e sessions; o CourseScreen lê sessions e toggleDone. Quando as sessões mudam, um valor novo é criado e os dois leitores renderizam de novo. Um store com seletores deixa cada leitor se inscrever na própria fatia.\"><rect x=\"200\" y=\"14\" width=\"320\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">PlannerProvider</text><text x=\"360.0\" y=\"49.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">{ status, courses, sessions, toggleDone }</text><rect x=\"60\" y=\"140\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">App</text><text x=\"170.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">status · courses · sessions</text><rect x=\"440\" y=\"140\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">CourseScreen</text><text x=\"550.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sessions · toggleDone</text><line x1=\"300\" y1=\"70\" x2=\"170\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"170.0,140.0 175.1,133.6 178.1,139.3\" fill=\"var(--amber)\"></polygon><line x1=\"420\" y1=\"70\" x2=\"550\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"550.0,140.0 541.9,139.3 544.9,133.6\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sessions mudou: os dois renderizam</text><text x=\"360\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">com um store, cada leitor se inscreve na própria fatia</text></svg>", "caption": "O context tem um valor só; todo leitor renderiza quando ele muda."}
```

Três hábitos mantêm o context barato:

- **Um context por assunto.** O usuário logado, o tema e os dados do planejador mudam em ritmos
  diferentes e são lidos por componentes diferentes. Três contexts pequenos valem mais que um grande,
  porque uma mudança no tema não renderiza tudo o que lê o usuário.
- **Um valor estável.** Um provider que monta o valor como um objeto novo a cada renderização própria
  faz todo leitor renderizar junto. O `PlannerProvider` só renderiza quando o estado do planejador
  muda, então o objeto dele só é novo quando algo dentro dele é; um provider que renderizasse também
  por outros motivos envolveria o valor num `useMemo`.
- **Context para valores que mudam pouco.** Um context que muda a cada tecla renderiza todos os
  leitores a cada tecla. É aí que as bibliotecas das três próximas seções se justificam: cada uma
  deixa um componente se inscrever numa fatia de um valor compartilhado e renderizar só quando essa
  fatia muda.

O context também não é um gerenciador de estado. Ele move um valor; o estado em si continua sendo um
`useState` no `usePlanner`. Toda biblioteca abaixo é, no fundo, um store que mora fora do React com um
hook que se inscreve nele, e é assim que elas conseguem renderizar de novo só os componentes cuja
fatia mudou.
