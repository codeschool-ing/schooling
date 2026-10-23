---
title: NG0100, o erro que só o modo de desenvolvimento mostra
version: 1
---

**Em modo de desenvolvimento, o Angular percorre a árvore duas vezes seguidas e confere se a segunda
passada encontra todo valor igual ao da primeira; quando um difere, ele relata `NG0100`.** Uma
expressão de template que dá uma resposta diferente a cada vez que é perguntada, sem nada ter mudado, é
um bug: a página mostraria qualquer resposta que calhasse de ser desenhada. A segunda passada é como o
modo de desenvolvimento a encontra, e um build de produção a pula, e por isso o erro nunca aparece lá.

A causa mais comum é um método que lê o relógio:

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';

@Component({
  selector: 'app-bench',
  imports: [],
  template: '<h2>Bench</h2><p>Checked at {{ now() }}</p>',
})
export class Bench {
  protected now(): number {
    return Date.now();
  }
}
```

O `grep -v` tira as linhas do stack trace, que começam com espaços e `at`:

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench | grep -v '^    at '
[vite] connecting...
[vite] connected.
Angular is running in development mode.
[error] ERROR RuntimeError: NG0100: ExpressionChangedAfterItHasBeenCheckedError: Expression has changed after it was checked. Previous value: '1792799255446'. Current value: '1792799255469'. Expression location: _Bench component. Find more at https://v21.angular.dev/errors/NG0100
Bench

Checked at 1792799255446
```

A mensagem tem tudo o que é preciso: o código, `NG0100`; o valor anterior e o atual, a poucos
milissegundos um do outro; o componente, `Bench`; e um link para a página que o explica. A própria
página desenhou o primeiro valor e seguiu em frente, e é por isso que o erro passa fácil despercebido:
ele está no console, não na tela.

## O que o causa, e o conserto de cada um

- **Uma expressão que não é uma função pura do estado do componente**: o relógio, um número aleatório,
  um objeto novo construído a cada chamada. Calcule o valor uma vez, quando ele deve mudar, e guarde-o
  num signal ou num campo.
- **Um filho mudando o estado do pai enquanto o pai é conferido**, normalmente num hook de ciclo de vida
  que roda depois de o template do pai ser desenhado. A aula 9 encontra esses hooks e a ordem deles.
- **Um getter que muda algo enquanto lê**, como um que incrementa um contador. As leituras de um
  template precisam ser leituras; a mudança pertence a um handler de evento.

O conserto nunca é fazer o erro sumir, capturando-o ou desligando a conferência do modo de
desenvolvimento. O erro está dizendo que a tela e o estado discordam, e em produção ninguém seria
avisado.
