---
title: let e const
version: 1
---

Um nome em JavaScript é declarado antes de ser usado, e **a palavra-chave com que você o declara
diz se ele pode passar a apontar para outra coisa depois.** `const` diz que não. `let` diz que sim.

```javascript
const title = "Dom Casmurro";
title = "Iracema";
```

```
ana@dev:~/js$ node const.js 2>&1 | head -n 5
/home/ana/js/const.js:2
title = "Iracema";
      ^

TypeError: Assignment to constant variable.
```

O erro é o ponto: um nome declarado com `const` não pode ser **reatribuído**, e o motor recusa na
linha que tenta.

## `const` fixa o nome, não o valor

A leitura errada mais comum de `const` é achar que ele torna um valor imutável. Não torna:

```javascript
const shelf = ["Dom Casmurro"];
shelf.push("Iracema");
console.log(shelf);

let read = 0;
read = read + 1;
console.log(read);
```

```
ana@dev:~/js$ node const-array.js
[ 'Dom Casmurro', 'Iracema' ]
1
```

`shelf` continua nomeando o mesmo array; **o array em si cresceu**. `const` só prometeu que `shelf`
nunca passaria a nomear outro array. Mudar o que está dentro de um objeto ou de um array se chama
mutação, e a aula 4 trata de quando isso é o que você quer e de quando é um bug. `read`, declarado
com `let`, recebeu um número novo, que é exatamente para isso que serve o `let`.

## Um nome vive no seu bloco

Tanto `let` quanto `const` pertencem ao **bloco** em que foram declarados: o par de chaves em volta
deles.

```javascript
const year = 1899;
if (year < 1900) {
  let century = "nineteenth";
  console.log(century);
}
console.log(century);
```

```
ana@dev:~/js$ node block.js 2>&1 | head -n 6
nineteenth
/home/ana/js/block.js:6
console.log(century);
            ^

ReferenceError: century is not defined
```

Dentro do `if`, `century` existe e é impresso. Fora, ele nunca foi declarado, e o motor para com um
`ReferenceError`. **Um nome que não escapa do seu bloco não colide com um nome de outro lugar**, e
essa é a maior parte do motivo de essas duas palavras-chave terem substituído o antigo `var`. A
aula 3 trata do `var` e de por que ele se comporta diferente.

## Qual usar

**`const` por padrão, `let` quando for reatribuir.** A maioria dos nomes de um programa recebe um
valor uma vez só, e dizer isso com `const` avisa quem lê depois que pode parar de procurar
mudanças. Quando um contador sobe ou um total acumula, `let` diz isso também. Você vai ver `var` em
código antigo e em tutoriais antigos; em código novo não existe caso em que ele seja a escolha
melhor.
