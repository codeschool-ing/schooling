---
title: As diretivas antigas, e a migração que as remove
version: 1
---

**Antes do Angular 17, as condições e os laços de um template eram diretivas escritas como atributos:
`*ngIf`, `*ngFor` e `[ngSwitch]`.** Elas continuam na maior parte do código Angular em produção, estão
obsoletas desde o Angular 20, e a CLI traz uma migração que as reescreve nos blocos que esta aula
ensinou. Esta seção as escreve na bancada, do jeito que o código mais antigo faz, e roda a migração.

```typescript
// src/app/bench/bench.ts
import { Component } from '@angular/core';
import { NgFor, NgIf } from '@angular/common';
import { Course } from '../planner';

@Component({
  selector: 'app-bench',
  imports: [NgIf, NgFor],
  templateUrl: './bench.html',
  styleUrl: './bench.css',
})
export class Bench {
  protected courses: Course[] = [
    { id: 'html-css', name: 'HTML and CSS' },
    { id: 'javascript', name: 'JavaScript' },
    { id: 'git', name: 'Git' },
  ];

  protected byId(index: number, course: Course): string {
    return course.id;
  }
}
```

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<p *ngIf="courses.length > 0; else none">{{ courses.length }} courses</p>
<ng-template #none><p>No courses.</p></ng-template>
<ul>
  <li *ngFor="let course of courses; trackBy: byId; let i = index">{{ i + 1 }}. {{ course.name }}</li>
</ul>
```

O que reconhecer:

- **São diretivas, então são importadas**: `NgIf` e `NgFor` do `@angular/common`, ou o
  `CommonModule`, que trazia todas. Os blocos não precisam de import.
- **O `*` é uma abreviação.** O `*ngIf` envolve o seu elemento num `<ng-template>`, um pedaço inerte
  de template que a diretiva desenha ou não. O ramo `else` precisa ser um template assim, com o nome
  `#none`, e é por isso que a sintaxe antiga espalha uma condição por dois lugares.
- **O `trackBy` recebe uma função**, não uma expressão, e era opcional, então quase todo código antigo
  não tem.
- **`let i = index`** é a grafia antiga do `$index`.

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
Bench

3 courses

1. HTML and CSS
2. JavaScript
3. Git
```

Funciona, e desenha o mesmo que os blocos desenhariam. Faça o commit antes, para que as edições da
migração sejam a única coisa no diff, e então rode-a:

```
ana@dev:~/planner$ git add -A && git commit -q -m "The bench, the old way"
```

```
ana@dev:~/planner$ npx ng generate @angular/core:control-flow
UPDATE src/app/bench/bench.html (274 bytes)
UPDATE src/app/bench/bench.ts (493 bytes)
```

```
ana@dev:~/planner$ git diff
diff --git a/src/app/bench/bench.html b/src/app/bench/bench.html
index 01049d3..449feb7 100644
--- a/src/app/bench/bench.html
+++ b/src/app/bench/bench.html
@@ -1,7 +1,12 @@
 <!-- src/app/bench/bench.html -->
 <h2>Bench</h2>
-<p *ngIf="courses.length > 0; else none">{{ courses.length }} courses</p>
-<ng-template #none><p>No courses.</p></ng-template>
+@if (courses.length > 0) {
+  <p>{{ courses.length }} courses</p>
+} @else {
+  <p>No courses.</p>
+}
 <ul>
-  <li *ngFor="let course of courses; trackBy: byId; let i = index">{{ i + 1 }}. {{ course.name }}</li>
+  @for (course of courses; track byId(i, course); let i = $index) {
+    <li>{{ i + 1 }}. {{ course.name }}</li>
+  }
 </ul>
diff --git a/src/app/bench/bench.ts b/src/app/bench/bench.ts
index 303eaf5..e6ff04c 100644
--- a/src/app/bench/bench.ts
+++ b/src/app/bench/bench.ts
@@ -1,11 +1,11 @@
 // src/app/bench/bench.ts
 import { Component } from '@angular/core';
-import { NgFor, NgIf } from '@angular/common';
+
 import { Course } from '../planner';
 
 @Component({
   selector: 'app-bench',
-  imports: [NgIf, NgFor],
+  imports: [],
   templateUrl: './bench.html',
   styleUrl: './bench.css',
 })
```

O `*ngIf` e o seu `<ng-template>` separado viraram um `@if` com um `@else`, e o laço virou um `@for`.
Olhe o track dele: `track byId(i, course)` chama a antiga função de `trackBy` com a posição e o item, e
`let i = $index` mantém o nome antigo `i` para a posição. Está correto, e não é o que alguém escreveria
hoje: `track course.id` diz a mesma coisa sem um método. Os imports de `NgIf` e `NgFor` saíram,
deixando um `imports` vazio e uma linha em branco onde estava o import. Uma migração preserva o
comportamento; a arrumação, como na aula 3, é com você.

## Limpando a bancada

A bancada cumpriu o papel nesta aula. Apague-a, tire-a do `App` de novo, e faça o commit do planner:

```
ana@dev:~/planner$ rm -r src/app/bench
```

```html
<!-- src/app/app.html -->
<h1>Study planner</h1>
<main>
  <app-week />
</main>
<router-outlet />
```

```typescript
// src/app/app.ts
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { Week } from './week/week';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, Week],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App {}
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep Tests
      Tests  4 passed (4)
```

```
ana@dev:~/planner$ git add -A && git commit -q -m "Control flow: the course list, and what is left this week"
```
