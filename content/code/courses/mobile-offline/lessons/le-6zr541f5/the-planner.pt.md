---
title: O planner de estudos, o app que este curso guarda
version: 1
---

**O curso tem um exemplo só, e ele é pequeno de propósito: um planner de estudos.** A pessoa lista
os cursos que está estudando, abre um, adiciona sessões com data e duração em minutos, marca cada
uma quando termina e vê quantos minutos a semana tem. A trilha `frontend` constrói o mesmo planner
como app web, e os cursos de plataforma antes da bifurcação o constroem num celular. Aqui ele não
tem tela nenhuma. Ele é o dado por baixo das telas, que é a parte que precisa funcionar quando a
rede não funciona.

Três cursos, seis sessões, todas na segunda metade de outubro de 2026. Salve isto como `data.ts` na
`~/planner`; toda aula começa dele:

```typescript
// data.ts: the planner's starting data, which every lesson of the course begins from.
export type Course = { id: string; name: string };
export type Session = { id: string; course: string; date: string; minutes: number; done: boolean };

export const courses: Course[] = [
  { id: "spanish", name: "Spanish A2" },
  { id: "statistics", name: "Statistics" },
  { id: "guitar", name: "Guitar" },
];

export const sessions: Session[] = [
  { id: "s1", course: "spanish", date: "2026-10-19", minutes: 30, done: true },
  { id: "s2", course: "statistics", date: "2026-10-20", minutes: 45, done: true },
  { id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: false },
  { id: "s4", course: "spanish", date: "2026-10-22", minutes: 30, done: false },
  { id: "s5", course: "statistics", date: "2026-10-26", minutes: 60, done: false },
  { id: "s6", course: "guitar", date: "2026-10-28", minutes: 20, done: false },
];
```

Uma data é uma string como `2026-10-21`, sem hora e sem fuso. Isso é de propósito: uma sessão de
estudo pertence a um dia do calendário da pessoa, e um timestamp a jogaria para o dia anterior para
alguém três horas a oeste. A aula 11 volta aos relógios, e ao motivo de o servidor não poder
confiar no do celular.

As duas telas que o planner desenha são uma lista de cursos e a semana. Aqui elas vão impressas, a
partir do dado acima. Salve isto como `show.ts`:

```typescript
// show.ts: the planner's two screens, printed: the courses, and one week.
import { courses, sessions } from "./data.ts";

const monday = process.argv[2] ?? "2026-10-19";
const end = new Date(`${monday}T12:00:00Z`);
end.setUTCDate(end.getUTCDate() + 7);
const sunday = end.toISOString().slice(0, 10);

for (const c of courses) {
  const mine = sessions.filter((s) => s.course === c.id);
  console.log(`${c.name.padEnd(12)} ${mine.length} sessions`);
}
const week = sessions.filter((s) => s.date >= monday && s.date < sunday);
const planned = week.reduce((n, s) => n + s.minutes, 0);
const done = week.filter((s) => s.done).reduce((n, s) => n + s.minutes, 0);
console.log(`week of ${monday}: ${planned} min planned, ${done} done`);
```

O `./data.ts` no import mantém a extensão, porque o Node procura o arquivo pelo nome escrito ali. E
a semana é passada como argumento em vez de lida do relógio, então o programa diz a mesma coisa
sempre que você o roda:

```
ana@dev:~/planner$ node show.ts 2026-10-19
Spanish A2   2 sessions
Statistics   2 sessions
Guitar       2 sessions
week of 2026-10-19: 125 min planned, 75 done
ana@dev:~/planner$ node show.ts 2026-10-26
Spanish A2   2 sessions
Statistics   2 sessions
Guitar       2 sessions
week of 2026-10-26: 80 min planned, 0 done
```

**Tudo aqui vive na memória e some quando o programa termina.** É o estado de um app antes deste
curso: o dado vem de outro lugar e nada fica para trás. A aula 3 põe essas linhas num banco de
dados no aparelho, e daí em diante o planner se lembra.
