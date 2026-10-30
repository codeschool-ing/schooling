"""Lesson 4: lifecycle.ts as an example, the shared state diagram, and the phone call."""
from fig import Fig

EXAMPLES = {
    "the-model": [
        {"language": "typescript", "file": "lifecycle.ts", "parts": [
            ('// lifecycle.ts: one lifecycle for both platforms, and what each one calls\ntype State = "notRunning" | "active" | "inactive" | "background" | "suspended";\ntype Event = "launch" | "interrupt" | "resume" | "leave" | "return" | "suspend" | "kill";\n\n// Where each event may happen, and the state it leads to.\nconst moves: Record<Event, { from: State[]; to: State }> = {\n  launch: { from: ["notRunning"], to: "active" },\n  interrupt: { from: ["active"], to: "inactive" },\n  resume: { from: ["inactive"], to: "active" },\n  leave: { from: ["inactive"], to: "background" },\n  return: { from: ["background", "suspended"], to: "active" },\n  suspend: { from: ["background"], to: "suspended" },\n  kill: { from: ["background", "suspended"], to: "notRunning" },\n};\n',
             "The five states and seven events of the model, and the only moves allowed. `kill` starts from background or suspended: the app in front is the last one the system takes.",
             "Os cinco estados e os sete eventos do modelo, e os únicos movimentos permitidos. `kill` parte de background ou suspended: o app da frente é o último que o sistema leva."),
            ('// What each platform tells the app. An empty list: the app hears nothing.\nconst calls: Record<Event, { android: string[]; ios: string[]; rn: string[] }> = {\n  launch: { android: ["onCreate", "onStart", "onResume"], ios: [".inactive", ".active"], rn: ["active"] },\n  interrupt: { android: ["onPause"], ios: [".inactive"], rn: ["inactive (iOS only)"] },\n  resume: { android: ["onResume"], ios: [".active"], rn: ["active"] },\n  leave: { android: ["onStop"], ios: [".background"], rn: ["background"] },\n  return: { android: ["onRestart", "onStart", "onResume"], ios: [".inactive", ".active"], rn: ["active"] },\n  suspend: { android: [], ios: [], rn: [] },\n  kill: { android: [], ios: [], rn: [] },\n};\n',
             "The three vocabularies of the previous section, as data: Android's callbacks, SwiftUI's scene phases and React Native's `AppState` values. The last two rows are empty on purpose.",
             "Os três vocabulários da etapa anterior, como dados: os callbacks do Android, as fases de cena do SwiftUI e os valores do `AppState` do React Native. As duas últimas linhas são vazias de propósito."),
            ('export function step(state: State, event: Event): State {\n  const move = moves[event];\n  if (!move) throw new Error(`no event called ${event}`);\n  if (!move.from.includes(state)) {\n    throw new Error(`${event} cannot happen in ${state}, only in ${move.from.join(" or ")}`);\n  }\n  return move.to;\n}\n\nconst heard = (names: string[]) => (names.length ? names.join(", ") : "nothing");\n',
             "`step` is the whole state machine: it refuses a move the table does not allow, and an event it has never heard of, rather than guessing.",
             "`step` é a máquina de estados inteira: recusa um movimento que a tabela não permite, e um evento que ela não conhece, em vez de adivinhar."),
            ('// The story of one afternoon, or the events given on the command line.\nconst story: [string, Event][] = [\n  ["Ana taps the planner\'s icon", "launch"],\n  ["a call takes over the screen", "interrupt"],\n  ["she answers it", "leave"],\n  ["the call ends; she is back", "return"],\n  ["she swipes up to go home", "interrupt"],\n  ["the home screen covers the app", "leave"],\n  ["some time passes", "suspend"],\n  ["another app needs the memory", "kill"],\n  ["she taps the icon again", "launch"],\n];\nconst args = process.argv.slice(2) as Event[];\nconst events: [string, Event][] = args.length ? args.map((e) => ["", e]) : story;\n',
             "The scenario: a phone call, a trip to the home screen, and a kill to free memory. Events typed after `node lifecycle.ts` replace it.",
             "O cenário: uma ligação, uma ida à tela inicial e uma morte para liberar memória. Eventos digitados depois de `node lifecycle.ts` o substituem."),
            ('let state: State = "notRunning";\nfor (const [what, event] of events) {\n  let next: State;\n  try {\n    next = step(state, event);\n  } catch (e) {\n    console.log(`REFUSED ${(e as Error).message}`);\n    process.exit(1);\n  }\n  console.log(`${what ? what + ": " : ""}${event}, ${state} -> ${next}`);\n  console.log(`    Android ${heard(calls[event].android)} | iOS ${heard(calls[event].ios)} | RN ${heard(calls[event].rn)}`);\n  if (next === "background") console.log("    save now: from here the app can be killed without a word");\n  state = next;\n}',
             "Each move prints the story line, the states, and what each platform would call. Entering the background prints the lesson's rule, because it is the last moment the app is sure to be told anything.",
             "Cada movimento imprime a linha da história, os estados e o que cada plataforma chamaria. Entrar em background imprime a regra da aula, porque é o último momento em que o app com certeza fica sabendo de algo."),
        ]},
    ],
}

T = {
    "en": dict(
        aria1="The five states of the shared lifecycle and the moves between them. Not running leads by launch to active. Active and inactive move into each other by interrupt and resume. Inactive leads by leave to background. Background leads by suspend to suspended. Background and suspended both lead by return to active. Background and suspended both lead by kill to not running, and no platform calls the app when that happens. Each state also carries its names: active is Android resumed, iOS .active, React Native active; inactive is paused, .inactive, inactive on iOS only; background is stopped, .background, background; suspended is a cached process on Android, suspended on iOS, and nothing in React Native.",
        nr=["not running", "no process"],
        act=["active", "Android: resumed", "iOS: .active", "RN: active"],
        ina=["inactive", "Android: paused", "iOS: .inactive", "RN: inactive (iOS)"],
        bg=["background", "Android: stopped", "iOS: .background", "RN: background"],
        sus=["suspended", "Android: cached process", "iOS: suspended", "RN: nothing"],
        kill="kill: no callback on any platform",
        cap1="One model, three vocabularies. The two dashed arrows are the ones no platform announces: the app is not told it was frozen, and not told it was killed.",
        aria2="A timeline of a phone call interrupting the planner. Ana is writing a session and the app is active. The call arrives: the app becomes inactive; Android calls onPause, iOS reports .inactive, React Native reports inactive on iOS only. She answers: the app goes to the background; Android calls onStop, iOS reports .background, React Native background. The call ends and she comes back: the app is active again; Android calls onRestart, onStart and onResume, iOS reports .inactive then .active, React Native active. The process stays alive throughout.",
        segs=["active: writing a session", "inactive: call rings", "background: on the call", "active: back"],
        ev=["call arrives", "answered", "call ends"],
        note="The process was alive the whole time: nothing was lost, and nothing had to be restored.",
        cap2="The common interruption, and the kind one: the app is paused and stopped, never killed, so everything in memory is still there when Ana comes back.",
    ),
    "pt": dict(
        aria1="Os cinco estados do ciclo de vida compartilhado e os movimentos entre eles. Not running leva, por launch, a active. Active e inactive passam um para o outro por interrupt e resume. Inactive leva, por leave, a background. Background leva, por suspend, a suspended. Background e suspended levam os dois, por return, a active. Background e suspended levam os dois, por kill, a not running, e nenhuma plataforma chama o app quando isso acontece. Cada estado traz também os seus nomes: active é resumed no Android, .active no iOS, active no React Native; inactive é paused, .inactive, inactive só no iOS; background é stopped, .background, background; suspended é um processo em cache no Android, suspended no iOS, e nada no React Native.",
        nr=["não rodando", "nenhum processo"],
        act=["ativo", "Android: resumed", "iOS: .active", "RN: active"],
        ina=["inativo", "Android: paused", "iOS: .inactive", "RN: inactive (iOS)"],
        bg=["em segundo plano", "Android: stopped", "iOS: .background", "RN: background"],
        sus=["suspenso", "Android: processo em cache", "iOS: suspended", "RN: nada"],
        kill="kill: nenhum callback em plataforma nenhuma",
        cap1="Um modelo, três vocabulários. As duas setas tracejadas são as que nenhuma plataforma anuncia: o app não fica sabendo que foi congelado, nem que foi morto.",
        aria2="Uma linha do tempo de uma ligação interrompendo o planner. Ana está escrevendo uma sessão e o app está ativo. A ligação chega: o app fica inativo; o Android chama onPause, o iOS informa .inactive, o React Native informa inactive só no iOS. Ela atende: o app vai para segundo plano; o Android chama onStop, o iOS informa .background, o React Native background. A ligação acaba e ela volta: o app fica ativo de novo; o Android chama onRestart, onStart e onResume, o iOS informa .inactive e depois .active, o React Native active. O processo continua vivo o tempo todo.",
        segs=["ativo: escrevendo uma sessão", "inativo: o telefone toca", "segundo plano: na ligação", "ativo: de volta"],
        ev=["a ligação chega", "atendida", "a ligação acaba"],
        note="O processo esteve vivo o tempo todo: nada se perdeu, e nada precisou ser restaurado.",
        cap2="A interrupção comum, e a gentil: o app é pausado e parado, nunca morto, então tudo o que estava na memória continua lá quando Ana volta.",
    ),
}


def states(t):
    f = Fig("l04-states", 620, 290, t["aria1"])
    f.box(10, 50, 160, 40, t["nr"], size=9)
    f.box(220, 40, 160, 66, t["act"], size=9, stroke="phosphor")
    f.box(430, 40, 160, 66, t["ina"], size=9)
    f.box(430, 180, 160, 66, t["bg"], size=9, stroke="amber")
    f.box(220, 180, 160, 66, t["sus"], size=9)
    f.arrow([(170, 70), (218, 70)])
    f.text(195, 60, "launch", mono=True, size=8.5, fill="phosphor")
    f.arrow([(380, 58), (428, 58)])
    f.text(405, 48, "interrupt", mono=True, size=8.5, fill="phosphor")
    f.arrow([(430, 88), (382, 88)])
    f.text(405, 99, "resume", mono=True, size=8.5, fill="phosphor")
    f.arrow([(510, 106), (510, 178)])
    f.text(518, 143, "leave", anchor="start", mono=True, size=8.5, fill="phosphor")
    f.arrow([(430, 205), (382, 205)])
    f.text(405, 195, "suspend", mono=True, size=8.5, fill="phosphor")
    f.arrow([(300, 180), (300, 108)])
    f.arrow([(440, 180), (372, 108)])
    f.text(306, 150, "return", anchor="start", mono=True, size=8.5, fill="phosphor")
    f.arrow([(220, 225), (90, 225), (90, 92)], color="amber", dashed=True)
    f.arrow([(510, 246), (510, 262), (70, 262), (70, 92)], color="amber", dashed=True)
    f.text(300, 276, t["kill"], size=9.5, fill="amber", bold=True)
    return f


def call(t):
    f = Fig("l04-call", 760, 205, t["aria2"])
    xs = [(20, 170), (170, 300), (300, 560), (560, 740)]
    strokes = ["phosphor", "wire", "amber", "phosphor"]
    for (a, b), s, lab in zip(xs, strokes, t["segs"]):
        f.box(a, 40, b - a, 30, [lab], size=9, stroke=s)
    rows = [("Android", ["onPause", "onStop", "onRestart, onStart, onResume"]),
            ("iOS", [".inactive", ".background", ".inactive, .active"]),
            ("RN", ["inactive (iOS)", "background", "active"])]
    for x, ev in zip((170, 300, 560), t["ev"]):
        f.text(x, 24, ev, size=9, italic=True, fill="paper-dim")
        f.arrow([(x, 72), (x, 160)], head=False, dashed=True, color="wire")
    for k, (name, cs) in enumerate(rows):
        y = 98 + k * 24
        f.text(20, y, name, anchor="start", size=9.5, bold=True)
        for x, c in zip((170, 300, 560), cs):
            f.text(x, y, c, mono=True, size=9, fill="phosphor")
    f.text(380, 184, t["note"], size=9.5, italic=True, fill="paper-dim")
    return f


def figures(lang):
    t = T[lang]
    return {
        "l04-states": states(t).json(t["cap1"], same=["Android: resumed", "iOS: .active", "RN: active", "Android: paused",
                                                     "iOS: .inactive", "RN: inactive (iOS)", "Android: stopped",
                                                     "iOS: .background", "RN: background", "iOS: suspended"]
                                     if lang == "pt" else None),
        "l04-call": call(t).json(t["cap2"], same=["Android", "iOS", "RN"] if lang == "pt" else None),
    }
