---
title: Quando a origem cai
version: 1
---

A borda confere a saúde da origem a cada dois segundos pelo `.probe` da definição do backend, e
`beresp.grace = 1h` mantém todo objeto vencido por uma hora depois do fim do tempo de vida. Juntos, eles
são a forma do Varnish do `proxy_cache_use_stale` da aula 6. Com um tempo de vida de cinco segundos,
deixe uma cópia vencer e pare as lojas:

```
ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/7 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=5
X-Varnish: 32803
Age: 0
X-Cache: MISS
ana@web:~$ sleep 6; sudo systemctl stop shop@1 shop@2; sleep 5; sudo varnishadm backend.list
Backend name   Admin    Probe    Health    Last change
boot.origin    probe    0/3      sick      Wed, 07 Oct 2026 04:17:31 GMT

ana@web:~$ curl -s -o /dev/null -D - -H 'Host: ipelivros.example' http://localhost:6081/api/books/7 | grep -iE '^(age|x-cache|x-varnish|cache-control)'
Cache-Control: public, max-age=5
X-Varnish: 37 32804
Age: 11
X-Cache: HIT
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Host: ipelivros.example' http://localhost:6081/api/books/8
503
```

O probe marcou a origem como **doente** (*sick*) depois de duas falhas nas três últimas conferências, e
a borda entregou o livro 7 como um `HIT` com **onze segundos** de idade, seis além do tempo de vida, em
vez de um erro. O livro 8, nunca buscado, não tem nada em grace, e a borda o respondeu com `503`. Suba as
lojas de novo, e o probe marca a origem como saudável em poucos segundos sem ninguém mexer na borda.

O grace faz um segundo trabalho enquanto a origem está saudável: quando uma cópia popular vence, a borda
a entrega do grace a todos que pedem enquanto **uma** requisição busca a cópia nova, e o Varnish põe as
requisições idênticas na fila atrás da busca já em andamento em vez de mandar cada uma à origem. É assim
que uma borda protege a origem do próprio tráfego, e a aula 11 mede a diferença que isso faz.

## Contando

O `varnishstat` guarda os contadores de tudo o que esta aula fez:

```
ana@web:~$ sudo varnishstat -1 -f MAIN.cache_hit -f MAIN.cache_miss -f MAIN.cache_hitpass -f MAIN.s_pass -f MAIN.n_object -f MAIN.backend_req | awk '{print $1, $2}'
MAIN.cache_hit 12
MAIN.cache_hitpass 0
MAIN.cache_miss 11
MAIN.n_object 7
MAIN.s_pass 5
MAIN.backend_req 15
```

Doze acertos, onze erros e cinco repasses (as requisições com cookies e credenciais), 15 requisições à
origem, e sete objetos guardados. Numa borda de verdade, os mesmos contadores, somados em todas as
cidades, são a taxa de acerto no painel da CDN. **O número de requisições à origem é o que vale vigiar**:
é para isso que a borda existe, e uma conta de CDN com taxa de acerto alta e uma origem ainda ocupada
quer dizer que algo está sendo repassado e não deveria.
