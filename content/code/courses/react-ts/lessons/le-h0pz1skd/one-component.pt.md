---
title: Um componente, quatro vezes
version: 1
---

**A aula 1 situou o React entre as alternativas com palavras. Esta aula faz isso com código.** A trilha
oferece quatro opções para o mesmo trabalho, e o jeito mais justo de compará-las é escrever uma coisa
pequena em cada uma e ver o que ela faz. Não o planejador: um componente só, pequeno o bastante para ler
inteiro em cada versão, com as três coisas de que toda interface precisa. Ele guarda **estado**, **deriva**
um valor desse estado e **muda** quando alguém clica.

O componente é uma semana de três sessões de estudo. Cada uma é um botão que a marca como feita, e acima
delas uma frase soma os minutos. Ele também escreve `Sessions ran` no console a partir do próprio código, e
é assim que esta aula vai ver a maior diferença entre os quatro.

Cada versão mora num projeto próprio ao lado do `~/planner`, criado pela ferramenta do próprio framework e
fixado do jeito que a aula 1 fixou o planejador. Primeiro o React, com o comando que a aula 1 usou:

```
ana@dev:~$ npm create vite@9.3.1 sessions-react -- --template react-ts --no-interactive > /dev/null && cd sessions-react && npm config set save-exact true --location=project && npm install --silent react@19.3.1 react-dom@19.3.1 && npm install --silent --save-dev typescript@6.0.3 vite@8.3.5 @vitejs/plugin-react@6.1.2 @types/react@19.3.0 @types/react-dom@19.3.0 @types/node@22.20.5 oxlint@1.88.0 && ls src
App.css
App.tsx
assets
index.css
main.tsx
```

O `App.tsx` do template dá lugar ao componente. `src/Sessions.tsx`:

```tsx
import { useState } from 'react'

type Session = { id: string; course: string; minutes: number; done: boolean }

const week: Session[] = [
  { id: 's1', course: 'Statistics', minutes: 40, done: true },
  { id: 's2', course: 'Python', minutes: 35, done: false },
  { id: 's3', course: 'Statistics', minutes: 45, done: false },
]

export function Sessions() {
  const [sessions, setSessions] = useState(week)
  const done = sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0)
  const total = sessions.reduce((sum, s) => sum + s.minutes, 0)
  console.log('Sessions ran')

  function toggle(id: string) {
    setSessions(sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }

  return (
    <section>
      <h1>This week</h1>
      <p>
        {done} of {total} minutes done
      </p>
      <ul>
        {sessions.map((s) => (
          <li key={s.id}>
            <button aria-pressed={s.done} onClick={() => toggle(s.id)}>
              {s.course} · {s.minutes} min
            </button>
          </li>
        ))}
      </ul>
    </section>
  )
}
```

Nada aqui é novo. O `useState` guarda as sessões, e `done` e `total` são constantes comuns calculadas a
cada renderização, como a aula 4 recomendou para tudo que dá para calcular a partir do estado. O `toggle`
monta um array novo em vez de mudar o antigo, porque o React decide se renderiza de novo comparando o
estado antigo com o novo, e um objeto alterado continua sendo o mesmo objeto. O `src/App.tsx` só o
desenha:

```tsx
import { Sessions } from './Sessions'

export default function App() {
  return <Sessions />
}
```

Depois um build de produção, servido pelo `vite preview` como na aula 13, e dois cliques:

```
ana@dev:~/sessions-react$ rm src/App.css && npm run build

> sessions-react@0.0.0 build
> tsc -b && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 17 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                   0.46 kB │ gzip:  0.29 kB
dist/assets/index-DGNrK5qb.css    1.78 kB │ gzip:  0.81 kB
dist/assets/index-CyOvCvN4.js   220.20 kB │ gzip: 68.88 kB

✓ built in 388ms
ana@dev:~/sessions-react$ look http://localhost:4173/ --do 'click button Python · 35 min' --do 'click button Statistics · 45 min'
Sessions ran
-- click button Python · 35 min
Sessions ran
-- click button Statistics · 45 min
Sessions ran
- heading "This week" [level=1]
- paragraph: 120 of 120 minutes done
- list:
  - listitem:
    - button "Statistics · 40 min" [pressed]
  - listitem:
    - button "Python · 35 min" [pressed]
  - listitem:
    - button "Statistics · 45 min" [pressed]
```

**`Sessions ran` três vezes**: uma quando a página carregou, e uma depois de cada clique. Esse é o modelo
do React, o que este curso inteiro usou: uma mudança de estado chama o componente de novo, inteiro, e o
React compara o que ele devolveu com o que devolveu da última vez. O build é o `npm run build` e não o
servidor de desenvolvimento por um motivo: em desenvolvimento, o strict mode chamaria o componente duas
vezes a cada vez, como a aula 3 mostrou, e cada linha da contagem apareceria em dobro.

Guarde o número, e o tamanho daquele arquivo `.js`. As outras três versões são comparadas com os dois.
