---
title: React
version: 1
---

**O React é uma biblioteca para desenhar interfaces, e os componentes dele são funções que devolvem
o que desenhar.** Ele não tem ferramenta de linha de comando própria; um projeto costuma ser feito com
o Vite, a ferramenta de build cujo dev server também é o que está por baixo do `ng serve`, e é por isso
que as páginas deste curso imprimiam `[vite] connecting...`. O gerador de projetos dele, o
`create-vite`, roda numa versão fixa:

```
ana@dev:~/compare$ npm create vite@9.3.1 -- react --template react-ts --no-immediate

> npx
> cva react --template react-ts --no-immediate


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/compare/react...
│
└  Done. Now run:

  cd react
  npm install
  npm run dev
```

O `--no-immediate` impede que ele instale e inicie sozinho. Instale, fixe cada pacote na versão que
foi instalada, como os do planner, e remova o exemplo do template:

```
ana@dev:~/compare/react$ npm install

added 27 packages, and audited 28 packages in 3s

found 0 vulnerabilities
```

```
ana@dev:~/compare/react$ npm install --save-exact react@19.3.1 react-dom@19.3.1 @types/node@22.20.5 @types/react@19.3.0 @types/react-dom@19.3.0 @vitejs/plugin-react@6.1.2 oxlint@1.90.0 typescript@6.0.3 vite@8.3.5

added 3 packages, changed 2 packages, and audited 31 packages in 3s

found 0 vulnerabilities
```

```
ana@dev:~/compare/react$ rm src/App.tsx src/App.css src/index.css
```

O template escreveu circunflexos, `^19.3.0` e afins; instalar cada pacote de novo com
`--save-exact` escreve a própria versão, e o `@types/node` vai para o Node.js em que esta trilha roda.

O cartão:

```schooling-example
{"language": "typescript", "file": "src/WeekCard.tsx", "parts": [
 {"code": "// src/WeekCard.tsx: one course's week, the React way\nimport { useState } from 'react';\n\nconst start = [\n  { id: 3, date: 'Tue 20 Oct', minutes: 60, done: true },\n  { id: 5, date: 'Sat 24 Oct', minutes: 50, done: false },\n];\n", "note": "Um componente React é uma função, e o arquivo é TSX: TypeScript com tags parecidas com HTML dentro."},
 {"code": "export function WeekCard() {\n  console.log('React: WeekCard runs');\n  const [sessions, setSessions] = useState(start);\n  const planned = sessions.reduce((sum, s) => sum + s.minutes, 0);\n  const done = sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0);\n", "note": "A função roda de novo toda vez que o estado muda: é assim que o React descobre o que desenhar. O `useState` devolve o valor atual e uma função para trocá-lo, e o React guarda o valor entre uma execução e outra. Os totais são `const` simples, calculados do zero a cada execução."},
 {"code": "  function toggle(id: number) {\n    setSessions(sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s)));\n  }\n", "note": "A marcação monta uma lista nova e a entrega ao `setSessions`, como o store do planner troca o estado em vez de mudá-lo."},
 {"code": "  return (\n    <section>\n      <h2>JavaScript</h2>\n      <ul>\n        {sessions.map((s) => (\n          <li key={s.id}>\n            <label>\n              <input type=\"checkbox\" checked={s.done} onChange={() => toggle(s.id)} /> {s.date}, {s.minutes} minutes\n            </label>\n          </li>\n        ))}\n      </ul>\n      <p>\n        {done} of {planned} minutes done\n      </p>\n    </section>\n  );\n}", "note": "O que desenhar é o valor de retorno da função. `{ }` guarda uma expressão; o `map` sobre a lista é o `@for` do React, com `key` no papel de `track`."}
]}
```

```typescript
// src/main.tsx: the card, and nothing else, in the page's #root
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { WeekCard } from './WeekCard';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <WeekCard />
  </StrictMode>,
);
```

Inicie com `npm run dev`, que serve na porta 5173, e marque a mesma sessão:

```
ana@dev:~/compare/react$ look http://localhost:5173/ --do 'check Sat 24 Oct, 50 minutes' --text body
[vite] connecting...
[vite] connected.
%cDownload the React DevTools for a better development experience: https://react.dev/link/react-devtools font-weight:bold
React: WeekCard runs
React: WeekCard runs
-- check Sat 24 Oct, 50 minutes
React: WeekCard runs
React: WeekCard runs
JavaScript
 Tue 20 Oct, 60 minutes
 Sat 24 Oct, 50 minutes

110 of 110 minutes done
```

A primeira linha é o React sugerindo a extensão de navegador dele, impressa com um estilo que o
terminal não desenha. Depois o mesmo 110 de 110, e **a função rodou quatro vezes**: duas no primeiro
desenho, e mais duas na marcação. Uma vez por desenho é como o React funciona; a segunda de cada par é
o `StrictMode`, que em desenvolvimento roda cada componente duas vezes de propósito, para código com um
efeito colateral que não deveria ter, uma requisição ou um contador, aparecer fazendo duas vezes. Um
build de produção roda uma vez por desenho. Pare o dev server.
