---
title: Signal Forms, o terceiro jeito, experimental
version: 1
---

**O Angular 21 traz um terceiro tipo de formulário, os Signal Forms, marcados como experimentais.** O
modelo é um signal seu, de um objeto simples. O `form(model, schema)` monta uma árvore de campos sobre
ele, um por propriedade, e o valor, os erros e o estado de cada campo são signals. As regras são
escritas uma vez, na função de schema, contra caminhos dentro do modelo. No template, o `[formField]`
liga um input a um campo.

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { FormField, form, min, required } from '@angular/forms/signals';

@Component({
  selector: 'app-bench',
  imports: [FormField],
  template: `
    <form novalidate>
      <label for="s-day">Day</label>
      <input id="s-day" type="date" [formField]="draft.date" />
      @for (error of draft.date().errors(); track error.kind) {
        <p>{{ error.message }}</p>
      }
      <label for="s-minutes">Length in minutes</label>
      <input id="s-minutes" type="number" [formField]="draft.minutes" />
      @for (error of draft.minutes().errors(); track error.kind) {
        <p>{{ error.message }}</p>
      }
    </form>
    <p>{{ model().date }}, {{ model().minutes }} minutes, valid: {{ draft().valid() }}</p>
  `,
  styles: `
    form {
      display: grid;
      gap: 0.5rem;
      max-width: 20rem;
    }
  `,
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  protected readonly model = signal({ date: '', minutes: 30 });
  protected readonly draft = form(this.model, (path) => {
    required(path.date, { message: 'This is needed.' });
    min(path.minutes, 5, { message: 'At least 5 minutes.' });
  });
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'fill Length in minutes = 2'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Length in minutes = 2
Day

This is needed.

Length in minutes

At least 5 minutes.

, 2 minutes, valid: false
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'fill Day = 2026-10-26' --do 'fill Length in minutes = 45'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Day = 2026-10-26
-- fill Length in minutes = 45
Day
Length in minutes

2026-10-26, 45 minutes, valid: true
```

O input escreveu direto no `model`: o `model().minutes` foi 2, depois 45, sem `getRawValue` no meio,
porque o valor do formulário e o signal são a mesma coisa. O `draft().valid()` é um signal, então um
`computed` pode lê-lo como qualquer outro. Toda mensagem aqui aparece de uma vez; cada campo também
tem um signal `touched()`, para a regra que a aula 15 usou.

Ele também escreve parte das regras do formulário na página. O HTML do próprio formulário mostra:

```
ana@dev:~/planner$ look http://localhost:4200/ --html 'app-bench form'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<form novalidate=""><label for="s-day">Day</label><input id="s-day" type="date" name="ng.form0.date" required=""><p>This is needed.</p><!--container--><label for="s-minutes">Length in minutes</label><input id="s-minutes" type="number" min="5" name="ng.form0.minutes"><!--container--></form>
```

O `[formField]` pôs os atributos do próprio navegador nos inputs, `required` na data e `min="5"` nos
minutos, a partir do schema, então a tecnologia assistiva sabe que a data é obrigatória sem ser
avisada duas vezes. É também por isso que o `<form>` leva `novalidate`, escrito à mão: nada do
`FormsModule` ou do `ReactiveFormsModule` está importado aqui para acrescentá-lo, e sem ele o
navegador mostraria os próprios balões para esses atributos. Ligar uma mensagem ao campo dela
continua sendo trabalho seu, com `aria-describedby`, como foi na aula 15.

**Experimental quer dizer que a API pode mudar numa versão menor**, sem o período de depreciação que o
resto do Angular promete. Para uma aplicação que precisa ser mantida por anos, a escolha do planner é
a de hoje: formulários reativos, que são estáveis, e ao lado dos quais os Signal Forms foram feitos
para ser adotados, um formulário por vez.
