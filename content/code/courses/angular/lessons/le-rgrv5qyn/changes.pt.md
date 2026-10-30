---
title: Reagindo a um input que muda
version: 1
---

**O `ngOnChanges` roda sempre que um input muda, e recebe qual foi a mudança; com inputs signal, um
`computed` ou um `effect` que lê o input faz o mesmo trabalho com menos código.** O hook era o único
jeito de reagir a um input na época dos decorators, então ele está em todo o código antigo, em geral
para manter um campo derivado em sincronia:

```typescript
// the decorator era
@Input() minutes = 0;
hours = 0;

ngOnChanges(changes: SimpleChanges): void {
  if (changes['minutes']) {
    this.hours = this.minutes / 60;
  }
}
```

O `changes` guarda uma entrada por input alterado, com `previousValue`, `currentValue` e `firstChange`.
O código precisa conferir qual input mudou, copiar o valor para um campo, e lembrar que o campo só
existe para acompanhar o input. A aula 6 chamaria isso de effect que define um signal, e a resposta é a
mesma:

```typescript
// with signals
readonly minutes = input(0);
protected readonly hours = computed(() => this.minutes() / 60);
```

Nenhum hook, nenhuma conferência de qual input mudou, nenhum campo para manter em sincronia. O
`computed` lê o input, então acompanha o input, que é tudo o que o `ngOnChanges` era montado para
conseguir.

Quando a reação não é um valor mas uma ação sobre o mundo de fora, é um `effect`, que a aula 6
apresentou exatamente para isso:

```typescript
constructor() {
  effect(() => {
    document.title = `${this.minutes()} minutes this week`;
  });
}
```

O `ngOnChanges` também só dispara para mudanças feitas pelo binding do template, não para um valor
definido pelo código, o que era uma fonte de bugs que um computed simplesmente não tem. Você ainda vai
lê-lo, e quando migrar um `@Input` para `input()` com a migração da aula 8, o `ngOnChanges` ao lado é a
próxima coisa a virar um `computed`.
