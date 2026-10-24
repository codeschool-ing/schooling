---
title: Todo controle tem um nome
version: 1
---

**O nome acessível de um controle é o que um leitor de tela diz para ele, e é por ele que o `getByRole` o
encontra.** O navegador o calcula a partir da primeira destas coisas que o elemento tiver:

1. `aria-labelledby`, que aponta para outros elementos pelo id e usa o texto deles;
2. `aria-label`, um texto escrito no próprio elemento;
3. para um campo de formulário, o seu `<label>`; para uma imagem, o seu `alt`;
4. para um link ou um botão, o texto de dentro, incluindo o `alt` de qualquer imagem lá dentro;
5. em último caso, o atributo `title`, que a maioria das pessoas nunca vê.

**As palavras visíveis deveriam ser o nome, ou o começo dele.** O 2.5.3 *Rótulo no nome*, nível A, pede que
o nome de um controle contenha o texto que ele mostra, porque quem usa controle por voz diz o que vê:
*clicar Add session*. Um `aria-label` que renomeia um botão para outra coisa quebra o único jeito que essa
pessoa tem de apertá-lo.

## O link de voltar

O link de voltar do planner mostra uma seta e mais nada, então o nome dele é a seta. O trabalho dele é
voltar para a lista de cursos, então é isso que ele deveria dizer. A seta pode ficar para o olho e ser
escondida da árvore com `aria-hidden="true"`, que tira um elemento da árvore de acessibilidade e o deixa
na tela.

Comece um arquivo de testes para o que um leitor de tela ouve, `e2e/screen-reader.spec.ts`:

```typescript
// e2e/screen-reader.spec.ts
import { expect, test } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
});

test("the back link says where it goes", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await expect(page.getByRole("link", { name: "All courses" })).toBeVisible();
});
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (5.3s)
    Error: expect(locator).toBeVisible() failed
    Locator: getByRole('link', { name: 'All courses' })
    Expected: visible
  1 failed
```

A correção dá palavras ao link e esconde a seta da árvore:

```
ana@dev:~/planner$ git diff src/view.ts
diff --git a/src/view.ts b/src/view.ts
index d627dd2..2e2aadd 100644
--- a/src/view.ts
+++ b/src/view.ts
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
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  2 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (428ms)
  ✘  1 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (649ms)
  ✓  3 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (329ms)
  ✓  4 [chromium] › e2e/keyboard.spec.ts:51:1 › after Done, the focus is on the session it marked (207ms)
  ✓  5 [chromium] › e2e/keyboard.spec.ts:57:1 › a link followed puts the focus on the new page's heading (186ms)
  ✓  6 [chromium] › e2e/keyboard.spec.ts:63:1 › the first page leaves the focus where it was (168ms)
    - Expected  - 1
    + Received  + 1
    -   "a ←",
    +   "a ← All courses",
  1 failed
  5 passed (6.6s)
```

**O teste novo passa, e a caminhada da aula 11 falha**, porque ela descreve cada parada pelo texto, e o texto
da primeira parada mudou. A ordem não mudou. É o teste da caminhada fazendo aquilo para que foi escrito: ele
impede que uma mudança no caminho do teclado passe despercebida, e alguém decide. Aqui a decisão é fácil;
corrija a primeira linha dele:

```typescript
    "a ← All courses",
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (316ms)
  ✓  2 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (444ms)
  ✓  3 [chromium] › e2e/keyboard.spec.ts:38:1 › the focused control can be seen (238ms)
  ✓  4 [chromium] › e2e/keyboard.spec.ts:51:1 › after Done, the focus is on the session it marked (182ms)
  ✓  5 [chromium] › e2e/keyboard.spec.ts:57:1 › a link followed puts the focus on the new page's heading (209ms)
  ✓  6 [chromium] › e2e/keyboard.spec.ts:63:1 › the first page leaves the focus where it was (186ms)
  6 passed (4.6s)
```

A caminhada lê o `textContent`, que inclui a seta escondida; o leitor de tela lê o nome, que não inclui.
Os dois estão certos sobre o que medem.
