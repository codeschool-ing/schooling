---
title: Condições com @if
version: 1
---

**`@if (condição) { … }` desenha o seu bloco enquanto a condição é verdadeira e o tira da página
quando é falsa.** Não esconde: tira. Os elementos de dentro não existem enquanto a condição é falsa, o
que é a diferença entre o `@if` e a propriedade `[hidden]` da aula 4, e isso importa para o que um
leitor de tela encontra e para o que um teste consegue consultar.

O resumo da semana diz quanto está planejado e quanto está feito. Ele também deveria dizer o que
falta, ou que não falta nada:

```html
<!-- src/app/week-summary/week-summary.html -->
<p>{{ planned }} minutes planned, {{ done }} done.</p>
@if (done >= planned) {
  <p>Everything planned is done.</p>
} @else {
  <p>{{ planned - done }} minutes to go.</p>
}
<label for="week-progress">Done this week</label>
<progress id="week-progress" [value]="done" [max]="planned"></progress>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --text app-week-summary
[vite] connecting...
Angular is running in development mode.
[vite] connected.
165 minutes planned, 90 done.

75 minutes to go.

Done this week
```

**O bloco faz parte da sintaxe do template, não é um atributo de um elemento.** O `@if` não precisa
de import, envolve qualquer número de elementos, e não põe nada de si na página: não há uma `<div>` em
volta do parágrafo. `@else if (outra)` acrescenta um ramo entre os dois, como em JavaScript.

```
ana@dev:~/planner$ look http://localhost:4200/ --html app-week-summary
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<app-week-summary><p>165 minutes planned, 90 done.</p><!--container--><p>75 minutes to go.</p><!--container--><label for="week-progress">Done this week</label><progress id="week-progress" value="90" max="165"></progress></app-week-summary>
```

Um parágrafo do `@if`, não dois: o ramo `@else` foi desenhado e o outro não existe na página. Os
comentários `<!--container-->` são os marcadores do Angular para onde vai o conteúdo de um bloco; são
comentários, então o navegador não desenha nada para eles.

## Dando nome ao que a condição achou

Uma condição muitas vezes é um valor que pode faltar: uma sessão que talvez não tenha sido achada, uma
resposta do servidor que talvez não tenha chegado. O `as` dá ao valor um nome dentro do bloco, já
estreitado para "não ausente", do jeito que o `if (next)` da aula 1 o estreitou em TypeScript:

```html
@if (next(); as session) {
  <p>Next: {{ session.date }}, {{ session.minutes }} minutes.</p>
} @else {
  <p>Nothing planned.</p>
}
```

Dentro do bloco, `session` é um `Session` e nunca `undefined`, então o template confere os tipos das
leituras de propriedade. A aula 6 usa esse formato com um signal, que é o que o `next()` com
parênteses é.
