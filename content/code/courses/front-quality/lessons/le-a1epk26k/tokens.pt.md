---
title: Um token que carrega o próprio significado
version: 1
---

**Um JSON Web Token são três pedaços de texto unidos por pontos: um cabeçalho, um corpo de afirmações e
uma assinatura sobre os dois primeiros.** O servidor que o assina consegue depois conferir, sem memória
nenhuma, que as afirmações são as que ele escreveu. Nada mais num JWT é secreto, e o erro mais comum com
um é pensar o contrário.

Para ver cada parte dele, eis um escrito à mão com o `crypto` do Node, assinado com HMAC-SHA-256, o
algoritmo que um JWT chama de `HS256`. Salve como `server/jwt.mjs`:

```javascript
// server/jwt.mjs
import { createHmac, timingSafeEqual } from "node:crypto";

const encode = (value) => Buffer.from(JSON.stringify(value)).toString("base64url");
const decode = (part) => JSON.parse(Buffer.from(part, "base64url").toString());
const mac = (text, secret) => createHmac("sha256", secret).update(text).digest();

export function sign(claims, secret) {
  const head = encode({ alg: "HS256", typ: "JWT" });
  const body = encode(claims);
  return `${head}.${body}.${mac(`${head}.${body}`, secret).toString("base64url")}`;
}

export function verify(token, secret, now = Math.floor(Date.now() / 1000)) {
  const [head, body, signature = ""] = token.split(".");
  if (decode(head).alg !== "HS256") throw new Error("unexpected algorithm");
  const given = Buffer.from(signature, "base64url");
  const expected = mac(`${head}.${body}`, secret);
  if (given.length !== expected.length || !timingSafeEqual(given, expected)) throw new Error("bad signature");
  const claims = decode(body);
  if (now >= claims.exp) throw new Error("expired");
  return claims;
}
```

O `verify` recusa três coisas, nesta ordem: um cabeçalho que cite qualquer algoritmo além do esperado,
uma assinatura que não confere, e um token depois do `exp` dele. A primeira checagem não é enfeite. Um
JWT diz qual é o próprio algoritmo, e um verificador que acreditasse no token sobre como conferi-lo
poderia ouvir `"alg": "none"`; as bibliotecas que já fizeram isso são o motivo de todo guia hoje dizer
para fixar o algoritmo no servidor.

E um programa curto que assina um token para a ana, válido por oito horas em 20 de outubro de 2026, e
depois tenta três jeitos de tirar outra resposta dele. Salve como `server/try-jwt.mjs`:

```javascript
// server/try-jwt.mjs
import { sign, verify } from "./jwt.mjs";

const secret = "a secret only the server knows";
const token = sign({ sub: "ana", iat: 1792483200, exp: 1792512000 }, secret);
console.log("token:   ", token);

const [head, body, signature] = token.split(".");
console.log("payload: ", Buffer.from(body, "base64url").toString());
console.log("verified:", verify(token, secret, 1792490000));

const forged = Buffer.from(JSON.stringify({ sub: "bruno", iat: 1792483200, exp: 1792512000 })).toString("base64url");
for (const [what, attempt, now] of [
  ["another name", `${head}.${forged}.${signature}`, 1792490000],
  ["another secret", sign({ sub: "ana", iat: 1792483200, exp: 1792512000 }, "a guess"), 1792490000],
  ["after exp", token, 1792512000],
]) {
  try {
    verify(attempt, secret, now);
    console.log(`${what}: accepted`);
  } catch (error) {
    console.log(`${what}: refused, ${error.message}`);
  }
}
```

```
ana@dev:~/planner$ node server/try-jwt.mjs
token:    eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhbmEiLCJpYXQiOjE3OTI0ODMyMDAsImV4cCI6MTc5MjUxMjAwMH0.nwOyKoscIUR4jcHTnfmb76Y3JUtCzYPI-JQYg_-Y3VY
payload:  {"sub":"ana","iat":1792483200,"exp":1792512000}
verified: { sub: 'ana', iat: 1792483200, exp: 1792512000 }
another name: refused, bad signature
another secret: refused, bad signature
after exp: refused, expired
```

**Leia a segunda linha antes de tudo: o corpo está à vista.** Base64url é uma codificação, não
criptografia, e qualquer pessoa com o token na mão lê o `sub`, o `iat` e o `exp` exatamente como o
servidor os escreveu. Um JWT nunca pode carregar algo que quem o tem não deva ver. O que a assinatura
compra é que ninguém consegue **mudá-lo**: um corpo com o nome do bruno sob a assinatura da ana é
recusado, um token assinado com um segredo chutado é recusado, e às 16:00 UTC, o `exp`, o próprio token
da ana também é recusado.

## O preço de carregar o significado

O servidor conferiu tudo isso sem procurar nada, que é o motivo de os tokens serem usados: qualquer
número de servidores confere um, e nenhum precisa dividir memória. **O preço é que nada consegue
revogá-lo.** Um id de sessão é esquecido apagando uma entrada; um token assinado vale até o `exp`, nas
mãos de quem estiver, a menos que cada servidor mantenha uma lista de tokens que não aceita mais, o que
é um armazenamento de sessões de novo com passos a mais. É por isso que access tokens são feitos para
expirar em minutos, e não em horas, e a próxima seção pesa os dois.

Faça o commit do servidor e dos dois arquivos desta seção:

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "A server with one account, a session cookie, and a JWT by hand"
```
