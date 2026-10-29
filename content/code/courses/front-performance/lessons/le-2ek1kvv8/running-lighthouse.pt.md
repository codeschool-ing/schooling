---
title: Rodando o Lighthouse
version: 1
---

**O Lighthouse é um programa Node**, mantido pelo Google, que abre o Chrome, carrega um endereço e
escreve um relatório. Instale-o no planner como ferramenta de desenvolvimento, numa versão fixa, como
toda ferramenta deste curso:

```
ana@dev:~/planner$ npm install --save-exact --save-dev lighthouse@13.5.0
npm warn deprecated @opentelemetry/sdk-trace-base@2.12.0: Use @opentelemetry/sdk-trace package

added 112 packages, and audited 136 packages in 5s

28 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

## Que Chrome ele abre

O Lighthouse procura o Chrome onde o Chrome costuma estar instalado. **Você já tem um Chromium**: o do
Playwright, da aula 1. O `CHROME_PATH` diz ao Lighthouse para usá-lo, e o Playwright diz onde ele está:

```
ana@dev:~/planner$ export CHROME_PATH=$(node -e 'import("playwright").then((p) => console.log(p.chromium.executablePath()))')
ana@dev:~/planner$ echo $CHROME_PATH
/home/ana/.cache/ms-playwright/chromium-1243/chrome-linux64/chrome
```

O `export` guarda a variável pelo resto deste terminal, e só deste: digite de novo em cada terminal novo
de onde você rodar o Lighthouse. Num computador com o Chrome instalado dá para pular esse passo, e o
Lighthouse abre aquele Chrome; as notas podem então diferir um pouco das daqui, porque é outro navegador.

## Um script para as opções

As opções que este curso sempre passa são longas, então ponha-as uma vez no `package.json`, como um
script chamado `lighthouse`:

```
ana@dev:~/planner$ npm pkg set scripts.lighthouse='lighthouse --quiet --chrome-flags=--headless=new --only-categories=performance --output=json --output=html --output-path=report'
```

- `--quiet` não imprime nada enquanto trabalha;
- `--chrome-flags=--headless=new` roda o navegador sem janela;
- `--only-categories=performance` deixa de fora acessibilidade, boas práticas e SEO, que o Lighthouse
  também avalia e que outros cursos cobrem;
- `--output=json --output=html --output-path=report` escreve o mesmo relatório duas vezes:
  `report.report.html` para ler no navegador, e `report.report.json` para um programa ler.

## O primeiro relatório

O `tools/report.ts` imprime a parte do JSON que esta aula lê: a nota, as cinco métricas por trás dela,
os insights que acharam algo e quando cada requisição terminou. Salve-o em `tools/`:

```typescript
// tools/report.ts: the part of a Lighthouse report this course reads, out of the
// JSON it writes: the score and the five metrics behind it, the insights that
// found something, and when each request finished.
//
//   node tools/report.ts report.report.json
import { readFile } from "node:fs/promises";

const report = JSON.parse(await readFile(process.argv[2], "utf8"));
const performance = report.categories.performance;
console.log(`performance ${Math.round(performance.score * 100)}, throttling ${report.configSettings.throttlingMethod}`);
for (const ref of performance.auditRefs.filter((r: any) => r.weight > 0)) {
  console.log(`  ${ref.acronym.padEnd(4)} ${report.audits[ref.id].displayValue.padEnd(8)} weight ${ref.weight}`);
}
// An insight scores 1 when it found nothing; anything less is worth reading.
for (const audit of Object.values<any>(report.audits)) {
  if (audit.id.endsWith("-insight") && audit.score !== null && audit.score < 1) {
    console.log(`  insight: ${audit.title}${audit.displayValue ? `, ${audit.displayValue}` : ""}`);
  }
}
// A data: address is part of the page, not a request to anybody, so only http ones are listed.
for (const r of report.audits["network-requests"].details.items.filter((r: any) => r.url.startsWith("http"))) {
  console.log(`  request ${new URL(r.url).pathname.padEnd(28)} done at ${String(Math.round(r.networkEndTime)).padStart(5)} ms, ${r.transferSize} B`);
}
```

Com o `server.ts` rodando como a aula 5 o deixou, rode o Lighthouse na página de curso e leia o relatório:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json
performance 100, throttling simulate
  FCP  1.1 s    weight 10
  LCP  1.1 s    weight 25
  TBT  0 ms     weight 30
  CLS  0        weight 25
  SI   1.1 s    weight 10
  insight: Use efficient cache lifetimes, Est savings of 18 KiB
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 150 ms
  request /courses/git                 done at    20 ms, 1802 B
  request /assets/index-C9VFYfGa.js    done at    46 ms, 17819 B
  request /assets/index-CGM1waBA.css   done at    45 ms, 538 B
  request /favicon.svg                 done at    79 ms, 9695 B
```

**Cem, e três insights mesmo assim.** Uma nota perfeita e uma lista de coisas para olhar não se
contradizem: a nota avalia cinco métricas num celular simulado, e um insight aponta algo que poderia
custar tempo em outra página, rede ou visita. A próxima seção mostra como se chegou aos cem; a seção "O
que o relatório ainda diz" volta aos três insights.

Abra também o `report.report.html` no navegador. É o mesmo relatório, diagramado como as ferramentas de
desenvolvedor do Chrome o mostram, com cada insight aberto nas requisições e nos elementos de que trata.
