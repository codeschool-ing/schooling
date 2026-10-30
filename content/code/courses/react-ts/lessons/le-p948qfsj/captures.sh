#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of react-ts, as a script that
# produces them.
#
#   sudo -E bash captures.sh           # after lesson 21's captures.sh
#
# Works in ~/planner as lesson 21 left it. What is STAGED rather than typed: the
# files ana wrote, put below and shown in the lesson. No server runs: the tests
# draw the components in jsdom, inside Node.js. The lab's environment sets
# COLORS=false, as it sets NO_COLOR, so that Testing Library prints the page
# without the colour codes a terminal would show.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/captures-lib.sh
lab restore after-le-0bxa2vsw

block install
on 'npm install --save-dev vitest@5.0.5 jsdom@29.1.1 @testing-library/react@16.3.3 @testing-library/dom@10.4.2 @testing-library/user-event@14.6.8 @testing-library/jest-dom@7.0.1'
on 'npm pkg set scripts.test="vitest run" && grep "\"test\"" package.json'

block config
put vite.config.ts <<'TS'
/// <reference types="vitest/config" />
import babel from '@rolldown/plugin-babel'
import react, { reactCompilerPreset } from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), babel({ presets: [reactCompilerPreset()] })],
  server: {
    proxy: {
      '/api': 'http://localhost:3001',
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
  },
})
TS
put src/test/setup.ts <<'TS'
import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'

// Every test draws into the same document: empty it after each one.
afterEach(cleanup)
TS

block unit
put src/week.test.ts <<'TS'
import { describe, expect, it } from 'vitest'
import type { Session } from './types'
import { addDays, inWeek, minutes, mondayOf } from './week'

describe('week', () => {
  it('finds the Monday of any day of the week', () => {
    expect(mondayOf('2026-10-19')).toBe('2026-10-19')
    expect(mondayOf('2026-10-21')).toBe('2026-10-19')
    expect(mondayOf('2026-10-25')).toBe('2026-10-19')
  })

  it('moves across the end of a month', () => {
    expect(addDays('2026-10-26', 7)).toBe('2026-11-02')
  })

  it('counts Sunday in the week and the next Monday out of it', () => {
    expect(inWeek('2026-10-25', '2026-10-19')).toBe(true)
    expect(inWeek('2026-10-26', '2026-10-19')).toBe(false)
  })

  it('adds up the minutes of some sessions', () => {
    const sessions = [{ minutes: 50 }, { minutes: 40 }] as Session[]
    expect(minutes(sessions)).toBe(90)
    expect(minutes([])).toBe(0)
  })
})
TS
on 'npm test'

block summary
put src/WeekSummary.test.tsx <<'TSX'
import { render, screen } from '@testing-library/react'
import { expect, it } from 'vitest'
import type { Session } from './types'
import { WeekSummary } from './WeekSummary'

// The week of 19 October 2026 as public/courses.json has it.
const week: Session[] = [
  { id: 's1', course: 'statistics', date: '2026-10-19', minutes: 50, done: true },
  { id: 's2', course: 'statistics', date: '2026-10-21', minutes: 40, done: false },
  { id: 's3', course: 'spanish', date: '2026-10-20', minutes: 30, done: true },
  { id: 's4', course: 'spanish', date: '2026-10-23', minutes: 30, done: false },
  { id: 's6', course: 'chemistry', date: '2026-10-22', minutes: 45, done: false },
]

it('says how much of the week is done', () => {
  render(<WeekSummary monday="2026-10-19" sessions={week} />)
  expect(screen.getByText('Week of 19 Oct 2026')).toBeInTheDocument()
  expect(screen.getByText('80 of 195 minutes done')).toBeInTheDocument()
})
TSX
on 'npm test -- WeekSummary'
block summary-fails
on "sed -i 's/80 of 195 minutes done/85 of 195 minutes done/' src/WeekSummary.test.tsx && npm test -- WeekSummary"
on "sed -i 's/85 of 195 minutes done/80 of 195 minutes done/' src/WeekSummary.test.tsx && npm test -- WeekSummary | grep Tests"

block events
put src/WeekNav.test.tsx <<'TSX'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, it, vi } from 'vitest'
import { WeekNav } from './WeekNav'

it('asks for the next and the previous Monday', async () => {
  const user = userEvent.setup()
  const onChange = vi.fn()
  render(<WeekNav monday="2026-10-19" onChange={onChange} />)

  await user.click(screen.getByRole('button', { name: 'Next week' }))
  await user.click(screen.getByRole('button', { name: 'Previous week' }))

  expect(onChange).toHaveBeenNthCalledWith(1, '2026-10-26')
  expect(onChange).toHaveBeenNthCalledWith(2, '2026-10-12')
})
TSX
on 'npm test -- WeekNav'

block form
put src/AddSessionForm.test.tsx <<'TSX'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { AddSessionForm } from './AddSessionForm'
import { PlannerContext, type Planner } from './plannerContext'

function renderForm() {
  const addSession = vi.fn()
  const planner: Planner = {
    status: 'ready',
    courses: [],
    sessions: [],
    toggleDone: vi.fn(),
    addSession,
  }
  render(
    <PlannerContext value={planner}>
      <AddSessionForm course="statistics" onAdded={vi.fn()} />
    </PlannerContext>,
  )
  return { addSession, user: userEvent.setup() }
}

describe('AddSessionForm', () => {
  it('says what is missing, and sends nothing', async () => {
    const { addSession, user } = renderForm()
    await user.click(screen.getByRole('button', { name: 'Add session' }))

    expect(await screen.findByText('Choose the day of the session.')).toBeInTheDocument()
    expect(screen.getByLabelText('Date')).toHaveAttribute('aria-invalid', 'true')
    expect(addSession).not.toHaveBeenCalled()
  })

  it('sends the session that was typed', async () => {
    const { addSession, user } = renderForm()
    await user.type(screen.getByLabelText('Date'), '2026-10-24')
    await user.clear(screen.getByLabelText('Minutes'))
    await user.type(screen.getByLabelText('Minutes'), '45')
    await user.click(screen.getByRole('button', { name: 'Add session' }))

    expect(addSession).toHaveBeenCalledWith(
      { course: 'statistics', date: '2026-10-24', minutes: 45 },
      expect.anything(),
    )
  })
})
TSX
on 'npm test -- AddSessionForm'

block all
on 'npm run lint && npx tsc -b && npm test'

lab save after-$(basename "$PWD")
finish
