---
title: O planner, como projeto Expo
version: 1
---

**Toda aula daqui em diante trabalha num app só, o planner de estudos.** Você lista os seus cursos, abre
um, acrescenta sessões de estudo com uma data e uma duração, marca-as como feitas, e vê quantos minutos
a semana tem. É o mesmo planner que a trilha `frontend` constrói como página web, com os mesmos dados e
as mesmas regras, para que as telas dele possam ser comparadas com as versões Android e iOS que
`android-apps` e `ios-apps` constroem. Esta aula cria o projeto e lhe dá as regras e os dados; a aula 4
lhe dá telas de verdade.

## Criando

A partir do modelo TypeScript do Expo, nas versões com que este curso foi gravado, como na aula 1, e sem
instalar ainda:

```
ana@dev:~$ npx create-expo-app@5.0.0 planner --template blank-typescript@sdk-58 --no-install > /dev/null 2>&1
ana@dev:~$ cd planner
ana@dev:~/planner$ ls
AGENTS.md
App.tsx
LICENSE
app.json
assets
index.ts
package.json
tsconfig.json
```

## Cada versão escrita exatamente

O modelo escreve as versões com um `~`, que quer dizer *esta versão ou um patch posterior*. Um projeto
que instala diferente no mês que vem é um projeto cujas transcrições deixam de bater, então o primeiro
comando fixa as quatro que o modelo trouxe, e os dois seguintes acrescentam o que esta aula precisa,
também fixados:

```
ana@dev:~/planner$ npm install -E expo@58.0.21 expo-status-bar@58.0.4 react@19.3.0 react-native@0.88.1

added 460 packages, and audited 461 packages in 32s

8 vulnerabilities (5 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npm install -E react-dom@19.3.0 react-native-web@0.21.4 @expo/metro-runtime@58.0.15 expo-dev-client@58.0.17

added 32 packages, removed 2 packages, and audited 491 packages in 6s

8 vulnerabilities (5 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner$ npm install -E -D jest@30.5.2 jest-expo@58.0.13 @testing-library/react-native@14.1.0 @types/jest@30.0.0 playwright@1.63.0 typescript@6.0.3 @types/react@19.3.0
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated whatwg-encoding@3.1.1: Use @exodus/bytes instead for a more spec-conformant and faster implementation
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@7.2.3: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@10.5.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me

added 575 packages, and audited 1066 packages in 26s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

**O `-E` escreve versões exatas**, e o `package-lock.json`, que o npm escreve ao lado do `package.json`,
registra cada pacote por baixo deles. Faça commit dos dois; nunca faça commit do `node_modules`. Para que
serve cada acréscimo:

| pacote | por quê |
|---|---|
| `react-dom`, `react-native-web`, `@expo/metro-runtime` | rodar o mesmo app num navegador, com HTML no lugar das views nativas |
| `expo-dev-client` | transformar o build Android do fim desta aula num development build |
| `jest`, `jest-expo`, `@testing-library/react-native`, `@types/jest` | renderizar componentes e apertar os botões deles em testes, sem celular |
| `playwright` | comandar um navegador de verdade a partir de um programa, para o build web |

As versões das bibliotecas do Expo são as que o `npx expo install` escolhe para o SDK 58. Se depois você
acrescentar uma biblioteca sua, pergunte primeiro ao `npx expo install`, leia a versão que ele escolhe, e
fixe essa.

**Cada instalação termina com uma contagem de alertas**, quinze na última, em pacotes de que as
ferramentas de linha de comando do Expo e o Jest dependem, no dia em que isto foi gravado. O `npm audit`
nomeia cada um, e diz o que a correção forçada dele faria:

```
ana@dev:~/planner$ npm audit | grep "Will install" | sort -u
Will install expo@51.0.39, which is a breaking change
```

**É por isso que você não roda `npm audit fix --force` aqui.** Para calar um alerta numa ferramenta de
build, ele levaria o `expo` de volta ao SDK 51, e todas as versões que pertencem a ele, o que é um
projeto diferente do que este curso escreve. Os alertas são sobre ferramentas que rodam no seu
computador enquanto você desenvolve, não sobre código que vai no app. Leia-os, e deixe a próxima versão
do Expo trazer as correções.

## As regras e os dados

O planner mantém as regras longe das telas, em `src/planner.ts`. Ele acrescenta uma sessão, marca uma
como feita, e soma uma semana, e não mexe em tela nenhuma, o que permite à aula 4 usá-lo sem mudança e a
um teste conferi-lo sem uma. Salve isto como `src/planner.ts`:

```typescript
// src/planner.ts: the study planner's rules, with no screen in them.
export type Course = { id: string; name: string };
export type Session = { id: string; course: string; date: string; minutes: number; done: boolean };
export type Plan = { courses: Course[]; sessions: Session[] };

export function addSession(plan: Plan, course: string, date: string, minutes: number): Plan {
  if (!plan.courses.some((c) => c.id === course)) throw new Error(`no course ${course}`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`not a date: ${date}`);
  if (!Number.isInteger(minutes) || minutes <= 0) throw new Error(`not a duration: ${minutes}`);
  const id = `s${plan.sessions.length + 1}`;
  return { ...plan, sessions: [...plan.sessions, { id, course, date, minutes, done: false }] };
}

export function markDone(plan: Plan, id: string): Plan {
  return { ...plan, sessions: plan.sessions.map((s) => (s.id === id ? { ...s, done: true } : s)) };
}

// The Monday of the week a date falls in, as YYYY-MM-DD.
export function mondayOf(date: string): string {
  const d = new Date(`${date}T12:00:00Z`);
  d.setUTCDate(d.getUTCDate() - ((d.getUTCDay() + 6) % 7));
  return d.toISOString().slice(0, 10);
}

// Minutes planned in the week that starts on `monday`, and how many are done.
export function weekTotal(plan: Plan, monday: string): { planned: number; done: number } {
  const end = new Date(`${monday}T12:00:00Z`);
  end.setUTCDate(end.getUTCDate() + 7);
  const last = end.toISOString().slice(0, 10);
  const week = plan.sessions.filter((s) => s.date >= monday && s.date < last);
  return {
    planned: week.reduce((n, s) => n + s.minutes, 0),
    done: week.filter((s) => s.done).reduce((n, s) => n + s.minutes, 0),
  };
}
```

Um curso se liga às suas sessões pelo `id`, nunca pelo nome, então renomear *Spanish A2* não perde nada.
Uma função nunca muda o plano que recebeu: devolve um novo, que é exatamente o que o React quer do
estado, como explica a aula 9. Os dados são um arquivo JSON pequeno. Salve-o como `src/courses.json`:

```json
{
  "courses": [
    { "id": "spanish", "name": "Spanish A2" },
    { "id": "statistics", "name": "Statistics" },
    { "id": "guitar", "name": "Guitar" }
  ],
  "sessions": [
    { "id": "s1", "course": "spanish", "date": "2026-10-19", "minutes": 30, "done": true },
    { "id": "s2", "course": "statistics", "date": "2026-10-20", "minutes": 45, "done": true },
    { "id": "s3", "course": "guitar", "date": "2026-10-21", "minutes": 20, "done": false },
    { "id": "s4", "course": "spanish", "date": "2026-10-22", "minutes": 30, "done": false },
    { "id": "s5", "course": "statistics", "date": "2026-10-26", "minutes": 60, "done": false },
    { "id": "s6", "course": "guitar", "date": "2026-10-28", "minutes": 20, "done": false }
  ]
}
```

**A semana deste curso é a da segunda-feira, 19 de outubro de 2026**, para que toda transcrição mostre os
mesmos números seja qual for o dia em que você lê. O build no navegador lê a data do endereço; em
qualquer outro lugar, vale a data real. Salve isto como `src/today.ts`:

```typescript
// src/today.ts: the date the planner treats as today, as YYYY-MM-DD.
// In a browser, ?today= in the address overrides the clock, so a lesson can pin the week.
export function today(): string {
  const pinned = typeof location === "undefined" ? null : new URLSearchParams(location.search).get("today");
  return pinned ?? new Date().toISOString().slice(0, 10);
}
```

## Uma primeira tela

O `App.tsx` do modelo diz *Open up App.tsx*. Troque-o por uma tela que usa as regras: um título, o total
da semana e os nomes dos cursos. A aula 4 explica cada elemento dela; por enquanto ela está aqui para
haver algo para rodar:

```tsx
// App.tsx: the planner's first screen, before lesson 4 gives it components of its own.
import { StatusBar } from "expo-status-bar";
import { Text, View } from "react-native";
import data from "./src/courses.json";
import { mondayOf, weekTotal, type Plan } from "./src/planner";
import { today } from "./src/today";

const plan: Plan = data;

export default function App() {
  const total = weekTotal(plan, mondayOf(today()));
  return (
    <View style={{ flex: 1, padding: 24, paddingTop: 64 }}>
      <Text role="heading">Study planner</Text>
      <Text>
        This week: {total.done} of {total.planned} minutes done
      </Text>
      {plan.courses.map((c) => (
        <Text key={c.id}>{c.name}</Text>
      ))}
      <StatusBar style="auto" />
    </View>
  );
}
```

O TypeScript confere o projeto inteiro sem escrever nada, e uma resposta vazia é aprovação:

```
ana@dev:~/planner$ npx tsc --noEmit
```
