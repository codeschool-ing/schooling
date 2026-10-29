---
title: The planner, the context and the components
version: 1
---

**The planner class is where types pay most**, because every page reads it. Rename it, and the two small
modules beside it:

```
ana@dev:~/planner$ git mv src/lib/planner.svelte.js src/lib/planner.svelte.ts
ana@dev:~/planner$ git mv src/lib/context.js src/lib/context.ts
ana@dev:~/planner$ git mv src/lib/flash.js src/lib/flash.ts
```

A file whose name ends in `.svelte.ts` is TypeScript that may use runes, as `.svelte.js` was
JavaScript that may. Replace `src/lib/planner.svelte.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/planner.svelte.ts", "parts": [
 {"code": "// planner.svelte.ts: the planner's rules, over data that arrives from the load functions.\nimport { inWeek } from '#lib/week.js';\nimport type { Course, Session } from '#lib/types.js';"},
 {"code": "/** What the planner reads: the file's data, and the week the address asks for. */\nexport interface PlannerSource {\n\tcourses: Course[];\n\tsessions: Session[];\n\tweek: string;\n}", "note": "What the planner reads is the file's data plus the week from the address: what `+layout.ts` returns."},
 {"code": "export class Planner {\n\t#data: () => PlannerSource;\n\n\tcourses = $derived.by(() => this.#data().courses);\n\tsessions = $derived.by(() => this.#data().sessions);\n\tweek = $derived.by(() => this.#data().week);", "note": "`$derived.by` takes a function, where lesson 14 wrote the expression itself. Both are worked out later, when first read; the function form says so in a way the checker can see, and without it TypeScript objects that `#data` is read before the constructor has set it."},
 {"code": "\n\tthisWeek = $derived(this.sessions.filter((s) => inWeek(s.date, this.week)));\n\ttotal = $derived(minutesOf(this.thisWeek));\n\tdoneMinutes = $derived(minutesOf(this.thisWeek.filter((s) => s.done)));\n\tbyCourse = $derived(totalsBy(this.thisWeek, 'course'));\n\tbyDay = $derived(totalsBy(this.thisWeek, 'date'));\n\n\tconstructor(data: () => PlannerSource) {\n\t\tthis.#data = data;\n\t}\n\n\tcourse(id: string) {\n\t\treturn this.courses.find((c) => c.id === id);\n\t}\n\n\tsessionsFor(id: string) {\n\t\treturn this.thisWeek.filter((s) => s.course === id).toSorted((a, b) => (a.date < b.date ? -1 : 1));\n\t}\n}\n\nfunction minutesOf(sessions: Session[]) {\n\treturn sessions.reduce((sum, s) => sum + s.minutes, 0);\n}\n\nfunction totalsBy(sessions: Session[], field: 'course' | 'date') {\n\tconst minutes: Record<string, number> = {};\n\tfor (const s of sessions) minutes[s[field]] = (minutes[s[field]] ?? 0) + s.minutes;\n\treturn minutes;\n}"}
]}
```

`src/lib/context.ts` says what the context holds, which is what makes `getPlanner()` return a `Planner`
in every component that calls it:

```schooling-example
{"language": "typescript", "file": "src/lib/context.ts", "parts": [
 {"code": "// context.ts: the planner, shared with the pages inside PlannerProvider.svelte.\nimport { createContext } from 'svelte';\nimport type { Planner } from '#lib/planner.svelte.js';\n\nexport const [getPlanner, setPlanner] = createContext<Planner>();", "note": "`createContext<Planner>()` passes the type in. Without it, the planner would be `unknown` to every component that gets it."}
]}
```

and `src/lib/flash.ts` takes its types from `svelte/transition`:

```schooling-example
{"language": "typescript", "file": "src/lib/flash.ts", "parts": [
 {"code": "// flash.ts: a highlight behind an element, fading out as it arrives.\nimport type { TransitionConfig } from 'svelte/transition';\n\nexport function flash(node: Element, { duration = 600 } = {}): TransitionConfig {\n\treturn {\n\t\tduration,\n\t\tcss: (t) => `background-color: rgb(255 215 0 / ${(1 - t) * 0.6})`\n\t};\n}", "note": "`TransitionConfig` is the type of what a transition function returns, so `t` in `css` is known to be a number."}
]}
```

## Components with lang="ts"

**A component's script is TypeScript when its tag says `lang="ts"`**, and the most useful thing to type
in it is its props, the component's contract with whoever uses it. Two components had errors. Replace
`src/lib/PlannerProvider.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/PlannerProvider.svelte", "parts": [
 {"code": "<script lang=\"ts\">\n\timport type { Snippet } from 'svelte';\n\timport { goto } from '$app/navigation';\n\timport { addDays } from '#lib/week.js';\n\timport { Planner, type PlannerSource } from '#lib/planner.svelte.js';\n\timport { setPlanner } from '#lib/context.js';\n\n\tlet { data, children }: { data: PlannerSource; children: Snippet } = $props();\n\n\tconst planner = setPlanner(new Planner(() => data));\n\n\tfunction shortcut(event: KeyboardEvent) {\n\t\tif ((event.target as Element).closest('input, textarea, select')) return;\n\t\tconst days = { ArrowLeft: -7, ArrowRight: 7 }[event.key];\n\t\tif (days) goto(`?week=${addDays(planner.week, days)}`, { reset: false });\n\t}\n</script>\n\n<svelte:window onkeydown={shortcut} />\n\n{@render children()}", "note": "The props are typed where they are taken: `$props()` returns whatever the type after the colon says. `Snippet` is the type of `children`, a piece of markup to render."}
]}
```

and `src/lib/AddSession.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script lang=\"ts\">\n\timport { enhance, type SubmitFunction } from '$app/forms';\n\timport { page } from '$app/state';\n\n\tlet { action }: { action: string } = $props();\n\tlet form = $derived(page.form);\n\tlet sending = $state(false);\n\n\tconst submit: SubmitFunction = () => {\n\t\tsending = true;\n\t\treturn async ({ update }) => {\n\t\t\tawait update();\n\t\t\tsending = false;\n\t\t};\n\t};\n</script>\n\n<form method=\"POST\" {action} use:enhance={submit}>\n\t{#if form?.problem}\n\t\t<p role=\"alert\">{form.problem}</p>\n\t{/if}\n\t<label>Date <input type=\"date\" name=\"date\" required value={form?.date ?? ''} /></label>\n\t<label>Minutes <input type=\"number\" name=\"minutes\" min=\"5\" max=\"600\" step=\"5\" required value={form?.minutes ?? 30} /></label>\n\t<button disabled={sending}>{sending ? 'Adding…' : 'Add session'}</button>\n</form>", "note": "`SubmitFunction` from `$app/forms` is the type of the function `use:enhance` takes, so `update` in the callback is typed too."}
]}
```

```
ana@dev:~/planner$ npm run check 2>&1 | grep -B1 -A3 Error
/home/ana/planner/src/routes/(planner)/courses/[id=slug]/+page.svelte:23:16
Error: Parameter 'session' implicitly has an 'any' type. (js)
<List items={sessions}>
	{#snippet row(session)}
		<form method="POST" action="?week={planner.week}&/done" use:enhance>
```

**One left**, in a file nobody has converted, and the next section finds that its cause is somewhere
else.
