---
title: Cookies
version: 1
---

**Um cookie é um valor pequeno que um servidor pede a um navegador para guardar e mandar de volta em
toda requisição seguinte ao mesmo site.** É como um site se lembra de um navegador entre requisições:
uma sessão, uma preferência, um idioma. O servidor define um com o cabeçalho `Set-Cookie`, e o
navegador o devolve em `Cookie`.

O serviço links não tem usuários de navegador, então esta seção usa uma demonstração que lembra
quantas vezes um navegador visitou:

```javascript
// demo/cookies.js
import express from "express";

function cookiesOf(req) {
  const out = {};
  for (const pair of (req.get("cookie") ?? "").split(";")) {
    const [name, ...rest] = pair.trim().split("=");
    if (name) out[name] = decodeURIComponent(rest.join("="));
  }
  return out;
}

const app = express();
app.get("/", (req, res) => {
  const visits = Number(cookiesOf(req).visits ?? 0) + 1;
  res.cookie("visits", String(visits), { httpOnly: true, secure: true, sameSite: "lax", maxAge: 24 * 3600 * 1000 });
  res.send(`visit number ${visits}\n`);
});
app.listen(3000, "127.0.0.1");
```

O `res.cookie` escreve o cabeçalho. Ler um não tem auxiliar no Express, então o `cookiesOf` divide o
cabeçalho `Cookie` à mão; o pacote `cookie-parser` faz o mesmo, e você o instalaria num serviço de
verdade. O curl guarda cookies num arquivo com `-c` e os manda de volta com `-b`, o que basta para
fazer o papel do navegador:

```
ana@dev:~/server/links$ curl -si -c jar.txt http://127.0.0.1:3000/ | grep -iE '^set-cookie|visit'
Set-Cookie: visits=1; Max-Age=86400; Path=/; Expires=Sat, 17 Oct 2026 23:30:23 GMT; HttpOnly; Secure; SameSite=Lax
visit number 1
ana@dev:~/server/links$ curl -s -b jar.txt -c jar.txt http://127.0.0.1:3000/
visit number 2

ana@dev:~/server/links$ curl -s -b jar.txt -c jar.txt http://127.0.0.1:3000/
visit number 3
```

**Cada atributo desse `Set-Cookie` é uma defesa**, e cada um fecha uma porta diferente:

| atributo | o que ele impede |
|---|---|
| `HttpOnly` | o próprio JavaScript da página não consegue ler o cookie, então um script injetado na página não consegue roubá-lo |
| `Secure` | o navegador só o manda por HTTPS, nunca em texto aberto |
| `SameSite=Lax` | outro site não consegue fazer o navegador mandá-lo junto com um formulário enviado de lá |
| `Max-Age` | ele expira, em vez de viver enquanto o navegador viver |

O cookie voltou por `http://` simples, embora diga `Secure`, porque o curl, como os navegadores, trata
o endereço do próprio computador como seguro; para qualquer outro endereço ele só viajaria por HTTPS.
**E um cookie é texto do cliente como todo o resto**: um navegador o guarda, uma pessoa pode editá-lo,
então `visits=1000000` chega tão fácil quanto o valor de verdade. Um cookie que não pode ser forjado
leva uma assinatura que o servidor confere, ou é só um id de sessão aleatório que significa algo
apenas no servidor, que é como funcionam as sessões de login.
