---
title: Uma biblioteca de formulários, e uma instalação que recusa
version: 1
---

**O React Hook Form registra os inputs, junta os valores no envio e guarda os erros, sem renderizar
de novo a cada tecla.** É uma entre várias bibliotecas de formulário, e a que este curso usa; com ela
vêm o Zod, que descreve o que são dados válidos, e o `@hookform/resolvers`, que liga os dois.
Instalá-los é a primeira coisa desta aula que não sai como planejado:

```
ana@dev:~/planner$ npm view react-hook-form dist-tags.latest
8.0.0-beta.5
ana@dev:~/planner$ npm install react-hook-form@7.91.0 zod@4.6.7 @hookform/resolvers@6.0.0 2>&1 | head -n 14
npm error code ERESOLVE
npm error ERESOLVE unable to resolve dependency tree
npm error
npm error While resolving: planner@0.0.0
npm error Found: effect@3.22.4
npm error node_modules/effect
npm error   peerOptional effect@"^3.6.5" from @typeschema/effect@0.14.0
npm error   node_modules/@typeschema/effect
npm error     peerOptional @typeschema/effect@"0.14.0" from @typeschema/main@0.14.1
npm error     node_modules/@typeschema/main
npm error       peerOptional @typeschema/main@">=0.13.7" from @hookform/resolvers@6.0.0
npm error       node_modules/@hookform/resolvers
npm error         @hookform/resolvers@"6.0.0" from the root project
npm error   peer effect@"^3.6.8" from @effect/schema@0.71.4
ana@dev:~/planner$ npm view @hookform/resolvers@6.0.0 peerDependenciesMeta.effect
{ optional: true }
ana@dev:~/planner$ npm install react-hook-form@7.91.0 zod@4.6.7 @hookform/resolvers@5.9.2

added 5 packages, and audited 35 packages in 2s

12 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm ls react-hook-form zod @hookform/resolvers
planner@0.0.0 /home/ana/planner
├─┬ @hookform/resolvers@5.9.2
│ ├── react-hook-form@7.91.0 deduped
│ └── zod@4.6.7 deduped
├── react-hook-form@7.91.0
└── zod@4.6.7
```

**A tag `latest` do React Hook Form no npm aponta para um beta**, o 8.0.0-beta.5, e é por isso que o
curso cita a 7.91.0, a versão estável mais nova, e nunca `latest`. Depois a primeira instalação
falhou. Leia um `ERESOLVE` de baixo para cima na árvore: o `@hookform/resolvers` 6.0.0 declara peers
opcionais para muitas bibliotecas de validação, entre elas o `effect` na versão 4, enquanto outro peer
opcional que ele lista, pelo `@typeschema/main`, quer o `effect` na versão 3. Os dois não podem ser
satisfeitos, e o npm 10 recusa em vez de adivinhar. O `npm view` confirma que o peer é opcional: o
conflito está num pacote que este projeto nem usa.

Duas saídas. O `--legacy-peer-deps` diz ao npm para ignorar as dependências peer, o que instala e
deixa você descobrir depois se algo quebrou. **A outra é uma versão que não tem o conflito**, e a
5.9.2, a última antes da 6, suporta o Zod 4 e o React Hook Form 7 e instalou sem reclamar. Fixá-la é
uma decisão com motivo, e o motivo está escrito aqui; quando a versão 6 for corrigida, a mudança é uma
linha.

```typescript
import { z } from 'zod'

export const sessionSchema = z.object({
  date: z.iso.date({ error: 'Choose the day of the session.' }),
  minutes: z
    .number({ error: 'Enter how many minutes.' })
    .int('Use whole minutes.')
    .min(5, 'A session is at least 5 minutes.')
    .max(240, 'A session is at most 240 minutes.'),
})

export type SessionInput = z.infer<typeof sessionSchema>
```

**O schema diz o que é uma sessão válida, uma vez.** O `z.iso.date` aceita uma string `YYYY-MM-DD` e
mais nada; os minutos precisam ser um número, inteiro, de 5 a 240. Cada regra leva a mensagem a mostrar
quando falha. O `z.infer` deriva o tipo TypeScript do schema, então os valores do formulário e as
regras não têm como discordar.
