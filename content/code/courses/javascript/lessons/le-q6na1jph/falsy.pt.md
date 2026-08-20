---
title: Os oito valores falsos
---

Num `if`, qualquer valor vira booleano. São **oito** os que viram `false` — e todo o resto vira `true`, inclusive `[]`, `{}` e `"0"`:

- `false`, `0`, `-0`, `0n` (BigInt zero)
- `""` (string vazia)
- `null`, `undefined`, `NaN`

A armadilha prática está em `0` e `""` serem falsos: `if (quantidade)` ignora a quantidade zero, e `if (nome)` ignora o nome vazio — nos dois casos tratando "existe e vale zero/vazio" como "não existe".

```schooling-example
{
  "language": "javascript",
  "file": "falsos.js",
  "parts": [
    {
      "code": "const config = { retries: 0, titulo: \"\" };",
      "note": "Dois valores legítimos que por acaso são falsos. Zero tentativas é uma decisão; título vazio também."
    },
    {
      "code": "console.log(config.retries || 3);\nconsole.log(config.titulo || \"sem título\");",
      "note": "O `||` clássico atropela os dois: ele testa \"é falso?\", não \"está ausente?\". O zero que o usuário escolheu virou três."
    },
    {
      "code": "console.log(config.retries ?? 3);\nconsole.log(JSON.stringify(config.titulo ?? \"sem título\"));",
      "note": "`??` só entra em ação para `null` e `undefined` — o zero e a string vazia passam intactos. É o operador que a maioria dos `||` de valor padrão realmente queria ser. (O `JSON.stringify` está aí só para a string vazia aparecer como `\"\"` em vez de uma linha em branco.)"
    }
  ],
  "output": "3\nsem título\n0\n\"\""
}
```
