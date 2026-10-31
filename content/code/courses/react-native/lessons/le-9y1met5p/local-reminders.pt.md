---
title: Um lembrete no dia de cada sessão
version: 1
---

Tudo sobre lembretes está num arquivo. Salve o `src/reminders.ts`:

```ts
// src/reminders.ts: a reminder on the evening of every session still to do, scheduled on the phone
// itself, so it arrives with no server and no network.
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Notifications from "expo-notifications";
import { Platform } from "react-native";
import type { Plan } from "./planner";

const KEY = "reminders";
export const CHANNEL = "reminders";
export const REMIND_AT = 18; // a session has a date and no time, so its reminder comes at six in the evening

export type Reminder = { id: string; at: Date; title: string; url: string };

// Which reminders a plan asks for, from now on. No phone needed, so a test can ask it anything.
export function remindersFor(plan: Plan, now: Date): Reminder[] {
  return plan.sessions
    .filter((s) => !s.done)
    .map((s) => {
      const course = plan.courses.find((c) => c.id === s.course)?.name ?? s.course;
      const at = new Date(`${s.date}T${String(REMIND_AT).padStart(2, "0")}:00:00`); // the phone's local time
      return { id: s.id, at, title: `${course}: ${s.minutes} min today`, url: `planner://course/${s.course}` };
    })
    .filter((r) => r.at > now);
}

// Every call replaces what was scheduled, so a session done, added or moved never leaves a stale one.
export async function scheduleReminders(plan: Plan, now = new Date()) {
  await Notifications.cancelAllScheduledNotificationsAsync();
  for (const r of remindersFor(plan, now)) {
    await Notifications.scheduleNotificationAsync({
      identifier: r.id,
      content: { title: r.title, body: "Tap to open the course.", data: { url: r.url } },
      trigger: { type: Notifications.SchedulableTriggerInputTypes.DATE, date: r.at, channelId: CHANNEL },
    });
  }
}

export async function remindersOn() {
  return (await AsyncStorage.getItem(KEY)) === "on";
}

// Turning reminders on is the moment to ask. On Android 13 and later the dialog only appears once the
// app has a channel, so the channel comes first.
export async function setReminders(on: boolean): Promise<"on" | "off" | "refused"> {
  if (on) {
    if (Platform.OS === "android") {
      await Notifications.setNotificationChannelAsync(CHANNEL, {
        name: "Study reminders",
        importance: Notifications.AndroidImportance.DEFAULT,
      });
    }
    if (!(await Notifications.requestPermissionsAsync()).granted) return "refused";
  } else {
    await Notifications.cancelAllScheduledNotificationsAsync();
  }
  await AsyncStorage.setItem(KEY, on ? "on" : "off");
  return on ? "on" : "off";
}
```

- **O `remindersFor` decide, e não mexe em nada.** Ele recebe um plano e um horário e devolve os lembretes
  que aquele plano pede: um por sessão não feita, às seis da tarde da data dela, se isso ainda está no
  futuro. Como ele não agenda nada, um teste pode lhe perguntar sobre qualquer plano em qualquer hora.
- **A data não tem fuso horário de propósito.** `new Date("2026-10-21T18:00:00")` é seis da tarde no fuso
  do próprio celular, que é o que uma pessoa quer dizer com "seis da tarde". Escrita com um `Z` no fim, seria
  seis horas em Greenwich, e três da tarde em São Paulo.
- **O `scheduleReminders` cancela tudo primeiro, depois agenda.** A alternativa, descobrir o que mudou e
  remendar a agenda, tem um bug para cada jeito como um plano pode mudar. O identificador de cada lembrete é
  o id da sessão dele, então a agenda sempre pode ser lida de volta e comparada.
- **O lembrete leva um endereço**, `planner://course/guitar`, no `data`. Um toque nele deveria abrir esse
  curso, e a seção dos handlers faz isso.

O gatilho é um `DATE`: um momento. Há gatilhos para intervalos, para todo dia num horário, e para padrões
de calendário também; uma sessão acontece uma vez, então uma data é a verdade.
