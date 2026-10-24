---
title: Quando o memo não faz nada
version: 1
---

**O `memo` só é tão bom quanto as props que recebe.** Uma prop que é nova a cada renderização, e a
comparação falha toda vez: o React faz a comparação, e depois a renderização mesmo assim, e o memo custou
algo e não poupou nada. O jeito mais fácil de chegar lá é uma arrow function escrita inline:

```
ana@dev:~/planner$ sed -i 's|onToggle={toggleDone} />}|onToggle={(id) => toggleDone(id)} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx
34:        render={(s) => <SessionRow session={s} onToggle={(id) => toggleDone(id)} />}
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click button Plan a session'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click button Plan a session
drawn: row s1 (update)
drawn: row s2 (update)
ana@dev:~/planner$ sed -i 's|onToggle={(id) => toggleDone(id)} />}|onToggle={toggleDone} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx
34:        render={(s) => <SessionRow session={s} onToggle={toggleDone} />}
```

`(id) => toggleDone(id)` faz o mesmo que `toggleDone`, e é uma **função nova a cada renderização**, então o
`onToggle` mudou toda vez e as duas linhas foram desenhadas depois do clique, como se o `memo` não
estivesse lá. O último `sed` devolveu a função estável.

Quais valores mantêm a identidade de uma renderização para a outra decide se o `memo` pode funcionar:

| uma prop que é | a mesma na próxima renderização? | para deixá-la a mesma |
|---|---|---|
| uma string, um número, um booleano | sim, se o valor for | nada a fazer |
| um objeto do cache do React Query | sim, onde os dados não mudaram | nada a fazer |
| um setter do `useState`, ou `mutate` | sim, sempre | nada a fazer |
| um objeto ou array montado na renderização | não | `useMemo`, aula 7 |
| uma função escrita na renderização | não | `useCallback`, aula 7 |
| JSX passado como `children` | não | raramente vale a pena |

É por isso que a aula 7 disse que `useMemo` e `useCallback` importam onde a identidade importa: **o
trabalho de verdade deles é alimentar o `memo`**, ou um array de dependências. Um `useCallback` numa função
passada a um componente que não é memoizado não compra nada.

E é por isso que acrescentar `memo` por reflexo é um erro. Todo componente memoizado é uma comparação a
cada renderização e um conjunto de props que precisa ficar estável enquanto o código viver, o que a
próxima pessoa a acrescentar uma arrow inline não vai saber. A próxima seção é a alternativa.
