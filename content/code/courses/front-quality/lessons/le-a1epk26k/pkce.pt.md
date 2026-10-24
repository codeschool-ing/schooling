---
title: O PKCE, calculado com os números do próprio padrão
version: 1
---

**O PKCE, Proof Key for Code Exchange, amarra o código do passo 3 ao app que o pediu, com um segredo
novo a cada login.** Ele é a RFC 7636, e usa dois valores:

1. O **code verifier**, um texto aleatório de 43 a 128 caracteres, gerado pelo app no começo e guardado
   só com ele.
2. O **code challenge**, o hash SHA-256 do verifier, escrito em base64url, mandado ao provedor no passo 1
   com `code_challenge_method=S256`.

No passo 4 o app manda o próprio verifier, e o provedor calcula o hash dele e o compara com o challenge
que guardou. **Quem interceptou o código no passo 3 tem o código e não o verifier**, que nunca saiu do app
até aquele momento, e um hash não se desfaz para encontrá-lo.

A RFC publica um exemplo resolvido, no Apêndice B, para qualquer implementação se conferir contra ele. O
verifier ali é `dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk`, e o challenge que ele dá é
`E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM`. O `crypto` do próprio Node faz a conta numa linha:

```
ana@dev:~/planner$ node -e 'const { createHash } = require("node:crypto"); console.log(createHash("sha256").update("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk").digest("base64url"))'
E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM
```

**O mesmo challenge, até o último caractere.** Isso é um teste no sentido que este curso usa: um valor
esperado calculado por outra pessoa, de forma independente, e o código concordando com ele. Um login de
verdade gera um verifier novo a cada vez a partir de 32 bytes aleatórios, o que em base64url dá
exatamente os 43 caracteres que o mínimo pede:

```
ana@dev:~/planner$ node -e 'console.log(require("node:crypto").randomBytes(32).toString("base64url").length)'
43
```

O `S256` é o método a usar; a RFC também permite o `plain`, em que o challenge é o próprio verifier, e
isso não protege nada que alguém escutando não consiga ler.
