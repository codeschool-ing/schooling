---
title: O que o template não consegue carregar
version: 1
---

**Um formulário template-driven só existe depois que o template rodou, e um pouco depois.** Os
controles são feitos pelas diretivas `ngModel`, e cada uma se registra no formulário de forma
assíncrona, depois que a detecção de mudanças atual termina. Uma classe que pede o valor ao formulário
cedo demais recebe um objeto vazio. O bench o registra em dois momentos:

```typescript
// src/app/bench/bench.ts
import { AfterViewInit, ChangeDetectionStrategy, Component, signal, viewChild } from '@angular/core';
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
export class Bench implements AfterViewInit {
  protected readonly date = signal('');
  protected readonly minutes = signal(30);
  private readonly form = viewChild.required(NgForm);

  ngAfterViewInit(): void {
    console.log('after view init:', JSON.stringify(this.form().value));
    setTimeout(() => console.log('a moment later:', JSON.stringify(this.form().value)));
  }

  protected check(f: NgForm): void {
    console.log('submitted:', JSON.stringify(f.value), 'valid:', f.valid);
  }
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
after view init: {}
Angular is running in development mode.
a moment later: {"date":"","minutes":30}
Day
Length in minutes
Check
```

O `ngAfterViewInit` é o hook de "a view foi desenhada", e nesse momento o formulário não tinha
controle nenhum. Um instante depois tinha os dois. Código que define um valor, acrescenta um
validador ou lê o formulário a partir da classe precisa saber dessa lacuna; com um formulário reativo
não há lacuna, porque a classe fez os controles antes de o template existir.

A lacuna é um de quatro limites, e os outros três crescem com o formulário:

| | template-driven | reativo |
|---|---|---|
| onde o formulário fica | no template, feito quando ele roda | na classe, feito antes |
| o tipo de um valor | `any`: o `f.value` é um objeto que ninguém descreveu | deduzido dos controles |
| uma lista de campos de tamanho variável | um `@for` de `ngModel`s com nomes gerados | um `FormArray` |
| um teste das regras | renderizar o template e digitar nele | criar os controles e definir os valores |
| validação | um atributo por regra, e uma diretiva para cada uma própria | uma função por regra, passada a um controle |

Uma regra como o `distinctDates` da aula 15 deixa isso claro. Escrita para um formulário reativo, é
uma função que recebe o array; para um template-driven, ela precisa virar uma diretiva, ir num
elemento em volta dos campos, e receber os valores pelo formulário em que está. **O formulário
cresce, e a versão template-driven cresce mais rápido**, que é o título desta aula.
