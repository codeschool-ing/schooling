---
title: Localização com o app fechado
version: 1
---

**Localização em segundo plano é a permissão mais examinada que um app pode pedir.** A revisão da Apple e
a do Google Play perguntam para que ela serve, o Google Play pede um vídeo do recurso, e as duas
plataformas lembram a pessoa, semanas depois, que o app vem usando. Ela é certa para navegação, para um
app de corrida, para o app de um entregador. Para um planner de estudos seria difícil de defender, então o
planner não pede; mas a forma do código vale a pena conhecer.

A forma mais barata é uma **geofence**: o app dá ao sistema um círculo, e o sistema acorda o app quando o
celular entra ou sai dele. O sistema vigia com o rádio que já usa para a rede, então uma geofence custa
muito menos bateria que seguir o GPS. Um lembrete quando a pessoa chega ao lugar onde estuda ficaria
assim:

```ts
// src/arrival.ts: a geofence around the place the person studies, watched by the system while the app
// is closed. Defined at the top level of a module the app imports, so it exists when the system wakes it.
import * as Location from "expo-location";
import * as TaskManager from "expo-task-manager";

const TASK = "planner-arrival";

type Event = { eventType: Location.GeofencingEventType; region: Location.LocationRegion };

TaskManager.defineTask<Event>(TASK, async ({ data, error }) => {
  if (error) return; // the system could not deliver the event; there is nothing to act on
  if (data.eventType === Location.GeofencingEventType.Enter) {
    // arrived: lesson 16 shows a notification from here
  }
});

export async function watchArrival(lat: number, lng: number) {
  if (!(await Location.requestForegroundPermissionsAsync()).granted) return "refused";
  if (!(await Location.requestBackgroundPermissionsAsync()).granted) return "foreground only";
  await Location.startGeofencingAsync(TASK, [
    { identifier: "study-place", latitude: lat, longitude: lng, radius: 200, notifyOnEnter: true, notifyOnExit: false },
  ]);
  return "watching";
}
```

- **A tarefa é definida no nível de cima de um módulo**, não dentro de um componente. Quando o sistema
  acorda o app para um evento da geofence, nenhuma tela é renderizada; a tarefa precisa existir assim que
  o JavaScript é carregado, então o `defineTask` roda no import.
- **A permissão de segundo plano é um segundo pedido**, depois do primeiro plano, e no Android 11 em diante
  nem é um diálogo: o sistema manda a pessoa aos Ajustes para escolher *Permitir o tempo todo*. Uma recusa
  lá ainda deixa a localização em primeiro plano funcionando, e é por isso que a função diz isso.
- **As declarações mudam**: `isAndroidBackgroundLocationEnabled` e `isIosBackgroundLocationEnabled` nas
  opções do plugin, e uma frase para `locationAlwaysAndWhenInUsePermission`, tudo o que o planner pôs como
  `false`.

Para seguir a posição continuamente, o `startLocationUpdatesAsync` toma o lugar do `startGeofencingAsync`.
No Android isso roda um **foreground service**, uma notificação que fica na tela enquanto o app estiver
rastreando, para a pessoa sempre saber.

*Este arquivo foi conferido pelo compilador de TypeScript contra o `expo-location` e o `expo-task-manager`
58 e não foi executado: tarefas em segundo plano precisam de um celular, e uma geofence precisa de um que
se mova.*
