---
title: O que testar, e o que deixar
version: 1
---

**A suíte inteira, uma vez:**

```
ana@dev:~/vue/planner$ npm test -- --run

> planner@0.0.0 test
> vitest --run


 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/planner.test.ts (7 tests) 6ms
 ✓ src/components/SessionForm.test.ts (3 tests) 93ms
 ✓ src/views/HomeView.test.ts (2 tests) 124ms
 ✓ src/components/SessionRow.test.ts (4 tests) 54ms
 ✓ src/stores/planner.test.ts (4 tests) 16ms

 Test Files  5 passed (5)
      Tests  20 passed (20)
   Start at  22:07:21
   Duration  1.89s (environment 77%, import 13%, tests 7%, transform 3%, worker 1%)

Environment  jsdom was created 5 times · 3.21s total, 77% of tracked time
             create it once per worker with pool: 'vmThreads' (keeps per-file isolation) or isolate: false (shares it across files)
             learn more: https://vitest.dev/guide/improving-performance#test-environments
```

**Vinte testes em cinco arquivos, em cerca de dois segundos**, a maior parte gasta criando cinco
documentos jsdom, um por arquivo, para que nenhum teste de um arquivo possa ver os de outro; a nota
embaixo do resumo diz como trocar parte desse isolamento por velocidade, e o planner não precisa
disso. Os testes são TypeScript, então têm os tipos checados junto com todo o resto:

```
ana@dev:~/vue/planner$ npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit
```

## Onde os testes estão, e onde não estão

O planner agora tem testes em três alturas, e as contagens dizem algo:

| o quê | testes | o que custa escrever um |
| --- | --- | --- |
| `planner.ts`, regras sobre valores | 7 | uma linha de entrada e uma linha de resposta |
| componentes, montados sozinhos | 7 | uma store, props, alguns eventos |
| a store, e uma página | 6 | um `fetch` falso, um relógio falso |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O que cada tipo de teste do planner toca. Um teste do planner.ts dá um valor a uma função e lê a resposta, e não toca em mais nada. Um teste do SessionRow ou do SessionForm monta o componente no jsdom com uma store Pinia nova. Um teste da store ou da página da semana também troca o fetch por uma resposta que o teste escolhe, e o teste da página da semana troca o relógio também. Quanto mais abaixo, mais cada teste prepara, e menos deles o planner tem.\"><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner.test.ts</text><text x=\"215\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">7</text><rect x=\"250\" y=\"30\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"293\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">planner.ts</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">SessionRow / SessionForm</text><text x=\"215\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">7</text><rect x=\"250\" y=\"92\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"293\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">componente</text><rect x=\"342\" y=\"92\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">jsdom</text><rect x=\"434\" y=\"92\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"477\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Pinia</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner / HomeView</text><text x=\"215\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">6</text><rect x=\"250\" y=\"154\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"293\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">store, página</text><rect x=\"342\" y=\"154\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"385\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">jsdom</text><rect x=\"434\" y=\"154\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"477\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Pinia</text><rect x=\"526\" y=\"154\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"569\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fetch falso</text><rect x=\"618\" y=\"154\" width=\"86\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"661\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">relógio falso</text><text x=\"215\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">testes</text></svg>", "caption": "Os testes mais baratos tocam o mínimo, e o planner tem mais deles.", "same": ["Pinia", "jsdom", "planner.ts"]}
```

**A maior parte dos testes está onde eles são mais baratos e mais precisos**, nas funções puras, e as
aulas que puseram as regras ali, a aula 3 e a aula 10, são o motivo de os componentes precisarem de
tão poucos. Essa é a forma a buscar em qualquer projeto Vue: regras em funções simples e composables
que podem ser testados sozinhos, componentes finos o bastante para que alguns testes do que desenham
e emitem bastem.

O que estes testes não fazem, de propósito:

- **Eles não testam o Vue.** Nenhum teste afirma que um `computed` recalcula ou que o `v-model` liga;
  o Vue tem os próprios testes para isso, e um teste do framework só falha quando o framework falha.
- **Eles não testam todas as páginas.** O `CourseView`, o router e o diálogo não têm nenhum. Cada um
  precisaria de um router ou de um navegador de verdade para a pouca lógica que tem, e a guarda do
  router é a peça que viria em seguida: ela decide quem vê uma página `not-found`.
- **Eles não rodam num navegador de verdade.** O jsdom não tem layout, nem anéis de foco, nem um
  `<dialog>` de verdade; um teste de como o diálogo prende o foco, a preocupação da aula 15, é para um
  teste no navegador, com Playwright ou com o modo navegador do próprio Vitest, que as aulas 10 a 12
  de `front-quality` retomam junto com a acessibilidade.
- **Eles não são contados pela cobertura.** O Vitest pode relatar quais linhas rodaram (`--coverage`,
  com o `@vitest/coverage-v8` instalado), e o número é um mapa do que ninguém testou, não uma meta. Um
  teste escrito para subir esse número verifica que uma linha rodou, não que ela estava certa.

O planner do Nuxt não tem testes neste curso. O `@nuxt/test-utils` roda o Vitest dentro de um
ambiente Nuxt, com os auto-imports e as rotas de servidor disponíveis, e tudo desta aula vale lá
também; o que ele acrescenta é o runtime do Nuxt, que a próxima aula deixa para trás em favor dos
frameworks ao lado do Vue.
