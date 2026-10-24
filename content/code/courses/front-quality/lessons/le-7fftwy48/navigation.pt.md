---
title: Mover o foco na navegação, e só nela
version: 1
---

**Quando um navegador carrega uma página nova, ele põe o foco de volta no começo do documento**, e um leitor
de tela anuncia o título da página nova. O planner nunca carrega uma página nova. Seguir um link muda a parte do endereço depois do `#`, o app desenha outra tela no mesmo documento, e o
navegador não faz nenhuma das duas coisas. O foco se perde junto com o link que o tinha, exatamente como
no **Done**, e quem usa um leitor de tela não fica sabendo de nada.

**Então um app de página única tem que fazer o que o navegador teria feito.** A resposta de costume, e a do
planner, é mover o foco para o título principal da tela nova. Um leitor de tela lê o título, que diz onde a
pessoa está, e o próximo Tab vai para o primeiro controle depois dele.

## Só na navegação

A primeira tela é o caso oposto. Nada foi seguido; o navegador acabou de carregar a página, e já pôs o foco
onde vai o foco de uma página nova. Movê-lo para o título nessa hora poria tudo o que está acima do título
atrás da pessoa, e o Tab andaria para a frente a partir do meio da página. Então são dois testes, um para
cada metade:

```typescript
// e2e/keyboard.spec.ts, below what is there
test("a link followed puts the focus on the new page's heading", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("link", { name: "JavaScript" }).press("Enter");
  await expect(page.getByRole("heading", { name: "JavaScript", level: 1 })).toBeFocused();
});

test("the first page leaves the focus where it was", async ({ page }) => {
  await page.goto("/");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  expect(await tabThrough(page, 1)).toEqual(["a HTML and CSS"]);
});
```

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts -g 'link followed|first page' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/keyboard.spec.ts:57:1 › a link followed puts the focus on the new page's heading (5.3s)
  ✓  2 [chromium] › e2e/keyboard.spec.ts:63:1 › the first page leaves the focus where it was (236ms)
    Error: expect(locator).toBeFocused() failed
    Locator:  getByRole('heading', { name: 'JavaScript', level: 1 })
    Expected: focused
    Received: inactive
  1 failed
  1 passed (9.7s)
```

**O segundo já passa, e é escrito agora para que a correção não possa quebrá-lo.** Uma correção que
focasse o título a cada desenho passaria no primeiro e falharia no segundo, e esse é o erro que este par
foi feito para pegar.

## A correção

A mudança pertence ao lugar onde o app sabe que houve uma navegação, que é o listener de `hashchange` em
`src/app.ts`. Um título também não pode receber o foco, então ele ganha o mesmo `tabindex="-1"` da linha
da sessão:

```
ana@dev:~/planner$ git diff src/app.ts
diff --git a/src/app.ts b/src/app.ts
index bd23cce..9ba01d9 100644
--- a/src/app.ts
+++ b/src/app.ts
@@ -14,6 +14,13 @@ export async function start(root: HTMLElement, load = () => fetch("/courses.json
       plan = next;
       draw();
     });
-  window.addEventListener("hashchange", draw);
+  window.addEventListener("hashchange", () => {
+    draw();
+    const heading = root.querySelector("h1");
+    if (heading) {
+      heading.tabIndex = -1;
+      heading.focus();
+    }
+  });
   draw();
 }
```

Desta vez roda a suíte inteira, não só o arquivo do teclado, porque as linhas das sessões e os títulos
agora têm um `tabindex`, e o axe tem opinião sobre tudo o que pode receber o foco. Aqui ele não tem
nenhuma.

```
ana@dev:~/planner$ npx playwright test 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓   1 [chromium] › e2e/empty.spec.ts:4:1 › a course with nothing planned says 0 for its week (657ms)
  ✓   3 [chromium] › e2e/frame.spec.ts:9:1 › another site cannot put the built planner in a frame (227ms)
  ✓   4 [chromium] › e2e/frame.spec.ts:13:1 › without the policy, the same frame loads: the control (244ms)
  ✓   5 [chromium] › e2e/headers.spec.ts:6:1 › the built site is served with its security headers (28ms)
  ✓   6 [chromium] › e2e/headers.spec.ts:16:1 › the built site works under its own policy (250ms)
  ✓   2 [chromium] › e2e/a11y.spec.ts:12:3 › the course list breaks no WCAG 2.2 AA rule axe can check (1.9s)
  ✓   7 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (578ms)
  ✓   9 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (393ms)
  ✓  10 [chromium] › e2e/keyboard.spec.ts:51:1 › after Done, the focus is on the session it marked (265ms)
  ✓  11 [chromium] › e2e/keyboard.spec.ts:57:1 › a link followed puts the focus on the new page's heading (281ms)
  ✓  12 [chromium] › e2e/keyboard.spec.ts:63:1 › the first page leaves the focus where it was (367ms)
  ✓   8 [chromium] › e2e/a11y.spec.ts:12:3 › a course page breaks no WCAG 2.2 AA rule axe can check (1.5s)
  ✓  13 [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week (266ms)
  ✓  14 [chromium] › e2e/storage.spec.ts:4:1 › the session cookie is out of reach of the page's scripts (296ms)
  ✓  15 [chromium] › e2e/planner.spec.ts:14:1 › a session added to a course counts in its week (361ms)
  ✓  16 [chromium] › e2e/planner.spec.ts:24:1 › Done marks a session and takes its button away (238ms)
  ✓  17 [chromium] › e2e/planner.spec.ts:30:1 › a failed load says so (167ms)
  17 passed (8.8s)
```

**O título mostra o anel quando o link foi seguido com Enter, e não quando foi clicado**, pela regra que a
penúltima seção descreveu: o foco herda o jeito como a pessoa chegou. Faça o commit das três correções e dos seus testes:

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Keyboard: a focus that can be seen, and that stays where it makes sense"
```
