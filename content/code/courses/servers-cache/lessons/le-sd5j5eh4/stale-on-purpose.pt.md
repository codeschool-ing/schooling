---
title: Servindo a cópia velha de propósito
version: 1
---

Até aqui uma cópia velha foi o problema. Há dois momentos em que ela é a melhor resposta disponível.

## Quando a aplicação está fora do ar

`proxy_cache_use_stale` nomeia as falhas em que o Nginx pode entregar uma cópia vencida em vez de um
erro. Com um tempo de vida de cinco segundos, deixe a cópia vencer e pare as duas lojas:

```
ana@web:~$ sudo sed -i 's|        proxy_cache api_cache;|        proxy_cache api_cache;\n        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;|' /etc/nginx/sites-available/ipelivros && grep -n 'use_stale' /etc/nginx/sites-available/ipelivros
25:        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/3 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"A Hora da Estrela","price_cents":3990}
X-Cache-Status: MISS
ana@web:~$ sleep 6; sudo systemctl stop shop@1 shop@2
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/3 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"A Hora da Estrela","price_cents":3990}
X-Cache-Status: STALE
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/api/books/4
502
ana@web:~$ sudo systemctl start shop@1 shop@2
```

**`STALE`, e um preço que estava certo seis segundos antes, em vez de um `502`.** Para um catálogo, uma
página com preços de alguns segundos atrás é muito melhor que uma página de erro, e as lojas estarem
fora do ar fica invisível para quem tem cópia. Um livro que nunca foi guardado não tem em que se apoiar,
e recebe o `502`. Se isso está certo depende do dado: um catálogo velho durante uma queda é uma
gentileza, e um saldo de conta velho é uma mentira. O `must-revalidate` da aula 5 é como uma origem pede
a todo cache que nunca faça isso com uma resposta; se um cache específico respeita isso é algo a testar,
e o lugar seguro para decidir é a configuração do próprio cache, sem `proxy_cache_use_stale` nos
locations que servem essas respostas.

## Enquanto uma cópia nova é buscada

Quando uma cópia vence e as requisições continuam chegando, a primeira espera pela loja, 120 ms aqui, e
toda outra requisição que chegar antes de a cópia nova entrar também espera. `updating` na mesma
diretiva, com `proxy_cache_background_update on`, muda isso: a cópia vencida é entregue na hora, e a
busca acontece por trás dela.

```
ana@web:~$ sudo sed -i 's|        proxy_cache_use_stale error timeout http_500 http_502 http_503 http_504;|        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;\n        proxy_cache_background_update on;|' /etc/nginx/sites-available/ipelivros && grep -n 'use_stale\|background' /etc/nginx/sites-available/ipelivros
25:        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
26:        proxy_cache_background_update on;
ana@web:~$ curl -s -o /dev/null -w '%{http_code} in %{time_total} s\n' https://ipelivros.example/api/books/5
200 in 0.149338 s
ana@web:~$ sleep 6; for i in 1 2 3; do curl -s -o /dev/null -D /tmp/h -w '%{time_total} s ' https://ipelivros.example/api/books/5; grep -i x-cache-status /tmp/h; sleep 0.5; done
0.027254 s X-Cache-Status: STALE
0.027737 s X-Cache-Status: HIT
0.027568 s X-Cache-Status: HIT
```

A primeira requisição depois do vencimento recebeu `STALE` em 27 milissegundos, o tempo de uma resposta
em cache, não os 150 da loja; a cópia foi renovada por trás, e as requisições seguintes voltam a ser
`HIT`. O custo é que um visitante viu uma resposta com até um tempo de vida mais uma busca de idade. Isso
é o **stale-while-revalidate** do HTTP, e uma origem pode pedi-lo no próprio cabeçalho, `Cache-Control:
max-age=60, stale-while-revalidate=30`, que muitos navegadores e CDNs também respeitam.

A aula 11 volta a esse momento pelo outro lado: o que acontece com a loja quando a cópia de uma página
popular vence e mil requisições chegam no mesmo segundo.
