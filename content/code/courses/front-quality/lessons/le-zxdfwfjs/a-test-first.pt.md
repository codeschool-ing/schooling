---
title: O teste primeiro
version: 1
---

**Um cabeçalho é uma promessa sobre o site, e o único jeito de cumpri-la é um teste que falha quando ela
some.** O Playwright consegue testar o site empacotado diretamente: subir o preview como um terceiro
servidor, e depois fazer requisições e abrir páginas contra ele. Acrescente o preview ao `webServer` do
`playwright.config.ts`:

```
ana@dev:~/planner$ git diff playwright.config.ts
diff --git a/playwright.config.ts b/playwright.config.ts
index 2894629..8c17527 100644
--- a/playwright.config.ts
+++ b/playwright.config.ts
@@ -12,5 +12,10 @@ export default defineConfig({
   webServer: [
     { command: "npm run api", url: "http://127.0.0.1:3000/api/plan", reuseExistingServer: true },
     { command: "npm run dev", url: "http://localhost:5173", reuseExistingServer: true },
+    {
+      command: "npm run build && npx vite preview --port 4173 --strictPort",
+      url: "http://localhost:4173",
+      reuseExistingServer: true,
+    },
   ],
 });
```

O `--strictPort` faz o preview falhar em vez de escorregar para outra porta, a armadilha da aula 1.
Depois, dois testes, um lendo os cabeçalhos e um abrindo a página sob eles. Salve isto como
`e2e/headers.spec.ts`:

```typescript
// e2e/headers.spec.ts
import { expect, test } from "@playwright/test";

const built = "http://localhost:4173/";

test("the built site is served with its security headers", async ({ request }) => {
  const headers = (await request.get(built)).headers();
  expect(headers["content-security-policy"]).toContain("script-src 'self'");
  expect(headers["content-security-policy"]).toContain("frame-ancestors 'none'");
  expect(headers["x-content-type-options"]).toBe("nosniff");
  expect(headers["referrer-policy"]).toBe("strict-origin-when-cross-origin");
  expect(headers["permissions-policy"]).toContain("camera=()");
  expect(headers["cross-origin-opener-policy"]).toBe("same-origin");
});

test("the built site works under its own policy", async ({ page }) => {
  const errors: string[] = [];
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(message.text());
  });
  await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
  await page.goto(built);
  await expect(page.getByText("This week: 160 min")).toBeVisible();
  expect(errors).toEqual([]);
});
```

**O segundo teste é o que mantém uma política honesta.** Uma Content Security Policy que quebra a página
é uma que alguém vai desligar no dia em que ela quebrar; um teste que abre a página sob a política e exige
nenhum erro no console pega a quebra antes de alguém ser tentado.

```
ana@dev:~/planner$ npx playwright test e2e/headers.spec.ts --reporter=list 2>&1 | grep -E "^  (✓|✘)|Error:|Received|passed|failed"
  ✘  1 [chromium] › e2e/headers.spec.ts:6:1 › the built site is served with its security headers (54ms)
  ✓  2 [chromium] › e2e/headers.spec.ts:16:1 › the built site works under its own policy (214ms)
    Error: expect(received).toContain(expected) // indexOf
    Received has value: undefined
  1 failed
  1 passed (4.8s)
```

O primeiro teste falha na primeira linha, porque não há `content-security-policy` nenhuma, e o segundo
passa, porque uma página sem política não tem o que violar. Os dois estão prestes a mudar.
