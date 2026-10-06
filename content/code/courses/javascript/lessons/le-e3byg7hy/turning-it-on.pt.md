---
title: Ligando
version: 1
---

**O modo estrito é ligado pela string `"use strict"` como primeira instrução de um arquivo ou de uma
função.** Ele muda como o código lá dentro se comporta, e o jeito mais claro de ver é o mesmo erro duas
vezes:

```javascript
function countBooks() {
  totl = 7;
}
countBooks();
console.log("no error; a global called totl now exists:", globalThis.totl);
```

```javascript
"use strict";

function countBooks() {
  totl = 7;
}
countBooks();
```

```
ana@dev:~/js$ node sloppy.js
no error; a global called totl now exists: 7
ana@dev:~/js$ node strict.js 2>&1 | head -n 5
/home/ana/js/strict.js:4
  totl = 7;
       ^

ReferenceError: totl is not defined
```

`totl` é um erro de digitação de `total`. No modo comum, o **não estrito**, atribuir a um nome não
declarado criou uma variável global chamada `totl`, como a aula 3 mostrou, e o programa seguiu com o
`total` de verdade nunca definido. **No modo estrito a mesma linha é um `ReferenceError`**, na linha do
erro de digitação, que é exatamente onde você quer descobrir.

## Onde vai o interruptor

- **bem no topo de um arquivo**, antes de qualquer outra instrução, ele cobre o arquivo inteiro.
  Comentários podem vir antes; código não pode, ou ele é só uma string que não faz nada;
- **no topo do corpo de uma função**, ele cobre aquela função e tudo dentro dela;
- **ele não pode ser desligado de novo** dentro de código estrito.

Uma string como interruptor parece estranho. Ela foi escolhida em 2009 para que navegadores mais
antigos, que não conheciam o modo estrito, a lessem como uma expressão inofensiva e a ignorassem, em
vez de falharem numa sintaxe nova.

## Na maior parte, já está ligado

**ES modules e corpos de classe são estritos automaticamente**, sem string nenhuma. A maior parte do
código escrito hoje está num ou noutro, e é por isso que muitas pessoas que programam nunca digitaram
`"use strict"`. A última seção desta aula lista os lugares que ainda são não estritos por padrão, e
vale conhecê-los, porque é lá que esses erros silenciosos moram.
