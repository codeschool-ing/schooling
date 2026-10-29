---
title: The library, in a repository of its own
version: 1
---

**The library starts as a copy, once, into a new folder that becomes its own repository**, and from then
on it is the only copy: at the end of the lesson the planner deletes its own and installs the package.
The pieces are the ones lessons 5 and 6 wrote: the token files and their scripts, the components and the
duration formatter they use.

```
ana@dev:~$ mkdir -p ~/planner-ui/src && cd ~/planner-ui
ana@dev:~/planner-ui$ cp ../planner/tokens.json ../planner/tokens.mjs ../planner/contrast.mjs .
ana@dev:~/planner-ui$ cp ../planner/src/components.ts ../planner/src/format.ts src/
ana@dev:~/planner-ui$ git init -q
ana@dev:~/planner-ui$ find . -path ./.git -prune -o -type f -print | sort
./contrast.mjs
./src/components.ts
./src/format.ts
./tokens.json
./tokens.mjs
```

## What the library must not depend on

`components.ts` imported the `Session` type from the planner's `planner.ts`. A library that imports from an
app is not a library, so it gets a type of its own with the same shape, and the import is pointed at it:

```typescript
// src/types.ts
export interface Session {
  id: number;
  course: string;
  date: string;
  minutes: number;
  done: boolean;
}
```

```
ana@dev:~/planner-ui$ sed -i 's#"./planner"#"./types"#' src/components.ts
ana@dev:~/planner-ui$ grep -n import src/components.ts
2:import { duration } from "./format";
3:import type { Session } from "./types";
```

**The library's types describe what its components need, not what an app happens to have.** If the
teachers' app has sessions with more fields, they still fit, because TypeScript compares shapes: an object
with extra fields satisfies an interface that lists fewer.

## One entry point

A package has a front door, the file that says what it offers. Everything not exported from it is
private, and can change without anybody depending on it:

```typescript
// src/index.ts
export { actionButton, sessionRow, weekSummary } from "./components";
export { duration } from "./format";
export type { Session } from "./types";
```

Three components, the formatter they use, and the type. **This list is the library's public interface**,
and the section on versions is about what it costs to change it.
