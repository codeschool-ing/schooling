---
title: Composables e os custom hooks do React
version: 1
---

**Um composable e um custom hook do React resolvem o mesmo problema, compartilhar lógica com estado
entre componentes, e se parecem: os dois são funções chamadas `use…`.** Eles se comportam de forma
diferente porque os componentes que os chamam se comportam, e essa diferença é a da aula 2: um
componente React roda a cada renderização, o setup de um componente Vue roda uma vez.

A mesma lógica, a semana, como um hook do React. Ela aparece para comparação e não faz parte do projeto
deste curso:

```jsx
// React: called on every render of the component that uses it.
function useWeek(start) {
  const [monday, setMonday] = useState(start)
  const sunday = useMemo(() => addDays(monday, 6), [monday])
  const next = useCallback(() => setMonday((m) => addDays(m, 7)), [])
  return { monday, sunday, next }
}
```

| | custom hook do React | composable do Vue |
|---|---|---|
| com que frequência roda | a cada renderização do chamador | uma vez, durante o setup do chamador |
| o que devolve | valores comuns, novos a cada renderização | refs, que continuam sendo os mesmos objetos e mudam o seu `.value` |
| valores derivados | `useMemo` com uma lista de dependências, escrita à mão | `computed`, que encontra as suas sozinho |
| funções que devolve | recriadas a cada renderização, a menos que embrulhadas em `useCallback` | criadas uma vez |
| a regra sobre chamá-lo | sempre, na mesma ordem, a cada renderização: nunca dentro de uma condição ou de um laço | durante o setup, nunca num callback que roda depois; dentro de uma condição é permitido |

## Por que as regras diferem

**O React identifica o estado de cada hook pela sua posição** na sequência de chamadas de hooks de cada
renderização. Chame `useState` dentro de um `if`, e na renderização em que a condição muda, cada hook
seguinte lê o estado do anterior. Daí a regra: os mesmos hooks, na mesma ordem, sempre.

**O Vue identifica o estado pelo próprio objeto ref.** O composable roda uma vez, os refs que ele cria
são objetos comuns guardados pelo componente, e nada neles depende de ordem. Um composable chamado dentro
de um `if` no setup funciona, desde que o setup ainda esteja rodando: o que o Vue precisa é só saber qual
componente está sendo montado, para prender a ele os hooks e os watchers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas metades. À esquerda, o React: o estado é encontrado pela posição. Na renderização 1 três hooks são chamados, o primeiro dentro de um if, nas posições 1, 2 e 3. Na renderização 2 a condição mudou e o hook dentro do if não é chamado, então o hook seguinte fica com a posição 1 e o que vem depois dele com a posição 2: cada hook seguinte lê o estado do anterior. À direita, o Vue: o setup roda uma vez, o composable useWeek é chamado dentro dele, dentro de um if se for preciso, e o componente guarda os objetos que ele devolve, monday, um ref, e sunday, um computed. O estado é o próprio objeto, não o seu lugar numa lista.\"><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">React: estado pela posição</text><text x=\"105\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">renderização 1</text><text x=\"265\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">renderização 2: o if é falso</text><text x=\"22\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"40\" y=\"58\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hook dentro do if</text><rect x=\"200\" y=\"58\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">hook seguinte</text><line x1=\"172\" y1=\"75\" x2=\"196\" y2=\"75\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"196.0,75.0 188.6,78.1 188.6,71.9\" fill=\"var(--amber)\"></polygon><text x=\"22\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"40\" y=\"104\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hook seguinte</text><rect x=\"200\" y=\"104\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o depois dele</text><line x1=\"172\" y1=\"121\" x2=\"196\" y2=\"121\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"196.0,121.0 188.6,124.1 188.6,117.9\" fill=\"var(--amber)\"></polygon><text x=\"22\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"40\" y=\"150\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o depois dele</text><rect x=\"200\" y=\"150\" width=\"130\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"180\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">cada hook seguinte lê o estado do anterior</text><line x1=\"360\" y1=\"14\" x2=\"360\" y2=\"236\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Vue: estado pelo objeto</text><rect x=\"390\" y=\"50\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">setup()</text><text x=\"460\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">roda uma vez</text><line x1=\"460\" y1=\"96\" x2=\"460\" y2=\"124\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"460.0,124.0 456.9,116.6 463.1,116.6\" fill=\"var(--phosphor)\"></polygon><rect x=\"390\" y=\"126\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">useWeek()</text><text x=\"460\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">dentro de um if: pode</text><rect x=\"565\" y=\"70\" width=\"135\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monday: ref</text><line x1=\"532\" y1=\"148\" x2=\"561\" y2=\"87\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"561.0,87.0 560.6,95.0 555.0,92.3\" fill=\"var(--phosphor)\"></polygon><rect x=\"565\" y=\"130\" width=\"135\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"632\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sunday: computed</text><line x1=\"532\" y1=\"148\" x2=\"561\" y2=\"147\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"561.0,147.0 553.7,150.4 553.5,144.1\" fill=\"var(--phosphor)\"></polygon><text x=\"540\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o componente guarda os mesmos objetos a vida toda</text></svg>", "caption": "O React acha o estado de um hook pela ordem das chamadas; o Vue, pelo ref que o composable criou."}
```

## O que se aproveita

O hábito de extrair lógica para uma função com o nome do que ela fornece, e a disciplina de fazê-la
limpar depois de si, são os mesmos nos dois, e nos equivalentes do Svelte e do Angular também (aula 22).
O que não se aproveita é o reflexo de um desenvolvedor React de embrulhar cada valor derivado num memo e
cada função num callback por medo de re-renderizações. Num composable, não há re-renderização a temer.
