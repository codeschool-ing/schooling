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

## O que se aproveita

O hábito de extrair lógica para uma função com o nome do que ela fornece, e a disciplina de fazê-la
limpar depois de si, são os mesmos nos dois, e nos equivalentes do Svelte e do Angular também (aula 22).
O que não se aproveita é o reflexo de um desenvolvedor React de embrulhar cada valor derivado num memo e
cada função num callback por medo de re-renderizações. Num composable, não há re-renderização a temer.
