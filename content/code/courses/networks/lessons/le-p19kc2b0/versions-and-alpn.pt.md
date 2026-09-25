---
title: Qual HTTP, qual TLS
version: 1
---

Os dois lados combinam as versões durante o handshake, e as duas combinações podem ser forçadas a
partir do `curl`. Pedindo só HTTP/1.1:

```
ana@laptop:~$ curl -sv -o /dev/null --http1.1 https://www.example.com/ 2>&1 | grep -E 'ALPN|^> GET|^< HTTP'
* ALPN: curl offers http/1.1
* ALPN: server accepted http/1.1
> GET / HTTP/1.1
< HTTP/1.1 200 OK
ana@laptop:~$ curl -sS -o /dev/null --tls-max 1.1 https://www.example.com/
curl: (35) OpenSSL/3.0.13: error:0A0000BF:SSL routines::no protocols available
```

`curl offers http/1.1`, o servidor aceita, e o pedido e a resposta são HTTP/1.1. Por padrão, a oferta
foi `h2,http/1.1`, e o servidor escolheu **`h2`, o HTTP/2**: os mesmos pedidos e respostas, mandados em
quadros binários, muitos ao mesmo tempo por uma conexão. O HTTP/3 é o QUIC da aula 3, sobre UDP; este
nginx não o oferece.

O segundo comando pediu **TLS 1.1 no máximo**, e nem chegou ao servidor: `no protocols available`. A
própria biblioteca de TLS do laptop, o OpenSSL 3, **se recusa a oferecer TLS 1.0 ou 1.1**, e todo
navegador atual também. As duas versões foram aposentadas em 2021 (RFC 8996). Um equipamento que não
consegue conectar a nada moderno, uma impressora antiga ou um scanner antigo que envia para uma página
web, muitas vezes falha por isso, e o conserto é o firmware dele, não a rede.
