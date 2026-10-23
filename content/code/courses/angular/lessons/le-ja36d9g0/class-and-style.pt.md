---
title: Classes e estilos
version: 1
---

**`[class.nome]` acrescenta ou tira uma classe conforme uma condição, e `[style.propriedade]` define
um estilo a partir de um valor.** São property bindings com uma primeira palavra especial, e cobrem
quase todo caso em que a aparência de um elemento depende dos dados. Dê à bancada alguns estilos para
alternar:

```css
/* src/app/bench/bench.css */
.long {
  font-weight: 600;
}
.bar {
  height: 0.5rem;
  background: currentColor;
}
```

e um template que os usa:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<p [class.long]="minutes > 40">{{ minutes }} minutes</p>
<p [class]="{ long: minutes > 40, short: minutes < 20 }">The same, as an object</p>
<div class="bar" [style.width.%]="minutes / 2.4"></div>
<p [style.color]="minutes > 200 ? 'red' : null">Red past 200</p>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --html app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<app-bench><h2>Bench</h2><label for="bench-minutes">Minutes</label><input id="bench-minutes" type="number" min="5" max="240"><progress value="45" max="240" aria-label="45 of 240 minutes"></progress><button type="button">More</button></app-bench>
```

Quatro linhas, quatro formas:

- **`[class.long]`** acrescenta `long` enquanto a condição é verdadeira e tira quando é falsa. Qualquer
  outra classe do elemento fica como está, o que importa quando uma folha de estilo ou outra diretiva
  a pôs ali.
- **`[class]` com um objeto** faz o mesmo para várias classes de uma vez: cada chave é uma classe, cada
  valor a condição dela. `short` era falsa, então está ausente.
- **`[style.width.%]`** traz a unidade no nome, então a expressão é só um número: 45 dividido por 2,4
  dá 18,75, e o estilo diz `18.75%`. `.px`, `.rem` e `.em` funcionam do mesmo jeito.
- **`null` remove um estilo.** Com 45 minutos, o `[style.color]` deu `null`, e o parágrafo não tem
  atributo `style` nenhum, em vez de um vazio.

**Prefira uma classe a um estilo.** Uma classe dá nome a um estado, `long`, e a folha de estilo diz
como ele se parece; um style binding escreve a aparência no template, onde a próxima pessoa a mudar o
design vai ter de procurá-la. Style bindings fazem sentido para valores que são de fato contínuos,
uma largura ou uma posição, como a barra aqui.

O jeito antigo de escrever a forma com objeto é `[ngClass]` e `[ngStyle]`, diretivas do
`@angular/common`. Elas ainda funcionam, e você vai vê-las em código mais antigo; `[class]` e `[style]`
fazem o mesmo sem import.
