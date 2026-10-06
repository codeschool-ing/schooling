---
title: Tornando os seus objetos iteráveis
version: 1
---

Para tornar um objeto iterável, **dê a ele um método `[Symbol.iterator]()` que devolva um iterador**.
Um intervalo de números é o exemplo clássico: dá para percorrê-lo sem nunca guardar um array com
todos os números dele.

```schooling-example
{
  "language": "javascript",
  "file": "range.js",
  "parts": [
    {
      "code": "class Range {\n  constructor(from, to, step = 1) {\n    this.from = from;\n    this.to = to;\n    this.step = step;\n  }",
      "note": "Uma classe comum. O intervalo guarda só os seus três números, por mais valores que descreva."
    },
    {
      "code": "  [Symbol.iterator]() {",
      "note": "O nome do método é o símbolo, escrito entre colchetes como uma chave computada da aula 4. Todo `for…of`, spread e desestruturação o chama."
    },
    {
      "code": "    let current = this.from;\n    const { to, step } = this;",
      "note": "Cada chamada cria um `current` novo, então cada laço sobre o intervalo tem a sua própria posição."
    },
    {
      "code": "    return {\n      next() {\n        if (current > to) return { value: undefined, done: true };\n        const value = current;\n        current += step;\n        return { value, done: false };\n      },\n    };\n  }\n}",
      "note": "O iterador: um objeto com `next()`. Ele devolve `{ done: true }` quando `current` passa de `to`, e senão o número atual e um passo adiante."
    },
    {
      "code": "const r = new Range(1, 10, 3);\nconsole.log([...r]);\nconsole.log([...r]);\nconsole.log(Math.max(...new Range(1900, 1930, 10)));",
      "note": "O intervalo usado de três jeitos. Espalhado duas vezes, e os dois saíram inteiros, porque cada spread pediu um iterador novo. Espalhado no `Math.max` também, que aceita qualquer iterável pelo `...`."
    }
  ],
  "output": "[ 1, 4, 7, 10 ]\n[ 1, 4, 7, 10 ]\n1930"
}
```

**O iterável e o iterador são dois objetos, de propósito.** O intervalo é uma descrição que pode ser
percorrida quantas vezes for; cada chamada de `[Symbol.iterator]()` começa uma caminhada nova com o
seu próprio `current`. Um iterador que devolvesse a si mesmo se gastaria depois de um laço, e o
segundo spread teria impresso um array vazio.

## Onde você vai encontrar isto

Você vai escrever `[Symbol.iterator]` raramente, porque os geradores da próxima seção o deixam muito
mais curto. Vai **usá-lo** o tempo todo sem ver: toda coleção da linguagem o implementa, e
bibliotecas o implementam para os seus próprios tipos, como o conjunto de resultados de um driver de
banco de dados, para que um `for…of` comum funcione neles.
