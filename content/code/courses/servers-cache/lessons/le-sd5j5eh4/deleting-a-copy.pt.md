---
title: Apagando uma cópia do disco
version: 1
---

O outro jeito de fazer o Nginx esquecer uma cópia é apagar o arquivo onde ela fica. A aula 5 mostrou que
cada cópia é um arquivo cuja primeira linha é a chave; o **nome** do arquivo é o MD5 dessa chave, e os
diretórios dele saem do fim do nome, porque o cache foi declarado com `levels=1:2`:

```
ana@web:~$ curl -s -X PUT -d '{"price_cents": 6990}' https://ipelivros.example/api/books/2 > /dev/null; curl -s -D /tmp/h https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"Grande Sertão: Veredas","price_cents":7990}
X-Cache-Status: HIT
ana@web:~$ echo -n 'http://shop/api/books/2' | md5sum
e8fb3bb9dc4188361a54f7d7c9036679  -
ana@web:~$ K=$(echo -n 'http://shop/api/books/2' | md5sum | cut -c1-32); sudo ls -l /var/cache/nginx/shop/${K: -1}/${K: -3:2}/$K
-rw------- 1 www-data www-data 764 Oct  7 01:09 /var/cache/nginx/shop/9/67/e8fb3bb9dc4188361a54f7d7c9036679
ana@web:~$ K=$(echo -n 'http://shop/api/books/2' | md5sum | cut -c1-32); sudo rm /var/cache/nginx/shop/${K: -1}/${K: -3:2}/$K
ana@web:~$ curl -s -D /tmp/h https://ipelivros.example/api/books/2 | jq -c '{title, price_cents}'; grep -i x-cache-status /tmp/h
{"title":"Grande Sertão: Veredas","price_cents":6990}
X-Cache-Status: MISS
```

O preço mudou para 6.990, o cache ainda dizia 7.990, e depois que o arquivo foi removido a próxima
requisição foi um `MISS` que buscou o novo. O caminho é o último caractere do hash (`9`), depois os dois
anteriores (`67`), depois o próprio hash, que é o que `levels=1:2` quer dizer.

Isso funciona, e é assim que scripts que "limpam" o Nginx de código aberto fazem. Dois cuidados vêm
junto. A chave precisa ser exatamente a que o Nginx calculou, esquema e nome do upstream incluídos, senão
o hash aponta para nada e a remoção não faz nada, em silêncio; e num site com várias máquinas Nginx, a
cópia precisa ser apagada em cada uma delas. Uma requisição de atualização pela porta da frente, como na
seção anterior, não tem nenhum dos dois problemas, e por isso costuma ser a melhor ferramenta das duas.
