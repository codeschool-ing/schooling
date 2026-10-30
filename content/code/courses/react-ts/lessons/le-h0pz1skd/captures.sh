#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 23's captures.sh
#
# Works in ana's home, beside ~/planner, which it does not touch: four small
# projects, one per framework, each made by that framework's own tool and
# pinned like lesson 1's. What is STAGED rather than typed: the files ana
# wrote, put below and shown in the lesson. The lab's environment sets
# NG_CLI_ANALYTICS=false, so the Angular CLI does not stop to ask whether it
# may collect usage data.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-k68qr0mk
CWD=
CLICKS="--do 'click button Python · 35 min' --do 'click button Statistics · 45 min'"

block react-new
on 'npm create vite@9.3.1 sessions-react -- --template react-ts --no-interactive > /dev/null && cd sessions-react && npm config set save-exact true --location=project && npm install --silent react@19.3.1 react-dom@19.3.1 && npm install --silent --save-dev typescript@6.0.3 vite@8.3.5 @vitejs/plugin-react@6.1.2 @types/react@19.3.0 @types/react-dom@19.3.0 @types/node@22.20.5 oxlint@1.88.0 && ls src'
CWD=sessions-react
block react-file
put src/Sessions.tsx <<'X'
import { useState } from 'react'

type Session = { id: string; course: string; minutes: number; done: boolean }

const week: Session[] = [
  { id: 's1', course: 'Statistics', minutes: 40, done: true },
  { id: 's2', course: 'Python', minutes: 35, done: false },
  { id: 's3', course: 'Statistics', minutes: 45, done: false },
]

export function Sessions() {
  const [sessions, setSessions] = useState(week)
  const done = sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0)
  const total = sessions.reduce((sum, s) => sum + s.minutes, 0)
  console.log('Sessions ran')

  function toggle(id: string) {
    setSessions(sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }

  return (
    <section>
      <h1>This week</h1>
      <p>
        {done} of {total} minutes done
      </p>
      <ul>
        {sessions.map((s) => (
          <li key={s.id}>
            <button aria-pressed={s.done} onClick={() => toggle(s.id)}>
              {s.course} · {s.minutes} min
            </button>
          </li>
        ))}
      </ul>
    </section>
  )
}
X
put src/App.tsx <<'X'
import { Sessions } from './Sessions'

export default function App() {
  return <Sessions />
}
X
block react-run
on 'rm src/App.css && npm run build'
serve 4173 npm run preview
on "look http://localhost:4173/ $CLICKS"
stop

CWD=
block vue-new
on 'npm create vite@9.3.1 sessions-vue -- --template vue-ts --no-interactive > /dev/null && cd sessions-vue && npm config set save-exact true --location=project && npm install --silent vue@3.5.44 && npm install --silent --save-dev typescript@6.0.3 vite@8.3.5 @vitejs/plugin-vue@6.0.10 @vue/tsconfig@0.9.1 @types/node@22.20.5 vue-tsc@3.3.13 && rm src/components/HelloWorld.vue && ls src src/components'
CWD=sessions-vue
block vue-file
put src/components/Sessions.vue <<'X'
<script setup lang="ts">
import { computed, ref } from 'vue'

type Session = { id: string; course: string; minutes: number; done: boolean }

const sessions = ref<Session[]>([
  { id: 's1', course: 'Statistics', minutes: 40, done: true },
  { id: 's2', course: 'Python', minutes: 35, done: false },
  { id: 's3', course: 'Statistics', minutes: 45, done: false },
])
const done = computed(() =>
  sessions.value.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0),
)
const total = computed(() => sessions.value.reduce((sum, s) => sum + s.minutes, 0))
console.log('Sessions ran')

function toggle(session: Session) {
  session.done = !session.done
}
</script>

<template>
  <section>
    <h1>This week</h1>
    <p>{{ done }} of {{ total }} minutes done</p>
    <ul>
      <li v-for="s in sessions" :key="s.id">
        <button :aria-pressed="s.done" @click="toggle(s)">
          {{ s.course }} · {{ s.minutes }} min
        </button>
      </li>
    </ul>
  </section>
</template>
X
put src/App.vue <<'X'
<script setup lang="ts">
import Sessions from './components/Sessions.vue'
</script>

<template>
  <Sessions />
</template>
X
block vue-run
on 'npm run build'
serve 4173 npm run preview
on "look http://localhost:4173/ $CLICKS"
stop

CWD=
block svelte-new
on 'npm create vite@9.3.1 sessions-svelte -- --template svelte-ts --no-interactive > /dev/null && cd sessions-svelte && npm config set save-exact true --location=project && npm install --silent --save-dev svelte@5.57.2 @sveltejs/vite-plugin-svelte@7.3.1 @tsconfig/svelte@5.0.8 @types/node@22.20.5 svelte-check@4.7.7 typescript@6.0.3 vite@8.3.5 && rm src/lib/Counter.svelte && grep -A 9 "\"devDependencies\"" package.json'
CWD=sessions-svelte
block svelte-file
put src/lib/Sessions.svelte <<'X'
<script lang="ts">
  type Session = { id: string; course: string; minutes: number; done: boolean }

  let sessions = $state<Session[]>([
    { id: 's1', course: 'Statistics', minutes: 40, done: true },
    { id: 's2', course: 'Python', minutes: 35, done: false },
    { id: 's3', course: 'Statistics', minutes: 45, done: false },
  ])
  const done = $derived(sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0))
  const total = $derived(sessions.reduce((sum, s) => sum + s.minutes, 0))
  console.log('Sessions ran')
</script>

<section>
  <h1>This week</h1>
  <p>{done} of {total} minutes done</p>
  <ul>
    {#each sessions as s (s.id)}
      <li>
        <button aria-pressed={s.done} onclick={() => (s.done = !s.done)}>
          {s.course} · {s.minutes} min
        </button>
      </li>
    {/each}
  </ul>
</section>
X
put src/App.svelte <<'X'
<script lang="ts">
  import Sessions from './lib/Sessions.svelte'
</script>

<Sessions />
X
block svelte-run
on 'npm run build'
serve 4173 npm run preview
on "look http://localhost:4173/ $CLICKS"
stop

CWD=
block angular-new
on 'npx --yes @angular/cli@21.2.28 new sessions-angular --defaults --skip-install --skip-git --ssr=false | tail -n 4'
CWD=sessions-angular
block angular-install
on 'npm install 2>&1 | head -n 1'
on 'npm config set save-exact true --location=project && npm install @angular/common@21.2.25 @angular/compiler@21.2.25 @angular/core@21.2.25 @angular/forms@21.2.25 @angular/platform-browser@21.2.25 @angular/router@21.2.25 rxjs@7.8.2 tslib@2.8.1 @angular/build@21.2.28 @angular/cli@21.2.28 @angular/compiler-cli@21.2.25 jsdom@28.1.0 prettier@3.9.10 typescript@5.9.3 vitest@4.0.18 > /dev/null && grep -A 8 "\"devDependencies\"" package.json && ls src/app'
block angular-file
put src/app/sessions.ts <<'X'
import { Component, computed, signal } from '@angular/core';

type Session = { id: string; course: string; minutes: number; done: boolean };

@Component({
  selector: 'app-sessions',
  template: `
    <section>
      <h1>This week</h1>
      <p>{{ done() }} of {{ total() }} minutes done</p>
      <ul>
        @for (s of sessions(); track s.id) {
          <li>
            <button [attr.aria-pressed]="s.done" (click)="toggle(s.id)">
              {{ s.course }} · {{ s.minutes }} min
            </button>
          </li>
        }
      </ul>
    </section>
  `,
})
export class Sessions {
  protected readonly sessions = signal<Session[]>([
    { id: 's1', course: 'Statistics', minutes: 40, done: true },
    { id: 's2', course: 'Python', minutes: 35, done: false },
    { id: 's3', course: 'Statistics', minutes: 45, done: false },
  ]);
  protected readonly done = computed(() =>
    this.sessions()
      .filter((s) => s.done)
      .reduce((sum, s) => sum + s.minutes, 0),
  );
  protected readonly total = computed(() =>
    this.sessions().reduce((sum, s) => sum + s.minutes, 0),
  );

  constructor() {
    console.log('Sessions ran');
  }

  protected toggle(id: string) {
    this.sessions.update((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)));
  }
}
X
put src/app/app.ts <<'X'
import { Component } from '@angular/core';
import { Sessions } from './sessions';

@Component({
  selector: 'app-root',
  imports: [Sessions],
  template: '<app-sessions />',
})
export class App {}
X
block angular-run
on 'rm src/app/app.html src/app/app.css src/app/app.spec.ts && npm run build'
serve 4200 npm start -- --configuration production
on "look http://localhost:4200/ $CLICKS"
stop

CWD=
block sizes
on 'for d in sessions-react/dist sessions-vue/dist sessions-svelte/dist sessions-angular/dist/sessions-angular/browser; do printf "%-45s %6s bytes\n" "$d" "$(cat $d/assets/*.js $d/*.js 2>/dev/null | gzip -9 | wc -c)"; done'

lab save after-$(basename "$PWD")
finish
