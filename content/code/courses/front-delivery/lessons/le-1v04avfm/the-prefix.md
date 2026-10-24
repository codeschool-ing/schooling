---
title: The prefix that decides what reaches the browser
version: 1
---

**Vite puts a variable into the bundle only if its name starts with `VITE_`.** Everything else in the
environment and in the `.env` files stays out, whatever the code asks for. The prefix is a fence between
two kinds of value that live in the same files and the same shell. Some are meant for the page. Others
are meant for the machine that builds it, such as a token for a deploy tool or a password for a
registry.

## A variable without the prefix

Put a variable without the prefix in `.env.local`, and make the planner print it, as a careless line of
code might:

```
ana@dev:~/planner$ echo 'SUPPORT_TOKEN=tok-demo-not-a-real-secret' > .env.local
ana@dev:~/planner$ echo 'console.log("token:", import.meta.env.SUPPORT_TOKEN);' >> src/main.ts
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ grep -o 'token:[^)]*' dist/assets/*.js
token:`,void 0
```

The value never reached the bundle. Vite saw `import.meta.env.SUPPORT_TOKEN`, found no exposed variable
of that name, and wrote `void 0`, which is JavaScript for `undefined`. **The code asked for it and the
build refused to hand it over**, without an error, because a missing variable is a normal thing for code
to ask about.

## Turning the fence off

The prefix is a setting, `envPrefix` in `vite.config.ts`, and it can be changed to another word. It
cannot be removed. Set it to an empty string, which would expose every variable the build can see, and
Vite stops:

```
ana@dev:~/planner$ echo 'export default { envPrefix: "" };' > vite.config.ts
ana@dev:~/planner$ npx vite build 2>&1 | head -2
error during build:
Error: envPrefix option contains value '', which could lead unexpected exposure of sensitive information.
```

The message names the reason. Remove the file again; the planner keeps Vite's default:

```
ana@dev:~/planner$ rm vite.config.ts
```

## What the prefix does not protect

The prefix decides what the build copies into the bundle. It says nothing about whether the value
should be there. A variable called `VITE_` anything is copied in **because its name says so**, and the
name is the only thing Vite looks at. The next section shows what that means for the line of code above,
when somebody "fixes" it the obvious way.

Other build tools use the same idea under other names: `NEXT_PUBLIC_` in Next.js, `NG_APP_` in some
Angular setups, `PUBLIC_` in SvelteKit, `VITE_` in Vue and React projects built with Vite. Whatever the
word is, it marks a value as one you have agreed to publish.
