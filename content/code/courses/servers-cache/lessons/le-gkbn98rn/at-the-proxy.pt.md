---
title: O mesmo estouro no proxy
version: 1
---

O cache do Nginx da aula 5 tem o mesmo problema, uma camada acima. Este programa são quarenta
visitantes, cada um na própria thread. Cada um conecta primeiro e depois espera numa barreira, para que
os quarenta peçam no mesmo instante uma página que ainda não está em cache:

```python
import http.client
import sys
import threading
from collections import Counter

host, path, visitors = sys.argv[1], sys.argv[2], int(sys.argv[3])
gate = threading.Barrier(visitors)
seen = Counter()


def visitor():
    conn = http.client.HTTPSConnection(host)
    conn.connect()                      # the TLS handshake, before the start
    gate.wait()                         # then everybody asks at the same moment
    conn.request("GET", path)
    response = conn.getresponse()
    seen[response.status, response.getheader("X-Cache-Status")] += 1


threads = [threading.Thread(target=visitor) for _ in range(visitors)]
for t in threads:
    t.start()
for t in threads:
    t.join()
print(sorted(seen.items()))
```

```
ana@web:~/work$ python3 visitors.py ipelivros.example /api/books/3 40
[((200, 'MISS'), 40)]
ana@web:~/work$ curl -s http://127.0.0.1:8001/api/stats; curl -s http://127.0.0.1:8002/api/stats
{"server": "shop1", "db_queries": 20}
{"server": "shop2", "db_queries": 20}
```

**Quarenta visitantes, quarenta erros de cache, quarenta consultas**, vinte em cada cópia da loja. O
Nginx repassou todos, porque cada um não encontrou nada no cache quando chegou. A correção é uma
diretiva:

```
ana@web:~/work$ sudo sed -i 's/^\( *\)proxy_cache api_cache;$/&\n\1proxy_cache_lock on;/' /etc/nginx/sites-available/ipelivros && grep -n 'proxy_cache' /etc/nginx/sites-available/ipelivros
23:        proxy_cache api_cache;
24:        proxy_cache_lock on;
25:        proxy_cache_bypass $http_authorization;
ana@web:~/work$ sudo nginx -t && sudo systemctl reload nginx
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

O `proxy_cache_lock on` é o lock desta aula, embutido no Nginx: **a primeira requisição por uma entrada
que falta vai ao upstream, e as outras esperam que ela encha o cache.** Outra página, outros quarenta
visitantes:

```
ana@web:~/work$ python3 visitors.py ipelivros.example /api/books/4 40
[((200, 'HIT'), 39), ((200, 'MISS'), 1)]
ana@web:~/work$ curl -s http://127.0.0.1:8001/api/stats; curl -s http://127.0.0.1:8002/api/stats
{"server": "shop1", "db_queries": 1}
{"server": "shop2", "db_queries": 0}
```

**Um erro, trinta e nove acertos, uma consulta.** As requisições que esperavam foram respondidas do
cache assim que a primeira o encheu. O `proxy_cache_lock_timeout`, 5 segundos por padrão, é o tempo de
vida do lock: uma requisição que esperou tanto vai ela mesma ao upstream, e a resposta dela não entra no
cache.

Duas outras camadas deste curso já tinham uma resposta. **O `proxy_cache_use_stale updating` da aula
6**, com `proxy_cache_background_update on`, é servir o velho, no Nginx: uma entrada vencida é servida
enquanto uma requisição a atualiza. E **o Varnish, da aula 7, agrupa por padrão**: requisições
simultâneas por um objeto que ele já está buscando esperam numa lista por essa única busca, que é o lock
acima sem nada para ligar.
