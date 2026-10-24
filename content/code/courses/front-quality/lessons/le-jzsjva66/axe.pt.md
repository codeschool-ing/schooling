---
title: O axe, uma máquina para o que uma máquina consegue decidir
version: 1
---

**O axe-core é um motor de regras de acessibilidade que roda dentro de uma página e aponta cada elemento que
quebra uma delas.** É código aberto, da Deque, e é a base da maioria dos verificadores de acessibilidade,
inclusive os que vêm nas ferramentas de desenvolvedor do Chrome. O `@axe-core/playwright` o coloca no
navegador que um teste do Playwright já controla:

```
ana@dev:~/planner$ npm install --save-exact -D @axe-core/playwright@4.14.0

added 2 packages, and audited 116 packages in 729ms

found 0 vulnerabilities
```

Cada regra do axe tem etiquetas que dizem o que ela testa, e um teste escolhe as regras por etiqueta.
**Estas cinco são a WCAG 2.2 no nível AA**, todos os critérios dos níveis A e AA de cada versão, já que a
2.2 se apoia na 2.1 e a 2.1 na 2.0:

| etiqueta | os critérios |
|---|---|
| `wcag2a`, `wcag2aa` | WCAG 2.0, níveis A e AA |
| `wcag21a`, `wcag21aa` | acrescentados na 2.1 |
| `wcag22aa` | acrescentados na 2.2 |

O axe também tem regras com a etiqueta `best-practice`, que são bons conselhos que nenhum critério da WCAG
exige, como toda página ter exatamente um landmark `main`. Vale a pena lê-las, e elas ficam fora de um
aprovado ou reprovado na WCAG, para que um teste vermelho sempre queira dizer que um critério falhou.

Antes do teste, um programa pequeno que imprime em palavras o que o axe encontra, para que os achados
possam ser lidos e não só contados. Salve como `server/axe.mjs`:

```javascript
// server/axe.mjs
import { chromium } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

const wcag22aa = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "wcag22aa"];
const browser = await chromium.launch();
const page = await (await browser.newContext()).newPage();
await page.clock.setFixedTime(new Date("2026-10-21T10:00:00-03:00"));
for (const address of process.argv.slice(2)) {
  await page.goto(address);
  await page.getByRole("heading", { level: 1 }).waitFor();
  const { violations } = await new AxeBuilder({ page }).withTags(wcag22aa).analyze();
  console.log(`${address}: ${violations.length} rule(s) broken`);
  for (const v of violations) {
    console.log(`  ${v.id} (${v.impact}): ${v.help}`);
    for (const node of v.nodes) console.log(`    ${node.target.join(" ")}  ${node.any[0]?.message ?? ""}`);
  }
}
await browser.close();
```

O axe precisa que a página pertença a um contexto de navegador próprio, e é por isso que a página é criada
com `newContext()` e não direto do navegador. O programa abre cada endereço que recebe, espera o título do
planner para que o axe veja a página desenhada, e imprime cada regra quebrada com a descrição de uma linha
do próprio axe, depois cada elemento que a quebra e o motivo que o axe dá. O relógio fica parado na semana
dos dados, como na aula 4, para que os totais na página sejam os que os testes esperam.
