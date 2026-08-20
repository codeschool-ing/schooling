---
title: let e const: o fim do var
---

`var` tem duas propriedades que ninguém pediu: ela vaza para fora do bloco onde foi declarada e pode ser redeclarada sem reclamação. `let` e `const` não fazem nem uma coisa nem outra, e por isso `var` não aparece mais em código novo.

```schooling-example
{
  "language": "javascript",
  "file": "escopo.js",
  "parts": [
    {
      "code": "if (true) {\n  var antiga = \"eu vazo\";\n  let nova = \"eu fico\";\n}",
      "note": "As duas são declaradas dentro do `if`. Só uma delas continua existindo depois da chave que fecha."
    },
    {
      "code": "console.log(antiga);",
      "note": "`var` é de FUNÇÃO, não de bloco: ela foi içada para o topo da função e sobreviveu ao bloco. É daí que vem quase todo bug de variável trocada em laço."
    },
    {
      "code": "try {\n  console.log(nova);\n} catch (e) {\n  console.log(e.constructor.name);\n}",
      "note": "`let` morre com o bloco. Fora dele o nome nem existe — e o erro é `ReferenceError`, não `undefined`, o que é uma diferença importante: falhar alto é melhor que seguir com lixo."
    },
    {
      "code": "const lista = [1, 2];\nlista.push(3);\nconsole.log(lista);",
      "note": "A confusão mais comum de `const`: ela congela a LIGAÇÃO, não o valor. `lista = []` daria erro; mexer dentro do array, não. Para congelar o conteúdo existe `Object.freeze`."
    }
  ],
  "output": "eu vazo\nReferenceError\n[ 1, 2, 3 ]"
}
```

A regra prática: **`const` por padrão, `let` quando o valor for mesmo trocar, `var` nunca.** Começar por `const` faz o compilador avisar quando você reatribui sem querer — e a maioria das reatribuições que a gente escreve sem pensar é acidente.
