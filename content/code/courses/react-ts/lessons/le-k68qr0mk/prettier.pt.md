---
title: Prettier, que encerra as discussões
version: 1
---

**Um formatador reescreve o código num layout só, para que ninguém precise escolher um.** Lint é sobre
erros; formatação é sobre onde as linhas quebram, o que não é erro nenhum mas gera mais comentários de
revisão do que qualquer outra coisa. O **Prettier** tira a decisão da mesa: lê o código, joga o layout
fora e o imprime de novo pelas regras dele.

```
ana@dev:~/planner$ npm install --save-dev prettier@3.9.10

added 1 package, and audited 294 packages in 768ms

66 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npx prettier --check . 2>&1 | tail -n 3
[warn] src/WeekSummary.tsx
[warn] vite.config.ts
[warn] Code style issues found in 38 files. Run Prettier with --write to fix.
```

**38 arquivos**, quase todo arquivo do projeto. Os padrões do Prettier são ponto e vírgula, aspas duplas e
linhas de 80 caracteres, e o planejador foi escrito sem ponto e vírgula, com aspas simples e linhas de até
100. O Prettier tem pouquíssimas opções, de propósito, e essas três estão entre elas, no
`.prettierrc.json`:

```json
{
  "semi": false,
  "singleQuote": true,
  "printWidth": 100
}
```

```
ana@dev:~/planner$ npx prettier --check .
Checking formatting...
[warn] server/api.mjs
[warn] src/main.tsx
[warn] src/week.ts
[warn] tsconfig.json
[warn] Code style issues found in 4 files. Run Prettier with --write to fix.
ana@dev:~/planner$ git add -A && git commit -q -m "Add ESLint and Prettier" && npx prettier --write . > /dev/null && git diff --stat
 server/api.mjs |  7 +++++--
 src/main.tsx   |  4 +++-
 src/week.ts    | 10 ++++++++--
 tsconfig.json  |  5 +----
 4 files changed, 17 insertions(+), 9 deletions(-)
ana@dev:~/planner$ sed -n '26,42p' src/week.ts
export function formatDay(day: string): string {
  return noon(day).toLocaleDateString('en-GB', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    timeZone: 'UTC',
  })
}

export function formatWeek(monday: string): string {
  return noon(monday).toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    timeZone: 'UTC',
  })
}
```

**Sobram quatro arquivos**, e são os interessantes: os lugares em que o layout do código diferia do do
Prettier em algo que não é configuração. As ferramentas acrescentadas até aqui são commitadas antes, para
que o diff mostre só o que o Prettier fez. No `src/week.ts`, os dois objetos de opções da aula 3 estavam
escritos numa linha cada, dentro de uma chamada que já estava quebrada em linhas, e o Prettier pôs cada
propriedade numa linha própria, como o `sed` mostra. Os outros são parecidos. O `tsconfig.json` vai no
sentido contrário: dois objetos curtos que cabem numa linha são postos numa só.

Você não precisa concordar com cada mudança, e esse é o ponto. **O layout agora é um fato sobre a
ferramenta, não sobre quem mexeu no arquivo por último**, e uma revisão pode tratar do que o código faz.
Editores rodam o Prettier a cada save, então na prática o código está formatado antes de alguém vê-lo.
