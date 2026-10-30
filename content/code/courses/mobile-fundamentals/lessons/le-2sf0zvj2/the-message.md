---
title: What a push carries, and how much
version: 1
---

**A push message is small JSON, and it comes in two kinds that behave differently on the phone.**
A *notification* message says what to show, a title and a body, and when the app is not on screen
the system shows it by itself. A *data* message carries only keys and values for the app, shows
nothing, and wakes the app in the background if the system allows it. Many messages are both: a
title and body to show, and a few keys the app reads when the person taps it.

| | a notification message | a data-only message |
|---|---|---|
| what it carries | a title and a body, perhaps a sound; optional data beside them | only data |
| app not on screen | the system shows it; your code runs on a tap | the system may wake the app to handle it, and may not |
| on iOS | an `aps.alert` in the payload | a background notification, `content-available` |
| the planner uses it for | "Your SQL session starts in 15 minutes" | "your week changed": refresh quietly |

The table follows Expo's guide to notification types and Apple's documentation on generating a
remote notification, read on 30 October 2026. **The data-only kind is the less reliable one.** The
same Expo guide says the system does not guarantee delivering it to the app, under Doze for
example, and cites Apple's advice not to send more than two or three background notifications an
hour. A refresh that must happen is not built on it; lesson 15's batched job is the floor under it.

## The size, which is small on purpose

**Both services cap the size of a message, and the cap is a few kilobytes.** Apple's documentation
on generating a remote notification gives **4 KB, 4096 bytes**, for every remote notification except
a VoIP one. Firebase's own page on message sizes could not be read from the machine this course was
recorded on; Expo's documentation of its push service, which sends through FCM and APNs, gives the
same 4096 bytes for both Android and iOS. A push is a doorbell, not a parcel.

`payload.ts` builds the reminder for one session in the shape each service expects, and measures it.
The token is a stand-in: a real one comes from the phone, and no message is sent anywhere. The check
measures the whole JSON the server would send, which is at least as large as what either service
counts, so it errs on the safe side. Save it in `~/planner` as `payload.ts`:

```schooling-example
{"language": "typescript", "file": "payload.ts", "parts": [{"code": "// payload.ts: one session reminder as APNs and FCM expect it, and a check of its size\nconst LIMIT = 4096; // bytes, for an ordinary remote notification\n\ntype Push = Record<string, unknown>;\ntype Data = Record<string, string>;\n", "note": "The limit is a constant with its unit, from the documentation the lesson names. `Data` is strings only, because FCM refuses anything else under `data`."}, {"code": "// APNs: what to show goes under \"aps\"; the app's own keys sit beside it.\nexport function apns(title: string, body: string, data: Data): Push {\n  return { aps: { alert: { title, body }, sound: \"default\" }, ...data };\n}\n\n// FCM HTTP v1: one \"message\", with the Android channel it is shown on.\nexport function fcm(token: string, title: string, body: string, data: Data): Push {\n  return {\n    message: { token, notification: { title, body }, android: { notification: { channelId: \"reminders\" } }, data },\n  };\n}\n", "note": "One function per service, so the shape is written once. The same title, body and data go into both; only where each one sits differs."}, {"code": "// The size the service sees is at most the size of the JSON we would send.\nexport function check(name: string, push: Push): boolean {\n  const bytes = Buffer.byteLength(JSON.stringify(push), \"utf8\");\n  const ok = bytes <= LIMIT;\n  console.log(`${name}: ${bytes} of ${LIMIT} bytes${ok ? \"\" : \", refused: too large to send\"}`);\n  return ok;\n}\n", "note": "Bytes, not characters: `Buffer.byteLength` counts UTF-8, where an accented letter in a Portuguese reminder takes two. A message over the limit is refused here, before any service sees it."}, {"code": "// A busy week: 4 courses a day for 7 days, each session with its notes.\nfunction busyWeek() {\n  const days = [\"19\", \"20\", \"21\", \"22\", \"23\", \"24\", \"25\"].map((d) => `2026-10-${d}`);\n  return days.flatMap((date, d) =>\n    [\"sql\", \"mobile\", \"kotlin\", \"git\"].map((courseId, c) => ({\n      id: `w${d * 4 + c + 1}`, courseId, date, minutes: 45, done: false,\n      notes: \"Re-read the section, redo the exercises answered wrong, write down one question.\",\n    })),\n  );\n}\n", "note": "Data for the mistake below: 28 sessions, the kind of week a student who plans hard really has."}, {"code": "const token = \"token-the-phone-sent-us\"; // a stand-in: a real one comes from the phone\nconst title = \"SQL Databases\";\nconst body = \"Your SQL session starts in 15 minutes\";\nconst data = { sessionId: \"s3\", courseId: \"sql\" };\n\nconsole.log(JSON.stringify(apns(title, body, data)));\ncheck(\"APNs\", apns(title, body, data));\nconsole.log(JSON.stringify(fcm(token, title, body, data)));\ncheck(\"FCM\", fcm(token, title, body, data));\n\nconst big = fcm(token, title, body, { ...data, week: JSON.stringify(busyWeek()) });\nif (!check(\"FCM with the whole week\", big)) {\n  console.log(\"send the sessionId alone, and let the app fetch the week\");\n}", "note": "The reminder for `s3`, built for each service and measured, then the same reminder carrying the whole week. Nothing is sent: the program prints what a server would hand over."}]}
```

```
ana@dev:~/planner$ node payload.ts
{"aps":{"alert":{"title":"SQL Databases","body":"Your SQL session starts in 15 minutes"},"sound":"default"},"sessionId":"s3","courseId":"sql"}
APNs: 142 of 4096 bytes
{"message":{"token":"token-the-phone-sent-us","notification":{"title":"SQL Databases","body":"Your SQL session starts in 15 minutes"},"android":{"notification":{"channelId":"reminders"}},"data":{"sessionId":"s3","courseId":"sql"}}}
FCM: 231 of 4096 bytes
FCM with the whole week: 5511 of 4096 bytes, refused: too large to send
send the sessionId alone, and let the app fetch the week
```

**The reminder is 142 bytes for APNs and 231 for FCM, far under the limit on both.** The two shapes
differ in where things go: APNs puts what to show under `aps.alert` and lets the app's own keys sit
beside `aps`. FCM's HTTP v1 API wraps everything in a `message`, puts what to show under
`notification`, names the Android notification channel the message appears on, and requires every
value under `data` to be a string. The FCM API's own description, read the same day, marks the
`token` field as deprecated in favour of `fid`, a Firebase installation ID that plays the same part.
That is the kind of change that makes a payload worth building in one tested function rather than
by hand in five places.

**The third message is the mistake, and the check refuses it.** It carries the student's whole week,
28 sessions with their notes, inside the push, so that the app would not have to ask the server.
At 5,511 bytes it is over 4096, so neither service would take it. And even under the limit, it would be the
wrong design: the push can arrive late, twice collapsed into one, or not at all, as the previous
section said. **Send the id of what changed, and let the app fetch the rest**, which is the last line
the program prints.

## What not to put in one

**A push travels through Google's or Apple's servers and lands on a lock screen.** Apple's App
Store Review Guidelines, read on 30 October 2026, say in guideline 4.5.4 that push notifications
should not be used to send sensitive personal or confidential information. "Your SQL session starts
in 15 minutes" is fine on a lock screen. A message that carried a student's marks, or the reason
they missed a week, is not, and the right push for it says "you have a new message" and nothing
else.
