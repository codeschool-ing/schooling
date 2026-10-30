---
title: Construtor ou ngOnInit
version: 1
---

**Os inputs não estão definidos quando o construtor roda, então código que lê um input pertence a
depois dele.** Esse fato sozinho é o motivo de o `ngOnInit` existir, e a maior parte dos `ngOnInit` do
código antigo está lá por nenhum outro motivo. Leia um input no construtor e veja o que acontece:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, OnInit, input } from '@angular/core';

@Component({
  selector: 'app-life',
  template: '<p>life: {{ label() }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Life implements OnInit {
  readonly label = input.required<string>();

  constructor() {
    console.log('constructor sees', this.label());
  }

  ngOnInit(): void {
    console.log('ngOnInit sees', this.label());
  }
}

@Component({
  selector: 'app-bench',
  imports: [Life],
  template: '<h2>Bench</h2><app-life label="first" />',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {}
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -A4 ERROR
✘ [ERROR] NG8118: `label` is a required `input` and does not have a value in this context. [plugin angular-compiler]

    src/app/bench/bench.ts:13:36:
      13 │     console.log('constructor sees', this.label());
         ╵                                     ~~~~~~~~~~
```

O compilador recusou, `NG8118`: ele viu um input obrigatório lido num lugar onde ainda não pode ter
valor, e apontou a linha. Em código que não é conferido desse jeito, um `@Input` lido num construtor,
por exemplo, o mesmo erro compila e lê `undefined`, ou falha com a página rodando com o `NG0950` da aula
8. Leve a leitura para o `ngOnInit` e ele vê `first`.

**Os signals levam a pergunta para outro lugar.** Um `computed` que lê o input não faz nada até alguém
o ler, e até lá o input já está definido, então o lugar onde ele é declarado deixa de importar:

```typescript
protected readonly title = computed(() => `life: ${this.label()}`);
```

Esse é o padrão do planner desde a aula 8: o `CoursePage` declara o `course` a partir do `courseId()`
num campo, e nunca precisa do `ngOnInit`. O que sobra para o construtor é aquilo em que ele sempre foi
bom: pedir coisas, o que a aula 10 faz com o `inject()`, e montar effects.

O que sobra para o `ngOnInit` é o código antigo, e um caso real: um trabalho que precisa acontecer uma
vez, com os inputs definidos, e que não é um valor, como mandar um evento de analytics sobre o registro
que uma página abriu. Um `effect` o rodaria de novo sempre que o input mudasse, o que pode ser
exatamente o errado.
