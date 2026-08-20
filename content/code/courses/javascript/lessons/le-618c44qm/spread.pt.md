---
title: Espalhar e juntar
---

As mesmas três reticências fazem coisas opostas conforme o lado em que estão: à direita elas **espalham**, à esquerda elas **juntam**.

```schooling-example
{
  "language": "javascript",
  "file": "spread.js",
  "parts": [
    {
      "code": "const base = { tema: \"escuro\", idioma: \"pt\" };\nconst novo = { ...base, idioma: \"en\" };\nconsole.log(novo);",
      "note": "Cópia com alteração, sem mexer no original. A ordem decide quem vence: a última chave repetida sobrescreve — por isso `idioma` sai `en`."
    },
    {
      "code": "const a = [1, 2];\nconst b = [0, ...a, 3];\nconsole.log(b);",
      "note": "O mesmo em array, mantendo a ordem. Substitui `concat` e o velho `push.apply`."
    },
    {
      "code": "function soma(...numeros) {\n  return numeros.reduce((t, n) => t + n, 0);\n}\nconsole.log(soma(1, 2, 3, 4));",
      "note": "Do outro lado: aqui as reticências JUNTAM os argumentos num array de verdade. É o substituto de `arguments`, que não era array e não existe em arrow function."
    },
    {
      "code": "const orig = { dono: { nome: \"Ana\" } };\nconst copia = { ...orig };\ncopia.dono.nome = \"Bia\";\nconsole.log(orig.dono.nome);",
      "note": "A pegadinha: a cópia é RASA. O objeto de dentro continua sendo o mesmo, e alterá-lo altera os dois. Para cópia profunda existe `structuredClone`."
    }
  ],
  "output": "{ tema: 'escuro', idioma: 'en' }\n[ 0, 1, 2, 3 ]\n10\nBia"
}
```
