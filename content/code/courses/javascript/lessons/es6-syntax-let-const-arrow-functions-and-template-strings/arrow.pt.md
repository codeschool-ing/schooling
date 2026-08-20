---
title: Arrow functions, e o que elas não têm
---

A seta encurta a escrita, mas essa é a parte menos importante. O que muda de verdade é que ela **não tem `this` próprio** — ela usa o `this` de onde foi escrita.

```schooling-example
{
  "language": "javascript",
  "file": "seta.js",
  "parts": [
    {
      "code": "const dobro = n => n * 2;\nconsole.log(dobro(4));",
      "note": "Um parâmetro, um retorno: sem parênteses, sem `return`, sem chaves. É a forma que aparece dentro de `map` e `filter` o tempo todo."
    },
    {
      "code": "const par = (a, b) => ({ a, b });\nconsole.log(par(1, 2));",
      "note": "Devolver um objeto exige os parênteses em volta. Sem eles, `{` é lido como início de bloco, e a função devolve `undefined` — em silêncio."
    },
    {
      "code": "const contador = {\n  n: 7,\n  comum() { return this.n; },\n  seta: () => (typeof this === \"undefined\" ? \"sem this\" : \"this de fora\"),\n};",
      "note": "A diferença que importa. A função comum recebe `this` de quem a CHAMOU; a seta herdou o `this` do lugar onde foi ESCRITA — e num módulo ES esse lugar não tem `this` nenhum."
    },
    {
      "code": "console.log(contador.comum());\nconsole.log(contador.seta());",
      "note": "A seta nem enxerga o objeto de que é propriedade. Por isso ela é ótima para callback — carrega o `this` de fora junto — e péssima para método."
    }
  ],
  "output": "8\n{ a: 1, b: 2 }\n7\nsem this"
}
```
