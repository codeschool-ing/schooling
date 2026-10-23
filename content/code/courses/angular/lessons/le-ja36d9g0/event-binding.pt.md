---
title: Eventos, e o valor que veio com eles
version: 1
---

**`(evento)="instrução"` roda a instrução toda vez que o elemento dispara aquele evento.** Parênteses
para eventos, colchetes para propriedades: os dados saem da classe para o DOM pelos colchetes, e voltam
para a classe pelos parênteses. A bancada ganha botões e um campo que informa o que foi digitado:

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-bench',
  imports: [],
  templateUrl: './bench.html',
  styleUrl: './bench.css',
})
export class Bench {
  protected minutes = 45;
  protected saved = 'nothing yet';

  protected add(m: number): void {
    this.minutes = Math.min(this.minutes + m, 240);
  }

  protected typed(event: Event): void {
    this.minutes = (event.target as HTMLInputElement).valueAsNumber || 0;
  }
}
```

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<p>{{ minutes }} minutes</p>
<button type="button" (click)="add(15)">Add 15</button>
<button type="button" (click)="minutes = 0">Clear</button>

<label for="bench-minutes">Minutes</label>
<input id="bench-minutes" type="number" [value]="minutes" (input)="typed($event)" />

<label for="bench-note">Note</label>
<input id="bench-note" #note (keydown.enter)="saved = note.value" />
<p>Saved: {{ saved }}</p>
```

O `look --do` executa ações em ordem, e imprime cada uma antes de executá-la. Clique no primeiro botão
duas vezes, digite um número no campo, depois digite uma nota e aperte Enter:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Add 15' --do 'click Add 15' --do 'fill Minutes = 100' --do 'fill Note = revise the router' --do 'press Enter'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- click Add 15
-- click Add 15
-- fill Minutes = 100
-- fill Note = revise the router
-- press Enter
Bench

100 minutes

Add 15ClearMinutesNote

Saved: revise the router
```

Três formas da mesma ideia:

- **`(click)="add(15)"`** chama um método com um argumento. O método muda um campo, e o Angular
  desenha o template de novo depois do evento, então o `75` apareceu sem ninguém pedir.
- **`(click)="minutes = 0"`** é uma instrução escrita ali mesmo: um event binding é o único lugar em
  que um template pode atribuir. Mantenha essas instruções numa linha curta; qualquer coisa maior vai
  num método, onde pode ser lida e testada.
- **`(input)="typed($event)"`** passa o próprio evento. O `$event` é o `Event` do DOM, e o método lê o
  valor do campo a partir do `target` dele. O `as HTMLInputElement` diz ao TypeScript que tipo de
  elemento o disparou, porque o `Event` sozinho não diz.

## Uma referência a um elemento

`#note` dá ao segundo campo um nome que o resto do template pode usar: uma **variável de referência de
template**. `note.value` lê o campo diretamente, sem campo na classe e sem `$event`. `(keydown.enter)`
é um evento de tecla com a tecla nomeada no binding, então a instrução roda com Enter e com nenhuma
outra tecla. Uma referência é a ferramenta certa quando o valor só é necessário no momento do evento;
quando a classe precisa dele o tempo todo, faça o binding, como os formulários da aula 16 fazem.

**Todo controle aqui é um `<button>` ou um `<input>` com rótulo.** Isso não é enfeite: o `look` os
achou pelo nome, `Add 15` e `Minutes`, exatamente como um leitor de tela acha, e uma `<div>` com
`(click)` não teria sido achada por nenhum dos dois. Uma `<div>` clicável também não é alcançada com
Tab nem acionada com Enter. Se ela faz algo quando clicada, ela é um botão, e o elemento deve dizer
isso.
