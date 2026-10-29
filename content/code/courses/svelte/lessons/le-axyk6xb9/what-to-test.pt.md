---
title: O que testar, e um comando para tudo
version: 1
---

**O planner agora tem três tipos de checagem, e cada um pega o que os outros não pegam**:

| checagem | o que ela lê | o que ela pega | quanto demora |
|---|---|---|---|
| `npm run check` | o código, sem rodá-lo | uma propriedade que não existe, um valor do tipo errado, marcação que um teclado não consegue usar | segundos |
| `npm run test:unit` | funções e componentes, rodados sozinhos | uma regra que dá a resposta errada: uma semana, um total, uma checagem | menos de um segundo |
| `npm run test:e2e` | o planner inteiro, com build e servidor, num navegador | um percurso que parou de funcionar: um formulário, um link, um redirecionamento, JavaScript desligado | segundos, e um build |

**A maioria dos testes pertence à linha do meio.** Um teste de unidade é rápido e aponta a linha exata
que quebrou; ele pode listar vinte casos de borda de uma data numa tabela. Um teste de ponta a ponta é
mais lento e, quando falha, diz só que um percurso quebrou em algum lugar entre o navegador e o arquivo,
então fica reservado para os poucos percursos que mais importam. O planner tem cinco, e acrescentar um
sexto para cada funcionalidade deixaria a suíte lenta e diria pouco mais.

Duas coisas nunca valem a pena testar. **O framework**: se o `$derived` recalcula ou se o `use:enhance`
envia um formulário é coisa do Svelte e do SvelteKit testarem, e eles testam. **A marcação exata**: um
teste que procura `<p class="svelte-1x2y3z">` quebra toda vez que um estilo muda e não pega nada. Os
testes do planner pedem o texto que uma pessoa lê e os controles que uma pessoa usa, e é por isso que
sobrevivem a um redesenho.

Um script roda tudo, na ordem do mais rápido:

```
ana@dev:~/planner$ npm pkg set scripts.test='npm run check && npm run test:unit && npm run test:e2e'
```

```
ana@dev:~/planner$ npm test 2>&1 | grep -E 'svelte-check found|Tests|passed|failed'
svelte-check found 0 errors and 0 warnings
 Test Files  4 passed (4)
      Tests  22 passed (22)
  5 passed (8.2s)
```

**Tudo verde**, do verificador de tipos a um navegador com JavaScript desligado. O `&&` para no primeiro
comando que falha, então um erro de tipo aparece antes que os testes mais lentos gastem tempo com código
que nem compila. Rode `npm test` antes de todo commit; um projeto que o roda a cada push, num serviço
como o GitHub Actions, é um projeto em que ninguém precisa lembrar.

Faça o commit do trabalho da aula:

```sh
git add -A && git commit -m "Lesson 19: unit tests with Vitest, end-to-end tests with Playwright"
```
