---
title: check --deploy, e o DEBUG desligado
version: 1
---

O Django sabe revisar as próprias configurações para uma implantação:

```
ana@vm:~/agenda$ uv run --env-file .env python manage.py check --deploy
System check identified some issues:

WARNINGS:
?: (security.W004) You have not set a value for the SECURE_HSTS_SECONDS setting. If your entire site is served only over SSL, you may want to consider setting a value and enabling HTTP Strict Transport Security. Be sure to read the documentation first; enabling HSTS carelessly can cause serious, irreversible problems.
?: (security.W008) Your SECURE_SSL_REDIRECT setting is not set to True. Unless your site should be available over both SSL and non-SSL connections, you may want to either set this setting True or configure a load balancer or reverse-proxy server to redirect all connections to HTTPS.
?: (security.W012) SESSION_COOKIE_SECURE is not set to True. Using a secure-only session cookie makes it more difficult for network traffic sniffers to hijack user sessions.
?: (security.W016) You have 'django.middleware.csrf.CsrfViewMiddleware' in your MIDDLEWARE, but you have not set CSRF_COOKIE_SECURE to True. Using a secure-only CSRF cookie makes it more difficult for network traffic sniffers to steal the CSRF token.
?: (security.W018) You should not have DEBUG set to True in deployment.
?: (security.W020) ALLOWED_HOSTS must not be empty in deployment.

System check identified 6 issues (0 silenced).
```

Seis avisos, e os dois últimos são desta aula: **`DEBUG` ligado**, e **`ALLOWED_HOSTS` vazio**. Defina
os dois como um servidor faria, no shell, onde vencem o `.env`:

```
ana@vm:~/agenda$ DJANGO_DEBUG=0 DJANGO_ALLOWED_HOSTS=agenda.example.org uv run --env-file .env python manage.py check --deploy
System check identified some issues:

WARNINGS:
?: (security.W004) You have not set a value for the SECURE_HSTS_SECONDS setting. If your entire site is served only over SSL, you may want to consider setting a value and enabling HTTP Strict Transport Security. Be sure to read the documentation first; enabling HSTS carelessly can cause serious, irreversible problems.
?: (security.W008) Your SECURE_SSL_REDIRECT setting is not set to True. Unless your site should be available over both SSL and non-SSL connections, you may want to either set this setting True or configure a load balancer or reverse-proxy server to redirect all connections to HTTPS.
?: (security.W012) SESSION_COOKIE_SECURE is not set to True. Using a secure-only session cookie makes it more difficult for network traffic sniffers to hijack user sessions.
?: (security.W016) You have 'django.middleware.csrf.CsrfViewMiddleware' in your MIDDLEWARE, but you have not set CSRF_COOKIE_SECURE to True. Using a secure-only CSRF cookie makes it more difficult for network traffic sniffers to steal the CSRF token.

System check identified 4 issues (0 silenced).
```

Os quatro que sobram são sobre **HTTPS**: um redirecionamento para ele, cookies que só viajam por ele, e
o HSTS, o cabeçalho que diz aos navegadores para nunca mais tentar HTTP simples. Eles pertencem ao
servidor que encerra o TLS, que é o nginx da aula 16, e são definidos lá.

## O que o ALLOWED_HOSTS faz

Rode o servidor de desenvolvimento com os mesmos dois valores, e peça a lista pelo endereço IP, depois
pelo nome:

```
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8000/events/
400
ana@vm:~/agenda$ curl -s -o /dev/null -w "%{http_code}\n" -H "Host: agenda.example.org" http://127.0.0.1:8000/events/
200
```

**400 para um host fora da lista.** O Django compara o cabeçalho `Host` da requisição com o
`ALLOWED_HOSTS` antes de qualquer outra coisa. Isso impede que requisições destinadas a outros nomes
cheguem à aplicação, inclusive as forjadas que poriam o domínio de um estranho nos links de um e-mail de
redefinição de senha. Com o `DEBUG` desligado, um erro também é uma página simples:

```
ana@vm:~/agenda$ curl -s -H "Host: agenda.example.org" http://127.0.0.1:8000/events/nope/; echo

<!doctype html>
<html lang="en">
<head>
  <title>Not Found</title>
</head>
<body>
  <h1>Not Found</h1><p>The requested resource was not found on this server.</p>
</body>
</html>
```

Nada de traceback, nada de lista de padrões de URL, nada de configurações. É o que um visitante de um
site em produção precisa ver, e o motivo de o `DEBUG` ser desligado por padrão.
