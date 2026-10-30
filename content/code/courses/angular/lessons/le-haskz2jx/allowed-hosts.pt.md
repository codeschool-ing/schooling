---
title: O servidor de produção, e os hosts por quem ele responde
version: 1
---

**O `ng build` agora produz dois programas: os arquivos que um navegador baixa, e um servidor Node.js
que renderiza páginas.**

```
ana@dev:~/planner$ npx ng build 2>&1 | grep -E 'Initial total|Prerendered|Output location'
                      | Initial total    | 344.15 kB |                95.25 kB
Prerendered 0 static routes.
Output location: /home/ana/planner/dist/planner
```

```
ana@dev:~/planner$ ls dist/planner dist/planner/server
dist/planner:
3rdpartylicenses.txt
browser
prerendered-routes.json
server

dist/planner/server:
angular-app-engine-manifest.mjs
angular-app-manifest.mjs
assets-chunks
chunk-ITOR7NUX.mjs
chunk-KUERU4XA.mjs
chunk-KYQQYI4M.mjs
chunk-LYHAGGDF.mjs
chunk-PJRDAGXT.mjs
chunk-UBU2ZLSD.mjs
index.server.html
main.server.mjs
polyfills.server.mjs
server.mjs
```

O `dist/planner/browser` guarda o que sempre guardou. O `dist/planner/server/server.mjs` é o
`server.ts`, compilado, com a aplicação inteira dentro. Ele é iniciado com o Node.js, num terminal
próprio; o `ng add` também o escreveu no `package.json` como `npm run serve:ssr:planner`, que roda a
mesma linha:

```
ana@dev:~/planner$ node dist/planner/server/server.mjs
Node Express server listening on http://localhost:4000
```

Ele escuta na porta 4000, e a API da aula 12 continua rodando na 3000. Mas a primeira página que ele
recebe volta vazia:

```
ana@dev:~/planner$ look http://localhost:4000/ --no-js --text body
```

E o terminal dele diz por quê:

```
ana@dev:~/planner$ node dist/planner/server/server.mjs
Node Express server listening on http://localhost:4000
ERROR: Bad Request ("http://localhost:4000/").
Header "host" with value "localhost:4000" is not allowed.
Falling back to client side rendering. This will become a 400 Bad Request in a future major version.

For more information, see https://angular.dev/best-practices/security#preventing-server-side-request-forgery-ssrf
```

## Por que um servidor confere o próprio nome

**Uma requisição diz para qual site ela é no cabeçalho `Host`, e quem manda a requisição escreve esse
cabeçalho.** Um navegador o preenche a partir da barra de endereço; o `curl`, ou qualquer programa,
pode escrever o que quiser. Isso importa aqui por causa de como o servidor resolve uma URL relativa.
Quando o planner renderiza no servidor e pede `/api/planner`, não há barra de endereço: o Angular
monta a URL completa a partir da requisição que está respondendo, cabeçalho `Host` incluído. Uma
requisição mandada com `Host: evil.example` faria o próprio servidor do planner buscar
`http://evil.example/api/planner` e renderizar na página o que voltasse.

Isso é **server-side request forgery**: um estranho escolhendo o que um servidor dentro da sua rede
pede. Num host de verdade o alvo perigoso não é o site de um estranho, mas algo que só o servidor
alcança, uma página interna de administração ou o endereço onde uma máquina na nuvem lê as próprias
credenciais. A defesa é listar os nomes sob os quais o site é servido e recusar o resto, que é o
bloco `security.allowedHosts` que o `ng add` escreveu no `angular.json` com uma lista vazia. Por
enquanto uma lista vazia cai para a renderização no navegador, com o erro acima; a mensagem diz que
uma versão futura vai recusar a requisição.

O planner é servido como `localhost`, então essa é a lista:

```
ana@dev:~/planner$ npx ng config projects.planner.architect.build.options.security.allowedHosts '["localhost"]'
```

A lista é lida na hora do build, então faça o build de novo e reinicie o servidor, Ctrl-C e o mesmo
comando. Uma porta não faz parte do nome, e `localhost:4000` casa com `localhost`. Então o nome do
próprio planner é renderizado, e qualquer outro é recusado:

```
ana@dev:~/planner$ look http://localhost:4000/ --no-js --text app-week
This week

19 October to 25 October 2026

The week could not be loaded: Http failure response for http://localhost:4000/api/planner: 404 Not Found
```

```
ana@dev:~/planner$ curl -s -i -H 'Host: evil.example' http://localhost:4000/ | head -1
HTTP/1.1 400 Bad Request
```

O dev server não precisa de nada disso: ele só responde em `localhost`, a não ser que mandem outra
coisa, e libera esse nome. Um deploy acrescenta os nomes reais, `planner.example.com` e o que mais
apontar para ele. Um nome pode começar com `*.` para liberar todos os subdomínios, o que só vale a
pena num domínio em que você controla todos os subdomínios. Um `*` sozinho libera todos os nomes, e é
a defesa desligada com uma configuração que parece uma. A lista também pode vir de uma variável de
ambiente, `NG_ALLOWED_HOSTS`, lida quando o servidor começa, para um deploy definir os próprios nomes
sem um build.

A página agora é renderizada, e diz que a semana não pôde ser carregada. Esse é o assunto da próxima
seção.
