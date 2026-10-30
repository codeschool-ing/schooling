---
title: Interpolação, e uma bancada para experimentar
version: 1
---

**Um template é HTML com buracos, e `{{ }}` é o buraco mais simples: o Angular avalia a expressão de
dentro, transforma o resultado em texto e põe o texto ali.** Esta aula trata dos quatro jeitos de um
template e a sua classe conversarem, e precisa de um lugar para experimentá-los que não seja o
planner, então a primeira coisa é uma bancada: um componente que só existe nesta aula.

```
ana@dev:~/planner$ npx ng generate component bench --skip-tests
CREATE src/app/bench/bench.css (0 bytes)
CREATE src/app/bench/bench.ts (182 bytes)
CREATE src/app/bench/bench.html (20 bytes)
```

`--skip-tests`, porque a bancada é apagada no fim da aula e o teste dela também seria. Ponha-a debaixo
da semana, no `App`:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<app-week />
<app-bench />
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

## Expressões nos buracos

A classe da bancada guarda alguns valores de formatos diferentes:

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
  protected course = { name: 'Git', sessions: 2 };
  protected note = '<b>bold?</b>';
  protected nothing: { name: string } | null = null;

  protected hours(m: number): string {
    return (m / 60).toFixed(2);
  }
}
```

e o template dela os lê:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<p>{{ minutes }} minutes is {{ hours(minutes) }} hours.</p>
<p>{{ course.name }}: {{ course.sessions }} sessions, {{ course.sessions * minutes }} minutes.</p>
<p>{{ note }}</p>
<p>{{ nothing?.name ?? 'no name' }}</p>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Bench

45 minutes is 0.75 hours.

Git: 2 sessions, 90 minutes.

<b>bold?</b>

no name
```

Cada linha mostra uma coisa que uma expressão pode fazer:

- **ler um campo**, `minutes`, e **chamar um método**, `hours(minutes)`. Os campos são `protected`: o
  template pode lê-los, e código de fora da classe não, que é o acesso de que um template precisa e
  nada além;
- **seguir uma propriedade** e **fazer contas**, `course.sessions * minutes`;
- **continuar texto**. O `note` guarda os caracteres de uma tag `<b>`, e a página mostra esses
  caracteres, não um texto em negrito. A interpolação sempre produz texto, e o navegador é instruído a
  tratá-lo como texto, então um valor que veio de um usuário não tem como virar marcação na página.
  Essa é a defesa contra o ataque que o `front-quality` chama de cross-site scripting, embutida na
  sintaxe;
- **lidar com o nada**: o `?.` para num `null` em vez de lançar erro, e o `??` fornece a alternativa,
  os dois como em JavaScript.

## O que uma expressão não pode fazer

Uma expressão de template é um pequeno subconjunto de JavaScript, de propósito. Ela não pode atribuir
(`minutes = 0`), criar objetos com `new`, usar `++`, nem alcançar globais como `window` e `console`:
ela vê o componente e mais nada. A única exceção, a atribuição, é permitida num event binding, duas
seções adiante, porque responder a um evento é justamente quando mudar alguma coisa é o objetivo.

Um método chamado num template é chamado toda vez que o Angular confere o template, o que pode
acontecer muitas vezes por segundo. O `hours()` é barato, então aqui não importa; a aula 6 mostra a
ferramenta para um valor que custa calcular, e a aula 19 a de formatação.
