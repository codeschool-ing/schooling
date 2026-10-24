---
title: Validação escrita no template
version: 1
---

**Num formulário template-driven os validadores são atributos.** `required` e `min="5"` num input com
`ngModel` são diretivas que acrescentam `Validators.required` e `Validators.min(5)` ao controle que o
`ngModel` fez. Uma referência de template, `#day="ngModel"`, dá esse controle ao template, para o
template poder perguntar se ele está inválido ou tocado; `#f="ngForm"` dá o formulário inteiro.

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, signal } from '@angular/core';
import { FormsModule, NgForm } from '@angular/forms';

@Component({
  selector: 'app-bench',
  imports: [FormsModule],
  template: `
    <form #f="ngForm" (ngSubmit)="check(f)">
      <label for="t-day">Day</label>
      <input id="t-day" type="date" name="date" [(ngModel)]="date" required #day="ngModel" />
      @if (day.invalid && (day.touched || f.submitted)) {
        <p>This is needed.</p>
      }
      <label for="t-minutes">Length in minutes</label>
      <input id="t-minutes" type="number" name="minutes" [(ngModel)]="minutes" required min="5" #length="ngModel" />
      @if (length.invalid && (length.touched || f.submitted)) {
        <p>At least 5 minutes.</p>
      }
      <button type="submit">Check</button>
    </form>
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
  protected readonly date = signal('');
  protected readonly minutes = signal(30);

  protected check(f: NgForm): void {
    console.log('submitted:', JSON.stringify(f.value), 'valid:', f.valid);
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'fill Length in minutes = 2' --do 'click Check'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill Length in minutes = 2
-- click Check
submitted: {"date":"","minutes":2} valid: false
Day

This is needed.

Length in minutes

At least 5 minutes.

Check
```

As mesmas regras do formulário da aula 15, com menos código na classe, e toda decisão está no
template: quais validadores, quando uma mensagem aparece, o que é mandado. Para um formulário de dois
campos isso é agradável de ler. É também onde o problema começa.
