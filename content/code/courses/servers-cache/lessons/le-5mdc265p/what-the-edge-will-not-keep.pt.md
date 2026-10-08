---
title: O que a borda não guarda
version: 1
---

A aula 5 descobriu que o Nginx entregava a cópia compartilhada a uma requisição com cabeçalho
`Authorization`, e precisou de duas linhas para parar. A lógica embutida do Varnish faz a escolha
oposta:

```
ana@web:~$ for i in 1 2; do curl -s -o /dev/null -D - -H 'Host: ipelivros.example' -H 'Cookie: session=abc' http://localhost:6081/api/books/3 | grep -iE '^(x-cache|x-varnish)'; done
X-Varnish: 7
X-Cache: MISS
X-Varnish: 32774
X-Cache: MISS
ana@web:~$ for i in 1 2; do curl -s -o /dev/null -D - -H 'Host: ipelivros.example' -H 'Authorization: Bearer abc' http://localhost:6081/api/books/3 | grep -iE '^(x-cache|x-varnish)'; done
X-Varnish: 10
X-Cache: MISS
X-Varnish: 32777
X-Cache: MISS
```

**Um erro de cache toda vez, e um número de transação só: o Varnish nem olhou o cache.** Uma requisição
que traz um `Cookie` ou um cabeçalho `Authorization` é **repassada** (*pass*) direto à origem e a resposta
não é guardada, porque qualquer um dos dois costuma querer dizer que a resposta pertence a uma pessoa. As
regras embutidas do Varnish também se recusam a guardar uma resposta que define um cookie, e qualquer
coisa cujo `Cache-Control` diga `private`, `no-cache` ou `no-store`.

Esse é o padrão seguro, e ele tem um custo que surpreende todo mundo que põe uma CDN na frente de um site
de verdade: **quase toda requisição de navegador traz um cookie.** Um script de analytics, um aviso de
consentimento ou uma preferência de idioma define um no domínio do site, toda requisição seguinte o
manda, e a borda repassa todas. Um site atrás de uma CDN com taxa de acerto perto de zero quase sempre
encontrou isso. A correção é remover, na borda, os cookies que a origem nunca lê num caminho (uma folha
de estilo não precisa de nenhum), e nunca desligar a regra por atacado, que é o vazamento da aula 5 com
uma plateia maior.
