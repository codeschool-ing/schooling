---
title: A caminhada por uma página, como teste
version: 1
---

**O primeiro teste aperta Tab e anota para onde o foco vai.** Essa lista é a ordem de tabulação da página,
e um teste que a segura transforma qualquer mudança na ordem numa decisão que alguém precisa tomar. Salve
isto como `e2e/keyboard.spec.ts`:

```typescript
// e2e/keyboard.spec.ts
import { expect, test, type Page } from "@playwright/test";

test.beforeEach(async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
});

async function tabThrough(page: Page, presses: number): Promise<string[]> {
  const seen: string[] = [];
  for (let i = 0; i < presses; i++) {
    await page.keyboard.press("Tab");
    seen.push(
      await page.evaluate(() => {
        const e = document.activeElement!;
        return `${e.tagName.toLowerCase()} ${e.getAttribute("name") ?? e.textContent}`;
      }),
    );
  }
  return seen;
}

test("Tab reaches every control of a course page, in reading order", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  expect(await tabThrough(page, 6)).toEqual([
    "a ←",
    "button Done",
    "input date",
    "input minutes",
    "textarea note",
    "button Add session",
  ]);
});
```

O `page.keyboard.press("Tab")` é um toque de tecla de verdade, mandado ao navegador como o sistema
operacional mandaria. O `document.activeElement` é o elemento que tem o foco, e o `tabThrough` descreve
cada um pela tag e pelo `name`, ou pelo texto quando não tem nome. A lista esperada é uma previsão feita
lendo a página de cima para baixo: o link de voltar, o único botão **Done** do curso de JavaScript, os
três campos e o botão do formulário.

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (378ms)
    - Expected  - 3
    + Received  + 3
    -   "input minutes",
    -   "textarea note",
    -   "button Add session",
    +   "input date",
    +   "input date",
    +   "input date",
  1 failed
```

**A previsão estava errada, e a página estava certa.** O Chromium para num campo de data quatro vezes:
uma em cada parte da data, mês, dia e ano, e uma no botão ao lado delas que abre um calendário. Quem
preenche o formulário pelo teclado aperta Tab quatro vezes para atravessá-lo, então seis toques nunca
chegaram aos minutos, à nota nem ao botão. No relatório, `-` é o que o teste esperava e `+` o que a
página fez. Corrija a expectativa:

```typescript
  expect(await tabThrough(page, 9)).toEqual([
    "a ←",
    "button Done",
    "input date",
    "input date",
    "input date",
    "input date",
    "input minutes",
    "textarea note",
    "button Add session",
  ]);
```

```
ana@dev:~/planner$ npx playwright test e2e/keyboard.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/keyboard.spec.ts:22:1 › Tab reaches every control of a course page, in reading order (354ms)
  1 passed (3.5s)
```

A ordem está certa: ela segue a página de cima para baixo, do jeito que ela se lê. **Este teste passa e
continua passando até alguém mover um controle**, e aí falha com a ordem nova impressa, que é o momento de
perguntar se a ordem nova ainda faz sentido. O texto do link de voltar, uma seta sozinha, é um problema à
parte, e é da aula 12: um leitor de tela o lê como *seta para a esquerda*.
