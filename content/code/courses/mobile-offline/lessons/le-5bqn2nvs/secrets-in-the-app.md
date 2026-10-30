---
title: A secret in the app is a secret you published
version: 1
---

**Anything compiled into an app is readable by anybody who downloads it, so an app cannot keep a
secret from its own users.** The tempting picture is that a key inside a compiled app is hidden:
it is in a binary, minified, perhaps encoded, and nobody would go looking. People do look, with
tools that unpack an Android package or an iOS app in a minute, and they look for exactly the
strings a key is made of. A key that ships in the app should be treated as published on the day
the app reaches the store.

This lesson closes the course with what should **not** be on the device, and that comes first
because it is the case no encryption from lesson 19 can rescue: the app has to use the key, so the
app has to be able to read it, and so can whoever holds the app.

## A build, in miniature

The planner wants study tips from a third-party service that charges per request and gave the
team a key. The first version puts the key in the configuration, beside the address of the service.
Save these three files in `~/planner/secrets`. First `config.json`:

```json
{
  "server": "https://tips.example.com",
  "tipsApiKey": "tips_live_4f9c2a7e1b6d83a0"
}
```

Then the screen's code, `app.ts`, which uses only the address:

```typescript
// app.ts: the planner's screen asks for a study tip for a course.
async function tip(course) {
  const res = await fetch(`${CONFIG.server}/tip?course=${course}`);
  return res.text();
}
```

And `bundle.ts`, which does to them what a build does: one file, the configuration embedded, the
comments and the indentation gone:

```typescript
// bundle.ts: what a build does to the planner, in miniature: the configuration and the code
// become one file that ships inside the app, with the comments and the indentation removed.
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";

const config = JSON.parse(readFileSync("config.json", "utf8"));
const code = readFileSync("app.ts", "utf8")
  .split("\n")
  .filter((line) => !line.trim().startsWith("//"))
  .map((line) => line.trim())
  .join("");
mkdirSync("dist", { recursive: true });
writeFileSync("dist/app.js", `const CONFIG=${JSON.stringify(config)};${code}\n`);
console.log(`dist/app.js: ${readFileSync("dist/app.js").length} bytes`);
```

Build it and look for the key's shape in what would ship:

```
ana@dev:~/planner/secrets$ node bundle.ts
dist/app.js: 206 bytes
ana@dev:~/planner/secrets$ grep -o 'tips_live_[0-9a-f]*' dist/app.js
tips_live_4f9c2a7e1b6d83a0
```

**The code never used `tipsApiKey`, and it shipped anyway.** A bundler embeds the configuration it
is given, so a key anywhere in what the build reads is in the bundle. The same is true of Android's
`BuildConfig` fields and resource strings, an iOS app's `Info.plist`, and the environment variables
Expo inlines at build time under names starting with `EXPO_PUBLIC_`, which its documentation says
plainly are visible in the app. Encoding the key in base64 or splitting it in two changes the
command a person types to find it, and nothing else.

## The fix is a server that holds the key

The key moves to the planner's own server, which the app already has to talk to for sync, and the
app asks that server for a tip. The server adds the key on its side, where nobody downloads it.
The configuration loses a line. Save the second `config.json`:

```json
{
  "server": "http://127.0.0.1:8020"
}
```

```
ana@dev:~/planner/secrets$ node bundle.ts
dist/app.js: 161 bytes
ana@dev:~/planner/secrets$ grep -c 'tips_live_' dist/app.js
0
```

Moving the key buys more than hiding it. The server can now refuse a person who is not signed in, count
requests per account, and change the key without a new release in the store. The next section
writes it, with the tokens that tell it who is asking.
