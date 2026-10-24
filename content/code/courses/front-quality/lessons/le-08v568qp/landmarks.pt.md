---
title: Landmarks, e as regras que o axe deixou de lado
version: 1
---

**Um landmark é uma região da página com um papel para o qual um leitor de tela consegue saltar.** O HTML dá
um elemento para cada um:

| elemento | landmark | o que fica lá |
|---|---|---|
| `<header>`, no nível de cima | banner | a área de cabeçalho do site |
| `<nav>` | navigation | um conjunto de links para andar pelo site |
| `<main>` | main | o conteúdo próprio da página, **um por página** |
| `<aside>` | complementary | algo ao lado do conteúdo |
| `<footer>`, no nível de cima | contentinfo | o rodapé do site |
| `<form>` com nome, `<section>` com nome | form, region | uma parte com nome |

A aula 10 deixou dois achados para esta aula. As regras `best-practice` do axe ficam fora do teste da WCAG,
e duas delas falham no planner. Para lê-las, deixe o `server/axe.mjs` pegar as etiquetas do ambiente:

```
ana@dev:~/planner$ git diff server/axe.mjs
diff --git a/server/axe.mjs b/server/axe.mjs
index 01bd488..647e39b 100644
--- a/server/axe.mjs
+++ b/server/axe.mjs
@@ -9,7 +9,7 @@ await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
 for (const address of process.argv.slice(2)) {
   await page.goto(address);
   await page.getByRole("heading", { level: 1 }).waitFor();
-  const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
+  const { violations } = await new AxeBuilder({ page }).withTags(process.env.AXE_TAGS?.split(",") ?? wcag22aa).analyze();
   console.log(`${address}: ${violations.length} rule(s) broken`);
   for (const v of violations) {
     console.log(`  ${v.id} (${v.impact}): ${v.help}`);
```

```
ana@dev:~/planner$ AXE_TAGS=best-practice node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'
http://localhost:5173/: 2 rule(s) broken
  landmark-one-main (moderate): Document should have one main landmark
    html  
  region (moderate): All page content should be contained by landmarks
    #app  Some page content is not contained by landmarks
http://localhost:5173/#/course/javascript: 2 rule(s) broken
  landmark-one-main (moderate): Document should have one main landmark
    html  
  region (moderate): All page content should be contained by landmarks
    a  Some page content is not contained by landmarks
    h1  Some page content is not contained by landmarks
    ul  Some page content is not contained by landmarks
    label:nth-child(1)  Some page content is not contained by landmarks
    label:nth-child(2)  Some page content is not contained by landmarks
    label:nth-child(3)  Some page content is not contained by landmarks
    p  Some page content is not contained by landmarks
```

A **`landmark-one-main`** pede um `main`; a **`region`** pede que tudo na página fique dentro de algum
landmark, para que nada escape a quem anda de landmark em landmark. Um teste que segura a primeira,
acrescentado ao `e2e/screen-reader.spec.ts`:

```typescript
// e2e/screen-reader.spec.ts, below what is there
test("every page has one main landmark", async ({ page }) => {
  for (const address of ["/", "/#/course/javascript"]) {
    await page.goto(address);
    await expect(page.getByRole("main")).toHaveCount(1);
  }
});
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts -g 'main landmark' 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✘  1 [chromium] › e2e/screen-reader.spec.ts:13:1 › every page has one main landmark (5.2s)
    Error: expect(locator).toHaveCount(expected) failed
    Locator:  getByRole('main')
    Expected: 1
    Received: 0
  1 failed
```

O conteúdo do planner é desenhado em `<div id="app">` no `index.html`, então a correção é na página, não no
código: a `div` vai para dentro de um `main`.

```
ana@dev:~/planner$ git diff index.html
diff --git a/index.html b/index.html
index 1c36a07..05c7eac 100644
--- a/index.html
+++ b/index.html
@@ -7,7 +7,9 @@
     <title>Study planner</title>
   </head>
   <body>
-    <div id="app"></div>
+    <main>
+      <div id="app"></div>
+    </main>
     <script type="module" src="/src/main.ts"></script>
   </body>
 </html>
```

```
ana@dev:~/planner$ AXE_TAGS=best-practice node server/axe.mjs http://localhost:5173/ 'http://localhost:5173/#/course/javascript'
http://localhost:5173/: 0 rule(s) broken
http://localhost:5173/#/course/javascript: 0 rule(s) broken
```

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (254ms)
  ✓  2 [chromium] › e2e/screen-reader.spec.ts:13:1 › every page has one main landmark (194ms)
  2 passed (3.6s)
```

**Um app de uma tela precisa de um landmark e de nenhum mais.** O planner não tem barra de navegação nem
rodapé, e inventá-los para ter landmarks seria acrescentar lugares para saltar que não guardam nada.
