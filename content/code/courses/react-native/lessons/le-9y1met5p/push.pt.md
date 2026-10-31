---
title: Push pelo serviço do Expo
version: 1
---

**O serviço de push do Expo fica na frente do APNs e do FCM**, então um servidor manda um tipo só de
mensagem, para um endereço só, e o Expo a entrega à Apple ou ao Google. O endereço do celular é um **token
de push do Expo**, que o app pede assim que as notificações são permitidas:

```ts
// src/push.ts: this phone's address for push notifications, from Expo's push service, for the server to
// keep. Only after the person has allowed notifications: without that, a push would never be shown.
import Constants from "expo-constants";
import * as Notifications from "expo-notifications";

export async function pushAddress(): Promise<string | null> {
  if (!(await Notifications.getPermissionsAsync()).granted) return null;
  const projectId = Constants.expoConfig?.extra?.eas?.projectId; // written by `eas init`, lesson 20
  const { data } = await Notifications.getExpoPushTokenAsync({ projectId });
  return data; // "ExponentPushToken[…]"
}
```

O `getExpoPushTokenAsync` pede ao sistema o token de verdade do APNs ou do FCM e o troca no Expo por um
parecido com `ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]`. O `projectId` diz a que projeto do Expo o app
pertence, que é como o Expo sabe quais credenciais da Apple e do Google usar; ele é escrito no `app.json`
pelo `eas init`, na aula 20. Depois o app manda o token ao próprio servidor, com a conta a que ele pertence.

O servidor manda um lembrete com uma requisição HTTP:

```javascript
// send.mjs: what the planner's server would do to remind one phone, through Expo's push service.
//
//   node send.mjs 'ExponentPushToken[…]'
const [to] = process.argv.slice(2);
const res = await fetch("https://exp.host/--/api/v2/push/send", {
  method: "POST",
  headers: { "content-type": "application/json", accept: "application/json" },
  body: JSON.stringify([
    { to, title: "Guitar: 20 min today", body: "Tap to open the course.", data: { url: "planner://course/guitar" } },
  ]),
});
// One ticket per message: accepted for delivery, or refused with a reason.
const { data } = await res.json();
for (const ticket of data) {
  if (ticket.status === "ok") console.log("accepted:", ticket.id);
  else console.log("refused:", ticket.message, ticket.details?.error ?? "");
}
```

**A resposta é um *ticket*, não uma entrega.** `ok` quer dizer que o Expo aceitou a mensagem e a repassou;
um erro diz por que recusou, e `DeviceNotRegistered` quer dizer que o app não está mais naquele celular,
então o servidor apaga o token. Um tempo depois o servidor pode pedir *receipts* com os ids dos tickets,
que dizem se a Apple ou o Google os aceitaram por sua vez. Nenhum dos dois diz que a pessoa viu: nenhum
serviço de push consegue.

*Nenhum dos dois arquivos foi executado para este curso. O `push.ts` foi conferido pelo compilador de
TypeScript contra o `expo-notifications` 58, e o `send.mjs` pelo `node --check`. Um token de push precisa de
um celular e de um projeto do Expo, e as gravações deste curso não tinham nenhum dos dois; o serviço de push
do Expo também estava inacessível da máquina que as gravou.*
