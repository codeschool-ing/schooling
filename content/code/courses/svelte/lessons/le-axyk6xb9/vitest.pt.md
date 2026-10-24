---
title: Vitest, e o primeiro teste
version: 1
---

**Um teste é um programa pequeno que roda um pedaço do planner e diz se ele fez o que devia.** Escrito
uma vez, ele roda em um segundo, toda vez que qualquer coisa muda, e lembra o que o planner devia fazer
muito depois de quem o escreveu ter esquecido. Esta aula escreve dois tipos: **testes de unidade**, que
chamam uma função ou renderizam um componente diretamente, com o **Vitest**; e **testes de ponta a
ponta**, que conduzem o planner inteiro num navegador de verdade, com o **Playwright**.

O Vitest é feito em cima do Vite, então lê o próprio `vite.config.js` do projeto, com o plugin do
SvelteKit e os imports `#lib`, e compila arquivos `.svelte` e `.ts` do jeito que o servidor de
desenvolvimento compila. Instale:

```
ana@dev:~/planner$ npm install --save-dev vitest@5.0.5

added 15 packages, removed 1 package, and audited 74 packages in 3s

17 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Diga a ele onde os testes estão. Substitua o `vite.config.js`:

```schooling-example
{"language": "javascript", "file": "vite.config.js", "parts": [
 {"code": "import adapter from '@sveltejs/adapter-node';\nimport { sveltekit } from '@sveltejs/kit/vite';\nimport { defineConfig } from 'vite';\n\nexport default defineConfig({\n\tplugins: [\n\t\tsveltekit({\n\t\t\tcompilerOptions: {\n\t\t\t\t// Force runes mode for the project, except for libraries. Can be removed in svelte 6.\n\t\t\t\trunes: ({ filename }) =>\n\t\t\t\t\tfilename.split(/[/\\\\]/).includes('node_modules') ? undefined : true\n\t\t\t},\n\n\t\t\t// adapter-node builds a Node server: `npm run build`, then `node build`.\n\t\t\tadapter: adapter(),\n\t\t\t// The address the planner is served at, given when it is built:\n\t\t\t//   ORIGIN=http://localhost:3000 npm run build\n\t\t\tpaths: { origin: process.env.ORIGIN }\n\t\t})\n\t],\n"},
 {"code": "\ttest: {\n\t\tinclude: ['src/**/*.test.ts']\n\t}\n});", "note": "O `test` é lido pelo Vitest e ignorado pelo Vite. Um arquivo de teste fica ao lado do arquivo que ele testa, e o nome dele termina em `.test.ts`."}
]}
```

e dê a ele um script:

```
ana@dev:~/planner$ npm pkg set scripts.test:unit='vitest run'
```

`vitest run` roda cada teste uma vez e para. `vitest` sozinho ficaria vigiando, e rodaria os testes de
novo sempre que um arquivo fosse salvo.

## O primeiro arquivo de teste

As regras sobre semanas são o código mais antigo do planner, e todo total depende delas. Salve isto
como `src/lib/week.test.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/week.test.ts", "parts": [
 {"code": "// week.test.ts: the date rules, one fact at a time.\nimport { describe, expect, test } from 'vitest';\nimport { addDays, format, inWeek, isDate, mondayOf } from '#lib/week.js';\n"},
 {"code": "describe('mondayOf', () => {\n\ttest('a Wednesday belongs to the Monday before it', () => {\n\t\texpect(mondayOf('2026-10-21')).toBe('2026-10-19');\n\t});\n\n\ttest('a Monday is its own Monday', () => {\n\t\texpect(mondayOf('2026-10-19')).toBe('2026-10-19');\n\t});\n\n\ttest('a Sunday ends the week, rather than starting the next', () => {\n\t\texpect(mondayOf('2026-10-25')).toBe('2026-10-19');\n\t});\n});\n", "note": "O `describe` agrupa testes sob um nome, e o `test` é um teste: um nome que diz o que deve ser verdade, e uma função que confere. `expect(x).toBe(y)` faz o teste falhar quando `x` não é `y`."},
 {"code": "test('addDays crosses the end of a month', () => {\n\texpect(addDays('2026-10-30', 3)).toBe('2026-11-02');\n});\n\ntest('inWeek includes the Sunday and not the next Monday', () => {\n\texpect(inWeek('2026-10-25', '2026-10-19')).toBe(true);\n\texpect(inWeek('2026-10-26', '2026-10-19')).toBe(false);\n});\n"},
 {"code": "test.each([\n\t['2026-10-19', true],\n\t['2026-02-31', false],\n\t['19/10/2026', false],\n\t['', false],\n\t[20261019, false]\n])('isDate(%j) is %s', (value, expected) => {\n\texpect(isDate(value)).toBe(expected);\n});\n\ntest('format writes the day, a short month and the year', () => {\n\texpect(format('2026-10-19')).toBe('19 Oct 2026');\n});", "note": "O `test.each` roda um teste por linha da tabela, com `%j` e `%s` no nome trocados pelos valores da linha. Listar casos de borda assim sai barato, e cada um falha na sua própria linha."}
]}
```

```
ana@dev:~/planner$ npm run test:unit

> planner@0.0.1 test:unit
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ✓ src/lib/week.test.ts (11 tests) 22ms

 Test Files  1 passed (1)
      Tests  11 passed (11)
   Start at  22:34:16
   Duration  197ms (transform 45%, tests 28%, import 19%, worker 8%)
```

**Onze testes, um arquivo, uma fração de segundo.** O do domingo é do tipo que vale escrever: o
`mondayOf` funciona contando para trás a partir do dia da semana, o JavaScript numera o domingo como 0,
e errar isso poria toda sessão de domingo na semana seguinte, de um jeito que ninguém notaria até um
total sair errado num domingo.
