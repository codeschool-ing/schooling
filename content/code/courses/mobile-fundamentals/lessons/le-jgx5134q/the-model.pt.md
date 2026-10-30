---
title: O modelo como programa, e uma tarde com uma ligação
version: 1
---

**Os cinco estados e os movimentos entre eles cabem numa pequena máquina de estados, e rodá-la sobre
uma história mostra o que cada plataforma diz a cada passo, e onde as três não dizem nada.** É um
modelo: celulares de verdade acrescentam detalhes, e a ordem de alguns callbacks varia com o que o
usuário faz. O que ele mantém exato é a parte de que esta aula trata, que é quando o app é avisado e
quando não é.

## lifecycle.ts

Salve em `~/planner` como `lifecycle.ts`:

```schooling-example
{"language": "typescript", "file": "lifecycle.ts", "parts": [{"code": "// lifecycle.ts: one lifecycle for both platforms, and what each one calls\ntype State = \"notRunning\" | \"active\" | \"inactive\" | \"background\" | \"suspended\";\ntype Event = \"launch\" | \"interrupt\" | \"resume\" | \"leave\" | \"return\" | \"suspend\" | \"kill\";\n\n// Where each event may happen, and the state it leads to.\nconst moves: Record<Event, { from: State[]; to: State }> = {\n  launch: { from: [\"notRunning\"], to: \"active\" },\n  interrupt: { from: [\"active\"], to: \"inactive\" },\n  resume: { from: [\"inactive\"], to: \"active\" },\n  leave: { from: [\"inactive\"], to: \"background\" },\n  return: { from: [\"background\", \"suspended\"], to: \"active\" },\n  suspend: { from: [\"background\"], to: \"suspended\" },\n  kill: { from: [\"background\", \"suspended\"], to: \"notRunning\" },\n};\n", "note": "Os cinco estados e os sete eventos do modelo, e os únicos movimentos permitidos. `kill` parte de background ou suspended: o app da frente é o último que o sistema leva."}, {"code": "// What each platform tells the app. An empty list: the app hears nothing.\nconst calls: Record<Event, { android: string[]; ios: string[]; rn: string[] }> = {\n  launch: { android: [\"onCreate\", \"onStart\", \"onResume\"], ios: [\".inactive\", \".active\"], rn: [\"active\"] },\n  interrupt: { android: [\"onPause\"], ios: [\".inactive\"], rn: [\"inactive (iOS only)\"] },\n  resume: { android: [\"onResume\"], ios: [\".active\"], rn: [\"active\"] },\n  leave: { android: [\"onStop\"], ios: [\".background\"], rn: [\"background\"] },\n  return: { android: [\"onRestart\", \"onStart\", \"onResume\"], ios: [\".inactive\", \".active\"], rn: [\"active\"] },\n  suspend: { android: [], ios: [], rn: [] },\n  kill: { android: [], ios: [], rn: [] },\n};\n", "note": "Os três vocabulários da etapa anterior, como dados: os callbacks do Android, as fases de cena do SwiftUI e os valores do `AppState` do React Native. As duas últimas linhas são vazias de propósito."}, {"code": "export function step(state: State, event: Event): State {\n  const move = moves[event];\n  if (!move) throw new Error(`no event called ${event}`);\n  if (!move.from.includes(state)) {\n    throw new Error(`${event} cannot happen in ${state}, only in ${move.from.join(\" or \")}`);\n  }\n  return move.to;\n}\n\nconst heard = (names: string[]) => (names.length ? names.join(\", \") : \"nothing\");\n", "note": "`step` é a máquina de estados inteira: recusa um movimento que a tabela não permite, e um evento que ela não conhece, em vez de adivinhar."}, {"code": "// The story of one afternoon, or the events given on the command line.\nconst story: [string, Event][] = [\n  [\"Ana taps the planner's icon\", \"launch\"],\n  [\"a call takes over the screen\", \"interrupt\"],\n  [\"she answers it\", \"leave\"],\n  [\"the call ends; she is back\", \"return\"],\n  [\"she swipes up to go home\", \"interrupt\"],\n  [\"the home screen covers the app\", \"leave\"],\n  [\"some time passes\", \"suspend\"],\n  [\"another app needs the memory\", \"kill\"],\n  [\"she taps the icon again\", \"launch\"],\n];\nconst args = process.argv.slice(2) as Event[];\nconst events: [string, Event][] = args.length ? args.map((e) => [\"\", e]) : story;\n", "note": "O cenário: uma ligação, uma ida à tela inicial e uma morte para liberar memória. Eventos digitados depois de `node lifecycle.ts` o substituem."}, {"code": "let state: State = \"notRunning\";\nfor (const [what, event] of events) {\n  let next: State;\n  try {\n    next = step(state, event);\n  } catch (e) {\n    console.log(`REFUSED ${(e as Error).message}`);\n    process.exit(1);\n  }\n  console.log(`${what ? what + \": \" : \"\"}${event}, ${state} -> ${next}`);\n  console.log(`    Android ${heard(calls[event].android)} | iOS ${heard(calls[event].ios)} | RN ${heard(calls[event].rn)}`);\n  if (next === \"background\") console.log(\"    save now: from here the app can be killed without a word\");\n  state = next;\n}", "note": "Cada movimento imprime a linha da história, os estados e o que cada plataforma chamaria. Entrar em background imprime a regra da aula, porque é o último momento em que o app com certeza fica sabendo de algo."}]}
```

## Uma tarde

Rode sem argumentos, e ele encena a história do fim do arquivo:

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

**Leia os três últimos movimentos devagar.** Depois de "the home screen covers the app" o programa
imprime o aviso, e daí em diante as colunas das plataformas ficam vazias: a passagem para suspenso é
silenciosa, e a morte também. Quando Ana toca o ícone de novo, o Android chama `onCreate`, o mesmo
callback que chamou no primeiríssimo lançamento. A não ser que o app tenha anotado algo na saída,
isso parece para ele a primeira vez que roda na vida; a aula 5 trata do que anotar.

A ligação da primeira metade, desenhada como tempo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 205\" role=\"img\" data-fig=\"l04-call\" aria-label=\"Uma linha do tempo de uma ligação interrompendo o planner. Ana está escrevendo uma sessão e o app está ativo. A ligação chega: o app fica inativo; o Android chama onPause, o iOS informa .inactive, o React Native informa inactive só no iOS. Ela atende: o app vai para segundo plano; o Android chama onStop, o iOS informa .background, o React Native background. A ligação acaba e ela volta: o app fica ativo de novo; o Android chama onRestart, onStart e onResume, o iOS informa .inactive e depois .active, o React Native active. O processo continua vivo o tempo todo.\"><rect x=\"20\" y=\"40\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">ativo: escrevendo uma sessão</text><rect x=\"170\" y=\"40\" width=\"130\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">inativo: o telefone toca</text><rect x=\"300\" y=\"40\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"430.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">segundo plano: na ligação</text><rect x=\"560\" y=\"40\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"650.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">ativo: de volta</text><text x=\"170\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">a ligação chega</text><path d=\"M170 72 L170 160\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"300\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">atendida</text><path d=\"M300 72 L300 160\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"560\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">a ligação acaba</text><path d=\"M560 72 L560 160\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"20\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Android</text><text x=\"170\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">onPause</text><text x=\"300\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">onStop</text><text x=\"560\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">onRestart, onStart, onResume</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">iOS</text><text x=\"170\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">.inactive</text><text x=\"300\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">.background</text><text x=\"560\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">.inactive, .active</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">RN</text><text x=\"170\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">inactive (iOS)</text><text x=\"300\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">background</text><text x=\"560\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">active</text><text x=\"380\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">O processo esteve vivo o tempo todo: nada se perdeu, e nada precisou ser restaurado.</text></svg>", "caption": "A interrupção comum, e a gentil: o app é pausado e parado, nunca morto, então tudo o que estava na memória continua lá quando Ana volta.", "same": ["Android", "iOS", "RN"]}
```

**A ligação não mata o app, e no Android nem destrói a Activity.** O app é pausado, parado enquanto a
ligação ocupa a tela, e reiniciado quando Ana volta, com tudo o que estava na memória ainda lá. Esse
é o caso comum, e é por isso que um app que nunca salva o estado parece funcionar nos testes: o
celular de quem desenvolve tem memória sobrando, e quem desenvolve volta em menos de um minuto.

## Um movimento que não pode acontecer

Dê você mesmo os eventos ao programa, e ele encena só esses. Aqui o app é morto em segundo plano, e
depois o usuário "volta" para ele:

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

**Não se volta a um app morto; só dá para lançá-lo de novo.** O modelo recusa o movimento porque não
há nada para onde voltar, e essa recusa é o jeito do programa de dizer o que o usuário não vê: o
planner na tela de apps recentes depois de uma morte é uma imagem, e tocá-la começa um processo novo
a partir de `onCreate`. O que o processo antigo guardava na memória e não anotou se perdeu.

Faça o commit do arquivo:

```
ana@dev:~/planner$ git add lifecycle.ts
ana@dev:~/planner$ git commit -q -m "The lifecycle, as one model for both platforms"
```
