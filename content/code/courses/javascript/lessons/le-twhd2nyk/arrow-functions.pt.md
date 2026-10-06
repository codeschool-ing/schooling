---
title: Arrow functions
version: 1
---

Uma **função** é um pedaço de código com um nome, ou pelo menos um lugar, que você pode executar de
novo com entradas diferentes. JavaScript tem três jeitos de escrever uma, e você vai ler os três em
qualquer código de verdade. A mais nova, a **arrow function**, é a mais curta:

```schooling-example
{
  "language": "javascript",
  "file": "shelf.js",
  "parts": [
    {
      "code": "function double(n) {\n  return n * 2;\n}",
      "note": "Uma declaração de função: a palavra-chave, um nome, os parâmetros e um corpo entre chaves. `return` devolve o resultado."
    },
    {
      "code": "const triple = function (n) {\n  return n * 3;\n};",
      "note": "Uma expressão de função: a mesma coisa escrita como um valor e entregue a um nome. O nome vive onde o `const` o coloca."
    },
    {
      "code": "const half = (n) => n / 2;",
      "note": "Uma arrow function. `=>` fica entre os parâmetros e o corpo, e sem chaves o corpo é uma única expressão, cujo valor é devolvido sem escrever `return`."
    },
    {
      "code": "const square = n => n * n;",
      "note": "Com exatamente um parâmetro, os parênteses são opcionais. O Prettier os recoloca por padrão, e a maioria das equipes os mantém."
    },
    {
      "code": "const describe = (title, year = \"unknown\") => {\n  const age = typeof year === \"number\" ? 2026 - year : \"?\";\n  return title + \" (\" + year + \"), \" + age + \" years old\";\n};",
      "note": "Com chaves, o corpo é um bloco como outro qualquer, e aí o `return` volta a ser necessário. `year = \"unknown\"` é um valor padrão, usado quando quem chama não passa nada para esse parâmetro."
    },
    {
      "code": "console.log(double(4), triple(4), half(4), square(4));\nconsole.log(describe(\"Dom Casmurro\", 1899));\nconsole.log(describe(\"Iracema\"));",
      "note": "As chamadas. `describe(\"Iracema\")` omite `year`, então o padrão o preenche."
    }
  ],
  "output": "8 12 2 16\nDom Casmurro (1899), 127 years old\nIracema (unknown), ? years old"
}
```

**As três formas fazem o mesmo trabalho para tudo nesta aula.** Elas diferem no que `this`
significa dentro delas, que é a aula 6, e em mais uma coisa no fim desta seção.

## A armadilha: devolver um objeto

Uma arrow sem chaves devolve a sua expressão. Um objeto também se escreve com chaves, então isto
parece devolver um:

```javascript
const wrong = (title) => { title: title };
const right = (title) => ({ title: title });

console.log(wrong("Iracema"));
console.log(right("Iracema"));
```

```
ana@dev:~/js$ node object-arrow.js
undefined
{ title: 'Iracema' }
```

**Depois de `=>`, uma chave sempre abre um bloco, nunca um objeto.** Em `wrong`, as chaves são o
corpo da função, `title:` é um rótulo (uma parte da linguagem que quase ninguém usa), e a função
não devolve nada. Envolver o objeto em parênteses, como faz `right`, o torna uma expressão de novo.
Todo mundo escreve o `wrong` uma vez.

## Uma arrow não pode ser construtora

```javascript
const Shelf = () => {};
const s = new Shelf();
```

```
ana@dev:~/js$ node new-arrow.js 2>&1 | head -n 5
/home/ana/js/new-arrow.js:2
const s = new Shelf();
          ^

TypeError: Shelf is not a constructor
```

`new` constrói um objeto a partir de uma função, e a aula 8 trata de como. **As arrow functions
ficaram de fora disso de propósito**: elas servem para pequenos pedaços de comportamento, passados
adiante e chamados, e a sintaxe de classe cobre o resto.

## Que forma escrever

Arrows para as funções pequenas que você entrega a outra coisa, como as que a aula 4 passa para
`map` e `filter`. Declarações para as funções nomeadas do nível de cima de um arquivo: elas leem
bem, e a aula 3 mostra que podem ser chamadas antes da linha que as define. A forma de expressão é
principalmente o que você vai ler em código escrito antes de 2015.
