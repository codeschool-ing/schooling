---
title: == contra ===
---

`==` compara depois de converter; `===` compara sem converter. A tabela do `==` tem casos que ninguém memoriza, e a saída disso é simples: **use `===` sempre.**

```schooling-example
{
  "language": "javascript",
  "file": "igual.js",
  "parts": [
    {
      "code": "console.log(0 == \"\");\nconsole.log(0 == \"0\");\nconsole.log(\"\" == \"0\");",
      "note": "Os três com `==`. Repare que os dois primeiros são verdadeiros e o terceiro é falso: `==` **não é transitivo**, o que basta para descartá-lo."
    },
    {
      "code": "console.log(null == undefined);\nconsole.log(null === undefined);",
      "note": "A única exceção que vale conhecer: `x == null` é o jeito curto de perguntar \"é `null` ou `undefined`?\". É o único uso defensável de `==`."
    },
    {
      "code": "console.log(NaN === NaN);\nconsole.log(Number.isNaN(NaN));",
      "note": "`NaN` é o único valor diferente de si mesmo. Testar com `===` nunca funciona; a pergunta certa é `Number.isNaN`."
    }
  ],
  "output": "true\ntrue\nfalse\ntrue\nfalse\nfalse\ntrue"
}
```
