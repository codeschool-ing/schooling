---
title: Digitando como uma pessoa digita
version: 1
---

**O `user-event` produz os eventos que uma pessoa de verdade produz, na ordem em que um navegador os
produz.** O `user.type(campo, "15")` põe o foco no campo, depois manda `keydown`, `keypress`, `input` e
`keyup` para o `1`, e de novo para o `5`. O `user.click(botão)` passa o ponteiro por cima, aperta,
solta e clica. A aula 2 atribuía o `.value` e chamava o `requestSubmit()`, o que pula todos esses
eventos.

Na maior parte das vezes os dois dão o mesmo resultado, e a diferença aparece quando mais importa.
Eis o que cada abordagem faz com um botão desabilitado, montado de propósito num teste de rascunho
(salve como `src/scratch.test.ts`, rode, e apague):

```typescript
// src/scratch.test.ts
// @vitest-environment jsdom
import { expect, test } from "vitest";
import { screen } from "@testing-library/dom";
import userEvent from "@testing-library/user-event";

test("a disabled button cannot be clicked by a person", async () => {
  let clicks = 0;
  document.body.innerHTML = '<button disabled>Add session</button>';
  const button = screen.getByRole("button", { name: "Add session" });
  button.addEventListener("click", () => clicks++);

  button.click();
  expect(clicks).toBe(0);

  await userEvent.setup().click(button);
  expect(clicks).toBe(0);
});

test("a button covered by pointer-events: none cannot be clicked either", async () => {
  document.body.innerHTML = '<button style="pointer-events: none">Add session</button>';
  const button = screen.getByRole("button", { name: "Add session" });
  await expect(userEvent.setup().click(button)).rejects.toThrow("pointer-events");
});
```

```
ana@dev:~/planner$ npx vitest run src/scratch.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  2 passed (2)
   Start at  19:40:03
   Duration  1.03s (environment 69%, tests 15%, import 10%, transform 5%, worker 1%)

ana@dev:~/planner$ rm src/scratch.test.ts
```

O primeiro teste mostra os dois concordando: um botão desabilitado ignora o `.click()` e o
`user.click` do mesmo jeito. O segundo mostra onde eles se separam. Um botão com
`pointer-events: none` não recebe o clique de um mouse, e o `user.click` **se recusa a fingir**: ele
lança um erro, e diz qual estilo está no caminho. Um `.click()` simples teria rodado o tratador, e o
teste teria passado para um botão que ninguém consegue apertar.

## As regras que vêm disso

- **Comece cada teste com `userEvent.setup()`** e use o objeto que ele devolve, como os testes do
  planner fazem; ele guarda o estado do teclado e do ponteiro daquele teste.
- **Toda chamada `user.…` é `async`**, então ponha `await`. Um `await` esquecido deixa o teste ler a
  página antes de a digitação acontecer, e passar ou falhar por questão de tempo.
- **O `user.keyboard("{Enter}")`, o `user.tab()` e o `user.hover()`** são o resto das mãos de uma
  pessoa. A aula 11 usa o `user.tab()` para percorrer a página só com o teclado.

O que o `user-event` ainda não sabe é layout. O jsdom não calcula nenhum, então um botão escondido
atrás de outro elemento por posicionamento CSS é clicável aqui e não num navegador. Isso continua
sendo da aula 4.
