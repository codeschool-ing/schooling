---
title: O que um cache compartilhado nunca deve guardar
version: 1
---

O cache de um navegador guarda as cópias de uma pessoa. Um cache compartilhado entrega as cópias dele a
**todos**, e a pior coisa que ele pode fazer não é ficar lento ou desatualizado: é dar a página de uma
pessoa a outra. Incidentes desse tipo têm uma forma só, uma página de conta ou um carrinho guardado uma
vez e depois entregue a quem pediu a mesma URL em seguida, e a defesa são três regras.

**Um: tudo o que muda por pessoa diz `private` ou `no-store`, e o cache compartilhado obedece.** O Nginx
obedece, como a seção anterior mostrou: três requisições por uma resposta `private`, três idas à loja,
nada guardado. A responsabilidade é dividida. A aplicação precisa mandar o cabeçalho em toda resposta
pessoal, inclusive páginas de erro e redirecionamentos; o cache precisa respeitá-lo, o que o Nginx faz
por padrão e uma linha desliga, `proxy_ignore_headers Cache-Control`. Essa linha aparece em conselhos
para tirar mais acertos de um cache, e é a linha que transforma um cache num vazamento.

**Dois: a chave precisa conter tudo o que muda a resposta.** A chave inclui a query, então `?a=1` e
`?a=2` ficam separados, e o segundo `?a=1` é um acerto:

```
ana@web:~$ for q in '' '?a=1' '?a=2' '?a=1'; do printf '%-6s ' "$q"; curl -s -o /dev/null -D - "https://ipelivros.example/api/books/5$q" | grep -i x-cache-status; done
       X-Cache-Status: MISS
?a=1   X-Cache-Status: MISS
?a=2   X-Cache-Status: MISS
?a=1   X-Cache-Status: HIT
```

Agora duas requisições que o cache trata exatamente como a primeira:

```
ana@web:~$ curl -s -o /dev/null -D - -H 'Cache-Control: no-cache' https://ipelivros.example/api/books/5 | grep -i x-cache-status
X-Cache-Status: HIT
ana@web:~$ curl -s -o /dev/null -D - -H 'Authorization: Bearer abc' https://ipelivros.example/api/books/5 | grep -i x-cache-status
X-Cache-Status: HIT
```

**As duas saíram do cache.** A primeira pediu uma cópia fresca com `Cache-Control: no-cache`, e o
Nginx ignora o que os clientes pedem, de propósito: senão qualquer cliente poderia forçar toda
requisição até a aplicação. A segunda trazia um cabeçalho `Authorization`, **e o Nginx entregou a ela a
cópia guardada para todos**. O Nginx não olha credenciais ao decidir o que entregar. Se a API algum dia
respondesse diferente para um usuário logado, a resposta desse usuário seria guardada sob a mesma chave
e entregue ao próximo visitante anônimo, ou o contrário. A defesa são duas linhas no location:

```
ana@web:~$ sudo sed -i 's|        proxy_cache api_cache;|        proxy_cache api_cache;\n        proxy_cache_bypass $http_authorization;\n        proxy_no_cache     $http_authorization;|' /etc/nginx/sites-available/ipelivros && grep -n 'proxy_cache\|proxy_no_cache' /etc/nginx/sites-available/ipelivros
27:        proxy_cache api_cache;
28:        proxy_cache_bypass $http_authorization;
29:        proxy_no_cache     $http_authorization;
ana@web:~$ curl -s -o /dev/null -D - -H 'Authorization: Bearer abc' https://ipelivros.example/api/books/5 | grep -i x-cache-status
X-Cache-Status: BYPASS
ana@web:~$ curl -s -o /dev/null -D - https://ipelivros.example/api/books/5 | grep -i x-cache-status
X-Cache-Status: HIT
```

`BYPASS` para a requisição com credenciais, que foi à loja e não foi guardada (`proxy_no_cache`), e
`HIT` para a que não tinha. O Nginx se recusa sozinho a guardar uma resposta que define um cookie
(`Set-Cookie`), pelo mesmo motivo; uma requisição que traz um fica por sua conta, com as mesmas duas
diretivas e `$http_cookie`.

**Três: se a resposta varia por algo que não está na URL, a chave ou o `Vary` precisa dizer.** Um idioma
escolhido pelo `Accept-Language`, ou uma moeda vinda de um cookie, mudam a resposta sem mudar a URL. Ou a
chave o inclui (`proxy_cache_key "$scheme$host$request_uri$cookie_currency"`), ou a resposta traz
`Vary: Accept-Language`, que o Nginx respeita guardando uma cópia por valor. A livraria não varia por
mais nada, e por isso a chave dela não precisou de mais nada.

O que pôr num cache compartilhado, então: respostas públicas, iguais para todo visitante, cuja
desatualização por um minuto não custa nada. **Na dúvida, deixe de fora**: um cache que erra o alvo
custa alguns milissegundos, e um cache que serve a pessoa errada custa uma comunicação à autoridade de
proteção de dados.
