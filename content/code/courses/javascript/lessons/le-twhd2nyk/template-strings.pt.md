---
title: Template strings
version: 1
---

Texto em JavaScript é uma **string**, escrita entre aspas. Aspas simples e duplas são a mesma
coisa. Um terceiro tipo, a **crase**, faz uma template string, e ela faz duas coisas que as outras
não fazem: põe valores dentro do texto e ocupa várias linhas.

## Valores dentro do texto

```javascript
const title = "Dom Casmurro";
const year = 1899;

console.log("'" + title + "' came out in " + year + ", " + (2026 - year) + " years ago.");
console.log(`'${title}' came out in ${year}, ${2026 - year} years ago.`);
console.log(`${title.toUpperCase()} has ${title.length} characters`);
console.log(`Is it old? ${year < 1950 ? "yes" : "no"}`);
```

```
'Dom Casmurro' came out in 1899, 127 years ago.
'Dom Casmurro' came out in 1899, 127 years ago.
DOM CASMURRO has 12 characters
Is it old? yes
```

A primeira linha monta a frase com `+`, e a segunda com um template. A saída é a mesma; **o
template é o que dá para ler**, porque a frase está escrita como frase. Dentro de `${ }` vai
qualquer expressão: um nome, uma conta, uma chamada de método, uma condição. O valor vira texto e
cai no lugar.

## Texto em várias linhas

Uma string entre aspas precisa terminar na linha em que começa. Um template mantém as quebras de
linha que você digita:

```javascript
const card = `Title:  Dom Casmurro
Author: Machado de Assis
Year:   1899`;

console.log(card);
console.log(card.split("\n").length, "lines");
```

```
ana@dev:~/js$ node multiline.js
Title:  Dom Casmurro
Author: Machado de Assis
Year:   1899
3 lines
```

A indentação também é mantida, e é por isso que `card` começa as linhas de continuação na margem.
Um template indentado para acompanhar o código em volta leva esses espaços para dentro do texto.

## Templates com tag

Um nome escrito logo antes da crase é uma **tag**: uma função que recebe os pedaços fixos do
template e os seus valores separadamente, e decide o que fazer com eles.

```javascript
console.log(`C:\notes\today`);
console.log(String.raw`C:\notes\today`);

function shout(strings, ...values) {
  console.log(strings);
  console.log(values);
  return strings.reduce((out, s, i) => out + s + (i < values.length ? String(values[i]).toUpperCase() : ""), "");
}

const who = "ana";
console.log(shout`hello ${who}, it is ${2026}`);
```

```
ana@dev:~/js$ node tagged.js
C:
otes	oday
C:\notes\today
[ 'hello ', ', it is ', '' ]
[ 'ana', 2026 ]
hello ANA, it is 2026
```

A primeira linha deu errado de propósito. Em qualquer string, `\n` é quebra de linha e `\t` é
tabulação, então o caminho saiu em pedaços. `String.raw` é uma tag que vem com a linguagem e
**mantém as barras invertidas como foram digitadas**. `shout` é uma tag que a ana escreveu: ela
recebeu os três pedaços fixos e os dois valores, e os juntou com os valores em maiúsculas.

**Um template não torna um texto seguro para entrar numa página web.** Ele junta strings e nada
mais, então um valor que contém HTML continua sendo HTML. A aula 11 mostra quanto isso custa e a
propriedade a usar no lugar.
