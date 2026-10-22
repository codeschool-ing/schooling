---
title: Sem sessão, sem revogação, e por que o CSRF está desligado
version: 1
---

A primeira transcrição desta aula voltou com um cookie `JSESSIONID`. É o padrão do Spring Security:
depois de uma autenticação bem-sucedida, ele guarda o usuário numa `HttpSession` no servidor, e o
cookie é como o navegador a encontra de novo. As duas cadeias da livraria dizem
`SessionCreationPolicy.STATELESS`, então o Spring Security nem cria sessão nem lê uma. Os cabeçalhos
de um pedido de token mostram isso:

```
ana@vm:~/bookshop$ curl -s -D - -o /dev/null -u ana:ana-reads-books -X POST localhost:8080/auth/token
HTTP/1.1 200 
X-Content-Type-Options: nosniff
X-XSS-Protection: 0
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY
Content-Type: application/json
Content-Length: 298
Date: Thu, 22 Oct 2026 22:14:06 GMT
```

Nenhum `Set-Cookie`. O cliente não recebe nada para mandar de volta além do próprio token, e toda
requisição se prova de novo. Isso tem uma consequência além da arrumação: uma segunda instância da
livraria aceita um token que a primeira assinou, desde que as duas tenham o mesmo segredo.

## O que o servidor não lembra

**O servidor não guarda registro dos tokens que entrega.** Ele confere uma assinatura e uma data, e é
só. A expiração é, portanto, o único jeito de um token parar de funcionar sozinho. Para vê-la
acontecer sem esperar quinze minutos, suba a aplicação com uma duração de dois segundos; uma
propriedade dada na linha de comando vence a do arquivo (aula 4):

```sh
java -jar target/bookshop-0.1.0.jar --bookshop.jwt.lifetime=2s
```

```
ana@vm:~/bookshop$ curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > ana.token
ana@vm:~/bookshop$ cut -d. -f2 ana.token | basenc -d --base64url; echo
{"iss":"bookshop","sub":"ana","exp":1792707255,"iat":1792707253,"scope":"orders"}
ana@vm:~/bookshop$ sleep 5; curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat ana.token)" localhost:8080/books/1
200
ana@vm:~/bookshop$ sleep 60; curl -si -H "Authorization: Bearer $(cat ana.token)" localhost:8080/books/1 | head -2
HTTP/1.1 401 
WWW-Authenticate: Bearer error="invalid_token", error_description="An error occurred while attempting to decode the Jwt: Jwt expired at 2026-10-22T22:14:15Z", error_uri="https://tools.ietf.org/html/rfc6750#section-3.1", resource_metadata="http://localhost:8080/.well-known/oauth-protected-resource"
```

O payload diz que o `exp` está dois segundos depois do `iat`, e cinco segundos depois o token ainda
funcionava. O decoder do Spring Security tolera **60 segundos de diferença de relógio** depois do
`exp`, por padrão, porque a máquina que emite um token e a que o confere raramente concordam no
segundo. Um minuto depois ele foi recusado, com o momento em que expirou no cabeçalho. O livro é
público, e a resposta ainda assim foi 401: **um token que falha na verificação é recusado onde quer
que seja enviado**, mesmo onde não é preciso token, porque o filtro bearer confere qualquer token que
recebe antes de as regras serem lidas.

O outro lado do mesmo fato é o que importa: **um JWT não pode ser revogado.** Um token copiado da
máquina de alguém vale até o seu `exp`, e nada que o servidor guarda pode ser riscado, porque o
servidor não guarda nada. Sair, com tokens assim, quer dizer o cliente jogar fora a sua cópia. Existem
três defesas, e cada uma custa algo:

- uma **duração curta**, e por isso a da livraria é de quinze minutos e não de uma semana; o preço é o
  cliente pedir de novo com mais frequência;
- **um segredo novo**, que encerra todos os tokens de uma vez, os de todo mundo;
- uma **lista de tokens revogados**, conferida em toda requisição, em geral por um claim `jti` que dá
  um id a cada token. Funciona, e traz de volta o estado no servidor que o token existia para tirar.

## CSRF, e a condição para desligá-lo

As duas cadeias chamam `csrf.disable()`, e isso parece uma fraqueza. Aqui está certo por um motivo só,
que vale conhecer com exatidão, porque o motivo pode deixar de ser verdade.

O **cross-site request forgery** se aproveita de um hábito dos navegadores: eles anexam os cookies de
um site a toda requisição a esse site, inclusive uma que a página de outro site dispara. Se um cookie
autenticasse a ana na livraria, uma página maliciosa que ela visitasse poderia enviar um formulário
escondido para `/orders`, e o navegador dela o mandaria com o cookie anexado. A defesa do Spring
Security é um **token CSRF**, um valor que as páginas da própria livraria teriam de mandar de volta e
que outro site não consegue ler.

Nada nesta livraria autentica com cookie. O token viaja num cabeçalho `Authorization`, que um navegador
nunca acrescenta sozinho, então uma requisição forjada de outro site chega sem credenciais e recebe
401. **No dia em que um cookie autenticar qualquer coisa** (um formulário de login com sessão, ou o JWT
movido para um cookie para ficar longe do JavaScript) **a proteção contra CSRF volta a ser ligada.**
