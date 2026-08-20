---
title: Desestruturação
---

Tirar campos de um objeto ou itens de um array sem repetir o nome da fonte em cada linha. É a sintaxe que mais aparece em código moderno depois da seta.

```schooling-example
{
  "language": "javascript",
  "file": "destruct.js",
  "parts": [
    {
      "code": "const curso = { id: \"js\", nome: \"JavaScript\", horas: 80 };",
      "note": "O objeto de partida."
    },
    {
      "code": "const { nome, horas } = curso;\nconsole.log(nome, horas);",
      "note": "Os nomes à esquerda são as CHAVES, não posições. Ordem não importa; grafia importa."
    },
    {
      "code": "const { nome: titulo, nivel = \"livre\" } = curso;\nconsole.log(titulo, nivel);",
      "note": "Duas coisas de uma vez: renomear na saída, e um padrão para a chave que não existe. O padrão só entra quando o valor é `undefined` — `null` passa direto."
    },
    {
      "code": "function resumo({ nome, horas }) {\n  return `${nome}: ${horas}h`;\n}\nconsole.log(resumo(curso));",
      "note": "Desestruturar no PARÂMETRO é onde ela mais rende: a assinatura passa a documentar o que a função usa, em vez de receber um `opcoes` opaco."
    }
  ],
  "output": "JavaScript 80\nJavaScript livre\nJavaScript: 80h"
}
```
