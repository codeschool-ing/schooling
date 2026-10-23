---
title: A rede, sob o controle do teste
version: 1
---

**O `page.route` fica entre a página e a rede: toda requisição que corresponde ao padrão dele vai para
uma função que o teste escreveu, que pode respondê-la, atrasá-la, alterá-la ou deixá-la passar.** É a
versão de navegador do parâmetro `load` que a aula 3 deu ao `start()`, e não exige mudança nenhuma no
app.

O quarto teste do planner usou a forma mais simples, `route.fulfill({ status: 500 })`: a página pediu o
`courses.json` e recebeu um erro, sem servidor nenhum falhar, e o teste conferiu a frase que a página
mostrou. O atraso da seção anterior usou o `route.continue()` para mandar a requisição adiante depois de
uma pausa. Uma terceira forma responde com dados que o teste inventou, que é como testar um estado que o
arquivo de verdade não tem, como um curso sem nada planejado:

```typescript
// e2e/empty.spec.ts
import { expect, test } from "@playwright/test";

test("a course with nothing planned says 0 for its week", async ({ page }) => {
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
  await page.route("**/courses.json", (route) =>
    route.fulfill({ json: { courses: [{ id: "rust", title: "Rust" }], sessions: [] } }),
  );
  await page.goto("/#/course/rust");
  await expect(page.getByRole("heading", { name: "Rust" })).toBeVisible();
  await expect(page.getByRole("listitem")).toHaveCount(0);
  await expect(page.getByText("This week: 0 min")).toBeVisible();
});
```

```
ana@dev:~/planner$ npx playwright test e2e/empty.spec.ts --reporter=list

Running 1 test using 1 worker

  ✓  1 [chromium] › e2e/empty.spec.ts:4:1 › a course with nothing planned says 0 for its week (265ms)

  1 passed (1.4s)
```

## O que não fingir

Cada rota é uma parte do sistema que o teste deixa de conferir. Fingir o `courses.json` em todo teste
quereria dizer que nenhum teste carregou o arquivo de verdade, e um erro de digitação nele iria para
produção. A suíte do planner mantém os dados reais nos testes que são sobre o caminho e só os finge nos
testes que são sobre um caso que os dados reais não produzem: um erro, um curso vazio, uma resposta
lenta. **Finja a rede para chegar a um estado; não a finja para evitar o estado real.**
