---
title: Dizer que algo mudou
version: 1
---

**Um leitor de tela lê aquilo para onde a pessoa vai. Uma mudança em outro lugar da página é silenciosa** a
menos que a página peça que ela seja lida. Quando uma sessão é acrescentada, o planner desenha uma linha
nova e um total novo, e quem não consegue vê-los não fica sabendo de nada, e pior, o foco foi embora junto
com o botão.

Uma **região viva** é o jeito de pedir. Um elemento com `role="status"`, ou `aria-live="polite"`, tem o seu
texto novo lido em voz alta quando muda, assim que o leitor termina o que está dizendo. O `role="alert"`, ou
`aria-live="assertive"`, interrompe, e é para erros que não podem esperar. Este pode esperar, então é um
status. O critério é o 4.1.3 *Mensagens de status*, nível AA.

**A região precisa existir antes de o texto chegar.** Um leitor vigia as regiões vivas que estão na página;
uma criada já com a mensagem dentro em geral não é lida por ninguém. O planner desenha a tela inteira com
`replaceChildren()`, que jogaria a região fora junto com todo o resto, então ela não pode fazer parte da
tela: ela é criada uma vez, ao lado da raiz, e mantida.

## O teste

```typescript
// e2e/screen-reader.spec.ts, below what is there
test("adding a session says so, and leaves the focus in the form", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await page.getByLabel("Date").fill("2026-10-23");
  await page.getByLabel("Minutes").fill("15");
  await page.getByRole("button", { name: "Add session" }).press("Enter");
  await expect(page.getByRole("status")).toHaveText("Session added: 2026-10-23, 15 min");
  await expect(page.getByLabel("Date")).toBeFocused();
});
```

O foco volta para o **Date**, o primeiro campo, porque a coisa mais provável depois de acrescentar uma
sessão é acrescentar outra.

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts -g 'says so' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/screen-reader.spec.ts:20:1 › adding a session says so, and leaves the focus in the form (5.4s)
    Error: expect(locator).toHaveText(expected) failed
    Locator: getByRole('status')
    Expected: "Session added: 2026-10-23, 15 min"
  1 failed
```

## A correção

O `render` ganha um segundo argumento, opcional, para o `update`: o que dizer. O tratador do formulário diz
o que fez e põe o foco de volta no formulário; o **Done** não diz nada, porque a aula 11 já move o foco para
uma linha que lê *done*. O app cria a região uma vez, a preenche a cada atualização e a esvazia na
navegação, para que uma mensagem sobre um curso não fique parada em outro. O diff do `src/view.ts` mostra
também o link de voltar de duas seções atrás, que ainda não foi para um commit:

```
ana@dev:~/planner$ git diff src
diff --git a/src/app.ts b/src/app.ts
index 9ba01d9..6d3b757 100644
--- a/src/app.ts
+++ b/src/app.ts
@@ -9,12 +9,17 @@ export async function start(root: HTMLElement, load = () => fetch("/courses.json
     return;
   }
   let plan: Plan = await response.json();
+  const status = document.createElement("p");
+  status.setAttribute("role", "status");
+  root.after(status);
   const draw = (): void =>
-    render(root, plan, today(), location.hash, (next) => {
+    render(root, plan, today(), location.hash, (next, said = "") => {
       plan = next;
       draw();
+      status.textContent = said;
     });
   window.addEventListener("hashchange", () => {
+    status.textContent = "";
     draw();
     const heading = root.querySelector("h1");
     if (heading) {
diff --git a/src/view.ts b/src/view.ts
index d627dd2..51c4797 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -1,7 +1,7 @@
 // src/view.ts
 import { addSession, markDone, weekTotal, type Plan } from "./planner";
 
-export function render(root: HTMLElement, plan: Plan, day: string, route: string, update: (next: Plan) => void): void {
+export function render(root: HTMLElement, plan: Plan, day: string, route: string, update: (next: Plan, said?: string) => void): void {
   const course = plan.courses.find((c) => route === `#/course/${c.id}`);
   root.replaceChildren();
   if (!course) {
@@ -21,7 +21,10 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
     root.append(list, el("p", `This week: ${weekTotal(plan, day)} min`, "week"));
     return;
   }
-  const back = el("a", "←", "back");
+  const back = el("a", " All courses", "back");
+  const arrow = el("span", "←");
+  arrow.setAttribute("aria-hidden", "true");
+  back.prepend(arrow);
   back.href = "#/";
   root.append(back, el("h1", course.title));
   const list = el("ul", "", "sessions");
@@ -55,7 +58,10 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
     event.preventDefault();
     const data = new FormData(form);
     const note = String(data.get("note") ?? "");
-    update(addSession(plan, course.id, String(data.get("date")), Number(data.get("minutes")), note));
+    const date = String(data.get("date"));
+    const minutes = Number(data.get("minutes"));
+    update(addSession(plan, course.id, date, minutes, note), `Session added: ${date}, ${minutes} min`);
+    root.querySelector<HTMLInputElement>(`input[name="date"]`)?.focus();
   });
   root.append(list, form, el("p", `This week: ${weekTotal(plan, day, course.id)} min`, "week"));
 }
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (265ms)
  ✓  2 [chromium] › e2e/screen-reader.spec.ts:13:1 › every page has one main landmark (215ms)
  ✓  3 [chromium] › e2e/screen-reader.spec.ts:20:1 › adding a session says so, and leaves the focus in the form (259ms)
  3 passed (3.9s)
```

O texto também é visível: uma linha sob o formulário dizendo o que acabou de ser acrescentado é útil para
todo mundo, e uma mensagem que só um leitor de tela consegue ouvir é uma que mais ninguém consegue
conferir.
