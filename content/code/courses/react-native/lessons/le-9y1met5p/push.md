---
title: Push through Expo's service
version: 1
---

**Expo's push service sits in front of APNs and FCM**, so a server sends one kind of message, to one
address, and Expo hands it to Apple or Google. The phone's address is an **Expo push token**, which the
app asks for once notifications are allowed:

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

`getExpoPushTokenAsync` asks the system for the phone's real APNs or FCM token and exchanges it with Expo
for one that looks like `ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]`. The `projectId` says which Expo project
the app belongs to, which is how Expo knows which Apple and Google credentials to use; it is written into
`app.json` by `eas init`, in lesson 20. The app then sends the token to its own server, with the account it
belongs to.

The server sends a reminder with one HTTP request:

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

**The answer is a *ticket*, not a delivery.** `ok` means Expo accepted the message and passed it on; an
error says why it refused, and `DeviceNotRegistered` means the app is gone from that phone, so the server
deletes the token. A while later the server can ask for *receipts* with the tickets' ids, which say
whether Apple or Google accepted them in turn. Neither says the person saw it: no push service can.

*Neither file was run for this course. `push.ts` was checked by the TypeScript compiler against
`expo-notifications` 58, and `send.mjs` by `node --check`. A push token needs a phone and an Expo project,
and this course's recordings had neither; Expo's push service was also unreachable from the machine that
recorded them.*
