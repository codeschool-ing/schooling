---
title: O que é detecção de mudanças
version: 1
---

**Detecção de mudanças é o Angular percorrendo a sua árvore de componentes, avaliando cada expressão de
cada template que visita, e mudando o DOM onde um valor difere da última vez.** É assim que o
`{{ planned }}` da página acompanha o `planned` da classe. Duas perguntas decidem tudo sobre ela:
*quando* o Angular percorre, e *quais* componentes ele visita. As respostas mudaram ao longo da história
do Angular, e essa mudança é o assunto desta aula.

A passada fica visível se um template chamar um método que registra cada chamada. Uma bancada, de novo:

```
ana@dev:~/planner$ npx ng generate component bench --skip-tests --inline-template --inline-style
CREATE src/app/bench/bench.ts (193 bytes)
```

`--inline-template` e `--inline-style` põem o template e os estilos dentro do arquivo da classe, o que
serve a um componente de poucas linhas, e esta aula escreve vários.

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-bench',
  imports: [],
  template: `
    <h2>Bench</h2>
    <p>{{ label() }}</p>
    <button type="button" (click)="nothing()">Do nothing</button>
  `,
})
export class Bench {
  protected label(): string {
    console.log('label() called');
    return 'a template expression';
  }

  protected nothing(): void {}
}
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

Carregue a página, e clique num botão que não muda nada:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench --do 'click Do nothing'
[vite] connecting...
[vite] connected.
label() called
label() called
Angular is running in development mode.
label() called
-- click Do nothing
label() called
label() called
Bench

a template expression

Do nothing
```

O `label()` foi chamado antes de alguém clicar, mais de uma vez, e de novo depois de um clique que não
mudou nada. Toda vez que o Angular chega a este componente ele avalia a expressão, porque o único jeito
de saber se a resposta de um método comum mudou é perguntar. Em modo de desenvolvimento ele também
percorre uma segunda vez, logo depois de cada passada, para conferir que nada se mexeu entre as duas; a
seção sobre o `NG0100` trata do que essa segunda passada pega.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Uma árvore de quatro componentes: App no topo, Week abaixo, e abaixo de Week um resumo e uma lista. Uma passada começa no App e visita cada componente de cima para baixo, avaliando as expressões do template. À direita, a mesma árvore com a lista marcada OnPush e sem marca: a passada a pula, e tudo o que está abaixo dela.\"><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">padrão: todo componente, toda passada</text><text x=\"530\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">OnPush: só o que foi marcado</text><rect x=\"120\" y=\"40\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><rect x=\"120\" y=\"110\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Week</text><rect x=\"30\" y=\"180\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><rect x=\"210\" y=\"180\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseCard</text><line x1=\"180\" y1=\"76\" x2=\"180\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"180.0,108.0 176.9,100.6 183.1,100.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"160\" y1=\"146\" x2=\"100\" y2=\"178\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"100.0,178.0 105.0,171.8 108.0,177.3\" fill=\"var(--phosphor)\"></polygon><line x1=\"200\" y1=\"146\" x2=\"260\" y2=\"178\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"260.0,178.0 252.0,177.3 255.0,171.8\" fill=\"var(--phosphor)\"></polygon><rect x=\"480\" y=\"40\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><rect x=\"480\" y=\"110\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Week</text><rect x=\"390\" y=\"180\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">WeekSummary</text><rect x=\"570\" y=\"180\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"630\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CourseCard</text><line x1=\"540\" y1=\"76\" x2=\"540\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,108.0 536.9,100.6 543.1,100.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"520\" y1=\"146\" x2=\"460\" y2=\"178\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"460.0,178.0 465.0,171.8 468.0,177.3\" fill=\"var(--phosphor)\"></polygon><line x1=\"560\" y1=\"146\" x2=\"620\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"620.0,178.0 612.0,177.3 615.0,171.8\" fill=\"var(--wire)\"></polygon><text x=\"630\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">OnPush, sem marca: pulado</text><line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"255\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line></svg>", "caption": "Uma passada vai da raiz para baixo. Um componente OnPush que nada marcou é pulado, com tudo o que está abaixo dele."}
```

É por isso que a aula 4 disse que um método num template só é barato quando o método é barato, e por
isso que o `computed` da aula 6 existe: um computed também é perguntado, e responde de memória a não
ser que algo que ele leu tenha mudado.
