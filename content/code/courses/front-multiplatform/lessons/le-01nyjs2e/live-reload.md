---
title: Live reload on a phone, and why it never ships
version: 1
---

**Build and sync takes seconds, and the native build after it takes longer.** For a change to a
button's text, that is a long way round. Capacitor can instead point the WebView at your development
server, so the app on the phone reloads as `npm run dev` does in your browser. It is a setting in
`capacitor.config.ts`:

```typescript
const config: CapacitorConfig = {
  appId: "com.example.studyplanner",
  appName: "Study planner",
  webDir: "dist",
  server: {
    url: "http://192.0.2.20:5173", // your computer's address on the network
    cleartext: true,
  },
};
```

Three conditions make it work. **The phone and the computer are on the same network**, and the
address is the computer's address on it, not `localhost`, which on the phone means the phone. **The
dev server listens on that network**, which `npm run dev -- --host` does; by default Vite listens
only on the computer itself, and its own start-up banner says so with `use --host to expose`. And **Android allows
plain `http`** for that address, which is what `cleartext: true` asks for.

Capacitor's CLI does the same without editing the file: `npx cap run android --live-reload --host
192.0.2.20 --port 5173` writes the setting for that run only. *Neither form was run for this course,
because it needs a phone or an emulator; lesson 3 says why there was none.*

## Why it never ships

**An app with `server.url` set does not contain your app.** It contains a WebView that opens an
address on your network, and on anybody else's phone that address is nothing at all, or somebody
else's computer. With `cleartext` it fetches the code without encryption, so anybody on the same
network can read or change what the app runs. Both stores' reviewers see an app that is a remote page.

So the rule is mechanical: **`server.url` is deleted, or never committed, before a release build**.
The `--live-reload` form of `cap run` exists for exactly that reason: the setting lives for one run,
and the file in git never has it. Lesson 13's release checklist has a line that searches for it.
