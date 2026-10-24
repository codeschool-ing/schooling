---
title: As mesmas perguntas num teste de unidade
version: 1
---

**O `user-event` do Testing Library também aperta teclas, então parte desta aula pode ser testada no
Vitest, sem navegador.** O `user.tab()` move o foco como o Tab moveria, e o `user.keyboard("{Enter}")`
aperta uma tecla no que estiver com o foco. Acrescente um teste ao `src/view.test.ts`:

```typescript
// src/view.test.ts, below what is there
test("Done, pressed from the keyboard, leaves the focus on its session", async () => {
  const user = userEvent.setup();
  show("#/course/javascript");
  await user.tab();
  await user.tab();
  expect(screen.getByRole("button", { name: "Done" })).toHaveFocus();
  await user.keyboard("{Enter}");
  expect(screen.getByText("2026-10-22 · 30 min")).toHaveFocus();
});
```

```
ana@dev:~/planner$ npx vitest run src/view.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  5 passed (5)
   Start at  21:08:14
   Duration  1.40s (environment 49%, tests 37%, import 8%, transform 6%)

ana@dev:~/planner$ git commit -qam "Test in jsdom that Done keeps the focus"
```

Ele passa de primeira, porque a correção já está no `src/view.ts`; escrito antes, é o teste que teria
achado o foco perdido em um segundo e meio, antes de abrir um navegador.

## O que se pode e o que não se pode perguntar ao jsdom

O jsdom acompanha o foco exatamente como o DOM diz: que elemento o tem, que elementos podem recebê-lo,
`tabindex` e tudo. **Ele não desenha nada.** Não há layout, então nada fica escondido nem coberto; a folha de
estilo do planner nem é carregada num teste de unidade, então não há contorno para medir; e um campo de data
é um elemento e uma parada, onde o Chromium faz quatro. As perguntas se dividem com clareza:

| a pergunta | jsdom | um navegador de verdade |
|---|---|---|
| onde o foco cai depois de uma ação? | sim | sim |
| que elementos o Tab alcança, em que ordem? | a ordem do DOM, sim | sim, com as paradas do próprio navegador |
| o elemento com foco pode ser visto? | não | sim |
| ele está coberto por outra coisa? | não | sim |

O teste de unidade é rápido e roda a cada vez que você salva, então é ele que pega primeiro um foco
perdido. O teste do Playwright é o que consegue dizer que o anel está lá para ser visto.
