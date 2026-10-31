---
title: A value fixed at build time
version: 1
---

Since lesson 10 the planner has found its server with one line in `src/api.ts`:

```ts
const BASE = process.env.EXPO_PUBLIC_API_URL ?? "http://localhost:8008";
```

**`process.env.EXPO_PUBLIC_…` is not read when the app runs.** A phone has no environment variables for an
app; Metro replaces the expression with the variable's value, as text, when it builds the bundle. Look for
the address in the release bundle exported a moment ago, and then build one with the variable set:

```
ana@dev:~/planner$ grep -a -o 'http://localhost:8008' dist-release/_expo/static/js/android/*
http://localhost:8008
ana@dev:~/planner$ EXPO_PUBLIC_API_URL=https://planner.example.org npx expo export --platform android --output-dir dist-env > /dev/null 2>&1
ana@dev:~/planner$ grep -a -o 'https://planner.example.org\|http://localhost:8008' dist-env/_expo/static/js/android/*
https://planner.example.org
```

**The first release carries `http://localhost:8008`**, the fallback, because the variable was not set in
the terminal that built it. On a phone, `localhost` is the phone itself, where no server runs, so every
request fails, and the developer's own development build, started from a terminal that had the variable,
works perfectly. **The second carries `https://planner.example.org` and no fallback at all**: the value was
fixed in, and the `??` folded away with the branch that could no longer happen.

That is the most common bug of this whole lesson: a release built on another machine, a build server or a
colleague's laptop, without the variable. Three habits prevent it:

- **Never let the fallback be a working value for anything but your own machine.** `localhost` looks
  harmless and is exactly what makes the bug silent.
- **Write the release's values where the release is built**, in the build service's environment, which
  lesson 20 shows for EAS Build, rather than in a terminal somebody has to remember to prepare.
- **Remember it is public.** `EXPO_PUBLIC_` means what it says: the value is text inside the app, readable
  by anybody who unpacks it, as the `grep` just did. An address is fine. A secret never goes there.

The three exports can go: `rm -rf dist-dev dist-release dist-env`.
