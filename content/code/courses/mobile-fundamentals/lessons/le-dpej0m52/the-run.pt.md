---
title: Onze toques, e cada pilha depois de cada um
version: 1
---

**Um segundo arquivo encena a sessão de uma aluna contra o `backstack.ts`.** Duas telas são abertas em
Courses, depois vem uma troca para Week e uma tela ali, a volta para Courses, e voltar até não sobrar
nada.
Ele imprime uma linha por passo: qual aba está aparecendo, o que cada pilha guarda da raiz para cima, e
se um iPhone desenharia um botão de voltar naquele momento. Salve-o como `taps.ts`, ao lado do
`backstack.ts`:

```typescript
// taps.ts: taps and back presses on the planner, and the stacks after each
import { start, open, tap, back, backButton, type Nav, type Tab } from "./backstack.ts";

type Step = { tap: Tab } | { open: string } | { back: true };
const steps: Step[] = [
  { open: "course:sql" },
  { open: "new-session" },
  { tap: "Week" },
  { open: "session:s3" },
  { tap: "Courses" },
  { back: true },
  { tap: "Courses" },
  { tap: "Week" },
  { back: true },
  { back: true },
  { back: true },
];

function row(...cells: string[]) {
  const widths = [18, 9, 36, 20, 10];
  console.log(cells.map((c, i) => c.padEnd(widths[i] ?? 0)).join("").trimEnd());
}
function line(label: string, nav: Nav, note = "") {
  row(label, nav.tab, nav.stacks.Courses.join(" > "), nav.stacks.Week.join(" > "),
    backButton(nav) ? "yes" : "no", note);
}

let nav = start();
row("step", "tab", "Courses stack", "Week stack", "iOS back");
line("(app opens)", nav);
for (const s of steps) {
  if ("open" in s) {
    nav = open(nav, s.open);
    line("open " + s.open, nav);
  } else if ("tap" in s) {
    nav = tap(nav, s.tap);
    line("tap " + s.tap, nav);
  } else {
    const r = back(nav);
    nav = r.nav;
    line("Android back", nav, r.left ? "(the app leaves)" : "");
  }
}
```

`Step` é uma união de três formatos, e `"open" in s` distingue um do outro; o TypeScript estreita o
tipo de `s` dentro de cada ramo, então `s.open` e `s.tap` existem com certeza onde são lidos. Rode:

```
ana@dev:~/planner$ node taps.ts
step              tab      Courses stack                       Week stack          iOS back
(app opens)       Courses  courses                             week                no
open course:sql   Courses  courses > course:sql                week                yes
open new-session  Courses  courses > course:sql > new-session  week                yes
tap Week          Week     courses > course:sql > new-session  week                no
open session:s3   Week     courses > course:sql > new-session  week > session:s3   yes
tap Courses       Courses  courses > course:sql > new-session  week > session:s3   yes
Android back      Courses  courses > course:sql                week > session:s3   yes
tap Courses       Courses  courses                             week > session:s3   no
tap Week          Week     courses                             week > session:s3   yes
Android back      Week     courses                             week                no
Android back      Courses  courses                             week                no
Android back      Courses  courses                             week                no        (the app leaves)
```

## Lendo linha por linha

**As linhas 4 a 6 são a razão de existirem abas.** Depois da troca para Week, a coluna de Courses
continua dizendo `courses > course:sql > new-session`, intocada enquanto a aluna empilhava `session:s3`
em Week. Tocar em Courses a traz de volta como estava, com formulário e tudo. Uma lista única de
histórico não conseguiria isso: a tela de Week teria sido empilhada por cima do formulário, e voltar
dela cairia no meio de Courses.

**A coluna `iOS back` muda com a aba, não com o tempo.** Na linha 4 ela diz `no`, embora a aluna tenha
aberto três telas: a aba que aparece é Week, na raiz, e um iPhone não desenha botão de voltar ali. Uma
linha depois, Week tem uma tela empilhada e a resposta é `yes`.

**A linha 8 é um segundo toque na aba que já está aparecendo.** A pilha de Courses cai de duas telas
para uma num passo só, enquanto Week mantém `session:s3`, porque a regra só mexe na aba que foi tocada.

**As três últimas linhas são o voltar do Android ficando sem telas.** O primeiro desempilha
`session:s3`. O segundo encontra Week na raiz, então troca para Courses, a aba inicial, e não
desempilha nada. O terceiro encontra Courses na raiz, e o app não tem mais para onde ir: o estado não
muda e a linha diz que o app sai. Num iPhone nenhum desses três toques existe, e a coluna diz `no`
desde que a pilha de Week esvaziou.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l10-stacks\" aria-label=\"As pilhas de Courses e de Week em sete momentos da sessão de taps.ts. Depois de abrir new-session, Courses tem courses, course:sql e new-session, e Week tem week. Depois de abrir session:s3 em Week, Week tem week e session:s3 e Courses não muda. Depois do voltar do Android em Courses, Courses perde new-session. Depois de um segundo toque em Courses, Courses fica só com a raiz. Então, em Week, voltar desempilha session:s3, o voltar seguinte troca para Courses, e o último voltar encontra Courses na raiz e o app sai.\"><text x=\"14\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Courses</text><text x=\"14\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Week</text><text x=\"118\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">open new-session</text><text x=\"118\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">linha 3</text><rect x=\"76\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"76\" y=\"88\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">course:sql</text><rect x=\"76\" y=\"64\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">new-session</text><rect x=\"76\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><text x=\"210\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">open session:s3</text><text x=\"210\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">linha 5</text><rect x=\"168\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"168\" y=\"88\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">course:sql</text><rect x=\"168\" y=\"64\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">new-session</text><rect x=\"168\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><rect x=\"168\" y=\"208\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">session:s3</text><text x=\"302\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android back</text><text x=\"302\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">linha 7</text><rect x=\"260\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"302.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"260\" y=\"88\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"302.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">course:sql</text><rect x=\"260\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"302.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><rect x=\"260\" y=\"208\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"302.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">session:s3</text><text x=\"394\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">tap Courses</text><text x=\"394\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">linha 8</text><rect x=\"352\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"394.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"352\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"394.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><rect x=\"352\" y=\"208\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"394.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">session:s3</text><text x=\"486\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android back</text><text x=\"486\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">linha 10</text><rect x=\"444\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"486.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"444\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"486.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><text x=\"578\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android back</text><text x=\"578\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">linha 11</text><rect x=\"536\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"578.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"536\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"578.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><text x=\"670\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Android back</text><text x=\"670\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">linha 12</text><rect x=\"628\" y=\"112\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"670.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">courses</text><rect x=\"628\" y=\"232\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"670.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">week</text><rect x=\"76\" y=\"150\" width=\"636\" height=\"1\" rx=\"0\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></rect><rect x=\"628\" y=\"160\" width=\"84\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"670.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">o app sai</text><rect x=\"20\" y=\"272\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"277\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a aba que aparece</text></svg>", "caption": "A pilha de cada aba só muda enquanto aquela aba aparece. Os três últimos voltar desempilham, trocam para a aba inicial e saem.", "same": ["Courses", "Week"]}
```

**Conte os toques a partir do ponto mais fundo.** Digamos que Courses tenha três telas e Week duas. A
partir do formulário de nova sessão, dois voltar levam Courses até a raiz e mais um sai: três ao todo,
porque a aluna já está na aba inicial. A partir de `session:s3` em Week também são
três: um desempilha, um troca, um sai. Faça o commit dos dois arquivos, para que o que esta aula
acrescentou seja um commit só dela:

```
ana@dev:~/planner$ git add backstack.ts taps.ts
ana@dev:~/planner$ git commit -q -m "Two tabs, each with its own back stack"
```
