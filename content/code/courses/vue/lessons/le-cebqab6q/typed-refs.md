---
title: Typed refs, the store and the router
version: 1
---

**A ref's type is usually inferred from its starting value, and has to be written when the starting
value says too little**: an empty array, `null`, or an element that does not exist yet. Those three are
almost all the remaining errors, and each has a small, standard fix.

## An empty array: say what it will hold

`ref([])` starts as an array of nothing, which TypeScript calls `never[]`, and nothing can be read from a
`never`. The store says what its arrays will hold, with a type argument:

```typescript
const courses = ref<Course[]>([])
const sessions = ref<Session[]>([])
```

with `type Course` and `type Session` added to the store's import from `../planner.js`, and the actions'
parameters typed like any function's: `hasCourse`'s `(id: string)`, `toggle(id: string)`,
`add(session: Omit<Session, 'id' | 'done'>)`, and `let loading: Promise<void> | null = null`. That one
change to the store fixes the errors in every view, because the views read the store, and **their types
follow from it with nothing written in them**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Where the planner&#x27;s types are written and where they are only inferred. planner.ts declares Course and Session. The store writes ref of Course array and ref of Session array, once. The views and the components read the store and receive those types with nothing written in them; SessionRow names Session in its props because it is given one by its parent.\"><rect x=\"20\" y=\"40\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">planner.ts</text><text x=\"120\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">interface Session</text><text x=\"120\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">written</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">stores/planner.ts</text><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ref&lt;Session[]&gt;([])</text><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">written once</text><rect x=\"500\" y=\"40\" width=\"200\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">HomeView.vue</text><text x=\"600\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sessions.value</text><text x=\"600\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">inferred</text><line x1=\"222\" y1=\"75\" x2=\"258\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"258.0,75.0 250.6,78.1 250.6,71.9\" fill=\"var(--wire)\"></polygon><line x1=\"462\" y1=\"75\" x2=\"498\" y2=\"75\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"498.0,75.0 490.6,78.1 490.6,71.9\" fill=\"var(--wire)\"></polygon><rect x=\"500\" y=\"150\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SessionRow: session: Session</text><line x1=\"600\" y1=\"112\" x2=\"600\" y2=\"148\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"600.0,148.0 596.9,140.6 603.1,140.6\" fill=\"var(--wire)\"></polygon></svg>", "caption": "The types are written where the data is born, and every reader after it gets them for free."}
```

## Something that may not be there yet: `?.`

`useTemplateRef('dialog')` is `null` until the component mounts, as lesson 9 showed, so the checker
insists on the possibility:

```typescript
const dialog = useTemplateRef<HTMLDialogElement>('dialog')
defineExpose({
  open: () => dialog.value?.showModal(),
  close: () => dialog.value?.close(),
})
```

`<HTMLDialogElement>` says which element it will be, so `showModal` is known to exist; `?.` calls it only
if the ref is filled. The same two changes go into `SessionForm`, `useTemplateRef<HTMLSelectElement>
('course')` and `courseField.value?.focus()`, and into `HomeView`, whose ref holds a component:
`useTemplateRef<InstanceType<typeof PlannerDialog>>('adding')`, which is how a template ref to a
component is typed, with `adding.value?.close()` in the script and `adding?.open()` in the template.

## A timer, a route, a message

The last few are one line each. The third row is not among the 59: it appears once the second is
fixed, because until then `to` has no type to complain about.

| error | where | fix |
|---|---|---|
| `timer` implicitly `any` | `useToday.ts` | the type of what `setInterval` returns, below the table |
| `to` implicitly `any` | `router.ts` | `const routes: RouteRecordRaw[] = [...]`, with `type RouteRecordRaw` imported from `vue-router`, so each route's guard gets its type |
| a parameter that may be a list, given where a string is expected | `router.ts`'s guard | `planner.hasCourse(String(to.params.id))`: a parameter can repeat, so the router types it as either |
| `message` implicitly `any` | `HomeView.vue`'s `onAdded` | `function onAdded(message: string)` |
| `shown.course` does not exist on `{}` | `SessionForm.vue` | a named type for the messages, below |

The timer is declared `let timer: ReturnType<typeof setInterval> | undefined`: whatever
`setInterval` returns, or nothing before the component mounts. And `SessionForm` names the shape of its
messages once, and uses it for both computed values:

```typescript
type Errors = Record<'course' | 'date' | 'minutes', string>

const errors = computed<Errors>(() => ({
```

and `const shown = computed<Partial<Errors>>(() => (tried.value ? errors.value : {}))`, where
`Partial` says that any of the three may be missing, which is exactly what an empty `{}` is. With
these, the checker runs clean:

```
ana@dev:~/vue/planner$ npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit
```
