---
title: Para onde vai o foco quando a página muda
version: 1
---

**Aperte Done pelo teclado e o foco some.** O planner desenha cada tela com `root.replaceChildren()`, então
marcar uma sessão como feita tira da página o botão que tinha o foco, e um elemento que não está mais na
página não pode segurá-lo. O foco volta para o `body`. O próximo Tab recomeça do alto da página, e um
leitor de tela não diz nada, ou diz o nome da página, num lugar para onde a pessoa não pediu para ir.

Isso falha no 2.4.3 *Ordem do foco*: o foco deveria andar numa ordem que preserva o sentido, e ser jogado
de volta para o começo não preserva sentido nenhum.

## Para onde ele deveria ir?

Para o elemento que tomou o lugar do que saiu, se houver um, e se não houver, para a coisa mais próxima
que faça sentido. Depois do **Done**, o botão é trocado pela palavra *done* na mesma linha, então a linha é
o lugar certo: um leitor de tela lê então *2026-10-22 · 30 min done*, que é a confirmação de que o toque
funcionou.

## O teste

```typescript
// e2e/keyboard.spec.ts, below what is there
test("after Done, the focus is on the session it marked", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await page.getByRole("button", { name: "Done" }).press("Enter");
  await expect(page.getByRole("listitem").filter({ hasText: "2026-10-22" })).toBeFocused();
});
```

O `press("Enter")` num locator foca o elemento e aperta a tecla, como faz quem chegou nele pelo Tab.

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts -g 'after Done' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/keyboard.spec.ts:51:1 › after Done, the focus is on the session it marked (5.3s)
    Error: expect(locator).toBeFocused() failed
    Locator:  getByRole('listitem').filter({ hasText: '2026-10-22' })
    Expected: focused
    Received: inactive
  1 failed
```

*inactive* é a palavra do Playwright para um elemento que não tem o foco.

## A correção

Um item de lista não pode receber o foco, então ele ganha **`tabindex="-1"`**, que deixa um script focá-lo
sem pô-lo na ordem de tabulação: o Tab continua indo de botão em botão. Cada linha também leva o id da
sessão, para que o tratador do clique encontre a linha nova depois que a tela é desenhada de novo:

```
ana@dev:~/planner$ git diff src/view.ts
diff --git a/src/view.ts b/src/view.ts
index 44588f5..d627dd2 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -27,11 +27,16 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
   const list = el("ul", "", "sessions");
   for (const s of plan.sessions.filter((s) => s.course === course.id)) {
     const item = el("li", `${s.date} · ${s.minutes} min `, s.done ? "session done" : "session");
+    item.dataset.session = String(s.id);
+    item.tabIndex = -1;
     if (s.done) {
       item.append(el("span", "done", "state"));
     } else {
       const tick = el("button", "Done", "tick");
-      tick.addEventListener("click", () => update(markDone(plan, s.id)));
+      tick.addEventListener("click", () => {
+        update(markDone(plan, s.id));
+        root.querySelector<HTMLElement>(`[data-session="${s.id}"]`)?.focus();
+      });
       item.append(tick);
     }
     if (s.note) {
```

O `update` desenha a tela nova antes de voltar, então o `querySelector` da linha seguinte encontra a linha
nova, não a antiga.

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (350ms)
  ✓  2 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (258ms)
  ✓  3 [chromium] › e2e/keyboard.spec.ts:51:1 › after Done, the focus is on the session it marked (172ms)
  3 passed (3.9s)
```
