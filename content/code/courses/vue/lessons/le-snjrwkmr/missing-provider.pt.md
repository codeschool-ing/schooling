---
title: Quando ninguém provê
version: 1
---

**Um `inject` sem ninguém acima que proveja devolve `undefined` e avisa, e um segundo argumento dá a ele
um valor padrão no lugar.** Vale fazer a pergunta para cada injeção: um componente que injeta algo fez
uma promessa sobre onde vai ser usado, e o padrão é o que ele faz quando a promessa é quebrada.

```html
<!-- src/demos/Orphan.vue -->
<script setup>
import { inject } from 'vue'
import { unitKey } from './keys.js'

const unit = inject(unitKey)
const unitOrDefault = inject(unitKey, 'minutes')
const made = inject('settings', () => ({ weekStartsOn: 'Monday' }), true)
</script>

<template>
  <p>No default: {{ String(unit) }}</p>
  <p>With a default: {{ unitOrDefault }}</p>
  <p>With a factory: {{ made.weekStartsOn }}</p>
</template>
```

A demo é aberta sozinha, sem nada acima dela provendo coisa alguma:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Orphan'
[vite] connecting...
[vite] connected.
[warn] [Vue warn]: injection "Symbol(unit)" not found. 
  at <Orphan>
== the text of #app
No default: undefined

With a default: minutes

With a factory: Monday
```

- **Sem padrão: `undefined`, e um aviso** que nomeia a chave, `injection "Symbol(unit)" not found`. A
  descrição do Symbol é o que deixa essa mensagem legível, e esse é um motivo para dar uma a toda chave.
- **Com padrão, `'minutes'`**, e nenhum aviso: um padrão diz que ser usado sem quem proveja é esperado.
- **Com uma factory**: quando o padrão é um objeto ou um array, passe uma função que o cria, e `true`
  como terceiro argumento para dizer que a função é uma factory e não o valor. O Vue então só a chama
  quando ninguém provê a chave, e um padrão caro de montar nunca é montado quando existe quem o proveja.

## Escolhendo o padrão

Há três respostas honestas, e cada uma serve a um tipo de valor:

| o valor injetado é | quando falta |
|---|---|
| uma configuração com um valor usual óbvio: uma unidade, uma densidade | um padrão que é esse valor usual |
| algo sem o qual o componente não funciona: o formulário a que um campo pertence | nenhum padrão, e um erro claro. Um campo fora de um formulário é um bug, e é melhor encontrá-lo na hora |
| um extra: uma consulta que melhora a exibição | um padrão que piora visivelmente, mas continua correto |

O `SessionRow` do planner, no fim desta aula, é o terceiro caso: sem os títulos dos cursos ele mostra o
id do curso, `statistics`, que é menos amigável que `Statistics` e continua verdadeiro. Um padrão que
esconde o problema, uma string vazia onde deveria haver um título, seria a falha silenciosa contra a
qual esta aula vive alertando.
