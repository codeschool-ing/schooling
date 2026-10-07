---
title: JSON: dados como texto
version: 1
---

**JSON é um formato de texto para dados**, e é o que a maioria das APIs manda e recebe. Ele empresta o
formato dos literais do JavaScript, objetos, arrays, strings, números, booleanos e `null`, e nada
mais. `JSON.stringify` transforma um valor em texto JSON e `JSON.parse` transforma o texto de volta:

```javascript
const book = {
  title: "Iracema",
  year: 1865,
  tags: ["romance", "indianist"],
  isbn: undefined,
  describe() { return this.title; },
  added: new Date(Date.UTC(2026, 9, 6, 15, 0)),
  copiesBy: new Map([["ana", 1]]),
  rating: NaN,
};

const text = JSON.stringify(book);
console.log(text);
console.log(typeof text);

const back = JSON.parse(text);
console.log(typeof back.added, back.rating, "isbn" in back);
console.log(JSON.stringify({ title: "Iracema", year: 1865 }, null, 2));
```

```
ana@dev:~/js$ node json.js
{"title":"Iracema","year":1865,"tags":["romance","indianist"],"added":"2026-10-06T15:00:00.000Z","copiesBy":{},"rating":null}
string
string null false
{
  "title": "Iracema",
  "year": 1865
}
```

## O que não sobrevive à viagem

O texto guarda menos do que o objeto guardava, e **nada avisou sobre nada disso**:

- `isbn`, que era `undefined`, e `describe`, uma função, **ficaram de fora**: o JSON não tem como
  escrever nenhum dos dois;
- `added`, um `Date`, virou **uma string**, e depois do parse continua string, como disse o `typeof`;
- `copiesBy`, um `Map`, virou `{}`, a perda de que a aula 5 avisou;
- `rating`, `NaN`, virou `null`, porque o JSON não tem `NaN` nem `Infinity`.

Então **o JSON carrega dados, não objetos**. Antes de mandar algo, converta o que o JSON não guarda: um
`Map` com `Object.fromEntries`, uma data com `toISOString()`, que é o que o `stringify` fez aqui.
`JSON.stringify(valor, null, 2)` indenta o texto, que é como imprimir JSON para uma pessoa.

## Lendo de volta

```javascript
const text = '{"title":"Iracema","added":"2026-10-06T15:00:00.000Z"}';
const book = JSON.parse(text, (key, value) => (key === "added" ? new Date(value) : value));
console.log(book.added instanceof Date, book.added.getUTCFullYear());

JSON.parse("{title: 'Iracema'}");
```

```
ana@dev:~/js$ node reviver.js 2>&1 | grep -v "^    at"
true 2026
<anonymous_script>:1
{title: 'Iracema'}
 ^

SyntaxError: Expected property name or '}' in JSON at position 1 (line 1 column 2)

Node.js v22.22.0
```

O `JSON.parse` aceita um segundo argumento, um **reviver**, chamado para cada chave na saída, que aqui
transformou a string da data de volta num `Date`. A segunda linha mostra o quanto o JSON é estrito:
**nomes de propriedade precisam de aspas duplas e strings não podem usar simples**, então um texto que
é JavaScript válido pode ser JSON inválido, e o `parse` lança um `SyntaxError` dizendo a posição. Texto
de fora do seu programa sempre pode vir malformado, então um `parse` dele pertence a um lugar onde o
erro possa ser tratado.
