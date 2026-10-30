---
title: O planner, com as chamadas ao aparelho
version: 1
---

**Os cinco plugins moram num arquivo novo, `src/device.ts`**, e o resto do planner o chama. A regra da
aula 1 continua valendo: `planner.ts` não tem DOM nem plugin, então a aula 7 ainda pode levá-lo como
está. Salve o arquivo novo:

```schooling-example
{"language": "typescript", "file": "src/device.ts", "parts": [{"code": "// src/device.ts: what the planner asks of the device, through Capacitor's plugins.\nimport { Preferences } from \"@capacitor/preferences\";\nimport { Directory, Encoding, Filesystem } from \"@capacitor/filesystem\";\nimport { LocalNotifications } from \"@capacitor/local-notifications\";\nimport { Geolocation } from \"@capacitor/geolocation\";\nimport { Camera } from \"@capacitor/camera\";\nimport type { Plan, Session } from \"./planner\";\n", "note": "Um import por plugin, cada um do seu pacote, e os tipos do planner. Nada aqui toca o DOM; o `view.ts` continua desenhando tudo."}, {"code": "export async function loadPlan(): Promise<Plan | null> {\n  const { value } = await Preferences.get({ key: \"plan\" });\n  return value === null ? null : JSON.parse(value);\n}\n", "note": "O **Preferences** guarda textos pequenos sob uma chave. O plano vira JSON na entrada e volta na saída, e uma chave que nunca foi gravada volta como `null`."}, {"code": "export async function savePlan(plan: Plan): Promise<void> {\n  await Preferences.set({ key: \"plan\", value: JSON.stringify(plan) });\n}\n"}, {"code": "export async function exportPlan(plan: Plan): Promise<string> {\n  const file = { path: \"planner-export.json\", directory: Directory.Data, encoding: Encoding.UTF8 };\n  await Filesystem.writeFile({ ...file, data: JSON.stringify(plan) });\n  const back = await Filesystem.readFile(file);\n  return `exported ${String(back.data).length} characters to ${file.path}`;\n}\n", "note": "O **Filesystem** escreve o plano na pasta de dados do próprio app, e o lê de volta para provar que o arquivo está lá. `Directory.Data` é privada do app e não exige permissão."}, {"code": "export async function remind(session: Session, course: string): Promise<string> {\n  const { display } = await LocalNotifications.requestPermissions();\n  if (display !== \"granted\") return `notifications are ${display}`;\n  const at = new Date(`${session.date}T08:00:00`);\n  await LocalNotifications.schedule({\n    notifications: [{ id: Number(session.id.slice(1)), title: course, body: `${session.minutes} minutes today`, schedule: { at } }],\n  });\n  return `reminder at ${at.toLocaleString(\"en-GB\")}`;\n}\n", "note": "O **LocalNotifications** pergunta primeiro, e desiste com a resposta se ela não foi sim. Depois agenda uma notificação às oito da manhã do dia da sessão, com o número da sessão como id."}, {"code": "export async function whereAmI(): Promise<string> {\n  const { coords } = await Geolocation.getCurrentPosition();\n  return `studying at ${coords.latitude.toFixed(3)}, ${coords.longitude.toFixed(3)}`;\n}\n", "note": "O **Geolocation** pergunta ao aparelho onde ele está. A pergunta de permissão acontece dentro desta chamada, na primeira vez."}, {"code": "export async function photoOfNotes(): Promise<string> {\n  const photo = await Camera.takePhoto({ quality: 80, webUseInput: true });\n  const image = await (await fetch(photo.webPath!)).blob();\n  return `a photo, ${image.type}, ${image.size} bytes`;\n}", "note": "A **Camera** abre a câmera, ou na web um seletor de arquivo. `webPath` é um endereço que a página consegue carregar, e a função informa o tipo e o tamanho da imagem."}]}
```

**O `src/view.ts` ganha quatro botões e uma linha que diz o que aconteceu.** "Export plan" e "Where am
I?" na lista de cursos, "Remind me on" uma data ao lado de cada sessão não feita, e "Photo of my notes"
embaixo do formulário. A linha é um `<p role="status">`, que um leitor de tela anuncia quando o texto
muda sem ninguém ir até ela. Troque o arquivo:

```typescript
// src/view.ts: draws the plan, and tells main.ts what the person did.
import { weekTotal, type Plan } from "./planner";

export type Actions = {
  open: (course: string | null) => void;
  add: (course: string, date: string, minutes: number) => void;
  done: (session: string) => void;
  device: (what: "export" | "where" | "photo" | "remind", session?: string) => void;
};

function el<K extends keyof HTMLElementTagNameMap>(tag: K, text = ""): HTMLElementTagNameMap[K] {
  const e = document.createElement(tag);
  e.textContent = text;
  return e;
}

function button(text: string, onClick: () => void): HTMLButtonElement {
  const b = el("button", text);
  b.addEventListener("click", onClick);
  return b;
}

export function render(root: HTMLElement, plan: Plan, monday: string, open: string | null, status: string, act: Actions) {
  root.replaceChildren();
  const total = weekTotal(plan, monday);
  const week = el("p", `This week: ${total.done} of ${total.planned} minutes done`);
  week.id = "week";
  const said = el("p", status);
  said.setAttribute("role", "status");
  const course = plan.courses.find((c) => c.id === open);
  if (!course) {
    root.append(el("h1", "Study planner"), week);
    const list = el("ul");
    for (const c of plan.courses) {
      const li = el("li");
      li.append(button(c.name, () => act.open(c.id)));
      list.append(li);
    }
    root.append(list, button("Export plan", () => act.device("export")), button("Where am I?", () => act.device("where")), said);
    return;
  }
  root.append(button("All courses", () => act.open(null)), el("h1", course.name), week);
  const list = el("ul");
  for (const s of plan.sessions.filter((s) => s.course === course.id)) {
    const li = el("li", `${s.date}, ${s.minutes} min `);
    if (s.done) li.append(el("span", "done"));
    else li.append(button("Mark done", () => act.done(s.id)), button(`Remind me on ${s.date}`, () => act.device("remind", s.id)));
    list.append(li);
  }
  const form = el("form");
  form.innerHTML = `<label>Date <input name="date" type="date" required></label>
<label>Minutes <input name="minutes" type="number" min="1" required></label>
<button>Add session</button>`;
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const f = new FormData(form);
    act.add(course.id, String(f.get("date")), Number(f.get("minutes")));
  });
  root.append(list, form, button("Photo of my notes", () => act.device("photo")), said);
}
```

**O `src/main.ts` carrega o plano salvo antes do arquivo JSON, e salva depois de cada mudança.** As
chamadas ao aparelho ficam numa função que transforma qualquer falha numa frase na linha de status,
porque uma permissão recusada é uma resposta normal e não uma pane:

```typescript
// src/main.ts: loads the plan, keeps it, and redraws it after every change.
import { addSession, markDone, mondayOf, type Plan } from "./planner";
import { render } from "./view";
import { exportPlan, loadPlan, photoOfNotes, remind, savePlan, whereAmI } from "./device";

const root = document.querySelector<HTMLElement>("#app")!;
const today = new URLSearchParams(location.search).get("today") ?? new Date().toISOString().slice(0, 10);
let plan: Plan = (await loadPlan()) ?? (await (await fetch("courses.json")).json());
let open: string | null = null;
let status = "";

function change(next: Plan) {
  plan = next;
  savePlan(plan).catch((e) => say(`not saved: ${e.message}`));
  draw();
}

function say(text: string) {
  status = text;
  draw();
}

async function device(what: "export" | "where" | "photo" | "remind", id?: string) {
  try {
    if (what === "export") say(await exportPlan(plan));
    if (what === "where") say(await whereAmI());
    if (what === "photo") say(await photoOfNotes());
    if (what === "remind") {
      const s = plan.sessions.find((x) => x.id === id)!;
      say(await remind(s, plan.courses.find((c) => c.id === s.course)!.name));
    }
  } catch (e) {
    say(`${what} failed: ${(e as Error).message}`);
  }
}

function draw() {
  render(root, plan, mondayOf(today), open, status, {
    open: (c) => { open = c; status = ""; draw(); },
    add: (c, d, m) => change(addSession(plan, c, d, m)),
    done: (s) => change(markDone(plan, s)),
    device,
  });
}
draw();
```

O `look.mjs` precisa de mais três opções para esta aula: **`--reload`**, para carregar a página de novo
no mesmo navegador e ver o que ela guardou; **`--upload FILE`**, para responder ao seletor de arquivo
que a câmera web abre; e **`--eval`**, para imprimir um valor de dentro da página. Troque-o também:

```javascript
// look.mjs: open a page in Chromium and print what a screen reader is given.
//
//   node look.mjs URL [--click NAME] [--fill LABEL=TEXT] [--grant PERMISSION]
//                     [--geo LAT,LON] [--wait MS] [--reload] [--upload FILE]
//                     [--eval EXPRESSION] ...
//
// The options run in order, after the page has loaded. --click presses the
// button whose accessible name is NAME, --fill types TEXT into the field
// labelled LABEL, --grant and --geo answer the permission questions a page
// asks, and --wait lets timers run. Lesson 4 added the last three: --reload
// loads the page again in the same browser, --upload answers the next file
// picker with FILE, and --eval prints what EXPRESSION is worth in the page.
// Then it prints the accessibility tree of the page, and every console
// message and uncaught error on the way.
import { chromium } from "playwright";

const [url, ...args] = process.argv.slice(2);
const browser = await chromium.launch();
const context = await browser.newContext({ locale: "en-GB", timezoneId: process.env.TZ });
const page = await context.newPage();
page.on("console", (m) => console.log(`console.${m.type()}: ${m.text()}`));
page.on("pageerror", (e) => console.log(`uncaught: ${e.message}`));
await page.goto(url);
for (let i = 0; i < args.length; i += 2) {
  const [flag, value] = [args[i], args[i + 1]];
  if (flag === "--click") await page.getByRole("button", { name: value, exact: true }).first().click();
  else if (flag === "--fill") {
    const [label, text] = value.split("=");
    await page.getByLabel(label, { exact: true }).fill(text);
  } else if (flag === "--grant") await context.grantPermissions([value], { origin: new URL(url).origin });
  else if (flag === "--geo") {
    const [latitude, longitude] = value.split(",").map(Number);
    await context.setGeolocation({ latitude, longitude });
  } else if (flag === "--wait") await page.waitForTimeout(Number(value));
  else if (flag === "--reload") { await page.reload(); i -= 1; }
  else if (flag === "--upload") page.once("filechooser", (chooser) => chooser.setFiles(value));
  else if (flag === "--eval") console.log(`${value} = ${await page.evaluate(value)}`);
  else throw new Error(`look: unknown option ${flag}`);
}
console.log(await page.locator("body").ariaSnapshot());
await browser.close();
```

Depois construa, o que também confere que cada plugin é chamado com os tipos que declara:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 25 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                       0.48 kB │ gzip: 0.28 kB
dist/assets/definitions-DlpntO5o.js   0.35 kB │ gzip: 0.25 kB
dist/assets/web-DpFAyu0A.js           1.19 kB │ gzip: 0.54 kB
dist/assets/web--6ckLfXI.js           2.08 kB │ gzip: 0.85 kB
dist/assets/web-DLR-cNiO.js           4.43 kB │ gzip: 1.29 kB
dist/assets/dist-iCT9NZ5Z.js          7.75 kB │ gzip: 3.09 kB
dist/assets/web-Dr3H1z9W.js           8.47 kB │ gzip: 2.82 kB
dist/assets/index-eEcbLLi_.js        17.19 kB │ gzip: 6.08 kB

✓ built in 246ms
```
