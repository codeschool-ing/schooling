---
title: O valor de this
---

`this` não é decidido onde a função é escrita, e sim **onde ela é chamada** — com uma exceção, a arrow function. Quase todo bug de `this` é a mesma função tendo sido separada do objeto dela.

```schooling-example
{
  "language": "javascript",
  "file": "this.js",
  "parts": [
    {
      "code": "const aluno = {\n  nome: \"Ana\",\n  ola() { return `oi, ${this.nome}`; },\n};\nconsole.log(aluno.ola());",
      "note": "Chamada como método: `this` é o que está à esquerda do ponto."
    },
    {
      "code": "const solta = aluno.ola;\ntry {\n  console.log(solta());\n} catch (e) {\n  console.log(e.constructor.name);\n}",
      "note": "A MESMA função, chamada sem dono. Em módulo ES o `this` é `undefined`, e ler `.nome` dele explode. É exatamente o que acontece ao passar `obj.metodo` como callback — e o `try` está aqui só para o exemplo continuar rodando."
    },
    {
      "code": "const presa = aluno.ola.bind(aluno);\nconsole.log(presa());",
      "note": "`bind` amarra o `this` de uma vez. A alternativa moderna é passar uma seta: `() => aluno.ola()`, que carrega o contexto de fora."
    }
  ],
  "output": "oi, Ana\nTypeError\noi, Ana"
}
```
