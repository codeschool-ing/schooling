---
title: Property binding, e o atributo que não é propriedade
version: 1
---

**`[nome]="expressão"` define uma propriedade de um elemento do DOM com o valor de uma expressão, e a
mantém definida enquanto o valor muda.** A interpolação só produz texto; um property binding passa o
próprio valor, um número, um booleano, um objeto, para o elemento. Troque o template da bancada:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<label for="bench-minutes">Minutes</label>
<input id="bench-minutes" type="number" [value]="minutes" [min]="5" [max]="240" />
<progress [value]="minutes" [max]="240" [aria-label]="minutes + ' of 240 minutes'"></progress>
<button type="button" [disabled]="minutes >= 240">More</button>
```

```
ana@dev:~/planner$ look http://localhost:4200/ --a11y app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
- heading "Bench" [level=2]
- LabelText
  - text: Minutes
- spinbutton "Minutes": 45
- progressbar "45 of 240 minutes": 45
- button "More"
```

A árvore de acessibilidade mostra o que cada binding fez: o campo é um spin button valendo 45, a barra
de progresso tem o nome que a expressão montou, e o botão está habilitado, porque `45 >= 240` é falso.
O `[disabled]` recebe um booleano, coisa que um atributo HTML comum não faz: no HTML,
`disabled="false"` continua desabilitado.

## Uma propriedade não é um atributo

O HTML tem **atributos**, escritos na marcação, e o navegador constrói objetos do DOM com
**propriedades** a partir deles. Em geral eles têm o mesmo nome e o mesmo valor inicial, e depois podem
seguir caminhos diferentes. Um property binding define a propriedade, e o que acontece com a marcação
depende da propriedade:

```
ana@dev:~/planner$ look http://localhost:4200/ --html app-bench
[vite] connecting...
[vite] connected.
Angular is running in development mode.
<app-bench><h2>Bench</h2><label for="bench-minutes">Minutes</label><input id="bench-minutes" type="number" min="5" max="240"><progress value="45" max="240" aria-label="45 of 240 minutes"></progress><button type="button">More</button></app-bench>
```

`min`, `max` e o `value` da barra de progresso aparecem como atributos: essas propriedades
**refletem**, o que quer dizer que o navegador escreve o valor delas de volta no atributo. O `value`
do campo não reflete, e não há `value="45"` no `<input>`, e mesmo assim o campo mostra 45. Num campo de
texto essa diferença é o ponto inteiro: o atributo `value` é só o texto inicial, e a propriedade
`value` é o que está na caixa agora, digitado ou ligado por binding. **O Angular faz binding com as
propriedades do DOM, não com o texto do HTML.**

Alguns atributos não têm propriedade, e algumas propriedades têm outro nome. O atributo `colspan` de
uma célula de tabela é a propriedade `colSpan`, com S maiúsculo, e fazer binding com o nome do
atributo falha:

```html
<!-- src/app/bench/bench.html -->
<h2>Bench</h2>
<table>
  <tr><td [colspan]="2">Two columns</td></tr>
</table>
```

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -A1 ERROR
✘ [ERROR] NG8002: Can't bind to 'colspan' since it isn't a known property of 'td'. [plugin angular-compiler]
```

**`[attr.nome]` faz o binding com o atributo.** Escreva `[attr.colspan]="2"` e o Angular define o
atributo, pelo nome HTML, que é o que você quer para um atributo sem propriedade por trás. Os
atributos ARIA eram o caso mais comum. O Angular 21 faz binding com eles sem o prefixo, e é por isso que
o `[aria-label]` acima funcionou; `[attr.aria-label]` continua correto e é o que o código mais antigo
diz.

A próxima seção troca o template da bancada de novo, então deixe a tabela onde está.
