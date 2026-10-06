---
title: Componentes sem se repetir
version: 1
---

Vinte cartões de evento com as mesmas quinze classes é a repetição da seção 02. **A primeira resposta não é CSS**: os templates do site devem produzir o cartão a partir de um lugar só, para que a lista seja escrita uma vez. Um template numa linguagem de servidor, um componente num framework, um include num gerador de sites estáticos: cada um é um arquivo só para "um cartão de evento", e as classes moram ali.

::: track frontend
No framework que você escolher depois de `javascript`, um componente é um arquivo que recebe dados e devolve marcação, e é ali que a lista de classes do Tailwind pertence: escrita uma vez, usada em todo lugar onde o componente está. A repetição de que as pessoas reclamam é, na maior parte, sinal de que o componente ainda não foi extraído.
:::

::: track *
Sites renderizados no servidor resolvem do mesmo jeito, com templates: o HTML de um cartão de evento é escrito uma vez e preenchido para cada evento.
:::

Quando a marcação não pode ser controlada, uma classe acrescentada por um sistema de gerenciamento de conteúdo ou por uma biblioteca, o **`@apply`** copia utilitários para uma classe sua:

```css
@import "tailwindcss";

@layer components {
  .btn {
    @apply rounded-md bg-emerald-700 px-4 py-2 font-semibold text-white;
  }
}
```

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd components -i input.css -o out.css --silent
ana@laptop:~/site$ grep -A8 "^  \.btn {" components/out.css
  .btn {
    border-radius: var(--radius-md);
    background-color: var(--color-emerald-700);
    padding-inline: calc(var(--spacing) * 4);
    padding-block: calc(var(--spacing) * 2);
    --tw-font-weight: var(--font-weight-semibold);
    font-weight: var(--font-weight-semibold);
    color: var(--color-white);
  }
ana@laptop:~/site$ probe components/index.html style "#reserve,#wait" background-color
button#reserve  background-color: oklch(0.508 0.118 165.612)
button#wait  background-color: oklch(0.374 0.01 67.558)
```

`.btn` virou uma regra comum cujas declarações são as declarações dos utilitários, lendo os mesmos tokens. Ela foi para a camada **`components`**, e isso decide o que acontece quando um botão também tem um utilitário. O segundo botão é `class="btn bg-stone-700"`: o fundo dele é stone, **`oklch(0.374 0.01 67.558)`**, não o esmeralda do `.btn`. `utilities` é a camada posterior, então um utilitário sobrepõe um componente, seção 11 da aula 10, que é exatamente o que se quer de uma mudança pontual.

**Use `@apply` com moderação.** Uma folha cheia de `@apply` é a folha da aula 10 escrita numa linguagem mais limitada, e traz de volta os nomes e os vazamentos que os utilitários vieram evitar. Para os seus próprios utilitários pequenos, `@utility nome { … }` define uma classe nova que se comporta como uma embutida, variantes inclusive.
