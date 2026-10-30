---
title: Uma permissão, duas plataformas, quatro cenários
version: 1
---

**As regras das duas últimas seções cabem num arquivo de cinco funções pequenas, e rodá-las lado a
lado deixa clara a diferença entre os dois tipos de app.** O `permission.ts` guarda uma permissão de
tempo de execução, a permissão de lembrete do planner, como um valor com uma plataforma e um estado.
Cada função é uma frase da documentação das plataformas: se pedir mostra um diálogo, o que uma resposta
faz, quando o Android manda explicar, o que ligar nos Ajustes faz, e o que o planner faz em seguida.
Salve-o como `permission.ts` em `~/planner`:

```schooling-example
{"language": "typescript", "file": "permission.ts", "parts": [{"code": "// permission.ts: one runtime permission, as each platform's documentation describes it\nexport type Platform = \"android\" | \"ios\";\nexport type State = \"not-asked\" | \"granted\" | \"denied\" | \"denied-for-good\";\nexport type Permission = { platform: Platform; state: State };\n\nexport function fresh(platform: Platform): Permission {\n  return { platform, state: \"not-asked\" };\n}\n", "note": "Uma permissão é uma plataforma e um estado, e mais nada. Os quatro estados são os que a documentação nomeia; `not-asked` e `denied-for-good` são os dois que um app não distingue só pela chamada de justificativa do Android, e é por isso que o modelo os mantém separados."}, {"code": "// Does asking show the system's dialog? Android shows it again after one\n// \"no\"; iOS shows it once, ever. After that, asking answers at once.\nexport function showsDialog(p: Permission): boolean {\n  if (p.state === \"not-asked\") return true;\n  return p.platform === \"android\" && p.state === \"denied\";\n}\n", "note": "A regra que difere. Um primeiro pedido mostra o diálogo nas duas; depois de um não, só o Android o mostra de novo. Em todo outro estado o pedido responde na hora, sem diálogo para a pessoa ver."}, {"code": "// The person's answer to the dialog. A second \"no\" on Android, and the\n// first on iOS, is final: the dialog never comes back.\nexport function answer(p: Permission, yes: boolean): Permission {\n  if (yes) return { ...p, state: \"granted\" };\n  const final = p.platform === \"ios\" || p.state === \"denied\";\n  return { ...p, state: final ? \"denied-for-good\" : \"denied\" };\n}\n", "note": "`final` é a diferença inteira entre as plataformas numa linha: no iOS todo não é final, no Android um não é final quando já houve um antes."}, {"code": "// Android's shouldShowRequestPermissionRationale(): true after one \"no\",\n// while one more dialog is still possible. iOS has no such call.\nexport function rationale(p: Permission): boolean {\n  return p.platform === \"android\" && p.state === \"denied\";\n}\n", "note": "`true` só na janela entre os dois diálogos do Android, que é quando a documentação manda explicar. Antes de qualquer pedido e depois do não final ela é `false` do mesmo jeito."}, {"code": "// The person can always change their mind in the system's Settings app.\nexport function turnedOnInSettings(p: Permission): Permission {\n  return { ...p, state: \"granted\" };\n}\n", "note": "O caminho de volta de qualquer estado, nas duas plataformas, e só por escolha da pessoa: nenhuma chamada do app leva até aqui."}, {"code": "// What the planner does next, in each state. Planning sessions never needs\n// the permission; only the reminder for a session does.\nexport function next(p: Permission): string {\n  if (p.state === \"granted\") return \"send reminders\";\n  if (p.state === \"not-asked\") return \"ask when a reminder is wanted\";\n  if (p.state === \"denied\") return \"explain why, then ask once more\";\n  return \"plan without reminders; offer Settings\";\n}", "note": "O que o planner faz com a resposta. Todo estado menos `granted` continua planejando sessões; só o lembrete depende da permissão."}]}
```

**Nada no arquivo pergunta coisa alguma à pessoa.** Ele é a metade do sistema: um modelo do que a
plataforma vai e não vai fazer quando o app pede. A metade do app é a ordem em que ele pede, e é isso
que o segundo arquivo varia. Ele encena quatro cenários, dois por plataforma. Num, o app pede na
abertura e a aluna recusa; no outro, o app espera até a aluna tocar em "remind me". Salve-o como
`ask.ts`:

```typescript
// ask.ts: when the planner asks to send reminders, and what it may do after
import { fresh, showsDialog, answer, rationale, turnedOnInSettings, next } from "./permission.ts";
import type { Platform, Permission } from "./permission.ts";

type Step = { when: string; ask?: "yes" | "no" | "nothing"; settings?: true };
type Scenario = { title: string; platform: Platform; steps: Step[] };

const scenarios: Scenario[] = [
  { title: "asked at launch, refused twice", platform: "android", steps: [
    { when: "first launch", ask: "no" },
    { when: "second launch", ask: "no" },
    { when: "taps 'remind me'", ask: "nothing" },
    { when: "turns it on in Settings", settings: true },
  ] },
  { title: "asked in context, after explaining", platform: "android", steps: [
    { when: "first launch" },
    { when: "taps 'remind me'", ask: "yes" },
  ] },
  { title: "asked at launch, refused once", platform: "ios", steps: [
    { when: "first launch", ask: "no" },
    { when: "taps 'remind me'", ask: "nothing" },
  ] },
  { title: "asked in context, after explaining", platform: "ios", steps: [
    { when: "first launch" },
    { when: "taps 'remind me'", ask: "yes" },
  ] },
];

function row(...cells: string[]) {
  const widths = [24, 8, 8, 17, 11];
  console.log("  " + cells.map((c, i) => c.padEnd(widths[i] ?? 0)).join("").trimEnd());
}

for (const s of scenarios) {
  console.log(`${s.platform}: ${s.title}`);
  row("when", "dialog", "answer", "state", "rationale", "the planner will");
  let p: Permission = fresh(s.platform);
  for (const step of s.steps) {
    let dialog = "-";
    let said = "-";
    if (step.settings) {
      p = turnedOnInSettings(p);
    } else if (step.ask !== undefined) {
      const shown = showsDialog(p);
      dialog = shown ? "shown" : "none";
      if (shown && step.ask !== "nothing") {
        said = step.ask;
        p = answer(p, step.ask === "yes");
      }
    }
    row(step.when, dialog, said, p.state, rationale(p) ? "yes" : "no", next(p));
  }
  console.log();
}
```

Um passo sem `ask` é um momento em que o app não pede nada; `"nothing"` quer dizer que o app pediu mas
a pessoa não viu diálogo para responder. Rode:

```
ana@dev:~/planner$ node ask.ts
android: asked at launch, refused twice
  when                    dialog  answer  state            rationale  the planner will
  first launch            shown   no      denied           yes        explain why, then ask once more
  second launch           shown   no      denied-for-good  no         plan without reminders; offer Settings
  taps 'remind me'        none    -       denied-for-good  no         plan without reminders; offer Settings
  turns it on in Settings -       -       granted          no         send reminders

android: asked in context, after explaining
  when                    dialog  answer  state            rationale  the planner will
  first launch            -       -       not-asked        no         ask when a reminder is wanted
  taps 'remind me'        shown   yes     granted          no         send reminders

ios: asked at launch, refused once
  when                    dialog  answer  state            rationale  the planner will
  first launch            shown   no      denied-for-good  no         plan without reminders; offer Settings
  taps 'remind me'        none    -       denied-for-good  no         plan without reminders; offer Settings

ios: asked in context, after explaining
  when                    dialog  answer  state            rationale  the planner will
  first launch            -       -       not-asked        no         ask when a reminder is wanted
  taps 'remind me'        shown   yes     granted          no         send reminders
```

## Lendo as quatro tabelas

**A primeira tabela é a cara.** O planner pediu na primeira abertura e a aluna, que ainda não tinha
visto uma sessão, disse não. O Android então deu mais uma chance ao app, e `rationale` disse `yes`: esse
era o momento de explicar. O app pediu de novo na segunda abertura, sem mais motivo que da primeira vez,
e o segundo não tornou a negação permanente. Quando a aluna enfim quis um lembrete e tocou em "remind
me", a coluna do diálogo diz `none`: o sistema respondeu por ela. Só a última linha, em que a aluna vai
aos Ajustes por escolha própria, traz os lembretes de volta.

**A segunda tabela é a mesma aluna e o mesmo app, pedindo num momento diferente.** Nada acontece na
abertura. O primeiro diálogo aparece quando a aluna toca em "remind me", ela entende por que ele está
ali, e diz sim. A permissão nunca correu perigo.

**As tabelas do iOS são mais curtas porque o iOS tem um diálogo só.** Pedida na abertura e recusada, a
permissão fica `denied-for-good` depois de uma única resposta, e `rationale` nunca diz `yes` porque a
plataforma não tem essa chamada. Pedida no contexto, ela é concedida no primeiro e único diálogo. Nas
duas plataformas a coluna da direita concorda com a seção anterior: depois do não final, o planner
continua planejando, e oferece os Ajustes.

**Conte os diálogos, porque são eles que a pessoa vê.** O app que pediu na abertura, no Android,
mostrou dois diálogos e terminou sem lembretes; o que pediu no contexto mostrou um e terminou com eles.
Nada na permissão mudou entre os dois, só o momento, que é o argumento desta aula em duas tabelas.
