---
title: Lembretes que o próprio celular agenda
version: 1
---

**"A sua sessão começa em 15 minutos" não precisa de servidor, token nem push.** O app conhece as
sessões e os horários. Ele pode pedir ao sistema do próprio celular que mostre uma notificação num
dado momento, e o sistema mostra, esteja o app rodando ou não, haja rede ou não. Isso é uma
notificação *local*. A aula 15 disse que nenhum job em segundo plano consegue rodar às 18:45 em
ponto; uma notificação local agendada é a ferramenta que consegue, porque o próprio sistema cumpre o
compromisso.

Cada plataforma agenda de um jeito. Os trechos abaixo foram adaptados do artigo da Apple sobre
agendar uma notificação localmente, do guia do Android sobre o Doze, que cita o alarme que pode
disparar enquanto o celular cochila, e da documentação do `expo-notifications`, e **não foram
compilados nem executados para este curso**:

```swift
let content = UNMutableNotificationContent()
content.title = "SQL Databases"
content.body = "Your SQL session starts in 15 minutes"
let when = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: remindAt)
let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
try await UNUserNotificationCenter.current()
    .add(UNNotificationRequest(identifier: "remind-s3", content: content, trigger: trigger))
```

```kotlin
// Android has no "show this at 18:45": an alarm wakes a receiver, which posts the notification
val alarms = context.getSystemService(AlarmManager::class.java)
val wake = PendingIntent.getBroadcast(
    context, 3, Intent(context, ReminderReceiver::class.java), PendingIntent.FLAG_IMMUTABLE,
)
alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, remindAt.toEpochMilli(), wake)
```

```tsx
import * as Notifications from "expo-notifications";

await Notifications.scheduleNotificationAsync({
  identifier: "remind-s3",
  content: { title: "SQL Databases", body: "Your SQL session starts in 15 minutes" },
  trigger: { type: Notifications.SchedulableTriggerInputTypes.DATE, date: remindAt, channelId: "reminders" },
});
```

**Cada um recebe um identificador**, `remind-s3`, para que o app possa cancelá-lo. O artigo da Apple
diz isso com clareza: um pedido agendado continua ativo até o gatilho disparar ou o app cancelá-lo,
e você o cancela quando ele não é mais necessário. Quando a aluna marca `s3` como concluída, ou a
muda para sábado, o lembrete de sexta precisa sair, senão o celular vai lembrá-la de uma sessão que
não existe mais.

## Calculando os lembretes da semana

A parte interessante não é a chamada ao sistema. É decidir **quais** lembretes agendar e **quando**,
e isso é lógica comum que você consegue rodar. O `reminders.ts` pega as sessões do planner com os
horários de início, e para cada uma decide: já concluída, fora desta semana, já passou, ou um lembrete
quinze minutos antes de começar. O "agora" vem como argumento, como o "hoje" na aula 1.

**Os horários são de relógio de parede na cidade da aluna, São Paulo**, e o sistema agenda um
instante. Então o programa converte "sexta, 23 de outubro, às 19:00 em `America/Sao_Paulo`" num
instante com a API `Intl`, que traz as regras de fuso horário do mundo, em vez de somar um número
fixo de horas, que estaria errado em qualquer cidade com horário de verão. Salve como
`reminders.ts`:

```typescript
// reminders.ts: which of the week's sessions get a reminder, and at what instant
import { mondayOf, type Session } from "./planner.ts";

const ZONE = "America/Sao_Paulo";
const BEFORE_MIN = 15;
type Timed = Session & { title: string; at: string }; // at: HH:MM, wall-clock time in ZONE

// How many minutes ZONE is ahead of UTC at a given instant.
function offsetMin(instant: Date): number {
  const f = new Intl.DateTimeFormat("en-GB", {
    timeZone: ZONE, hourCycle: "h23", year: "numeric", month: "2-digit", day: "2-digit",
    hour: "2-digit", minute: "2-digit",
  });
  const p = Object.fromEntries(f.formatToParts(instant).map((x) => [x.type, x.value]));
  const wall = Date.UTC(+p.year, +p.month - 1, +p.day, +p.hour, +p.minute);
  return (wall - instant.getTime()) / 60000;
}

// The instant at which the wall clock in ZONE reads `date` `time`.
function instantOf(date: string, time: string): Date {
  const guess = new Date(`${date}T${time}:00Z`);
  return new Date(guess.getTime() - offsetMin(guess) * 60000);
}

const local = new Intl.DateTimeFormat("en-GB", {
  timeZone: ZONE, weekday: "short", day: "numeric", month: "short", hour: "2-digit", minute: "2-digit",
});

const sessions: Timed[] = [
  { id: "s1", courseId: "sql", title: "SQL Databases", date: "2026-10-19", at: "08:00", minutes: 50, done: true },
  { id: "s2", courseId: "mobile", title: "Mobile Fundamentals", date: "2026-10-20", at: "19:00", minutes: 40, done: true },
  { id: "s6", courseId: "mobile", title: "Mobile Fundamentals", date: "2026-10-21", at: "07:30", minutes: 30, done: false },
  { id: "s5", courseId: "mobile", title: "Mobile Fundamentals", date: "2026-10-22", at: "18:30", minutes: 30, done: true },
  { id: "s3", courseId: "sql", title: "SQL Databases", date: "2026-10-23", at: "19:00", minutes: 60, done: false },
  { id: "s4", courseId: "mobile", title: "Mobile Fundamentals", date: "2026-10-27", at: "08:30", minutes: 45, done: false },
];

const now = new Date(process.argv[2]); // given, never read from the clock here
const week = mondayOf(now.toISOString().slice(0, 10));
for (const s of sessions) {
  const start = instantOf(s.date, s.at);
  const remindAt = new Date(start.getTime() - BEFORE_MIN * 60000);
  const label = `${s.id} ${s.title.padEnd(19)} ${local.format(start)}`;
  if (s.done) console.log(`${label}  skip: done`);
  else if (mondayOf(s.date) !== week) console.log(`${label}  skip: not this week`);
  else if (remindAt <= now) console.log(`${label}  skip: already past`);
  else console.log(`${label}  remind at ${local.format(remindAt)} = ${remindAt.toISOString()}`);
}
```

As sessões da aula 1 tinham data e não tinham horário, então este arquivo dá a cada uma um horário
de início, e acrescenta uma sessão, `s6`, cedo na quarta de manhã, para ter uma que já passou. Rode
ao meio-dia de quarta, 21 de outubro, horário de São Paulo:

```
ana@dev:~/planner$ node reminders.ts 2026-10-21T12:00:00-03:00
s1 SQL Databases       Mon 19 Oct, 08:00  skip: done
s2 Mobile Fundamentals Tue 20 Oct, 19:00  skip: done
s6 Mobile Fundamentals Wed 21 Oct, 07:30  skip: already past
s5 Mobile Fundamentals Thu 22 Oct, 18:30  skip: done
s3 SQL Databases       Fri 23 Oct, 19:00  remind at Fri 23 Oct, 18:45 = 2026-10-23T21:45:00.000Z
s4 Mobile Fundamentals Tue 27 Oct, 08:30  skip: not this week
```

**Um lembrete em seis sessões**, e cada pulo tem o seu motivo. `s1`, `s2` e `s5` estão concluídas.
`s6` começou às 07:30 desta manhã, então o lembrete dela ficaria no passado. `s4` é da semana que
vem, e ganha o lembrete quando o app planejar aquela semana. E `s3`, na sexta às 19:00, ganha um às
**18:45 de São Paulo, que são 21:45 UTC**: o mesmo instante, escrito duas vezes, e a segunda forma é
a que um servidor ou um sistema guarda. Num celular, esse laço é o que roda quando o plano muda,
cancelando os lembretes antigos pelo identificador e agendando os novos.
