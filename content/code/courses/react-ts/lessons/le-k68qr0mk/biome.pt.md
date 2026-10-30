---
title: Biome, uma ferramenta para os dois
version: 1
---

**O Biome faz o trabalho de um linter e o de um formatador num programa só**, escrito em Rust como o
Oxlint. Ele também ordena imports. Instalado, iniciado com os padrões dele, rodado sobre `src`, depois
alimentado com as configurações do Prettier e rodado de novo, com o último comando listando o que sobrou:

```
ana@dev:~/planner$ npm install --save-dev @biomejs/biome@2.6.2

added 2 packages, and audited 296 packages in 2s

67 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npx biome init > /dev/null && npx biome check src 2>&1 | grep -E '^(Checked|Found)'
Checked 35 files in 20ms. No fixes applied.
Found 41 errors.
Found 1 warning.
ana@dev:~/planner$ npx biome migrate prettier --write > /dev/null && npx biome check src 2>&1 | grep -E '^(Checked|Found)'
Checked 35 files in 18ms. No fixes applied.
Found 6 errors.
Found 1 warning.
ana@dev:~/planner$ npx biome check src 2>&1 | grep '^src' | sed 's/ ━.*//'
src/main.tsx:41:12 lint/style/noNonNullAssertion
src/AddSessionForm.test.tsx:5:1 assist/source/organizeImports  FIXABLE 
src/AddSessionForm.tsx:5:1 assist/source/organizeImports  FIXABLE 
src/Dialog.tsx:1:1 assist/source/organizeImports  FIXABLE 
src/Field.tsx:1:1 assist/source/organizeImports  FIXABLE 
src/WeekScreen.tsx:1:1 assist/source/organizeImports  FIXABLE 
src/usePlanner.ts:1:1 assist/source/organizeImports  FIXABLE 
```

O `biome init` escreveu um `biome.json` com os padrões do Biome, e contra eles o planejador tinha **41
erros**, quase todos de layout: o Biome formata com tabs e aspas duplas, a não ser que alguém diga o
contrário. O **`biome migrate prettier`** leu o `.prettierrc.json` e escreveu as mesmas escolhas no
`biome.json`, e então sobraram só seis erros e um aviso:

- **`organizeImports`, seis vezes**: o Biome ordena os nomes dentro de cada import, e põe os tipos onde a
  ordem dele manda. Ele mesmo consegue corrigir esses, que é o que `FIXABLE` quer dizer.
- **`noNonNullAssertion`**, no `main.tsx`: `document.getElementById('root')!`. A aula 12 disse que um `!`
  é uma afirmação que você precisa conseguir defender, e esta dá para defender, já que o `index.html` tem
  o elemento. O Biome não tem como saber disso, então pergunta.

**Uma ferramenta ou várias** é uma escolha de verdade, e as duas são comuns. O Biome é uma dependência,
uma configuração e um comando muito rápido; Oxlint com Prettier, ou ESLint com Prettier, são várias, com
mais plugins entre elas. O planejador fica com o Prettier e os linters que já tem, então o Biome sai:

```
ana@dev:~/planner$ npm uninstall @biomejs/biome && rm biome.json && git status --short

removed 2 packages, and audited 294 packages in 612ms

66 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
 M server/api.mjs
 M src/main.tsx
 M src/week.ts
 M tsconfig.json
```

O que resta para commitar é o que o Prettier mudou, em quatro arquivos.
