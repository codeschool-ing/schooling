---
title: TypeScript, part 1, types on values
version: 1
---

**TypeScript is JavaScript with types written beside the values, and a compiler that checks them
before the program runs.** Then the types are thrown away. Nothing about them survives into the
browser: what runs is the JavaScript you already know from `javascript`, minus the annotations.
That one fact explains most of what surprises people about TypeScript, so this section shows it
before anything else.

## A folder to try it in

TypeScript is an npm package. Lesson 2's project will bring its own copy; this one is only for these
two sections, at the same version Angular 21 uses:

```
ana@dev:~$ mkdir ~/ts
ana@dev:~$ cd ~/ts
ana@dev:~/ts$ npm init -y > /dev/null
ana@dev:~/ts$ npm install --save-exact typescript@5.9.3

added 1 package, and audited 2 packages in 759ms

found 0 vulnerabilities
ana@dev:~/ts$ du -sh ~/ts
23M	/home/ana/ts
```

`--save-exact` writes `5.9.3` into `package.json` rather than `^5.9.3`, so the next `npm install`
in this folder takes the same version and not whatever is newest that day. Lesson 2 makes the same
choice for the whole project.

## Types are checked, then erased

Save this as `~/ts/hello.ts`. The last line is wrong on purpose: `label` asks for a number and is
given a string.

```typescript
// hello.ts
const minutes: number = 45;

function label(m: number): string {
  return m + " min";
}

console.log(label(minutes));
console.log(label("45"));
```

`: number` after a name is a **type annotation**: it says what the value is allowed to be. After the
parentheses of a function, it says what the function returns. Node 22 can run a `.ts` file directly,
and here is what it does with this one:

```
ana@dev:~/ts$ node hello.ts
45 min
45 min
```

Both lines printed. **Node removed the annotations and ran the rest**, and the rest is valid
JavaScript: `"45" + " min"` is a string like any other. Running is not checking. The compiler, `tsc`,
is the one that reads the types:

```
ana@dev:~/ts$ npx tsc --noEmit --strict hello.ts
hello.ts(9,19): error TS2345: Argument of type 'string' is not assignable to parameter of type 'number'.
ana@dev:~/ts$ echo $?
2
```

`hello.ts(9,19)` is line 9, column 19: the `"45"`. `--noEmit` asks for the check without writing
any JavaScript out, and `--strict` turns on the checks every Angular project has on; lesson 2's
`tsconfig.json` says so in its first line of options. An exit code of 2 is how a build script knows
the check failed.

**This is the whole bargain.** You write more, and a class of mistakes stops reaching the browser.
In an Angular project you never call `tsc` yourself: `ng build` and `ng serve` run the same check
over every file, and over every template too, from lesson 4 on.

## Most types are inferred

Writing `: number` on `minutes` was not needed. TypeScript sees `45` and decides; hovering over the
name in an editor shows `const minutes: 45`, a type even narrower than `number`, because a `const`
can never be anything else. Annotate the places where the compiler cannot see the answer: function
parameters, and anything that starts empty and is filled later.

## The shape of an object

The planner this course builds keeps study sessions. An **interface** names the shape of one:

```typescript
// session.ts
interface Session {
  id: number;
  courseId: string;
  date: string;
  minutes: number;
  done: boolean;
  note?: string;
}

const sessions: Session[] = [
  { id: 1, courseId: "javascript", date: "2026-10-20", minutes: 60, done: true },
  { id: 2, courseId: "git", date: "2026-10-22", minutes: 25, done: false },
];

function total(list: Session[]): number {
  return list.reduce((sum, s) => sum + s.minutes, 0);
}

function pending(list: Session[]): Session[] {
  return list.filter((s) => !s.done);
}

console.log(total(sessions), pending(sessions).length);
console.log(sessions[0].minuts);
```

`note?:` is optional: an object without it is still a `Session`. `Session[]` is an array of them.
The last line has a typo, and the checker names it and guesses what you meant:

```
ana@dev:~/ts$ npx tsc --noEmit --strict session.ts
session.ts(25,25): error TS2551: Property 'minuts' does not exist on type 'Session'. Did you mean 'minutes'?
```

Node would have printed `undefined` for that line and carried on. In an application, that
`undefined` is a blank where a number should be, found by somebody looking at the screen.

## Several possibilities, and narrowing

A type can be a list of exact values. A session's state could be written

```typescript
type State = "planned" | "done" | "skipped";
```

and a variable of type `State` then accepts those three strings and refuses `"Done"`. The `|`
reads as *or*: `string | undefined` is a string or nothing, which is what TypeScript says
`sessions.find(...)` returns, because the search may find nothing. Before you use the result, you
check:

```typescript
const next = sessions.find((s) => !s.done);
if (next) {
  console.log(next.minutes); // inside the if, next is a Session
}
```

Inside the `if`, the compiler knows `next` is not `undefined` and lets you read `.minutes`; outside,
it refuses. That is called **narrowing**, and with `--strict` on you meet it in every lesson: an
input that may not be set yet, a route parameter that may be missing, a server answer that may be an
error.
