---
title: "O que saiu: os grants implicit e password"
version: 1
---

A RFC 6749 definiu quatro grants em 2012. Dois são os que esta lição rodou, o authorization code e o
client credentials. **Os outros dois ainda estão em documentação antiga, em bibliotecas antigas e em
muita resposta na internet, e os dois agora são recusados.** A RFC 9700, as recomendações de
segurança do OAuth de 2025, diz que o grant implicit não deve ser usado e que o grant password não
pode ser; o rascunho do OAuth 2.1 tira os dois do protocolo.

| grant | como funcionava | por que saiu | no lugar |
|---|---|---|---|
| implicit, `response_type=token` | o `/authorize` devolvia o access token direto no redirecionamento, na parte do endereço depois do `#` | o token viaja pelo canal da frente: pode parar no histórico e em logs, nada o prende ao cliente, e não há refresh token | o fluxo de código com PKCE, que também funciona para um app no navegador |
| resource owner password credentials, `grant_type=password` | o cliente coletava a senha do usuário e a enviava para `/token` | é o problema de compartilhar senha da primeira seção com um rótulo do OAuth: o app vê a senha, e nenhum segundo fator ou tela de consentimento se põe no meio | o fluxo de código, para que a senha seja digitada só no servidor de autorização |

**O grant implicit era um contorno para navegadores que não é mais necessário.** Ele existia porque,
quando foi desenhado, o JavaScript de uma página não podia contar com permissão para chamar `/token`
em outra origem. O CORS tornou essa chamada comum, o PKCE a tornou segura para um cliente sem
segredo, e o motivo acabou.

O `idp.py` recusa os dois, cada um do seu jeito. O pedido implicit volta ao callback com um erro,
porque o cliente e o endereço dele estão certos e só o tipo de resposta não está. O `grep` guarda o
único cabeçalho que importa:

```
ana@api:~/shelf$ curl -si "${AUTH/response_type=code/response_type=token}&scope=openid&code_challenge=$CHALLENGE" | grep Location
Location: http://127.0.0.1:9000/callback?error=unsupported_response_type
```

O grant password não é um grant que este servidor conheça:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=password -d username=ana -d password=her-password
{"error": "unsupported_grant_type", "error_description": "password is not offered here"}
```

O rascunho do OAuth 2.1 muda mais duas coisas que o fluxo de código deixava opcionais, e o `idp.py`
já exige as duas: **PKCE em todo pedido de código**, e comparação exata do `redirect_uri`, que
barrou o endereço da porta 9999 quando você rodou o fluxo à mão. Um pedido sem challenge não recebe
código:

```
ana@api:~/shelf$ curl -si "$AUTH&scope=openid" | grep Location
Location: http://127.0.0.1:9000/callback?error=invalid_request&error_description=PKCE+with+S256+is+required
```

Uma biblioteca ou um tutorial que oferece qualquer um dos dois grants está dizendo a sua idade.
Deixe os dois desligados em todo servidor de autorização que você configurar, e espere que uma
revisão pergunte por quê se estiverem ligados.
