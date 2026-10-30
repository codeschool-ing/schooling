---
title: Onde a reserva fica
version: 1
---

**Um boundary `Suspense` funciona como um error boundary, para esperar em vez de falhar.** Quando algo
dentro dele não está pronto, o React desenha o `fallback` no lugar de todos os filhos, e quando tudo
está pronto, os filhos substituem a reserva. Onde você o põe decide quanto da tela cede lugar à reserva.

```schooling-figure
{"svg": "<svg data-fig=\"suspend\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma linha do tempo de abrir um curso. O clique muda o openId; o React renderiza o CourseScreen lazy, cujo código não está lá, então ele suspende e o Suspense mais próximo desenha a reserva, Loading the course. O arquivo chega; o React renderiza de novo, e a tela do curso substitui a reserva.\"><rect x=\"10\" y=\"40\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">click</text><text x=\"75.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">setOpenId</text><line x1=\"141\" y1=\"67\" x2=\"151\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"151.0,67.0 143.5,70.2 143.5,63.8\" fill=\"var(--wire)\"></polygon><rect x=\"152\" y=\"40\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"217.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">parte lazy</text><text x=\"217.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">não carregada</text><line x1=\"283\" y1=\"67\" x2=\"293\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"293.0,67.0 285.5,70.2 285.5,63.8\" fill=\"var(--wire)\"></polygon><rect x=\"294\" y=\"40\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"359.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reserva</text><text x=\"359.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Loading the course…</text><line x1=\"425\" y1=\"67\" x2=\"435\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"435.0,67.0 427.5,70.2 427.5,63.8\" fill=\"var(--wire)\"></polygon><rect x=\"436\" y=\"40\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"501.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET</text><text x=\"501.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseScreen-…js</text><line x1=\"567\" y1=\"67\" x2=\"577\" y2=\"67\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"577.0,67.0 569.5,70.2 569.5,63.8\" fill=\"var(--wire)\"></polygon><rect x=\"578\" y=\"40\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">renderiza de novo</text><text x=\"643.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o curso</text><line x1=\"152\" y1=\"120\" x2=\"566\" y2=\"120\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"359\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o estudante vê a reserva</text><text x=\"643\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a tela</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um erro no caminho passa pelo Suspense e vai ao error boundary mais próximo</text></svg>", "caption": "Não estar pronto faz o Suspense mais próximo desenhar a reserva até estar.", "same": ["Loading the course…"]}
```

Posicionar um é uma questão do que o estudante deve ver enquanto espera:

| onde o `Suspense` fica | o que o estudante vê enquanto o código carrega |
|---|---|
| em volta do app inteiro, no `main.tsx` | o planejador some, toda vez que qualquer parte lazy carrega |
| dentro do `<main>`, em volta da tela do curso | só o conteúdo muda; a página do planejador fica |
| um em volta de cada uma de várias partes lazy | cada parte aparece assim que o seu código chega |
| um em volta de várias partes lazy juntas | uma reserva, até todas terem chegado |

As duas últimas linhas são uma escolha de verdade. Vários boundaries mostram conteúdo mais cedo, mas a
tela se preenche aos pedaços e as coisas se mexem quando cada pedaço chega. Um boundary para várias
partes espera a mais lenta delas e então mostra tudo de uma vez. Nenhum está errado; depende de as
partes fazerem sentido sozinhas.

Dividir tem um custo próprio, e **uma parte lazy é uma requisição, com uma espera, que uma parte
empacotada não tem**. Os lugares úteis para cortar são os que muitos usuários nunca alcançam ou
alcançam mais tarde:

- **Telas**, principalmente num app com rotas, em que a maioria das visitas vê duas ou três delas. A
  aula 17 divide por rota.
- **Coisas pesadas usadas num lugar só**: uma biblioteca de formulário, um gráfico, um editor de texto
  rico.
- **Não componentes pequenos da primeira tela**. Eles são necessários na hora, e carregá-los à parte só
  acrescenta uma requisição antes de a página ficar completa.

**O `Suspense` espera mais do que código.** Qualquer coisa que *suspenda* o aciona, e no React 19 três
tipos de coisa suspendem:

| o que suspende | de onde vem |
|---|---|
| um componente `lazy` cujo código não chegou | o próprio React, esta aula |
| `use(promise)` numa promise ainda não resolvida | o `use` do React 19, a mesma função que lê um contexto |
| um hook de dados feito para isso, como o `useSuspenseQuery` do TanStack Query | a biblioteca |

Um fetch num `useEffect`, como na aula 5, não suspende: o componente renderiza, mostra o próprio estado
de carregamento e renderiza de novo quando os dados chegam. É por isso que o planejador ainda desenha
*Loading the planner…* a partir de `status`, e não de uma reserva de `Suspense`. Mudar isso pediria o
`useSuspenseQuery`, e aí o estado de falha também teria de vir de um error boundary, com um jeito de
reiniciar a query numa nova tentativa; a aula 15, em que os dados são carregados no servidor, é onde
`Suspense` e dados se encontram de verdade.
