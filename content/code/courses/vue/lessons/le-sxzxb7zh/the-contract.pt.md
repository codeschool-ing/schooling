---
title: O contrato entre dois componentes
version: 1
---

**Props e emits juntos são o contrato público de um componente: o que ele precisa receber e o que ele
pode relatar.** Todo o resto, os seus refs, os seus valores computed, o seu markup, é privado e pode
mudar sem que mais ninguém perceba. Um componente com um contrato claro pode ser movido, reutilizado e
testado sozinho, e a aula 21 testa os componentes do planner exatamente por esse contrato.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"App, no topo, é dono das sessões. Setas marcadas props descem para dois filhos: CourseCard, que recebe um título e três números, e SessionRow, que recebe uma sessão e um título. Uma seta marcada evento sobe de SessionRow para App, levando toggle e um id. App então substitui a lista, e os valores novos descem de novo como props.\"><rect x=\"250\" y=\"15\" width=\"220\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">App.vue</text><text x=\"360\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dono das sessões</text><rect x=\"60\" y=\"170\" width=\"220\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">CourseCard</text><text x=\"170\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">desenha, não é dono de nada</text><rect x=\"440\" y=\"170\" width=\"220\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">SessionRow</text><text x=\"550\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">desenha, e avisa de um clique</text><line x1=\"300\" y1=\"77\" x2=\"190\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"190.0,168.0 193.7,160.9 197.7,165.7\" fill=\"var(--phosphor)\"></polygon><text x=\"150\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">props</text><text x=\"150\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">title, goal, planned, done</text><line x1=\"395\" y1=\"77\" x2=\"500\" y2=\"168\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"500.0,168.0 492.4,165.5 496.5,160.8\" fill=\"var(--phosphor)\"></polygon><text x=\"436\" y=\"128\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">props</text><text x=\"436\" y=\"144\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">session, title</text><line x1=\"600\" y1=\"168\" x2=\"470\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></line><polygon points=\"470.0,60.0 477.7,62.3 473.7,67.1\" fill=\"var(--amber)\"></polygon><text x=\"612\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">evento</text><text x=\"612\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">toggle('s5')</text></svg>", "caption": "Os dados descem como props; as notícias sobem como eventos, para quem é dono dos dados."}
```

A figura é a forma de toda aplicação Vue: o estado mora tão alto quanto precisa, desce pelas props e
volta subindo como eventos até o componente que é dono dele. O `App.vue` é dono das sessões do
planner; quando um `SessionRow` é marcado, ele diz `toggle` com um id, e o `App` substitui a lista. A
linha nunca toca na lista.

## O que não está no contrato passa adiante

Um atributo que o filho não declarou como prop, nem como evento, não se perde: o Vue o coloca no
elemento raiz do filho. Isso se chama **atributo fallthrough**, e é como um pai acrescenta uma classe, um
`id` ou um atributo `aria-` a um componente sem que o componente precise saber.

```html
<!-- src/demos/Fallthrough.vue -->
<script setup>
import GoalBar from './GoalBar.vue'
</script>

<template>
  <GoalBar label="Statistics" :minutes="45" id="stats" class="wide" aria-describedby="help" />
  <p id="help">Minutes this week.</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Fallthrough' --html p --text -
[vite] connecting...
[vite] connected.
Statistics: minutes is a number
== the HTML of p
<p id="stats" class="wide" aria-describedby="help">Statistics: 45 of 60 minutes</p>
```

`id`, `class` e `aria-describedby` foram parar no `<p>` que é a raiz do `GoalBar`, ao lado das props
que ele declarou. O atributo de acessibilidade é o importante: o pai sabe que um texto de ajuda fica ao
lado da barra, e a barra não precisou de uma prop para isso.

Três detalhes completam a regra:

- **`class` e `style` se mesclam** com os da própria raiz, em vez de substituí-los.
- **Um componente com vários elementos raiz não tem um lugar único para colocá-los**, então o Vue avisa e
  não os coloca em lugar nenhum, a menos que o componente diga onde com `v-bind="$attrs"` num dos seus
  elementos.
- **`defineOptions({ inheritAttrs: false })`** desliga isso, para um componente que quer colocá-los ele
  mesmo: um input com label cuja raiz é um `<label>` mas cujos atributos pertencem ao `<input>` lá
  dentro.

## Escrevendo um contrato que valha a pena

| pergunte a um componente | uma boa resposta |
|---|---|
| do que ele precisa? | o mínimo de props que o deixe se desenhar: um id e um título, não o estado da aplicação inteira |
| o que ele pode relatar? | eventos com o nome do que o aluno fez, com o detalhe de que o pai precisa e nada mais |
| quem é dono dos dados que ele mostra? | alguém acima dele, sempre; ele pode guardar estado só sobre si mesmo, um hover ou um rascunho |

Um componente que precisa de oito props são dois componentes, ou está recebendo estado que deveria ter
pedido por id. Um componente que emite um evento a cada tecla provavelmente é um campo de formulário, que
é a próxima seção.
