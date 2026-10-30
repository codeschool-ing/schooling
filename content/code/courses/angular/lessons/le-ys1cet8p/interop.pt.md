---
title: Entre Observables e signals, e o pipe async
version: 1
---

**Um Observable assinado precisa ter a assinatura cancelada, senão sobrevive a quem o iniciou.** O
relógio da aula 9 continuou batendo depois que o componente dele se foi; uma assinatura faz o mesmo.
Um pedido termina sozinho depois da resposta, então esquecer um custa pouco. O `interval`, um
`toObservable` de um signal, os eventos de um formulário: esses continuam até alguém cancelar a
assinatura, e esse alguém é o código que assinou.

Há três jeitos de deixar isso por conta de outra coisa, e o bench já usou um deles.

**`toSignal(observable)`** assina na hora e cancela quando o componente, ou o serviço, que o criou é
destruído. O que sai é um signal como qualquer outro: um template o lê, um `computed` o lê. É o padrão
em código novo, porque o resto de um componente moderno é feito de signals.

**`takeUntilDestroyed()`** é um operador, do mesmo pacote, para uma assinatura que precisa ser
escrita por extenso, porque o que ela faz é um efeito e não um valor:

```typescript
constructor() {
  interval(1000)
    .pipe(takeUntilDestroyed())
    .subscribe(() => console.log('still here'));
}
```

Ele termina a cadeia quando o componente é destruído. Chamado fora de um construtor ou de um campo,
ele precisa receber o `DestroyRef` do componente, pelo motivo que a aula 10 deu sobre o `inject`.

**O pipe `async`** é o terceiro, e o que a maior parte do código Angular existente usa. Ele assina no
template, mostra o último valor, e cancela quando o elemento sai:

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { AsyncPipe } from '@angular/common';\nimport { HttpClient } from '@angular/common/http';\nimport { ChangeDetectionStrategy, Component, inject } from '@angular/core';\nimport { map } from 'rxjs';\nimport { PlannerData } from '../planner';\n\n@Component({\n  selector: 'app-bench',\n  imports: [AsyncPipe],\n  template: '<p>Sessions left to do: {{ left$ | async }}</p>',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {", "note": "Um pipe precisa ser importado no componente, como um componente. A aula 19 é sobre pipes."},
 {"code": "  protected readonly left$ = inject(HttpClient)\n    .get<PlannerData>('/api/planner')\n    .pipe(map((data) => data.sessions.filter((s) => !s.done).length));\n}", "note": "O `$` no fim do nome é uma convenção, não sintaxe: diz que o campo é um Observable, para quem lê saber que deve assinar em vez de ler."}
]}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Sessions left to do: 3
```

O pipe marca o componente para conferência sempre que chega um valor, então funciona com `OnPush` e
sem zone.js. Dois `| async` do mesmo Observable num template assinam duas vezes, e como o Observable
é frio, são dois pedidos; o `@if (left$ | async; as left)` assina uma vez e dá nome ao valor para o
bloco de dentro. Com o `toSignal` a questão nem aparece: uma assinatura, lida quantas vezes quiser.
