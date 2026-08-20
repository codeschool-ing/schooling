---
title: Closure: a função que lembra
---

Uma função criada dentro de outra continua enxergando as variáveis da de fora, mesmo depois de a de fora ter terminado. Isso não é um recurso avançado: é o que faz callback, `setTimeout` e quase todo padrão de módulo funcionarem.

```schooling-example
{
  "language": "javascript",
  "file": "closure.js",
  "parts": [
    {
      "code": "function contador() {\n  let n = 0;",
      "note": "`n` vive dentro de `contador`. Ninguém de fora consegue tocá-lo — não há `private`, e não precisa."
    },
    {
      "code": "  return {\n    incrementar: () => ++n,\n    ler: () => n,\n  };\n}",
      "note": "As duas setas fecham sobre o mesmo `n`. Devolver funções em vez do valor é o que transforma escopo em encapsulamento."
    },
    {
      "code": "const c = contador();\nc.incrementar();\nc.incrementar();\nconsole.log(c.ler());",
      "note": "`contador()` já retornou faz tempo, e `n` continua vivo — porque alguém ainda o referencia. É o coletor de lixo que decide, não a pilha de chamadas."
    },
    {
      "code": "const outro = contador();\nconsole.log(outro.ler());",
      "note": "Cada chamada cria um escopo NOVO. Dois contadores não compartilham nada, que é o que separa closure de variável global."
    }
  ],
  "output": "2\n0"
}
```
