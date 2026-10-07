---
title: Trocando uma cópia agora
version: 1
---

O Nginx de código aberto não tem um comando `PURGE`; o módulo para isso faz parte do NGINX Plus,
comercial. O que ele tem é o `proxy_cache_bypass`, já usado na aula 5 para mandar requisições com
credenciais por fora do cache. Uma requisição desviada vai à loja, e **a resposta dela é guardada**,
trocando o que houver lá. Então uma requisição que só o operador do site consegue fazer vira um botão de
atualizar para uma URL.

```
ana@web:~$ cat /etc/nginx/conf.d/refresh.conf
# A request carrying this header is sent to the shop, and its answer replaces
# the cached copy. The token keeps strangers from emptying the cache at will.
map $http_x_cache_refresh $cache_refresh {
    default                    0;
    "lab-refresh-token-2026"   1;
}
ana@web:~$ sudo sed -i 's|        proxy_cache_bypass $http_authorization;|        proxy_cache_bypass $http_authorization $cache_refresh;|' /etc/nginx/sites-available/ipelivros && grep -n 'proxy_cache_bypass' /etc/nginx/sites-available/ipelivros
24:        proxy_cache_bypass $http_authorization $cache_refresh;
```

O `map` transforma um cabeçalho numa variável: `1` quando a requisição traz o token certo, `0` caso
contrário, e o `proxy_cache_bypass` pula o cache sempre que algum dos valores dele não é vazio nem `0`.
Depois:

```
ana@web:~$ curl -s -o /dev/null -D - -H 'X-Cache-Refresh: lab-refresh-token-2026' https://ipelivros.example/api/books/2 | grep -i x-cache-status
X-Cache-Status: BYPASS
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"Grande Sertão: Veredas","price_cents":7990}
X-Cache-Status: HIT
ana@web:~$ curl -s -o /dev/null -D - -H 'X-Cache-Refresh: guess' https://ipelivros.example/api/books/2 | grep -i x-cache-status
X-Cache-Status: HIT
```

O `BYPASS` buscou o preço novo e o guardou, e a próxima requisição comum é um `HIT` com 7.990. Um token
errado é uma requisição comum, servida da cópia.

**O token importa.** Sem ele, qualquer um que descubra o nome do cabeçalho manda toda requisição por fora
do cache, o que transforma um cache que protege a aplicação num jeito de mirar tráfego nela. Um token num
cabeçalho é o mínimo; um endpoint de atualização que só escuta num endereço interno, ou que só aceita
requisições das máquinas que publicam conteúdo, é melhor. E a atualização é por URL: um preço que
aparece em vinte páginas precisa de vinte atualizações, que é onde entra a limpeza por etiqueta da
próxima aula.
