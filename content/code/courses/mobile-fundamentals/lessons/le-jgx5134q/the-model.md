---
title: The model as a program, and an afternoon with a phone call
version: 1
---

**The five states and the moves between them fit in a small state machine, and running it on a
story shows what each platform says at each step, and where all three say nothing.** It is a model:
real phones add detail, and the order of some callbacks varies with what the user does. What it keeps
exact is the part this lesson is about, which is when the app is told and when it is not.

## lifecycle.ts

Save it in `~/planner` as `lifecycle.ts`:

```schooling-example
{"language": "typescript", "file": "lifecycle.ts", "parts": [{"code": "// lifecycle.ts: one lifecycle for both platforms, and what each one calls\ntype State = \"notRunning\" | \"active\" | \"inactive\" | \"background\" | \"suspended\";\ntype Event = \"launch\" | \"interrupt\" | \"resume\" | \"leave\" | \"return\" | \"suspend\" | \"kill\";\n\n// Where each event may happen, and the state it leads to.\nconst moves: Record<Event, { from: State[]; to: State }> = {\n  launch: { from: [\"notRunning\"], to: \"active\" },\n  interrupt: { from: [\"active\"], to: \"inactive\" },\n  resume: { from: [\"inactive\"], to: \"active\" },\n  leave: { from: [\"inactive\"], to: \"background\" },\n  return: { from: [\"background\", \"suspended\"], to: \"active\" },\n  suspend: { from: [\"background\"], to: \"suspended\" },\n  kill: { from: [\"background\", \"suspended\"], to: \"notRunning\" },\n};\n", "note": "The five states and seven events of the model, and the only moves allowed. `kill` starts from background or suspended: the app in front is the last one the system takes."}, {"code": "// What each platform tells the app. An empty list: the app hears nothing.\nconst calls: Record<Event, { android: string[]; ios: string[]; rn: string[] }> = {\n  launch: { android: [\"onCreate\", \"onStart\", \"onResume\"], ios: [\".inactive\", \".active\"], rn: [\"active\"] },\n  interrupt: { android: [\"onPause\"], ios: [\".inactive\"], rn: [\"inactive (iOS only)\"] },\n  resume: { android: [\"onResume\"], ios: [\".active\"], rn: [\"active\"] },\n  leave: { android: [\"onStop\"], ios: [\".background\"], rn: [\"background\"] },\n  return: { android: [\"onRestart\", \"onStart\", \"onResume\"], ios: [\".inactive\", \".active\"], rn: [\"active\"] },\n  suspend: { android: [], ios: [], rn: [] },\n  kill: { android: [], ios: [], rn: [] },\n};\n", "note": "The three vocabularies of the previous section, as data: Android's callbacks, SwiftUI's scene phases and React Native's `AppState` values. The last two rows are empty on purpose."}, {"code": "export function step(state: State, event: Event): State {\n  const move = moves[event];\n  if (!move) throw new Error(`no event called ${event}`);\n  if (!move.from.includes(state)) {\n    throw new Error(`${event} cannot happen in ${state}, only in ${move.from.join(\" or \")}`);\n  }\n  return move.to;\n}\n\nconst heard = (names: string[]) => (names.length ? names.join(\", \") : \"nothing\");\n", "note": "`step` is the whole state machine: it refuses a move the table does not allow, and an event it has never heard of, rather than guessing."}, {"code": "// The story of one afternoon, or the events given on the command line.\nconst story: [string, Event][] = [\n  [\"Ana taps the planner's icon\", \"launch\"],\n  [\"a call takes over the screen\", \"interrupt\"],\n  [\"she answers it\", \"leave\"],\n  [\"the call ends; she is back\", \"return\"],\n  [\"she swipes up to go home\", \"interrupt\"],\n  [\"the home screen covers the app\", \"leave\"],\n  [\"some time passes\", \"suspend\"],\n  [\"another app needs the memory\", \"kill\"],\n  [\"she taps the icon again\", \"launch\"],\n];\nconst args = process.argv.slice(2) as Event[];\nconst events: [string, Event][] = args.length ? args.map((e) => [\"\", e]) : story;\n", "note": "The scenario: a phone call, a trip to the home screen, and a kill to free memory. Events typed after `node lifecycle.ts` replace it."}, {"code": "let state: State = \"notRunning\";\nfor (const [what, event] of events) {\n  let next: State;\n  try {\n    next = step(state, event);\n  } catch (e) {\n    console.log(`REFUSED ${(e as Error).message}`);\n    process.exit(1);\n  }\n  console.log(`${what ? what + \": \" : \"\"}${event}, ${state} -> ${next}`);\n  console.log(`    Android ${heard(calls[event].android)} | iOS ${heard(calls[event].ios)} | RN ${heard(calls[event].rn)}`);\n  if (next === \"background\") console.log(\"    save now: from here the app can be killed without a word\");\n  state = next;\n}", "note": "Each move prints the story line, the states, and what each platform would call. Entering the background prints the lesson's rule, because it is the last moment the app is sure to be told anything."}]}
```

## An afternoon

Run it with no arguments, and it plays the story at the bottom of the file:

```
ana@dev:~/planner$ node lifecycle.ts
Ana taps the planner's icon: launch, notRunning -> active
    Android onCreate, onStart, onResume | iOS .inactive, .active | RN active
a call takes over the screen: interrupt, active -> inactive
    Android onPause | iOS .inactive | RN inactive (iOS only)
she answers it: leave, inactive -> background
    Android onStop | iOS .background | RN background
    save now: from here the app can be killed without a word
the call ends; she is back: return, background -> active
    Android onRestart, onStart, onResume | iOS .inactive, .active | RN active
she swipes up to go home: interrupt, active -> inactive
    Android onPause | iOS .inactive | RN inactive (iOS only)
the home screen covers the app: leave, inactive -> background
    Android onStop | iOS .background | RN background
    save now: from here the app can be killed without a word
some time passes: suspend, background -> suspended
    Android nothing | iOS nothing | RN nothing
another app needs the memory: kill, suspended -> notRunning
    Android nothing | iOS nothing | RN nothing
she taps the icon again: launch, notRunning -> active
    Android onCreate, onStart, onResume | iOS .inactive, .active | RN active
```

**Read the last three moves slowly.** After "the home screen covers the app" the program prints its
warning, and from then on the platforms' columns are empty: the move to suspended is silent, and so is
the kill. When Ana taps the icon again, Android calls `onCreate`, which is the same callback it called
at the very first launch. Unless the app wrote something down on the way out, this looks to it
like the first time it has ever run; lesson 5 is about what to write.

The phone call in the first half, drawn as time:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 205\" role=\"img\" data-fig=\"l04-call\" aria-label=\"A timeline of a phone call interrupting the planner. Ana is writing a session and the app is active. The call arrives: the app becomes inactive; Android calls onPause, iOS reports .inactive, React Native reports inactive on iOS only. She answers: the app goes to the background; Android calls onStop, iOS reports .background, React Native background. The call ends and she comes back: the app is active again; Android calls onRestart, onStart and onResume, iOS reports .inactive then .active, React Native active. The process stays alive throughout.\"><rect x=\"20\" y=\"40\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">active: writing a session</text><rect x=\"170\" y=\"40\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">inactive: call rings</text><rect x=\"300\" y=\"40\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">background: on the call</text><rect x=\"560\" y=\"40\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">active: back</text><text x=\"170\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">call arrives</text><path d=\"M170 72 L170 160\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"300\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">answered</text><path d=\"M300 72 L300 160\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"560\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">call ends</text><path d=\"M560 72 L560 160\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"20\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Android</text><text x=\"170\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">onPause</text><text x=\"300\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">onStop</text><text x=\"560\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">onRestart, onStart, onResume</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">iOS</text><text x=\"170\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">.inactive</text><text x=\"300\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">.background</text><text x=\"560\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">.inactive, .active</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">RN</text><text x=\"170\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">inactive (iOS)</text><text x=\"300\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">background</text><text x=\"560\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">active</text><text x=\"380\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">The process was alive the whole time: nothing was lost, and nothing had to be restored.</text></svg>", "caption": "The common interruption, and the kind one: the app is paused and stopped, never killed, so everything in memory is still there when Ana comes back."}
```

**The call does not kill the app, and on Android it does not even destroy the Activity.** The app is
paused, stopped while the call has the screen, and restarted when Ana comes back, with everything in
memory still there. That is the common case, and it is why an app that never saves its state seems to
work in testing: the developer's phone has memory to spare, and the developer comes back within a
minute.

## A move that cannot happen

Give the program the events yourself, and it plays only those. Here the app is killed from the
background, and then the user "returns" to it:

```
ana@dev:~/planner$ node lifecycle.ts launch interrupt leave kill return
launch, notRunning -> active
    Android onCreate, onStart, onResume | iOS .inactive, .active | RN active
interrupt, active -> inactive
    Android onPause | iOS .inactive | RN inactive (iOS only)
leave, inactive -> background
    Android onStop | iOS .background | RN background
    save now: from here the app can be killed without a word
kill, background -> notRunning
    Android nothing | iOS nothing | RN nothing
REFUSED return cannot happen in notRunning, only in background or suspended
```

**A killed app cannot be returned to; it can only be launched again.** The model refuses the move
because there is nothing to return to, and that refusal is the program's way of saying what the
user cannot see: the planner on the recent-apps screen after a kill is a picture, and tapping it
starts a new process from `onCreate`. Whatever the old process held in memory and did not write down
is gone.

Commit the file:

```
ana@dev:~/planner$ git add lifecycle.ts
ana@dev:~/planner$ git commit -q -m "The lifecycle, as one model for both platforms"
```
