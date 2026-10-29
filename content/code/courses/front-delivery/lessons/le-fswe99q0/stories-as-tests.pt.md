---
title: Stories como testes: uma foto e uma auditoria de cada uma
version: 1
---

**Toda story é um estado que alguém decidiu que valia ver, o que faz de toda story um caso de teste já
escrito.** Esta seção as transforma em testes: para cada story, em cada tema, abrir o quadro dela, comparar
uma captura de tela com a aprovada da última vez, e rodar o axe nela. Um componente que mudou por acidente
falha na primeira; um que ficou ilegível falha na segunda.

## Playwright

O **Playwright** controla um navegador de verdade a partir de um script; a aula 4 de front-quality o usa
para testes de ponta a ponta. Instale o executor de testes e a integração com o axe, fixados:

```
ana@dev:~/planner$ npm install --save-dev --save-exact @playwright/test@1.63.0 @axe-core/playwright@4.14.0 2>&1 | tail -1
found 0 vulnerabilities
ana@dev:~/planner$ npm pkg set scripts.test="vitest run src"
ana@dev:~/planner$ npx playwright --version
Version 1.63.0
```

O segundo comando importa tanto quanto o primeiro. O Vitest procura qualquer arquivo terminado em
`.spec.ts` ou `.test.ts`, então tentaria rodar o teste do Playwright como se fosse dele e falharia; apontar
os testes de unidade para `src` mantém os dois executores separados.

O **Playwright 1.63.0** controla um build específico do Chromium, que ele baixa separado do pacote, uma vez
por computador:

```sh
npx playwright install chromium
```

Esse comando não foi executado nesta gravação, cujo computador já tinha esse build do Chromium; no seu, ele
baixa uns 150 MB numa pasta dentro da sua pasta pessoal. No Linux, se o Chromium então não iniciar por
falta de bibliotecas do sistema, `npx playwright install --with-deps chromium` as instala, e pede `sudo`
para isso.

## A configuração e o teste

A configuração sobe o Storybook construído com o próprio host do planner antes dos testes, e o derruba
depois:

```typescript
// playwright.config.ts
import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "tests",
  use: { baseURL: "http://127.0.0.1:6007" },
  webServer: {
    command: "node host.mjs storybook-static 6007",
    url: "http://127.0.0.1:6007/iframe.html",
    reuseExistingServer: false,
  },
  projects: [{ name: "chromium", use: { browserName: "chromium", viewport: { width: 480, height: 200 } } }],
});
```

O teste visita cada story em cada tema:

```schooling-example
{"language": "typescript", "file": "tests/stories.spec.ts", "parts": [
 {"code": "// tests/stories.spec.ts\nimport AxeBuilder from \"@axe-core/playwright\";\nimport { expect, test } from \"@playwright/test\";", "note": "O executor de testes do Playwright, e o motor do axe embrulhado para ele, o mesmo que o `tools/a11y-test` do repositório deste próprio curso usa."},
 {"code": "\nconst stories = [\n  \"planner-session-row--to-do\",\n  \"planner-session-row--done\",\n  \"planner-session-row--long\",\n  \"planner-week-summary--in-progress\",\n  \"planner-week-summary--empty\",\n];", "note": "As stories pelo id, como o `index.json` as listou. Uma lista escrita, e não lida do índice, para uma story nova virar teste de propósito, e não por acidente."},
 {"code": "\nfor (const id of stories) {\n  for (const theme of [\"light\", \"dark\"]) {\n    test(`${id} in ${theme}`, async ({ page }) => {\n      await page.goto(`/iframe.html?id=${id}&viewMode=story&globals=theme:${theme}`);\n      const story = page.locator(\"#storybook-root\");", "note": "Um teste por story por tema: dez ao todo. O endereço do quadro leva o tema, como a seção sobre temas mostrou, e `#storybook-root` é o elemento em que o Storybook desenha a story."},
 {"code": "      await expect(story).toHaveScreenshot(`${id}-${theme}.png`);", "note": "Fotografar a story e compará-la com a imagem salva com aquele nome. A primeira execução não tem com o que comparar, então salva uma e falha, dizendo isso."},
 {"code": "      const results = await new AxeBuilder({ page }).include(\"#storybook-root\").analyze();\n      expect(results.violations.map((v) => v.id)).toEqual([]);\n    });\n  }\n}", "note": "Rodar o axe só na story, e esperar nenhuma violação. Listar os ids das regras faz uma falha dizer o que quebrou."}
]}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Cinco stories na lateral e dois temas no topo fazem dez testes. Cada teste abre o quadro da story, compara uma captura de tela com a imagem aprovada e roda o axe nela.\"><text x=\"270\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">light</text><text x=\"400\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dark</text><text x=\"20\" y=\"51\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">session-row--to-do</text><rect x=\"215\" y=\"40\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">foto</text><text x=\"295\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"345\" y=\"40\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">foto</text><text x=\"425\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><text x=\"20\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">session-row--done</text><rect x=\"215\" y=\"74\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">foto</text><text x=\"295\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"345\" y=\"74\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">foto</text><text x=\"425\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><text x=\"20\" y=\"119\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">session-row--long</text><rect x=\"215\" y=\"108\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">foto</text><text x=\"295\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"345\" y=\"108\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">foto</text><text x=\"425\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><text x=\"20\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">week-summary--in-progress</text><rect x=\"215\" y=\"142\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">foto</text><text x=\"295\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"345\" y=\"142\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">foto</text><text x=\"425\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><text x=\"20\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">week-summary--empty</text><rect x=\"215\" y=\"176\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">foto</text><text x=\"295\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"345\" y=\"176\" width=\"110\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">foto</text><text x=\"425\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">axe</text><rect x=\"500\" y=\"50\" width=\"200\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cada teste</text><text x=\"515\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1. abrir o quadro</text><text x=\"515\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. comparar a foto</text><text x=\"515\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. rodar o axe, nenhuma falha</text><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5 stories × 2 temas = 10 testes</text></svg>", "caption": "Toda story em todo tema é um teste que já sabe como deve parecer."}
```

Construa a oficina e rode os testes duas vezes:

```
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1
ana@dev:~/planner$ npx playwright test > first-run.txt 2>&1
ana@dev:~/planner$ grep -m1 "doesn't exist" first-run.txt
    Error: A snapshot doesn't exist at /home/ana/planner/tests/stories.spec.ts-snapshots/planner-session-row--to-do-light-chromium-linux.png, writing actual.
ana@dev:~/planner$ grep -E '^  [0-9]+ (failed|passed)' first-run.txt
  10 failed
ana@dev:~/planner$ ls tests/stories.spec.ts-snapshots | head -4
planner-session-row--done-dark-chromium-linux.png
planner-session-row--done-light-chromium-linux.png
planner-session-row--long-dark-chromium-linux.png
planner-session-row--long-light-chromium-linux.png
ana@dev:~/planner$ npx playwright test 2>&1 | tail -1
  10 passed (15.1s)
ana@dev:~/planner$ rm first-run.txt
```

**A primeira execução falha de propósito**: não havia imagens aprovadas, então o Playwright gravou cada uma
e relatou uma falha, em vez de passar uma comparação com nada. Olhe as imagens que ele salvou, em
`tests/stories.spec.ts-snapshots/`, e se estiverem certas, elas agora são o estado aprovado. A segunda
execução compara com elas e passa. As imagens vão para o commit junto com os testes.

## Uma mudança que ninguém pediu

Mude o raio dos cantos dos botões, como uma refatoração da folha de estilo poderia fazer por acidente,
reconstrua e teste:

```
ana@dev:~/planner$ sed -i 's/border-radius: var(--space-1);/border-radius: var(--space-4);/' src/style.css
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1
ana@dev:~/planner$ npx playwright test -g 'to-do in light' 2>&1 | grep -E 'pixels \(ratio|1 failed' | head -2
      144 pixels (ratio 0.02 of all image pixels) are different.
      - 144 pixels (ratio 0.02 of all image pixels) are different.
ana@dev:~/planner$ ls test-results/*/
error-context.md
planner-session-row--to-do-light-actual.png
planner-session-row--to-do-light-diff.png
planner-session-row--to-do-light-expected.png
```

**144 pixels diferem, dois por cento da imagem.** O Playwright também gravou três imagens em
`test-results/`: a aprovada, a nova, e uma de diferenças com os pixels mudados em vermelho, que é o que
quem revisa olha. Se a mudança foi intencional, `npx playwright test --update-snapshots` torna as imagens
novas as aprovadas, e essa atualização vai no pull request, onde alguém a vê. Esta não foi intencional:

```
ana@dev:~/planner$ git checkout src/style.css
Updated 1 path from the index
```
