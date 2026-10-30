---
title: O useMemo guarda um cálculo entre renderizações
version: 1
---

**O `useMemo(fn, deps)` chama `fn` na primeira renderização, guarda o que ela devolveu, e devolve
esse mesmo valor nas renderizações seguintes até algo em `deps` mudar.** Dois motivos para usá-lo, e
o segundo é o que importa com mais frequência: um cálculo lento o bastante para se notar, e um valor
de cuja identidade outro código depende.

O planejador calcula `thisWeek` em toda renderização com `sessions.filter(…)`, e o `filter` sempre
devolve um array novo, mesmo quando o conteúdo é o mesmo. Para ver o que isso faz, duas mudanças
temporárias: um botão no `App` que só faz o `App` renderizar de novo, e um efeito no `WeekSummary`
que registra sempre que a prop `sessions` é um array diferente:

```
ana@dev:~/planner$ cp src/App.tsx /tmp/App.tsx; cp src/WeekSummary.tsx /tmp/WeekSummary.tsx
ana@dev:~/planner$ sed -i 's|^  const \[openId, setOpenId\] = useState<string \| null>(null)$|&\n  const [, setTick] = useState(0)|; s|^      <WeekNav .*|&\n      <button type="button" onClick={() => setTick((t) => t + 1)}>Render App again</button>|' src/App.tsx
ana@dev:~/planner$ sed -i 's|^  const done = sessions.filter((s) => s.done)$|  useEffect(() => console.log('"'"'WeekSummary received a new sessions array'"'"'), [sessions])\n&|; 1i import { useEffect } from "react"' src/WeekSummary.tsx
ana@dev:~/planner$ grep -n "setTick\|useEffect" src/App.tsx src/WeekSummary.tsx | grep -v "^src/App.tsx:[0-9]*:  useEffect(() => {$"
src/App.tsx:1:import { useEffect, useState } from 'react'
src/App.tsx:17:  const [, setTick] = useState(0)
src/App.tsx:82:      <button type="button" onClick={() => setTick((t) => t + 1)}>Render App again</button>
src/WeekSummary.tsx:1:import { useEffect } from "react"
src/WeekSummary.tsx:11:  useEffect(() => console.log('WeekSummary received a new sessions array'), [sessions])
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Render App again' --do 'click button Render App again'
WeekSummary received a new sessions array
WeekSummary received a new sessions array
-- click button Render App again
WeekSummary received a new sessions array
-- click button Render App again
WeekSummary received a new sessions array
```

As duas linhas na carga são o efeito dobrado do strict mode, como na aula 5. **Depois, cada clique em
"Render App again" registra de novo**: nada na semana mudou, mas o `App` renderizou, o `filter` fez
um array novo, e para o `Object.is` um array novo é um valor diferente. Para este efeito isso é um
registro desperdiçado; para um efeito que busca dados, ou se inscreve em algo, ou para o `memo` da
aula 21, é trabalho de verdade feito à toa.

## A primeira tentativa

Envolver o cálculo em `useMemo` é uma mudança só, e feita onde o cálculo já está, ela falha:

```
ana@dev:~/planner$ sed -i 's|^  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))$|  const thisWeek = useMemo(\n    () => sessions.filter((s) => inWeek(s.date, monday)),\n    [sessions, monday],\n  )|; s|^import { useEffect, useState } from .react.$|import { useEffect, useMemo, useState } from '"'"'react'"'"'|' src/App.tsx
ana@dev:~/planner$ grep -n -A 3 "const thisWeek" src/App.tsx
77:  const thisWeek = useMemo(
78-    () => sessions.filter((s) => inWeek(s.date, monday)),
79-    [sessions, monday],
80-  )
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Render App again' 2>&1 | grep -E '^Uncaught|^\[error\] React'
[error] React has detected a change in the order of Hooks called by %s. This will lead to bugs and errors if not fixed. For more information, read the Rules of Hooks: https://react.dev/link/rules-of-hooks
Uncaught Error: Rendered more hooks than during the previous render.
```

**A quebra da aula 6, exatamente.** O `thisWeek` era calculado abaixo dos dois returns antecipados,
então o hook novo só é chamado depois que os dados chegam: nove hooks carregando, dez pronto. O
`useMemo` é um hook como qualquer outro, e transformar um cálculo comum num hook é justamente o
momento em que ele precisa subir para cima de todo `return`.

## Acima dos returns

```
ana@dev:~/planner$ grep -n -B 1 -A 5 "const thisWeek" src/App.tsx
59-
60:  const thisWeek = useMemo(
61-    () => sessions.filter((s) => inWeek(s.date, monday)),
62-    [sessions, monday],
63-  )
64-
65-  if (status === 'loading') return <p>Loading the planner…</p>
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Render App again' --do 'click button Render App again'
WeekSummary received a new sessions array
WeekSummary received a new sessions array
-- click button Render App again
-- click button Render App again
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Render App again' --do 'click button Next week'
WeekSummary received a new sessions array
WeekSummary received a new sessions array
-- click button Render App again
-- click button Next week
WeekSummary received a new sessions array
ana@dev:~/planner$ cp /tmp/App.tsx src/App.tsx; cp /tmp/WeekSummary.tsx src/WeekSummary.tsx
```

Agora apertar "Render App again" não registra nada: `sessions` e `monday` eram os mesmos, então o
`useMemo` devolveu o array que já tinha, e o efeito viu o mesmo valor. "Next week" mudou `monday`, o
`useMemo` rodou o filtro de novo, e o efeito registrou uma vez. **Esse é o contrato: as mesmas
entradas dão o mesmo objeto.**

As duas mudanças temporárias saíram com o `cp` do fim, e o `useMemo` também. O filtro do planejador
sobre seis sessões não é lento, e nada nele depende ainda da identidade do array; a aula 21 traz o
`useMemo` de volta onde o `memo` faz a identidade importar, e mede se ajuda. **Não envolva cálculos
em `useMemo` por reflexo.** Ele custa um hook, um array de dependências que precisa ficar certo e
uma regra dos hooks a respeitar, como a primeira tentativa mostrou, e não compra nada para um cálculo
que já era barato.
