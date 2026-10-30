---
title: O estado pertence a uma posição na árvore
version: 1
---

**O React mantém o estado de um componente enquanto o mesmo componente estiver na mesma posição da
árvore.** Ele não prende o estado a uma variável, nem aos dados que um componente desenha; prende a
um lugar. Para ver isso, os cartões precisam de algum estado próprio. Um último componente
temporário, `src/Probe.tsx`, é um botão que conta quantas vezes foi apertado:

```tsx
import { useState } from 'react'

// For lesson 3 only: a button that remembers how often it was pressed.
export function Probe({ name }: { name: string }) {
  const [count, setCount] = useState(0)
  return (
    <button type="button" onClick={() => setCount(count + 1)}>
      {name} pressed {count}
    </button>
  )
}
```

A instrumentação das duas últimas seções sai, e o `Card` desenha um `Probe` abaixo dos children:

```
ana@dev:~/planner$ sed -i '/rendered/d; /watch/d' src/*.tsx src/main.tsx
ana@dev:~/planner$ sed -i 's|^      {children}$|      {children}\n      <Probe name={title} />|; 1i import { Probe } from "./Probe"' src/Card.tsx
ana@dev:~/planner$ cat src/Card.tsx
import { Probe } from "./Probe"
import type { ReactNode } from 'react'

type CardProps = {
  title: string
  children: ReactNode
}

export function Card({ title, children }: CardProps) {
  return (
    <article className="card">
      <h2>{title}</h2>
      {children}
      <Probe name={title} />
    </article>
  )
}
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics pressed 0' --do 'click button Statistics pressed 1' --do 'click button Next week' 2>&1 | tail -n 12
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Statistics pressed 2"
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Spanish pressed 0"
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Organic chemistry pressed 0"
```

O `look` apertou o probe de Statistics duas vezes e depois "Next week", e o fim do retrato é a lista
de cursos depois disso. **A semana nova tem números diferentes, e o probe de Statistics ainda diz
2.** O clique renderizou todos os cartões de novo, com props novas, e o React manteve a contagem de
cada `Probe`, porque depois da renderização o `Probe` do primeiro cartão ainda era um `Probe`, ainda
dentro do primeiro `Card`, ainda dentro do primeiro `CourseCard`. Mesmo tipo, mesma posição: mesmo
componente, mesmo estado.

## Mudando a posição de propósito

A `key` diz ao React qual item é qual numa lista, e a aula 2 deu a cada `CourseCard` o id do curso.
Ela funciona em qualquer elemento, e faz mais do que distinguir irmãos: **uma key diferente é um
componente diferente**, então o React descarta o antigo, estado e nós do DOM juntos, e começa um
novo. Dê ao `CourseList` a segunda-feira da semana como key:

```
ana@dev:~/planner$ sed -i 's|<CourseList courses|<CourseList key={monday} courses|' src/App.tsx
ana@dev:~/planner$ grep -n "<CourseList" src/App.tsx
16:      <CourseList key={monday} courses={courses} sessions={thisWeek} />
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics pressed 0' --do 'click button Statistics pressed 1' --do 'click button Next week' 2>&1 | tail -n 12
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Statistics pressed 0"
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Spanish pressed 0"
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 0 sessions · 0 min
      - button "Organic chemistry pressed 0"
```

Os mesmos cliques, o mesmo clique final, e todo probe voltou a `0`. A key mudou de `2026-10-19` para
`2026-10-26`, então o React tratou a lista de cursos da semana nova como uma lista que nunca tinha
visto, e todo componente abaixo dela foi criado de novo do nada.

```schooling-figure
{"svg": "<svg data-fig=\"identity\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Dois casos lado a lado. À esquerda, depois de Next week o primeiro CourseCard ainda tem um Card que tem um Probe no mesmo lugar, então o React mantém a contagem 2. À direita, o CourseList tem a key 2026-10-19 antes e 2026-10-26 depois; uma key diferente é um componente diferente, então a subárvore inteira é criada de novo e a contagem é 0.\"><text x=\"180\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">mesma posição: mantido</text><text x=\"100\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">antes</text><rect x=\"30\" y=\"58\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseList</text><line x1=\"100\" y1=\"84\" x2=\"100\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"100.0,98.0 96.8,90.5 103.2,90.5\" fill=\"var(--wire)\"></polygon><rect x=\"30\" y=\"98\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseCard</text><line x1=\"100\" y1=\"124\" x2=\"100\" y2=\"138\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"100.0,138.0 96.8,130.5 103.2,130.5\" fill=\"var(--wire)\"></polygon><rect x=\"30\" y=\"138\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Card</text><line x1=\"100\" y1=\"164\" x2=\"100\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"100.0,178.0 96.8,170.5 103.2,170.5\" fill=\"var(--wire)\"></polygon><rect x=\"30\" y=\"178\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Probe · 2</text><text x=\"270\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois</text><rect x=\"200\" y=\"58\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseList</text><line x1=\"270\" y1=\"84\" x2=\"270\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"270.0,98.0 266.8,90.5 273.2,90.5\" fill=\"var(--wire)\"></polygon><rect x=\"200\" y=\"98\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseCard</text><line x1=\"270\" y1=\"124\" x2=\"270\" y2=\"138\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"270.0,138.0 266.8,130.5 273.2,130.5\" fill=\"var(--wire)\"></polygon><rect x=\"200\" y=\"138\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Card</text><line x1=\"270\" y1=\"164\" x2=\"270\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"270.0,178.0 266.8,170.5 273.2,170.5\" fill=\"var(--wire)\"></polygon><rect x=\"200\" y=\"178\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Probe · 2</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">key nova: recomeçou</text><text x=\"460\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">antes</text><rect x=\"390\" y=\"58\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">key=2026-10-19</text><line x1=\"460\" y1=\"84\" x2=\"460\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"460.0,98.0 456.8,90.5 463.2,90.5\" fill=\"var(--wire)\"></polygon><rect x=\"390\" y=\"98\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseCard</text><line x1=\"460\" y1=\"124\" x2=\"460\" y2=\"138\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"460.0,138.0 456.8,130.5 463.2,130.5\" fill=\"var(--wire)\"></polygon><rect x=\"390\" y=\"138\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Card</text><line x1=\"460\" y1=\"164\" x2=\"460\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"460.0,178.0 456.8,170.5 463.2,170.5\" fill=\"var(--wire)\"></polygon><rect x=\"390\" y=\"178\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Probe · 2</text><text x=\"630\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">depois</text><rect x=\"560\" y=\"58\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">key=2026-10-26</text><line x1=\"630\" y1=\"84\" x2=\"630\" y2=\"98\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"630.0,98.0 626.8,90.5 633.2,90.5\" fill=\"var(--wire)\"></polygon><rect x=\"560\" y=\"98\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">CourseCard</text><line x1=\"630\" y1=\"124\" x2=\"630\" y2=\"138\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"630.0,138.0 626.8,130.5 633.2,130.5\" fill=\"var(--wire)\"></polygon><rect x=\"560\" y=\"138\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Card</text><line x1=\"630\" y1=\"164\" x2=\"630\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"630.0,178.0 626.8,170.5 633.2,170.5\" fill=\"var(--wire)\"></polygon><rect x=\"560\" y=\"178\" width=\"140\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">Probe · 0</text></svg>", "caption": "O mesmo tipo na mesma posição mantém o estado; uma key nova começa do zero."}
```

Isso é uma ferramenta, não um acidente. Um formulário que deve começar vazio quando o usuário passa
para outro registro é o uso clássico: dê a ele o id do registro como key, e trocar de registro o
reinicia sem uma linha de código para limpar cada campo. O erro oposto é assunto da aula 8: uma
lista cujas keys não acompanham os itens, de modo que o estado fica numa posição enquanto o item a
que ele pertencia se move.

## Arrumando tudo

Tudo o que era temporário sai, e o strict mode volta:

```
ana@dev:~/planner$ sed -i 's| key={monday}||' src/App.tsx
ana@dev:~/planner$ sed -i '/Probe/d' src/Card.tsx
ana@dev:~/planner$ rm src/Probe.tsx src/rendered.ts src/watch.ts
ana@dev:~/planner$ sed -i 's/^import { createRoot }/import { StrictMode } from '"'"'react'"'"'\n&/; s/^  <>$/  <StrictMode>/; s/^  <\/>,$/  <\/StrictMode>,/' src/main.tsx
ana@dev:~/planner$ cat src/main.tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 1 session · 45 min
```

O planejador depois desta aula é o da aula 2 mais o `today`, o `WeekNav` e um pedaço de estado.
