---
title: Quando uma cópia falha
version: 1
---

Pare a segunda cópia da loja, como uma queda faria, e continue perguntando:

```
ana@web:~$ sudo systemctl stop shop@2
ana@web:~$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w "%{http_code} " http://ipelivros.example/api/books/1; done; echo
200 200 200 200 200 200 
ana@web:~$ tail -n 2 /var/log/nginx/ipelivros.error.log
2026/10/07 00:26:07 [error] 1212#1212: *288 connect() failed (111: Connection refused) while connecting to upstream, client: 127.0.0.1, server: ipelivros.example, request: "GET /api/books/1 HTTP/1.1", upstream: "http://127.0.0.1:8002/api/books/1", host: "ipelivros.example"
```

**Todas as requisições deram certo.** O log de erros mostra o que aconteceu com a primeira que foi
mandada à cópia parada: a conexão foi recusada, e o Nginx tentou o próximo membro do grupo antes de o
cliente perceber qualquer coisa. Isso é o `proxy_next_upstream`, que por padrão tenta de novo num erro
ou num estouro de tempo antes de qualquer parte da resposta ter sido enviada. Depois o membro foi
marcado como indisponível, e nada mais foi mandado a ele.

Isso é uma **verificação de saúde passiva**: o Nginx descobre que um membro caiu porque requisições
reais falham, e as duas configurações que a governam ficam em cada linha `server`, `max_fails`
(padrão 1) e `fail_timeout` (padrão 10 segundos). Depois de `max_fails` falhas dentro de
`fail_timeout`, o membro fica de lado por `fail_timeout`, e então é tentado de novo com uma requisição
real.

Pare a outra cópia também:

```
ana@web:~$ sudo systemctl stop shop@1
ana@web:~$ curl -si http://ipelivros.example/api/books/1 | head -n 4
HTTP/1.1 502 Bad Gateway
Server: nginx/1.24.0 (Ubuntu)
Date: Wed, 07 Oct 2026 03:26:08 GMT
Content-Type: text/html
ana@web:~$ tail -n 1 /var/log/nginx/ipelivros.error.log
2026/10/07 00:26:08 [error] 1209#1209: *297 no live upstreams while connecting to upstream, client: 127.0.0.1, server: ipelivros.example, request: "GET /api/books/1 HTTP/1.1", upstream: "http://shop/api/books/1", host: "ipelivros.example"
```

**`502 Bad Gateway` quer dizer que o Nginx não conseguiu resposta nenhuma da aplicação**, e o log diz
por quê em três palavras: `no live upstreams`. Agora suba as duas cópias de novo e pergunte na hora:

```
ana@web:~$ sudo systemctl start shop@1 shop@2
ana@web:~$ curl -s -o /dev/null -w "%{http_code}\n" http://ipelivros.example/api/books/1
502
ana@web:~$ sleep 10; curl -s -o /dev/null -w "%{http_code}\n" http://ipelivros.example/api/books/1
200
```

Ainda `502` com as duas cópias rodando, e `200` dez segundos depois. Os dois membros estavam dentro
do `fail_timeout`, então o Nginx ainda não os tentava. São dez segundos de queda depois de a aplicação
ter se recuperado, e esse é o preço de uma verificação que só aprende com tráfego real.

## Verificações ativas, e um membro de reserva

Uma **verificação de saúde ativa** pergunta a cada membro, num intervalo, se ele está bem, antes de
arriscar qualquer requisição real. O Nginx de código aberto não tem isso; faz parte do NGINX Plus,
comercial, e o HAProxy, o Traefik e o Caddy têm nas versões gratuitas. Com o Nginx de código aberto, a
resposta comum é que quem sobe a aplicação (o systemd aqui, o Kubernetes em outros lugares) vigia a
saúde dela e a reinicia, e a verificação passiva do Nginx cobre os segundos no meio.

Mais duas configurações numa linha `server` ajudam:

```conf
upstream shop {
    zone shop 64k;
    server 127.0.0.1:8001 max_fails=3 fail_timeout=5s;
    server 127.0.0.1:8002 max_fails=3 fail_timeout=5s;
    server 127.0.0.1:8003 backup;
}
```

`max_fails=3` impede que uma requisição azarada tire um membro do grupo. `backup` nomeia um membro que
não recebe nada enquanto algum outro está de pé: uma página de manutenção, ou uma cópia menor em outro
lugar. Não há `8003` neste laboratório, então este bloco não foi carregado aqui; ele aparece pela
forma.
