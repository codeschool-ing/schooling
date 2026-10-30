#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 10's captures.sh
#
# Starts from ~/planner as lesson 10 left it. What is STAGED rather than typed:
# the files ana wrote, put below and shown in the lesson; the API server, which
# ana starts in a terminal of its own and the script starts in the background
# (its output is shown as that terminal printed it); data/planner.json, deleted
# before each demonstration so that each starts from the seed data; and the
# page's date, Wednesday 21 October 2026, set with --today.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-g57xzsbq
L='look http://localhost:5173/ --today 2026-10-21'
TICK="--do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses'"
api_start() { lab exec ana 'cd ~/planner && (setsid node server/api.mjs > /tmp/api.out 2>&1 < /dev/null & echo $! > /tmp/api.pid)'; sleep 1; }
api_stop() { lab exec ana 'kill $(cat /tmp/api.pid) 2>/dev/null; rm -f /tmp/api.pid'; sleep 0.5; }
fresh() { lab exec ana 'rm -f ~/planner/data/planner.json'; }

block server
put server/api.mjs <<'JS'
// server/api.mjs: the planner's API, from lesson 11 on. Node.js and nothing else.
//
//   node server/api.mjs      listens on http://localhost:3001
//
// It keeps the planner in data/planner.json, made from public/courses.json the
// first time. DELAY=ms makes every answer wait that long, to see loading states.
import { randomUUID } from 'node:crypto'
import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { createServer } from 'node:http'

const DATA = new URL('../data/planner.json', import.meta.url)
const SEED = new URL('../public/courses.json', import.meta.url)
const DELAY = Number(process.env.DELAY ?? 0)

async function load() {
  try {
    return JSON.parse(await readFile(DATA, 'utf8'))
  } catch {
    return JSON.parse(await readFile(SEED, 'utf8'))
  }
}

async function save(planner) {
  await mkdir(new URL('.', DATA), { recursive: true })
  await writeFile(DATA, JSON.stringify(planner, null, 2) + '\n')
}

async function readBody(request) {
  let text = ''
  for await (const chunk of request) text += chunk
  return text ? JSON.parse(text) : {}
}

function send(response, status, body) {
  response.writeHead(status, { 'content-type': 'application/json' })
  response.end(JSON.stringify(body))
}

createServer(async (request, response) => {
  await new Promise((resolve) => setTimeout(resolve, DELAY))
  const url = new URL(request.url, 'http://localhost')
  console.log(request.method, url.pathname)
  const planner = await load()

  if (request.method === 'GET' && url.pathname === '/api/planner') {
    return send(response, 200, planner)
  }

  if (request.method === 'POST' && url.pathname === '/api/sessions') {
    const { course, date, minutes } = await readBody(request)
    const valid =
      planner.courses.some((c) => c.id === course) &&
      /^\d{4}-\d\d-\d\d$/.test(date) &&
      Number.isInteger(minutes) && minutes >= 5 && minutes <= 240
    if (!valid) return send(response, 400, { error: 'not a valid session' })
    const session = { id: randomUUID(), course, date, minutes, done: false }
    planner.sessions.push(session)
    await save(planner)
    return send(response, 201, session)
  }

  const match = url.pathname.match(/^\/api\/sessions\/([\w-]+)$/)
  if (request.method === 'PATCH' && match) {
    const session = planner.sessions.find((s) => s.id === match[1])
    if (!session) return send(response, 404, { error: 'no such session' })
    const { done } = await readBody(request)
    if (typeof done !== 'boolean') return send(response, 400, { error: 'done must be true or false' })
    session.done = done
    await save(planner)
    return send(response, 200, session)
  }

  send(response, 404, { error: 'not found' })
}).listen(3001, () => console.log('planner API on http://localhost:3001'))
JS
on "printf 'data/\\n' >> .gitignore && tail -n 2 .gitignore"
fresh; api_start
prompt; echo 'node server/api.mjs'
on 'curl -s http://localhost:3001/api/planner | head -c 160; echo'
on "curl -s -w ' %{http_code}\\n' -X PATCH http://localhost:3001/api/sessions/s2 -H 'content-type: application/json' -d '{\"done\":true}'"
on "curl -s -X PATCH http://localhost:3001/api/sessions/s2 -H 'content-type: application/json' -d '{\"done\":\"yes\"}' -w ' %{http_code}\\n'"
on "curl -s -X POST http://localhost:3001/api/sessions -H 'content-type: application/json' -d '{\"course\":\"statistics\",\"date\":\"\",\"minutes\":30}' -w ' %{http_code}\\n'"
on 'ls data'
echo '----- the API terminal'
lab exec ana 'cat /tmp/api.out'

block proxy
put vite.config.ts <<'TS'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': 'http://localhost:3001',
    },
  },
})
TS
serve 5173 npm run dev
on 'curl -s http://localhost:5173/api/planner | head -c 80; echo'

block install
on 'npm install @tanstack/react-query@5.104.5'

block query
put src/usePlanner.ts <<'TS'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import type { Course, Session } from './types'

export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>
type Planner = { courses: Course[]; sessions: Session[] }
type Status = 'loading' | 'ready' | 'failed'

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, { ...init, headers: { 'content-type': 'application/json' } })
  if (!response.ok) throw new Error(`HTTP ${response.status} for ${path}`)
  return response.json()
}

export function usePlanner() {
  const queryClient = useQueryClient()
  const planner = useQuery({
    queryKey: ['planner'],
    queryFn: () => request<Planner>('/api/planner'),
  })
  const refresh = () => queryClient.invalidateQueries({ queryKey: ['planner'] })

  const toggle = useMutation({
    mutationFn: (id: string) => {
      const current = queryClient.getQueryData<Planner>(['planner'])
      const session = current?.sessions.find((s) => s.id === id)
      return request(`/api/sessions/${id}`, {
        method: 'PATCH',
        body: JSON.stringify({ done: !session?.done }),
      })
    },
    onSuccess: refresh,
  })
  const add = useMutation({
    mutationFn: (session: NewSession) =>
      request('/api/sessions', { method: 'POST', body: JSON.stringify(session) }),
    onSuccess: refresh,
  })

  const status: Status = planner.isPending ? 'loading' : planner.isError ? 'failed' : 'ready'
  return {
    status,
    courses: planner.data?.courses ?? [],
    sessions: planner.data?.sessions ?? [],
    toggleDone: toggle.mutate,
    addSession: add.mutate,
  }
}
TS
put src/main.tsx <<'TSX'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { PlannerProvider } from './PlannerProvider'

const queryClient = new QueryClient()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <PlannerProvider>
        <App />
      </PlannerProvider>
    </QueryClientProvider>
  </StrictMode>,
)
TSX
on 'npm run lint && npx tsc -b && echo no errors'
api_stop; fresh; api_start
on "$L --network | grep -E 'api|courses'"

block mutate
on "$L --network $TICK | grep -E 'api|minutes done'"
on "$L | grep 'minutes done'"
on "grep -A 4 '\"s2\"' data/planner.json"

block add
on "$L --network --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' --do 'click button Back to courses' | grep -E 'api|minutes done'"

block down
api_stop; fresh
on "$L --network --do 'wait 9000' | grep -E 'api|alert|error'"
api_start

api_stop; fresh

stop
lab save after-$(basename "$PWD")
finish
