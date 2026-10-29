---
title: Emits tipados
version: 1
---

**O `defineEmits` também recebe um tipo: um tipo objeto cujas chaves são os eventos e cujos valores são
as listas de argumentos que cada um leva.** O `SessionRow`, na seção anterior, declara um evento:

```typescript
const emit = defineEmits<{
  toggle: [id: string]
}>()
```

`[id: string]` é uma *tupla*, uma lista fixa de argumentos com nomes; um evento com dois seria
`[id: string, done: boolean]`. Com ela, o verificador sabe duas coisas que não tinha como saber antes:
com o que o `emit` pode ser chamado, dentro do componente, e o que um listener vai receber, fora dele.

## Dentro: um evento com o nome errado

Troque o `emit('toggle', session.id)` da linha por `emit('toggel', session.id)`, como um escorregão
dos dedos faria, e rode o verificador:

```
ana@dev:~/vue/planner$ sed -i "s/emit('toggle'/emit('toggel'/" src/components/SessionRow.vue
ana@dev:~/vue/planner$ npm run type-check

> planner@0.0.0 type-check
> vue-tsc --noEmit

src/components/SessionRow.vue(23,68): error TS2345: Argument of type '"toggel"' is not assignable to parameter of type '"toggle"'.
```

**O verificador aponta a linha e o evento que não existe.** Sem tipos, o mesmo escorregão emite um
evento que ninguém escuta: a caixa não faz nada quando marcada, o console não diz nada, e o bug é
encontrado por um estudante. Desfaça a troca:

```
ana@dev:~/vue/planner$ sed -i "s/emit('toggel'/emit('toggle'/" src/components/SessionRow.vue
```

## Fora: o que o listener recebe

No `HomeView`, `@toggle="toggle"` entrega o argumento do evento ao `toggle(id: string)` da store. O
verificador compara os dois: um evento declarado como `[id: number]` falharia ali, no listener, com o
tipo do evento e o da função lado a lado. O contrato da aula 6, props descem e eventos sobem, agora
está escrito numa linguagem que uma máquina lê tão bem quanto uma pessoa.

## A metade de runtime

Como nas props, o Vue mantém uma lista de runtime dos eventos declarados, gerada a partir do tipo, então
a regra de fallthrough da aula 6 continua sabendo que `toggle` é um evento do próprio componente, e não
um nativo. O que o tipo não consegue manter em tempo de execução é a conferência dos argumentos; um
validador de runtime, a forma por objeto da aula 6, continua sendo o jeito de ter uma, e com tipos ela
raramente faz falta.
