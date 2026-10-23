---
title: Para que serve o track
version: 1
---

**Quando uma lista muda, o Angular mantém o DOM que já desenhou para todo item cuja chave de track
ele ainda encontra, e o move, em vez de desenhá-lo de novo.** Isso é mais rápido, e também é o que
mantém o que uma pessoa digitou, focou ou rolou preso ao item certo. A chave de track decide o que "o
mesmo item" quer dizer, e uma chave ruim quebra isso em silêncio. De volta a uma bancada para ver
acontecer:

```
ana@dev:~/planner$ npx ng generate component bench --skip-tests
CREATE src/app/bench/bench.css (0 bytes)
CREATE src/app/bench/bench.ts (182 bytes)
CREATE src/app/bench/bench.html (20 bytes)
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-bench />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Week } from './week/week';
import { Bench } from './bench/bench';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {}
```

A bancada desenha os mesmos três cursos duas vezes, uma rastreada por `course.id` e outra por
`$index`, com um campo vazio em cada linha, e um botão que inverte a lista:

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';
import { Course } from '../planner';

@Component({
  selector: 'app-bench',
  imports: [],
  templateUrl: './bench.html',
  styleUrl: './bench.css',
})
export class Bench {
  protected courses: Course[] = [
    { id: 'html-css', name: 'HTML and CSS' },
    { id: 'javascript', name: 'JavaScript' },
    { id: 'git', name: 'Git' },
  ];

  protected reverse(): void {
    this.courses = [...this.courses].reverse();
  }
}
```

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<button type="button" (click)="reverse()">Reverse</button>
<h3>Tracked by id</h3>
@for (course of courses; track course.id) {
  <p><label>by id: {{ course.name }} <input /></label></p>
}
<h3>Tracked by position</h3>
@for (course of courses; track $index) {
  <p><label>by position: {{ course.name }} <input /></label></p>
}
```

Digite 25 na linha do Git de cada lista, depois inverta:

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y app-bench --do 'fill by id: Git = 25' --do 'fill by position: Git = 25' --do 'click Reverse'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- fill by id: Git = 25
-- fill by position: Git = 25
-- click Reverse
- heading "Bench" [level=2]
- button "Reverse"
- heading "Tracked by id" [level=3]
- paragraph
  - LabelText
    - text: by id: Git 
    - textbox "by id: Git ": 25
- paragraph
  - LabelText
    - text: by id: JavaScript 
    - textbox "by id: JavaScript "
- paragraph
  - LabelText
    - text: by id: HTML and CSS 
    - textbox "by id: HTML and CSS "
- heading "Tracked by position" [level=3]
- paragraph
  - LabelText
    - text: by position: Git 
    - textbox "by position: Git "
- paragraph
  - LabelText
    - text: by position: JavaScript 
    - textbox "by position: JavaScript "
- paragraph
  - LabelText
    - text: by position: HTML and CSS 
    - textbox "by position: HTML and CSS ": 25
```

**Rastreado por id, o 25 foi junto com o Git** para o topo da lista: o Angular achou a chave `git` de
novo, manteve o DOM daquela linha, com campo e tudo, e o moveu. **Rastreado por posição, o 25 ficou na
terceira linha, que agora é HTML and CSS.** A posição 2 continuava existindo depois da inversão, então
o Angular manteve o DOM da terceira linha e só trocou o texto. Nada deu erro, e o valor que uma pessoa
digitou agora está ao lado do curso errado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas listas de três linhas, antes e depois de a lista ser invertida. Cada linha é um pedaço de DOM com um campo; o campo da linha do Git tem 25. Rastreado por id, o DOM da linha do Git vai para o topo, com o seu 25. Rastreado por posição, o DOM de cada linha fica onde estava e só o texto muda, então o 25 fica na terceira linha, que agora diz HTML and CSS.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">rastreado por id</text><text x=\"130\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">antes</text><text x=\"590\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois do Reverse</text><rect x=\"30\" y=\"42\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTML and CSS</text><rect x=\"170\" y=\"47\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"76\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JavaScript</text><rect x=\"170\" y=\"81\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"110\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Git</text><rect x=\"170\" y=\"115\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">25</text><rect x=\"490\" y=\"42\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Git</text><rect x=\"630\" y=\"47\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">25</text><rect x=\"490\" y=\"76\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JavaScript</text><rect x=\"630\" y=\"81\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"490\" y=\"110\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTML and CSS</text><rect x=\"630\" y=\"115\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M232 126 C 360 126, 360 56, 486 56\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><line x1=\"480\" y1=\"56\" x2=\"486\" y2=\"56\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"486.0,56.0 478.6,59.1 478.6,52.9\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a linha do Git se move, com o campo</text><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">rastreado por posição</text><text x=\"130\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">antes</text><text x=\"590\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">depois do Reverse</text><rect x=\"30\" y=\"182\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTML and CSS</text><rect x=\"170\" y=\"187\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"216\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JavaScript</text><rect x=\"170\" y=\"221\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"250\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Git</text><rect x=\"170\" y=\"255\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">25</text><rect x=\"490\" y=\"182\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Git</text><rect x=\"630\" y=\"187\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"490\" y=\"216\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">JavaScript</text><rect x=\"630\" y=\"221\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"490\" y=\"250\" width=\"200\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"264\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">HTML and CSS</text><rect x=\"630\" y=\"255\" width=\"50\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"655\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">25</text><line x1=\"232\" y1=\"196\" x2=\"486\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"486.0,196.0 478.6,199.1 478.6,192.9\" fill=\"var(--wire)\"></polygon><line x1=\"232\" y1=\"230\" x2=\"486\" y2=\"230\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"486.0,230.0 478.6,233.1 478.6,226.9\" fill=\"var(--wire)\"></polygon><line x1=\"232\" y1=\"264\" x2=\"486\" y2=\"264\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><polygon points=\"486.0,264.0 478.6,267.1 478.6,260.9\" fill=\"var(--wire)\"></polygon><text x=\"360\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada linha fica; só o texto muda</text></svg>", "caption": "A chave decide o que conta como a mesma linha. Por posição, o 25 vai parar ao lado do curso errado."}
```

## Escolhendo a chave

A chave deve ser o que faz de um item *aquele* item, e nunca muda enquanto ele existe:

- **um id dos dados**, `course.id` ou `session.id`, é quase sempre o certo;
- **o `$index`** só é certo para uma lista que nunca reordena, insere ou remove, o que é mais raro do
  que parece;
- **o próprio item**, `track course`, funciona quando os mesmos objetos ficam na lista, e falha assim
  que a lista é reconstruída a partir de uma resposta do servidor, porque todo objeto é novo e nada é
  reconhecido.

O código escrito antes do `@for` usava o `*ngFor`, em que o track era opcional e quase sempre faltava.
Sem ele, cada item é reconhecido pelo objeto, e uma lista recarregada do servidor é desenhada de novo
do zero. A última seção desta aula encontra esse código.
