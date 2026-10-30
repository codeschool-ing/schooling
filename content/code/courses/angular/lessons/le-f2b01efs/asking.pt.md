---
title: Pedir uma coisa em vez de construí-la
version: 1
---

**Injeção de dependência quer dizer que uma classe diz do que precisa e outra coisa a entrega.** A
classe não chama `new` nos seus colaboradores, e não vai buscar um global; ela pede, e um injetor
responde. O Angular é construído sobre isso de baixo para cima. Todo `inject()` que você escreveu até
aqui, o `inject(DestroyRef)` da aula 9 entre eles, foi uma pergunta feita a um injetor.

A tela da semana mostra por que isso importa. O `Week` descobre qual semana contar assim:

```typescript
private readonly week = weekOf(isoDay(new Date()));
```

`new Date()` é o relógio do computador, lido pelo próprio componente. Ninguém consegue entregar ao
`Week` outro dia: as transcrições deste curso só conseguem um porque o `look --today` troca o relógio
do navegador por baixo dele, e um teste teria de fazer o mesmo. Um componente que pedisse o dia de
hoje, em vez de lê-lo, poderia receber qualquer dia de quem o constrói. É aí que esta aula chega, na
quarta seção.

## Uma classe que é pedida

Comece com algo menor que uma data: uma classe com um método, e um componente que quer uma instância
dela. O bench de novo:

```
ana@dev:~/planner$ npx ng generate component bench --inline-template --inline-style --skip-tests
CREATE src/app/bench/bench.ts (269 bytes)
```

```schooling-example
{"language": "typescript", "file": "src/app/bench/bench.ts", "parts": [
 {"code": "import { ChangeDetectionStrategy, Component, Injectable, inject } from '@angular/core';\n\n@Injectable()\nexport class Greeter {\n  greet(name: string): string {\n    return `Hello, ${name}`;\n  }\n}", "note": "O `@Injectable()` marca uma classe que o Angular pode construir e entregar. Sozinho, não diz onde."},
 {"code": "@Component({\n  selector: 'app-bench',\n  template: '<p>{{ text }}</p>',\n  changeDetection: ChangeDetectionStrategy.OnPush,\n})\nexport class Bench {\n  private readonly greeter = inject(Greeter);\n  protected readonly text = this.greeter.greet('Ana');\n}", "note": "O bench pede um `Greeter` e o usa. Ele nunca escreve `new Greeter()`."}
]}
```

Ele entra no `App` do jeito que o bench da aula 9 entrou:

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
  <app-course-page courseId="javascript" />
  <app-bench />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Bench } from './bench/bench';
import { CoursePage } from './course-page/course-page';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week, CoursePage, Bench],
  templateUrl: './app.html',
  styleUrl: './app.css',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class App {}
```

O stack trace de um erro do Angular ocupa uma dúzia de linhas dos arquivos do próprio framework,
então o `grep -v` as deixa de fora, como fez na aula 7:

```
ana@dev:~/planner$ look http://localhost:4200/ --text body | grep -v '^    at '
[vite] connecting...
[vite] connected.
[error] ERROR ɵNotFound: NG0201: No provider found for `_Greeter`. Source: Environment Injector. Find more at https://v21.angular.dev/errors/NG0201
[error] ɵNotFound: NG0201: No provider found for `_Greeter`. Source: Environment Injector. Find more at https://v21.angular.dev/errors/NG0201
Study planner
```

**O NG0201 diz que ninguém foi informado de como fazer um `Greeter`.** O `@Injectable()` deixa o
Angular construir a classe, mas nenhum injetor no caminho para cima a partir do bench tinha sido
avisado dela, então a pergunta chegou ao último, que responde toda pergunta falhando. `_Greeter` é o
nome que o build dá à classe. O erro é impresso duas vezes, uma pelo tratador de erros do Angular e
outra pelo `catch` no fim do `main.ts`, porque a aplicação nunca terminou de iniciar. Só o título
chegou à página: um componente que não pode ser construído para a view onde está, e aqui essa view
era a aplicação inteira.

## Onde achar um

Um argumento resolve. `providedIn: 'root'` diz ao Angular que o injetor raiz da aplicação sabe fazer
um `Greeter`, e o faz na primeira vez que alguém pede:

```typescript
// src/app/bench/bench.ts
import { ChangeDetectionStrategy, Component, Injectable, inject } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class Greeter {
  greet(name: string): string {
    return `Hello, ${name}`;
  }
}

@Component({
  selector: 'app-bench',
  template: '<p>{{ text }}</p>',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class Bench {
  private readonly greeter = inject(Greeter);
  protected readonly text = this.greeter.greet('Ana');
}
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Hello, Ana
```

O injetor raiz faz **um** `Greeter` e entrega o mesmo a todo mundo que pedir, enquanto a aplicação
estiver rodando. Uma classe que ninguém pede nunca é feita, e o build a deixa fora do bundle, e é por
isso que `providedIn: 'root'` é a forma que o CLI escreve e a primeira a usar.

## A grafia antiga

Código escrito antes do Angular 14 pede pelos parâmetros do construtor, e você vai ler muito dele:

```typescript
export class Bench {
  constructor(private readonly greeter: Greeter) {}
}
```

O Angular lê o tipo do parâmetro e injeta um `Greeter` ali. É a mesma pergunta ao mesmo injetor, e
as duas formas podem se misturar numa classe. O `inject()` é o que o CLI gera hoje, e tem duas
vantagens que um parâmetro não tem: funciona num campo comum, e numa função que nem é uma classe, o
que a última seção desta aula usa.
