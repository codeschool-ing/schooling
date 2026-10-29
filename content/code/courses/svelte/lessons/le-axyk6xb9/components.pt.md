---
title: Renderizando um componente num teste
version: 1
---

**O `render` de `svelte/server` roda um componente do jeito que o servidor roda e devolve o HTML dele**,
que um teste pode ler. Ele não precisa de nada instalado além do Svelte, e serve para um componente cujo
trabalho é mostrar alguma coisa. Salve isto como `src/lib/WeekTotal.test.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/WeekTotal.test.ts", "parts": [
 {"code": "// WeekTotal.test.ts: what the component renders, on the server, for a few totals.\nimport { expect, test } from 'vitest';\nimport { render } from 'svelte/server';\nimport WeekTotal from '#lib/WeekTotal.svelte';\n"},
 {"code": "test('ninety minutes is an hour and a half', () => {\n\tconst { body } = render(WeekTotal, { props: { minutes: 90 } });\n\texpect(body).toContain('90 minutes this week (1 h 30 min)');\n});\n\ntest('the label replaces \"this week\"', () => {\n\tconst { body } = render(WeekTotal, { props: { minutes: 45, label: 'for Guitar this week' } });\n\texpect(body).toContain('45 minutes for Guitar this week (0 h 45 min)');\n});", "note": "O `body` é o HTML que o componente produziu. As props entram como entrariam vindas de um pai."}
]}
```

```
ana@dev:~/planner$ npm run test:unit 2>&1 | tail -6

 Test Files  4 passed (4)
      Tests  22 passed (22)
   Start at  22:34:23
   Duration  1.26s (transform 74%, import 21%, tests 3%, worker 2%)
```

O que isto não testa é nada que aconteça depois de o HTML existir: um clique, um formulário enviado,
uma transição, um foco que se move. O Vitest também roda testes num navegador de verdade, com um pacote
para isso e alguma configuração, e para componentes que são sobretudo interação esse é o próximo passo.
No planner, as interações que importam são percursos inteiros, uma pessoa acrescentando uma sessão e
vendo a semana mudar, e é isso que a próxima seção testa, na aplicação inteira de uma vez.
