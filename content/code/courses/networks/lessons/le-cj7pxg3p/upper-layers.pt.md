---
title: Camadas 5 a 7: um comando, todas as camadas
version: 1
---

Acima da camada 4, o modelo tem três camadas, e na prática o programa faz as três. O `curl -v` narra o
que faz para buscar uma página, e seis de suas linhas, escolhidas com `grep`, sobem a pilha:

```
ana@laptop:~$ curl -sv -o /dev/null https://www.example.com/ 2>&1 | grep -E 'IPv4:|Trying|Connected|SSL connection|^> GET|^< HTTP'
* IPv4: 192.0.2.80
*   Trying 192.0.2.80:443...
* Connected to www.example.com (192.0.2.80) port 443
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / X25519 / id-ecPublicKey
> GET / HTTP/2
< HTTP/2 200 
```

| linha | camada | o que aconteceu |
|---|---|---|
| `IPv4: 192.0.2.80` | 7, DNS | o nome `www.example.com` virou um endereço |
| `Trying 192.0.2.80:443` | 3 e 4 | um endereço e uma porta: onde conectar |
| `Connected to … port 443` | 4 | o handshake do TCP terminou |
| `SSL connection using TLSv1.3` | 5 e 6 | uma sessão criptografada foi combinada |
| `> GET / HTTP/2` | 7 | o pedido |
| `< HTTP/2 200` | 7 | a resposta: OK |

**A camada 5, a sessão, é a que o modelo descreve com menos clareza.** Ela foi pensada para manter uma
conversa através de interrupções; hoje esse trabalho é feito pela retomada de sessão do TLS, por um
cookie de login ou pela própria aplicação, e nada no fio vem marcado como "camada 5". A camada 6, a
apresentação, é como os dados são codificados, e a criptografia é a parte dela que mais importa hoje.

A camada 7 é o protocolo que um programa fala: HTTP para a web, DNS para nomes, SMTP para e-mail, SSH
para um shell remoto. A maior parte deste curso mora aqui, das aulas 4 a 9, porque é onde os usuários
encontram a rede.
