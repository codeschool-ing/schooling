---
title: O planner, instalando os próprios componentes
version: 1
---

**O planner agora instala `@planner/ui` como qualquer outra dependência, e apaga as próprias cópias.** Se
tudo foi levado fielmente, toda conferência que o planner tem passa sem mudar um teste, que é a prova mais
forte que uma refatoração pode oferecer.

Aponte o escopo `@planner` do planner para o registry, com a mesma linha que a biblioteca usa, e instale a
versão exata:

```
ana@dev:~/planner$ cp ../planner-ui/.npmrc .
ana@dev:~/planner$ npm install --save-exact @planner/ui@0.1.0 2>&1 | tail -1
found 0 vulnerabilities
ana@dev:~/planner$ grep -A1 '"dependencies"' package.json
  "dependencies": {
    "@planner/ui": "0.1.0"
```

## Trocando os imports

Três arquivos importavam os componentes de `./components`, e a folha de estilo importava os tokens
gerados. Cada um agora cita o pacote:

```
ana@dev:~/planner$ sed -i 's#"./components"#"@planner/ui"#' src/view.ts src/session-row.stories.ts src/week-summary.stories.ts
ana@dev:~/planner$ sed -i 's#@import "./tokens.css";#@import "@planner/ui/tokens.css";#' src/style.css
ana@dev:~/planner$ grep -n "@planner/ui" src/*.ts src/style.css
src/session-row.stories.ts:4:import { sessionRow } from "@planner/ui";
src/view.ts:2:import { actionButton, sessionRow, weekSummary } from "@planner/ui";
src/week-summary.stories.ts:3:import { weekSummary } from "@planner/ui";
src/style.css:2:@import "@planner/ui/tokens.css";
```

Depois apague o que o pacote agora fornece, e os dois scripts que o geravam e conferiam:

```
ana@dev:~/planner$ git rm -q src/components.ts src/format.ts src/tokens.css tokens.json tokens.mjs contrast.mjs
ana@dev:~/planner$ npm pkg delete scripts.tokens scripts.contrast
```

## Toda conferência, sem mudança

A conferência de tipos, os testes de unidade, o build, e a oficina com as fotos e as auditorias:

```
ana@dev:~/planner$ npx tsc && npm test 2>&1 | grep Tests
      Tests  5 passed (5)
ana@dev:~/planner$ npm run build 2>&1 | grep css
dist/assets/index-BU4yu1tj.css  2.11 kB │ gzip: 0.64 kB
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1
ana@dev:~/planner$ npx playwright test 2>&1 | tail -1
  10 passed (15.0s)
```

**O nome da folha de estilo, `index-BU4yu1tj.css`, é o que o build da aula 5 gravou**: os tokens chegam por
um pacote agora e o CSS é byte a byte o que era. Os dez testes visuais passam contra imagens aprovadas antes
da mudança, então nenhum pixel de nenhuma story mudou.

Faça o commit da troca:

```
ana@dev:~/planner$ git add -A && git commit -qm "Use @planner/ui 0.1.0 instead of local copies"
```

Daqui em diante, uma mudança num token ou num componente acontece em `~/planner-ui`, vira uma versão, e só
chega ao planner quando o planner instala essa versão. Uma consequência prática de um registry no seu
próprio computador: **ele precisa estar rodando sempre que o planner instala**, ou o `npm install` não acha
`@planner/ui`. O registry de uma empresa é um servidor que está sempre no ar, e isso é a maior parte do que
se paga por ele.
