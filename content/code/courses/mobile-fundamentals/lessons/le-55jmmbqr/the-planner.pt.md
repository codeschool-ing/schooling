---
title: O planner de estudos, como um programa sem tela
version: 1
---

**Toda aula deste curso trabalha no mesmo app pequeno: um planner de estudos.** Um aluno lista os
cursos que está fazendo, abre um, acrescenta sessões de estudo com uma data e uma duração em
minutos, marca as que fez e vê quanto do plano da semana já cumpriu. É o mesmo app que a trilha
`frontend` constrói num navegador, e os cursos depois da bifurcação o constroem de novo para Android,
para iOS e em React Native, com as mesmas telas e os mesmos dados.

Aqui ele **não tem tela nenhuma**, e esse é o ponto. Os dados do planner, e as somas que toda tela
vai mostrar, são TypeScript puro que roda em qualquer lugar. As aulas seguintes envolvem esse núcleo
em tudo o que um celular faz com um app: um ciclo de vida que o mata (aula 4), uma pilha de volta
(aula 10), uma rede que cai (aula 14), um banco de dados no aparelho (aula 16). As telas são o que
muda de uma plataforma para outra, então ficam com os cursos depois da bifurcação.

## O projeto

Crie uma pasta para ele, e um `package.json` dizendo que os arquivos são módulos de JavaScript
moderno:

```
ana@dev:~$ mkdir planner
ana@dev:~$ cd planner
```

Salve isto como `package.json` em `~/planner`. O `"type": "module"` é o que deixa um arquivo fazer
`import` de outro; sem ele, o Node.js os leria como do tipo CommonJS, mais antigo, que a aula 9 do
`javascript` compara. Salve como `package.json`:

```json
{
  "name": "planner",
  "private": true,
  "type": "module"
}
```

## O núcleo

Os dados do planner são duas listas, cursos e sessões, e quatro funções trabalham sobre elas. Salve
como `planner.ts`:

```schooling-example
{"language": "typescript", "file": "planner.ts", "parts": [{"code": "// planner.ts: the study planner's data, and the sums every screen needs\nexport type Course = { id: string; title: string };\nexport type Session = {\n  id: string;\n  courseId: string;\n  date: string; // YYYY-MM-DD, the day it is planned for\n  minutes: number;\n  done: boolean;\n};\nexport type Plan = { courses: Course[]; sessions: Session[] };\n", "note": "Os dados. Uma sessão aponta para o curso pelo `id` dele, nunca pelo título, então renomear um curso não perde nada. Os tipos são o que o `node` remove antes de rodar o arquivo."}, {"code": "// The Monday of the week a date falls in, as YYYY-MM-DD.\nexport function mondayOf(date: string): string {\n  const d = new Date(date + \"T12:00:00Z\");\n  const back = (d.getUTCDay() + 6) % 7; // Monday 0 ... Sunday 6\n  d.setUTCDate(d.getUTCDate() - back);\n  return d.toISOString().slice(0, 10);\n}\n", "note": "Aqui a semana começa na segunda-feira. A data é lida ao meio-dia UTC, então nenhum fuso horário a empurra para o dia anterior; `getUTCDay` conta a partir do domingo, e o `+ 6` faz a segunda valer zero."}, {"code": "export function addSession(plan: Plan, s: Session): Plan {\n  if (!plan.courses.some((c) => c.id === s.courseId)) {\n    throw new Error(`no course ${s.courseId}`);\n  }\n  return { ...plan, sessions: [...plan.sessions, s] };\n}\n", "note": "Uma sessão de um curso que não existe é recusada, com erro, em vez de entrar e se perder depois. O plano devolvido é um objeto novo; o antigo fica intacto."}, {"code": "export function markDone(plan: Plan, id: string): Plan {\n  return {\n    ...plan,\n    sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)),\n  };\n}\n", "note": "Concluída é marcada e nunca desmarcada, do mesmo jeito que uma etapa terminada continua terminada."}, {"code": "// Minutes planned and minutes done in the week that contains `today`.\nexport function weekTotal(plan: Plan, today: string) {\n  const monday = mondayOf(today);\n  const week = plan.sessions.filter((s) => mondayOf(s.date) === monday);\n  const planned = week.reduce((sum, s) => sum + s.minutes, 0);\n  const done = week.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0);\n  return { monday, planned, done };\n}", "note": "A soma que toda tela mostra. `today` é um argumento, não o relógio, então o mesmo plano sempre dá a mesma resposta e um teste consegue fixá-la."}]}
```

**Nada aqui altera um plano no lugar**: `addSession` e `markDone` devolvem um novo. Isso custa uma
cópia de uma lista curta e compra algo em que toda aula seguinte se apoia. Um plano é um valor que
você pode salvar, comparar e restaurar inteiro, e a aula 5 faz exatamente isso quando o sistema leva
o app embora.

## Rodando

Um segundo arquivo monta um plano para a semana da segunda-feira, 19 de outubro de 2026, muda o plano
três vezes e imprime o total da semana. **Ele recebe o "hoje" em vez de ler o relógio**, então
imprime a mesma coisa sempre que você roda, e é isso que deixa a sua saída igual à de baixo. Salve
como `week.ts`:

```typescript
// week.ts: a plan, three changes to it, and the week's total
import { addSession, markDone, weekTotal, type Plan } from "./planner.ts";

let plan: Plan = {
  courses: [
    { id: "sql", title: "SQL Databases" },
    { id: "mobile", title: "Mobile Fundamentals" },
  ],
  sessions: [
    { id: "s1", courseId: "sql", date: "2026-10-19", minutes: 50, done: true },
    { id: "s2", courseId: "mobile", date: "2026-10-20", minutes: 40, done: true },
    { id: "s3", courseId: "sql", date: "2026-10-23", minutes: 60, done: false },
    { id: "s4", courseId: "mobile", date: "2026-10-27", minutes: 45, done: false },
  ],
};

plan = addSession(plan, { id: "s5", courseId: "mobile", date: "2026-10-22", minutes: 30, done: false });
plan = markDone(plan, "s5");
console.log(weekTotal(plan, "2026-10-21"));
```

Rode com o `node`, que apaga os tipos e roda o resto:

```
ana@dev:~/planner$ ls
package.json
planner.ts
week.ts
ana@dev:~/planner$ node week.ts
{ monday: '2026-10-19', planned: 180, done: 120 }
```

Confira os números contra os dados. Existem cinco sessões, e a `s4` é no dia 27 de outubro, a
segunda-feira seguinte, então fica de fora. As outras quatro somam 50 + 40 + 60 + 30 = **180 minutos
planejados**, e `s1`, `s2` e `s5` estão feitas, 50 + 40 + 30 = **120 minutos feitos**. Toda tela do
planner, em toda plataforma a que a trilha chega, mostra esses dois números para essa semana.

Por fim, transforme a pasta num repositório e guarde este estado, para que o que cada aula
acrescentar seja um commit que você pode rever depois:

```
ana@dev:~/planner$ git init -q
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -q -m "The planner core, as lesson 1 gives it"
ana@dev:~/planner$ git log --oneline
87ae50d The planner core, as lesson 1 gives it
```
