---
title: Coerção: quando a linguagem adivinha
---

JavaScript converte tipos sozinho quando um operador recebe o que não esperava. Isso resolve pequenas conveniências e cria as maiores surpresas da linguagem.

```schooling-example
{
  "language": "javascript",
  "file": "coercao.js",
  "parts": [
    {
      "code": "console.log(1 + \"1\");\nconsole.log(1 - \"1\");",
      "note": "`+` é sobrecarregado: com uma string de um lado ele CONCATENA. `-` não tem essa ambiguidade, então converte para número. Mesmo par de valores, dois resultados de naturezas diferentes."
    },
    {
      "code": "console.log([] + {});\nconsole.log([1, 2] + [3]);",
      "note": "Objeto virando string passa por `toString()`. O de array junta com vírgula; o de objeto comum devolve `[object Object]`. É por isso que aquela mensagem aparece na tela às vezes."
    },
    {
      "code": "console.log(0.1 + 0.2);\nconsole.log(0.1 + 0.2 === 0.3);",
      "note": "Este não é bug de JavaScript: é ponto flutuante IEEE-754, e vale igual em Python, Java e C. Dinheiro se guarda em centavos inteiros, nunca em `float`."
    },
    {
      "code": "console.log(Number(\"12px\"));\nconsole.log(parseInt(\"12px\", 10));",
      "note": "`Number` é tudo ou nada; `parseInt` lê enquanto der e para. Ler a largura de um CSS pede o segundo — e o `10` não é opcional por hábito, é o que evita a base errada."
    }
  ],
  "output": "11\n0\n[object Object]\n1,23\n0.30000000000000004\nfalse\nNaN\n12"
}
```
