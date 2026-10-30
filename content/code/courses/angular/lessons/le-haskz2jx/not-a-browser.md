---
title: The server is not a browser
version: 1
---

**On the server there is no window, no `localStorage`, no layout and no focus, and code that
reaches for them fails there.** Restart the dev server, Ctrl-C and `npx ng serve`, so its terminal
starts clean, and open a course's page:

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Angular hydrated 15 component(s) and 108 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
Hide sessions that are done
Tue 13 Oct, 45 minutes
Tue 20 Oct, 1 hour
Sat 24 Oct, 50 minutes
```

The page is right. The terminal is not:

```
ana@dev:~/planner$ npx ng serve
❯ Building...
✔ Building...
Browser bundles     
Initial chunk files  | Names            |  Raw size
main.js              | main             |  25.04 kB | 
styles.css           | styles           |   8.81 kB | 
chunk-VL5AOURQ.js    | -                |   6.21 kB | 
polyfills.js         | polyfills        | 172 bytes | 

                     | Initial total    |  40.24 kB

Lazy chunk files     | Names            |  Raw size
chunk-CVOEV7ZX.js    | courses-routes   |  40.42 kB | 


Server bundles      
Initial chunk files  | Names            |  Raw size
main.server.mjs      | main.server      |  26.30 kB | 
chunk-5G2P2OON.mjs   | -                |   6.24 kB | 
server.mjs           | server           |   1.84 kB | 
polyfills.server.mjs | polyfills.server | 363 bytes | 

Lazy chunk files     | Names            |  Raw size
chunk-4PI5SPPZ.mjs   | courses-routes   |  40.46 kB | 

Application bundle generation complete. [2.776 seconds] - 2026-10-23T12:00:03.421Z

Watch mode enabled. Watching for file changes...
NOTE: Raw file sizes do not reflect development server per-request transformations.
  ➜  Local:   http://localhost:4200/
Preferences will last this visit only: ReferenceError: localStorage is not defined
    at map (/home/ana/planner/src/app/preferences.ts:26:9)
    at Object.eval (/home/ana/planner/.angular/cache/21.2.29/planner/vite/deps_ssr/chunk-5IER7EOY.js:4208:5)
    at runEffect (/home/ana/planner/.angular/cache/21.2.29/planner/vite/deps_ssr/chunk-5IER7EOY.js:1033:10)
    at Object.run (/home/ana/planner/.angular/cache/21.2.29/planner/vite/deps_ssr/chunk-5IER7EOY.js:4132:7)
    at ZoneAwareEffectScheduler.flushQueue (/home/ana/planner/.angular/cache/21.2.29/planner/vite/deps_ssr/chunk-5IER7EOY.js:4066:14)
    at ZoneAwareEffectScheduler.flush (/home/ana/planner/.angular/cache/21.2.29/planner/vite/deps_ssr/chunk-5IER7EOY.js:4048:33)
    at _ApplicationRef.synchronizeOnce (/home/ana/planner/.angular/cache/21.2.29/planner/vite/deps_ssr/chunk-HGKWEPPS.js:12413:32)
    at _ApplicationRef.synchronize (/home/ana/planner/.angular/cache/21.2.29/planner/vite/deps_ssr/chunk-HGKWEPPS.js:12401:14)
    at _ApplicationRef.tickImpl (/home/ana/planner/.angular/cache/21.2.29/planner/vite/deps_ssr/chunk-HGKWEPPS.js:12376:12)
    at _ApplicationRef._tick (/home/ana/planner/.angular/cache/21.2.29/planner/vite/deps_ssr/chunk-HGKWEPPS.js:12364:12)
```

`Preferences`, from lesson 22, writes the preference to `localStorage` in an effect, and effects run
on the server as they do in the browser. Node.js has no `localStorage`, the call throws, and the
`catch` lesson 22 wrote turns the error into the warning. Nothing broke, which is what that `catch`
was for. But the warning is false: no visit is losing anything, and it is printed for every course
page anybody opens. Reading at the start is already safe, because `read()` catches the same error
and answers the defaults.

The service should not touch storage on the server at all. Angular says where the code is running
through a token, `PLATFORM_ID`, and `isPlatformBrowser` reads it:

```schooling-example
{"language": "typescript", "file": "src/app/preferences.ts", "parts": [
 {"code": "// src/app/preferences.ts\nimport { Injectable, PLATFORM_ID, computed, effect, inject, signal } from '@angular/core';\nimport { isPlatformBrowser } from '@angular/common';\n\nconst KEY = 'planner.preferences';\n\ninterface Saved {\n  hideDone: boolean;\n}\nfunction read(): Saved {\n  try {\n    const saved = JSON.parse(localStorage.getItem(KEY) ?? '{}');\n    return { hideDone: saved?.hideDone === true };\n  } catch {\n    return { hideDone: false };\n  }\n}\n@Injectable({ providedIn: 'root' })\nexport class Preferences {", "note": "`PLATFORM_ID` comes from `@angular/core`, the test for it from `@angular/common`."},
 {"code": "  private readonly inBrowser = isPlatformBrowser(inject(PLATFORM_ID));\n  private readonly state = signal<Saved>(this.inBrowser ? read() : { hideDone: false });\n  readonly hideDone = computed(() => this.state().hideDone);", "note": "Asked once, when the service is made. On the server the preferences start as the defaults, without trying."},
 {"code": "  constructor() {\n    if (!this.inBrowser) return;\n    effect(() => {\n      const saved = JSON.stringify(this.state());\n      try {\n        localStorage.setItem(KEY, saved);\n      } catch (error) {\n        console.warn('Preferences will last this visit only:', error);\n      }\n    });\n  }", "note": "And the effect that writes is created only in a browser. The `catch` stays, for a browser that blocks storage."},
 {"code": "  setHideDone(hide: boolean): void {\n    this.state.update((saved) => ({ ...saved, hideDone: hide }));\n  }\n}"}
]}
```

The next course page renders with nothing in the terminal.

## What the server cannot know

The server now renders every course page with the defaults, because the preference lives in a
browser the server has never seen. A person who hides the sessions that are done gets three
sessions in the HTML and one on the screen:

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do 'check Hide sessions that are done' --do 'go /courses/javascript'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Angular hydrated 15 component(s) and 108 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
-- check Hide sessions that are done
-- go /courses/javascript
[vite] connecting...
Angular is running in development mode.
[vite] connected.
Angular hydrated 9 component(s) and 72 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
Hide sessions that are done
Sat 24 Oct, 50 minutes
```

```
ana@dev:~/planner$ curl -s http://localhost:4200/courses/javascript | grep -o '[A-Z][a-z][a-z] [0-9]* Oct, [^<]*'
Tue 13 Oct, 45 minutes 
Tue 20 Oct, 1 hour 
Sat 24 Oct, 50 minutes 
```

The browser reads the preference as it hydrates and draws its own list, and Angular replaces the
server's rows with it. For a moment, on a slow connection, the done sessions are visible and then
vanish. For a preference about tidiness that is a fair price. A preference that must be right in
the first HTML, a language or a dark theme, has to reach the server with the request, and the one
thing every request carries is its cookies: such a preference belongs in a cookie, not in
`localStorage`.

## What runs only in the browser

Lesson 9 said that `afterNextRender` and `ngAfterViewInit` run only in the browser, and this is
where that matters. The `Autofocus` directive of lesson 20 calls `focus()` inside `afterNextRender`,
so on the server it does nothing and needs no test of where it is. The form's page from the server
has no focus anywhere; in the browser, the first date field has it:

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --no-js --a11y 'app-add-session form' | head -5
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1"
```

```
ana@dev:~/planner$ look http://localhost:4200/courses/git/add --a11y 'app-add-session form' | head -9
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Angular hydrated 3 component(s) and 56 node(s), 0 component(s) were skipped. Learn more at https://v21.angular.dev/guide/hydration.
- form
  - heading "Add sessions" [level=3]
  - LabelText
    - text: Date 1
  - Date "Date 1" [focused]
```

**That is the rule for code that needs a browser: put it where Angular runs only in the browser.**
`afterNextRender` for anything that needs the page drawn, an event listener for anything a person
does, `isPlatformBrowser` for the rest. On the server, `window`, `document` and `localStorage` are all
`undefined`: Angular builds the HTML in a small imitation of the DOM, which a component reaches
through its own elements or the `DOCUMENT` token, never through the globals. A bare `window`
outside those places is the usual way an application breaks the first time it is rendered on a
server.

## Two clocks

`TODAY`, since lesson 10, is `new Date()`, and on the server that is the server's clock, in the
server's time zone. The week in the HTML is the server's week. A student in São Paulo at 22:00 on a
Sunday is still in their week; a server keeping UTC is already at 01:00 on Monday, and sends the
next one. The browser computes its own `TODAY`, draws its own week, and the page changes under the
student's eyes. The planner does not settle this, and it is worth knowing it is there: anything
computed from "now" is computed twice, on two clocks.
