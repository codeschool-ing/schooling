---
title: Segurando a árvore num teste
version: 1
---

**Eis a página de curso como o navegador a descreve agora**, pelo mesmo programa de antes:

```
ana@dev:~/planner$ node server/tree.mjs 'http://localhost:5173/#/course/javascript'
http://localhost:5173/#/course/javascript
- main:
  - link "All courses":
    - /url: "#/"
  - heading "JavaScript" [level=1]
  - list:
    - listitem: 2026-10-20 · 60 min done
    - listitem:
      - text: 2026-10-22 · 30 min
      - button "Done"
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes"
  - text: Note
  - textbox "Note"
  - button "Add session"
  - paragraph: "This week: 90 min"
  - status
```

O link de voltar é *All courses*, tudo fica dentro do `main`, e a linha de status está lá, vazia e
esperando. **O Playwright consegue segurar essa forma inteira numa asserção só**, o `toMatchAriaSnapshot`,
que compara uma parte da página com um modelo no mesmo YAML. Acrescente um último teste ao
`e2e/screen-reader.spec.ts`:

```typescript
// e2e/screen-reader.spec.ts, below what is there
test("a course page reads as it should", async ({ page }) => {
  await page.goto("/#/course/javascript");
  await expect(page.getByRole("main")).toMatchAriaSnapshot(`
    - link "All courses"
    - heading "JavaScript" [level=1]
    - list:
      - listitem: 2026-10-20 · 60 min done
      - listitem:
        - text: 2026-10-22 · 30 min
        - button "Done"
    - textbox "Date"
    - spinbutton "Minutes"
    - textbox "Note"
    - button "Add session"
    - paragraph: "This week: 90 min"
  `);
});
```

O modelo não precisa de todas as linhas: ele casa quando a página tem esses elementos, nessa ordem, com esses
papéis e nomes, e ignora o que o modelo deixa de fora, como o endereço de cada link e o próprio texto dos
rótulos. **Uma mudança num nome, num papel, no nível de um título ou na ordem o faz falhar**, e a falha
imprime as duas árvores. É a árvore que uma pessoa ouve, segura com a mesma firmeza com que um teste de
unidade segura o resultado de uma função.

```
ana@dev:~/planner$ npx playwright test e2e/screen-reader.spec.ts 2>&1 | grep -E "^  (✓|✘)|^    [-+] |^    (Expected|Received|Locator):|passed|failed"
  ✓  1 [chromium] › e2e/screen-reader.spec.ts:8:1 › the back link says where it goes (249ms)
  ✓  2 [chromium] › e2e/screen-reader.spec.ts:13:1 › every page has one main landmark (199ms)
  ✓  3 [chromium] › e2e/screen-reader.spec.ts:20:1 › adding a session says so, and leaves the focus in the form (246ms)
  ✓  4 [chromium] › e2e/screen-reader.spec.ts:29:1 › a course page reads as it should (171ms)
  4 passed (4.1s)
```

E tudo, os dois executores, antes do commit:

```
ana@dev:~/planner$ npx tsc --noEmit && npx vitest run 2>&1 | grep -E "Test Files|Tests "
 Test Files  5 passed (5)
      Tests  35 passed (35)
ana@dev:~/planner$ npx playwright test 2>&1 | tail -1
  21 passed (7.6s)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "What a screen reader is told: a named back link, a main landmark, a status line"
```

## O que o snapshot não é

Ele é um registro do que a árvore diz hoje, e só vale o que foi conferido quando ele foi escrito. O
Playwright consegue escrever o modelo para você a partir da página como ela está, e um modelo escrito
assim, nunca lido, segura um erro com a mesma firmeza com que segura a resposta certa. Leia cada linha dele
como a pessoa que usa leitor de tela e vai ouvi-lo.
