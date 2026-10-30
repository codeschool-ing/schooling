---
title: TypeScript, part 2, classes, generics and decorators
version: 1
---

**Every Angular component, service, pipe and directive is a class with a decorator on top.** The
previous section gave values their types; this one covers the three pieces of TypeScript an Angular
file uses on its first line and every line after: classes with access modifiers, generics, and
decorators.

## A class, with what TypeScript adds to it

`javascript` taught classes: a constructor, fields, methods, `get`. TypeScript adds words that say
who may touch what, and, like the types, they are checked by the compiler and erased afterwards.

```schooling-example
{"language": "typescript", "file": "week.ts", "parts": [
 {"code": "interface Session {\n  courseId: string;\n  minutes: number;\n  done: boolean;\n}", "note": "The shape of one session, kept to what this example needs."},
 {"code": "class Week {\n  private readonly sessions: Session[] = [];", "note": "`private` means only code inside `Week` may use the field, and `readonly` means not even that code may point it at a different array after it is set. Pushing into the array is still allowed: the field is fixed, the array is not."},
 {"code": "  constructor(readonly label: string) {}\n\n  add(s: Session): void {\n    this.sessions.push(s);\n  }", "note": "A **parameter property**: `readonly` in front of a constructor parameter declares a field and fills it in one move. Angular code uses this shape constantly, so learn to read it."},
 {"code": "  get total(): number {\n    return this.sessions.reduce((sum, s) => sum + s.minutes, 0);\n  }\n}\n\nconst week = new Week(\"19 to 25 October\");\nweek.add({ courseId: \"javascript\", minutes: 60, done: true });\nweek.add({ courseId: \"git\", minutes: 25, done: false });\nconsole.log(week.label, week.total);", "note": "A getter: read as `week.total`, without parentheses, and computed each time."},
 {"code": "week.sessions = [];", "note": "From outside the class, both rules apply at once, and the compiler refuses this line."}
]}
```

```
ana@dev:~/ts$ npx tsc --noEmit --strict week.ts
week.ts(22,6): error TS2341: Property 'sessions' is private and only accessible within class 'Week'.
week.ts(22,6): error TS2540: Cannot assign to 'sessions' because it is a read-only property.
```

Two messages for one line, because the line breaks two rules. Delete it and the check passes.
`private` is a promise the compiler keeps, not the browser: in the JavaScript that runs, the field is
an ordinary property. Lesson 6 shows Angular code using `protected` and `readonly` together on almost
every field a template reads.

## Generics: a type with a blank in it

Some code works the same way for any type of value. A function that returns the first item of a
list does not care what the items are, but its caller does: the first of a list of numbers is a
number. A **generic** keeps that connection with a type parameter, written in angle brackets:

```typescript
// first.ts
function first<T>(list: T[]): T | undefined {
  return list[0];
}

const minutes = first([45, 60]);
const course = first(["git", "javascript"]);
const wrong: string | undefined = first([45, 60]);
```

Read `<T>` as "for some type T". Called with `[45, 60]`, T is `number`, so `minutes` is
`number | undefined`; called with strings, T is `string`. The third line asks for a string and gets
a number:

```
ana@dev:~/ts$ npx tsc --noEmit --strict first.ts
first.ts(8,7): error TS2322: Type 'number | undefined' is not assignable to type 'string | undefined'.
  Type 'number' is not assignable to type 'string'.
```

You will write few generics of your own in this course, and read them on every page. Angular's
`signal<number>(0)` in lesson 6 is a value that holds numbers, `input<Session>()` in lesson 8 is an
input that takes a session, and `http.get<Course[]>(url)` in lesson 12 is a request whose answer is
claimed to be a list of courses. Lesson 12 is also where you learn why *claimed* is the right word.

## Decorators: a function applied to a class

A **decorator** is the `@Something(...)` written above a class. It is a function, called once
when the class is defined, that receives the class and may record something about it. This one
prints what it was given:

```typescript
// label.ts
function Labelled(label: string) {
  return function (target: Function) {
    console.log(`${label} is ${target.name}`);
  };
}

@Labelled("the planner")
class Planner {}

console.log(new Planner());
```

Node's built-in TypeScript support only removes types; it does not rewrite syntax, and a decorator
is syntax JavaScript in Node 22 does not have:

```
ana@dev:~/ts$ node label.ts
/home/ana/ts/label.ts:8
@Labelled("the planner")
^

SyntaxError: Invalid or unexpected token
    at wrapSafe (node:internal/modules/cjs/loader:1638:18)
    at Module._compile (node:internal/modules/cjs/loader:1680:20)
    at Object..js (node:internal/modules/cjs/loader:1839:10)
    at Module.load (node:internal/modules/cjs/loader:1441:32)
    at Function._load (node:internal/modules/cjs/loader:1263:12)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49

Node.js v22.22.0
```

So this file has to be compiled first. `--experimentalDecorators` selects the kind of decorator
Angular uses, `--target es2022` the version of JavaScript to write, and `--outDir out` where:

```
ana@dev:~/ts$ npx tsc --strict --target es2022 --experimentalDecorators --outDir out label.ts
ana@dev:~/ts$ node out/label.js
the planner is Planner
Planner {}
```

The decorator ran before `new Planner()` did, as the class was being defined. **`@Component` is
this**, with more inside: it receives your class and a description of it, the selector, the
template, the styles, and Angular reads that description to know how to build and draw the class.
The `@Labelled` above prints; `@Component` records. Lesson 3 reads every field of the description.

One more thing happens in a real Angular build. The CLI's compiler reads the decorators **ahead of
time**, at build time, and turns each template into JavaScript that creates the DOM directly. The
browser never sees `@Component` at all, which is one reason an Angular application can be smaller
than its source suggests.
