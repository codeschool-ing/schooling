---
title: O planner de estudos
version: 1
---

**O planner guarda uma lista de cursos e as sessões de estudo que você planeja para cada um, e soma a
sua semana.** Você abre um curso, adiciona uma sessão com uma data e um número de minutos, marca como
feita quando estudou, e vê o total da semana. É tudo o que ele faz, e é o bastante para precisar de
cada tipo de teste que este curso ensina. Conforme cresce, ele também precisa das defesas das aulas 5
a 9, e dos reparos das aulas 10 a 13 para as pessoas que esta primeira versão deixa de fora.

## Um projeto a partir de um template

O Vite é a ferramenta que serve o app enquanto você o escreve e o empacota para publicação. O pacote
`create-vite` dele cria um projeto novo a partir de um template, e o `vanilla-ts` é o que tem
TypeScript e nenhum framework:

```
ana@dev:~$ npm create vite@9.3.1 planner -- --template vanilla-ts --no-interactive

> npx
> cva planner --template vanilla-ts --no-interactive


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/planner...
│
└  Done. Now run:

  cd planner
  npm install
  npm run dev
```

O `npm create vite@9.3.1` baixa o `create-vite` nessa versão e o executa; tudo o que vem depois do
`--` vai para ele e não para o npm, e o `--no-interactive` impede que ele faça perguntas cujas
respostas já tem. Ele escreveu um app pequeno de demonstração, um contador, que não é o app deste
curso:

```
ana@dev:~$ cd planner
ana@dev:~/planner$ ls -A . src public
.:
.gitignore
index.html
package.json
public
src
tsconfig.json

public:
favicon.svg
icons.svg

src:
assets
counter.ts
main.ts
style.css
```

Os arquivos do contador saem, e as duas imagens que ele usava também:

```
ana@dev:~/planner$ rm -r src/counter.ts src/assets public/favicon.svg public/icons.svg
```

## Os dados

O planner lê os cursos e as sessões de um arquivo só, que o Vite serve do jeito que está. Tudo o que
fica em `public/` é servido na raiz do site, então este arquivo vai estar em `/courses.json`. Salve
isto como `public/courses.json`:

```json
{
  "courses": [
    { "id": "html-css", "title": "HTML and CSS" },
    { "id": "javascript", "title": "JavaScript" },
    { "id": "git", "title": "Git" }
  ],
  "sessions": [
    { "id": 1, "course": "git", "date": "2026-10-14", "minutes": 20, "done": true },
    { "id": 2, "course": "html-css", "date": "2026-10-19", "minutes": 45, "done": true },
    { "id": 3, "course": "javascript", "date": "2026-10-20", "minutes": 60, "done": true },
    { "id": 4, "course": "javascript", "date": "2026-10-22", "minutes": 30, "done": false },
    { "id": 5, "course": "git", "date": "2026-10-25", "minutes": 25, "done": false },
    { "id": 6, "course": "html-css", "date": "2026-10-26", "minutes": 40, "done": false }
  ]
}
```

Três cursos e seis sessões em outubro de 2026. Quatro das sessões caem na semana de segunda 19 a
domingo 25 de outubro, uma na semana anterior e uma na seguinte, então um total daquela semana tem
algo a deixar de fora em cada ponta.

## As regras, separadas da página

O `src/planner.ts` guarda o que o planner sabe sobre sessões e semanas, e nada sobre a página. Cada
função dele recebe valores e devolve um valor, e é isso que vai fazer dele o arquivo mais fácil de
testar do projeto. Salve-o como `src/planner.ts`:

```schooling-example
{"language": "typescript", "file": "src/planner.ts", "parts": [{"code": "// src/planner.ts\nexport interface Course {\n  id: string;\n  title: string;\n}\n\nexport interface Session {\n  id: number;\n  course: string;\n  date: string;\n  minutes: number;\n  done: boolean;\n}\n\nexport interface Plan {\n  courses: Course[];\n  sessions: Session[];\n}\n", "note": "Três formatos, e eles são todos os dados. Uma sessão aponta para o curso pelo `id` dele, e a data é um texto como `2026-10-21`, do jeito que o `courses.json` escreve."}, {"code": "export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {\n  if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);\n  if (!/^\\d{4}-\\d{2}-\\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);\n  if (!Number.isInteger(minutes) || minutes < 1 || minutes > 600) {\n    throw new Error(`minutes must be a whole number from 1 to 600, not ${minutes}`);\n  }\n  const id = Math.max(0, ...plan.sessions.map((s) => s.id)) + 1;\n  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };\n}\n", "note": "Adicionar uma sessão recusa o que não dá para guardar, e diz qual valor recusou. A função nunca altera o plano que recebeu: devolve um novo, com a sessão no fim."}, {"code": "export function markDone(plan: Plan, id: number): Plan {\n  return { ...plan, sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)) };\n}\n", "note": "O mesmo hábito: um plano novo, em que uma sessão está feita."}, {"code": "export function today(now: Date = new Date()): string {\n  const m = String(now.getMonth() + 1).padStart(2, \"0\");\n  const d = String(now.getDate()).padStart(2, \"0\");\n  return `${now.getFullYear()}-${m}-${d}`;\n}\n", "note": "A data de hoje no calendário do próprio estudante, no mesmo formato da data de uma sessão. O `getMonth()` conta a partir de 0, daí o `+ 1`."}, {"code": "export function weekOf(day: string): [string, string] {\n  const d = new Date(day);\n  const monday = new Date(d);\n  monday.setDate(d.getDate() - ((d.getDay() + 6) % 7));\n  const sunday = new Date(monday);\n  sunday.setDate(monday.getDate() + 6);\n  return [monday.toISOString().slice(0, 10), sunday.toISOString().slice(0, 10)];\n}\n", "note": "A semana a que um dia pertence, de segunda a domingo. O `getDay()` dá 0 para domingo e 1 para segunda, então `(getDay() + 6) % 7` é quantos dias atrás foi a segunda."}, {"code": "export function weekTotal(plan: Plan, day: string, course?: string): number {\n  const [from, to] = weekOf(day);\n  return plan.sessions\n    .filter((s) => s.date >= from && s.date <= to)\n    .filter((s) => course === undefined || s.course === course)\n    .reduce((sum, s) => sum + s.minutes, 0);\n}", "note": "Os minutos planejados naquela semana, de todos os cursos ou de um só. Datas escritas como `YYYY-MM-DD` ficam, em ordem de texto, na mesma ordem do calendário, e é por isso que `>=` e `<=` funcionam com elas."}]}
```

## Versões exatas

O template pediu o `vite` em `^8.3.4` e o `typescript` em `~6.0.3`: um circunflexo deixa o npm pegar
qualquer 8 mais novo, um til qualquer 6.0 mais novo. Isso é cômodo, e quer dizer que duas pessoas
instalando em dias diferentes podem receber códigos diferentes. **Este curso fixa cada pacote numa
versão só**, para que o que você instala seja o que as aulas gravaram. O `--save-exact` escreve o
número sem o símbolo:

```
ana@dev:~/planner$ npm install --save-exact vite@8.3.5 typescript@6.0.3

added 16 packages, and audited 17 packages in 9s

found 0 vulnerabilities
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  },
  "devDependencies": {
    "typescript": "6.0.3",
    "vite": "8.3.5"
  }
}
```

O `npm install` também escreveu o `package-lock.json`, que fixa cada pacote que esses dois trouxeram
junto, até o último. Guarde os dois arquivos no Git. A próxima seção escreve a página.
