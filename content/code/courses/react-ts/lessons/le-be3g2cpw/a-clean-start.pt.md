---
title: Um começo limpo, e os dados que a tela vai desenhar
version: 1
---

**A página do modelo sai, e a primeira tela do planejador entra no lugar.** Esta seção tira o modelo
do caminho e escreve os três arquivos que não têm nada a ver com o React: a forma dos dados, os
próprios dados e a aritmética das semanas. As quatro seções seguintes escrevem os componentes que os
desenham, uma ideia de cada vez, e a tela aparece no fim da quarta.

## Tirando o modelo

A folha de estilo do modelo, as imagens e o sprite de ícones em `public/` pertencem à página que
você está substituindo:

```
ana@dev:~/planner$ rm -r src/App.css src/assets public/icons.svg
ana@dev:~/planner$ ls src public
public:
courses.json
favicon.svg

src:
App.tsx
index.css
main.tsx
```

O `main.tsx` fica exatamente como estava, e o `index.html` também. O planejador mantém o nome do
`index.css` do modelo e troca o conteúdo por uma folha de estilo própria, curta o bastante para ser
lida inteira e sem nada de que este curso dependa:

```css
:root {
  font-family: system-ui, sans-serif;
  line-height: 1.5;
  color-scheme: light dark;
}

body {
  margin: 0;
}

main {
  max-width: 36rem;
  margin: 0 auto;
  padding: 1.5rem 1rem;
}

.card {
  border: 1px solid #8888;
  border-radius: 6px;
  padding: 0.5rem 1rem;
  margin: 0.5rem 0;
}

.card h2 {
  font-size: 1.1rem;
  margin: 0;
}

.card p {
  margin: 0.25rem 0 0;
}
```

## A forma dos dados

O `src/types.ts` diz em TypeScript o que o `courses.json` da aula 1 diz em JSON:

```typescript
export type Course = {
  id: string
  name: string
}

export type Session = {
  id: string
  course: string
  date: string
  minutes: number
  done: boolean
}
```

O `export type` dá a uma forma um nome que outros arquivos importam. **Um tipo só existe enquanto
você escreve o código**: ele diz ao editor e ao compilador o que uma `Session` guarda, e nada dele
chega ao navegador. A aula 19 diz mais; por ora, uma `Session` tem cinco campos, e todo componente
que recebe uma conhece os nomes e os tipos deles.

## Os dados, por enquanto

O planejador vai buscar o `public/courses.json` no servidor, e isso é a aula 5, porque buscar é um
efeito e efeitos têm uma aula só deles. Até lá, os mesmos dados moram num módulo:

```typescript
import type { Course, Session } from './types'

// The same data as public/courses.json, until lesson 5 fetches that file.
export const courses: Course[] = [
  { id: 'statistics', name: 'Statistics' },
  { id: 'spanish', name: 'Spanish' },
  { id: 'chemistry', name: 'Organic chemistry' },
]

export const sessions: Session[] = [
  { id: 's1', course: 'statistics', date: '2026-10-19', minutes: 50, done: true },
  { id: 's2', course: 'statistics', date: '2026-10-21', minutes: 40, done: false },
  { id: 's3', course: 'spanish', date: '2026-10-20', minutes: 30, done: true },
  { id: 's4', course: 'spanish', date: '2026-10-23', minutes: 30, done: false },
  { id: 's5', course: 'chemistry', date: '2026-10-14', minutes: 60, done: true },
  { id: 's6', course: 'chemistry', date: '2026-10-22', minutes: 45, done: false },
]
```

A linha `import type` traz só os tipos, então o compilador pode removê-la por completo. Os dois
arrays são tipados com eles, o que quer dizer que uma sessão com `minutes: '50'` entre aspas seria
recusada antes de o app rodar.

## Semanas, sem React

Cada número da primeira tela depende de quais sessões caem numa semana. Isso é aritmética simples
com datas, e mora num arquivo que não importa nada do React:

```schooling-example
{"language": "typescript", "file": "src/week.ts", "parts": [{"code": "import type { Session } from './types'\n", "note": "O tipo de uma sessão, importado só pela forma."}, {"code": "// A day is a 'YYYY-MM-DD' string, and a week starts on Monday. The arithmetic\n// is done at noon UTC, so that no time zone can move a date to its neighbour.\nconst noon = (day: string) => new Date(`${day}T12:00:00Z`)\n", "note": "Os dias viajam como strings `'YYYY-MM-DD'`, como no JSON. Transformar um deles num `Date` ao meio-dia UTC faz com que nenhum fuso horário, por mais a leste ou a oeste, o empurre pela meia-noite para o dia anterior ou o seguinte."}, {"code": "export function addDays(day: string, n: number): string {\n  const d = noon(day)\n  d.setUTCDate(d.getUTCDate() + n)\n  return d.toISOString().slice(0, 10)\n}\n", "note": "Somar dias no calendário UTC e cortar o resultado nos dez primeiros caracteres dá outra string de dia."}, {"code": "export function mondayOf(day: string): string {\n  const back = (noon(day).getUTCDay() + 6) % 7\n  return addDays(day, -back)\n}\n", "note": "O `getUTCDay()` conta o domingo como 0. Somar 6 e tirar o resto por 7 conta a segunda como 0, que é quantos dias voltar."}, {"code": "export function inWeek(day: string, monday: string): boolean {\n  return day >= monday && day <= addDays(monday, 6)\n}\n", "note": "Como o formato fica em ordem quando ordenado como texto, uma semana são duas comparações de string: na segunda ou depois, no domingo ou antes."}, {"code": "export function minutes(sessions: Session[]): number {\n  return sessions.reduce((sum, s) => sum + s.minutes, 0)\n}\n", "note": "Um total é a soma dos `minutes` das sessões que ele recebe, todas ou só as feitas."}, {"code": "export function formatDay(day: string): string {\n  return noon(day).toLocaleDateString('en-GB', {\n    weekday: 'short', day: 'numeric', month: 'short', timeZone: 'UTC',\n  })\n}\n\nexport function formatWeek(monday: string): string {\n  return noon(monday).toLocaleDateString('en-GB', {\n    day: 'numeric', month: 'short', year: 'numeric', timeZone: 'UTC',\n  })\n}", "note": "Os dois jeitos de um dia aparecer na tela. O `en-GB` põe o dia antes do mês, e `timeZone: 'UTC'` lê a data de volta do jeito como ela foi feita."}]}
```

Pergunte ao Node, que roda um arquivo TypeScript diretamente desde que só precise remover os tipos:

```
ana@dev:~/planner$ node -e "import('./src/week.ts').then((w) => console.log(w.mondayOf('2026-10-21'), w.inWeek('2026-10-14', '2026-10-19'), w.formatDay('2026-10-19'), w.formatWeek('2026-10-19')))"
2026-10-19 false Mon 19 Oct 19 Oct 2026
```

Quarta-feira, 21 de outubro, pertence à semana de segunda, dia 19; o dia 14 não pertence; e os dois
formatos são os que as telas da aula 1 mostram. **Deixar isto fora dos componentes é uma decisão, não
uma conveniência**: uma função que recebe strings e devolve strings pode ser conferida numa linha de
Node, como aqui, e a aula 22 a testa sem navegador.
