---
title: Template strings
---

Crase em vez de aspas, `${}` para interpolar, e a quebra de linha vale literalmente. Some a concatenação com `+`, que é onde nascem os espaços faltando.

```javascript
const nome = "Ana";
const n = 3;

console.log(`${nome} concluiu ${n} ${n === 1 ? "curso" : "cursos"}.`);
// Ana concluiu 3 cursos.
```

A interpolação aceita **qualquer expressão**, não só variável — chamada de função, ternário, operação. O que ela não deve receber é texto vindo do usuário destinado a virar HTML: aí a interpolação vira o furo, e é por isso que este portal tem um `esc()` em `app/text.js`.
