---
title: O que os formulários tipados compram, e o código de antes deles
version: 1
---

**Desde o Angular 14 todo formulário reativo é tipado, e os tipos vêm dos valores com que os controles
são feitos.** Nesta aula o compilador soube que `minutes` é um número, que `date` é uma string, que o
`form.value` pode estar sem um campo e o `getRawValue()` não, e que um rascunho mandado ao
`store.add` tem todo campo de que o `Session` precisa, menos o id e o `done`. Um nome de controle
escrito errado, uma string onde o store quer um número, um campo esquecido no rascunho: cada um é
agora um erro de build, onde antes era um formulário que mandava a coisa errada.

**Código escrito antes do Angular 14 não é tipado**, e o `ng update` o manteve funcionando renomeando
as classes dele: `UntypedFormGroup`, `UntypedFormControl`, `UntypedFormBuilder`. Cada uma é o
comportamento antigo sob um nome que diz isso, com todo valor `any`. Trocar uma pela versão tipada,
num formulário que você já está mudando, é como um código assim fica tipado, um formulário por vez; o
compilador então lista o que o formulário antigo vinha deixando passar.

| você precisa de | use |
|---|---|
| um conjunto fixo de campos com nome | `FormGroup`, ou `fb.group` |
| uma lista cujo tamanho muda | `FormArray`, ou `fb.array` |
| campos com nome não conhecidos de antemão, todos de um tipo | `FormRecord`, com chave string |
| um campo sozinho | `FormControl`, ou `fb.control` |

O Angular 21 também traz um terceiro tipo, experimental, os **Signal Forms**, em
`@angular/forms/signals`: o formulário é um signal de um objeto simples, e o valor e o status de todo
campo também são signals. A aula 16 põe os três lado a lado. Formulários reativos são o que as
aplicações Angular usam hoje, e o que o planner mantém.

O formulário é o único arquivo novo da aula, com o `add` do store ao lado:

```
ana@dev:~/planner$ git status --short
 M src/app/course-page/course-page.html
 M src/app/course-page/course-page.ts
 M src/app/planner-store.ts
?? src/app/add-session/
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Reactive forms: add sessions to a course"
```
