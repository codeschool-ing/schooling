---
title: O planner até aqui
version: 1
---

**Três componentes agora, aninhados do jeito que a árvore da aula 1 os desenhou, e todos standalone.**
O `App` importa o `Week`, o `Week` importa o `WeekSummary`, e nenhum deles é declarado em mais lugar
nenhum. Esta seção olha o resultado, roda os testes e faz o commit.

```
ana@dev:~/planner$ look http://localhost:4200/
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Study planner
This week

This week: nothing planned yet.
```

Três linhas na página, uma por componente: o título é do `App`, `This week` é do `Week`, e a frase é do
`WeekSummary`. A página não mostra onde um componente termina e o próximo começa, e é assim que deve
ser. A árvore de acessibilidade, a estrutura que um leitor de tela anuncia, mostra a mesma coisa: dois
títulos em dois níveis e um parágrafo, e nenhum rastro dos componentes em volta deles.

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y body
[vite] connecting...
[vite] connected.
Angular is running in development mode.
- heading "Study planner" [level=1]
- heading "This week" [level=2]
- paragraph
  - text: This week: nothing planned yet.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A árvore de componentes da aula 1 de novo, com os três componentes construídos até aqui desenhados em linha cheia: App, Week e WeekSummary. Os outros, CoursePage, CourseCard, SessionList, SessionRow e AddSession, estão tracejados, com a aula que constrói cada um.\"><rect x=\"290\" y=\"12\" width=\"140\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><text x=\"360.0\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">pronto</text><rect x=\"110\" y=\"90\" width=\"180\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Week</text><text x=\"200.0\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">pronto</text><rect x=\"430\" y=\"90\" width=\"180\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"520.0\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CoursePage</text><text x=\"520.0\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">aula 17</text><line x1=\"330\" y1=\"54\" x2=\"220\" y2=\"88\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"220.0,88.0 226.1,82.8 228.0,88.8\" fill=\"var(--wire)\"></polygon><line x1=\"390\" y1=\"54\" x2=\"500\" y2=\"88\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"500.0,88.0 492.0,88.8 493.9,82.8\" fill=\"var(--wire)\"></polygon><rect x=\"20\" y=\"176\" width=\"150\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><text x=\"95.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">pronto</text><rect x=\"190\" y=\"176\" width=\"150\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"265.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CourseCard</text><text x=\"265.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">aula 8</text><rect x=\"380\" y=\"176\" width=\"150\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"455.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SessionList</text><text x=\"455.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">aula 8</text><rect x=\"550\" y=\"176\" width=\"150\" height=\"42\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"625.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">AddSession</text><text x=\"625.0\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">aula 14</text><line x1=\"170\" y1=\"132\" x2=\"95\" y2=\"174\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"95.0,174.0 99.9,167.7 103.0,173.1\" fill=\"var(--wire)\"></polygon><line x1=\"230\" y1=\"132\" x2=\"265\" y2=\"174\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"265.0,174.0 257.9,170.3 262.7,166.3\" fill=\"var(--wire)\"></polygon><line x1=\"490\" y1=\"132\" x2=\"455\" y2=\"174\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"455.0,174.0 457.3,166.3 462.1,170.3\" fill=\"var(--wire)\"></polygon><line x1=\"550\" y1=\"132\" x2=\"625\" y2=\"174\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"625.0,174.0 617.0,173.1 620.1,167.7\" fill=\"var(--wire)\"></polygon></svg>", "caption": "Três dos componentes da aula 1 existem; os tracejados dizem que aula constrói cada um."}
```

## Os testes

O `ng generate` escreveu um teste para o `Week` como fez para o `WeekSummary`, e os dois só conferem
se o componente pode ser criado. O segundo teste do `App` ainda procura o título:

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | tail -9
 ✓ |planner| src/app/week/week.spec.ts (1 test) 49ms
 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 45ms
 ✓ |planner| src/app/app.spec.ts (2 tests) 68ms

 Test Files  3 passed (3)
      Tests  4 passed (4)
   Start at  20:13:18
   Duration  1.17s (transform 134ms, setup 901ms, import 150ms, tests 162ms, environment 1.71s)
```

Quatro testes, três arquivos, todos passando. **Criar o `App` num teste cria o `Week` e o
`WeekSummary` também**, porque o template do `App` os usa: um teste de componente roda os componentes
reais que ele importa, não substitutos, a não ser que você os troque de propósito. A aula 24 trata de
quando você faria isso.

## Um commit

```
ana@dev:~/planner$ git add -A && git commit -q -m "Standalone components: the week and its summary"
```

Daqui em diante, cada aula termina com o planner commitado, e a aula seguinte começa desse commit. Se
o seu e o do curso se afastarem, o `git diff` contra o seu último commit é a primeira coisa a ler.
