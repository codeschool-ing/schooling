---
title: React
version: 1
---

**O React descreve a página com uma função: o componente é chamado, devolve o que desenhar, e é
chamado de novo sempre que o estado dele muda.** Não há templates; a marcação é **JSX**, uma sintaxe
parecida com HTML dentro do JavaScript, que o build transforma em chamadas de função. Feito do mesmo
jeito:

```
ana@dev:~/vue/compare$ npm create vite@9.3.1 -- react --template react-ts --no-immediate

> npx
> cva react --template react-ts --no-immediate


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/vue/compare/react...
│
└  Done. Now run:

  cd react
  npm install
  npm run dev
```

```
ana@dev:~/vue/compare/react$ npm install

added 27 packages, and audited 28 packages in 3s

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/react$ npm install --save-exact react@19.3.1 react-dom@19.3.1

added 3 packages, and audited 31 packages in 858ms

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/react$ rm src/App.tsx src/App.css
```

O card:

```jsx
// src/WeekCard.tsx: one course's week, the React way.
import { useState } from 'react'

const start = [
  { id: 's3', date: '19 October', minutes: 30, done: true },
  { id: 's6', date: '23 October', minutes: 40, done: false },
]

export function WeekCard() {
  console.log('React: WeekCard runs')
  const [sessions, setSessions] = useState(start)
  // Worked out again on every render: the whole function runs each time.
  const planned = sessions.reduce((sum, s) => sum + s.minutes, 0)
  const done = sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0)

  function toggle(id: string) {
    setSessions(sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }

  return (
    <section>
      <h2>Spanish</h2>
      <ul>
        {sessions.map((s) => (
          <li key={s.id}>
            <label>
              <input type="checkbox" checked={s.done} onChange={() => toggle(s.id)} /> {s.date},{' '}
              {s.minutes} minutes
            </label>
          </li>
        ))}
      </ul>
      <p>
        {done} of {planned} minutes done
      </p>
    </section>
  )
}
```

e a entrada dele, que o renderiza no `#root` do template:

```jsx
// src/main.tsx: the card, and nothing else, in the page's #root.
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { WeekCard } from './WeekCard.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <WeekCard />
  </StrictMode>,
)
```

As diferenças em relação ao card do Vue, linha por linha:

- **`useState(start)`** dá o valor atual e uma função para substituí-lo. Não há objeto reativo para
  mudar: `toggle` monta uma lista nova com `map` e a entrega a `setSessions`, do jeito que o
  `toggleDone` da aula 3 fazia, e o React desenha de novo porque recebeu um valor novo.
- **Os totais são `const`s simples**, calculados de novo a cada vez que a função roda; nada os guarda
  em cache a não ser que você peça com `useMemo`, e para uma soma de dois números ninguém deveria pedir.
- **A caixa de seleção é controlada**: `checked={s.done}` desenha o estado e `onChange` pede a
  mudança. Não há `v-model`; os dois sentidos são sempre escritos por extenso.
- **`{sessions.map(...)}`** é o `v-for`, JavaScript puro, com a mesma `key` pelo mesmo motivo.

`npm run dev`, e a mesma marcação:

```
ana@dev:~/vue/compare/react$ look http://localhost:5173/ --do 'check text=23 October' --text body
[vite] connecting...
%cDownload the React DevTools for a better development experience: https://react.dev/link/react-devtools font-weight:bold
React: WeekCard runs
React: WeekCard runs
[vite] connected.
-- check text=23 October
React: WeekCard runs
React: WeekCard runs
== the text of body
Spanish
 19 October, 30 minutes
 23 October, 40 minutes

70 of 70 minutes done
```

**O mesmo card, e a função rodou duas vezes antes da marcação e duas depois.** Rodar de novo a cada
mudança é o modelo do React, e a seção da comparação volta a isso. Rodar *duas vezes* é o
`<StrictMode>`, só em desenvolvimento: o React chama o componente uma segunda vez de propósito, para
revelar código que não é seguro rodar mais de uma vez. A linha com `%c` é o convite do React para
instalar suas ferramentas de desenvolvedor, estilizado para um console que o `look` imprime como texto
simples.
