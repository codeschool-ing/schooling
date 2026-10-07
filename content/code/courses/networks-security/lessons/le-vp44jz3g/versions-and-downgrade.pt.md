---
title: Quais versões o servidor aceita
version: 1
---

O TLS teve quatro versões, e o SSL duas antes dele. **SSL 2 e 3, TLS 1.0 e TLS 1.1 estão todos
obsoletos**, os dois últimos formalmente desde 2021. Cada um tem fraquezas conhecidas, e um servidor
que ainda os aceita deixa um cliente, ou alguém fingindo ser um, escolhê-los. No seu laboratório
esta aula começa com `sudo bash nslab.sh reset` sem política nenhuma carregada no `fw`, para que toda
pergunta aqui seja sobre TLS e nenhuma sobre o firewall. O proxy da loja permite dois:

```
root@www:~# grep -n ssl_protocols /etc/nginx/sites-enabled/shop
15:    ssl_protocols TLSv1.2 TLSv1.3;
```

Testado a partir do `laptop`, pedindo cada versão pelo nome:

```
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/
200
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com -tls1_3 </dev/null 2>/dev/null | grep "^New,"
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com -tls1_2 </dev/null 2>/dev/null | grep "^New,"
New, TLSv1.2, Cipher is ECDHE-ECDSA-AES256-GCM-SHA384
```

TLS 1.3 com `TLS_AES_256_GCM_SHA384`, e TLS 1.2 com `ECDHE-ECDSA-AES256-GCM-SHA384`. Depois o TLS 1.1:

```
ana@laptop:~$ curl -sS -o /dev/null --tls-max 1.1 https://www.example.com/; echo "exit $?"
curl: (35) OpenSSL/3.0.13: error:0A0000BF:SSL routines::no protocols available
exit 35
```

**O cliente recusou antes de o servidor ser consultado**: o OpenSSL do Ubuntu 24.04 não oferece TLS 1.1
no seu nível de segurança padrão. Isso protege este cliente e não prova nada sobre o servidor. Para
testar o servidor, o piso do próprio cliente tem de ser rebaixado de propósito, só para este teste:

```
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com -tls1_1 -cipher "DEFAULT:@SECLEVEL=0" </dev/null 2>&1 | grep -oE "alert protocol version|SSL alert number [0-9]+"
alert protocol version
SSL alert number 70
```

O servidor respondeu com **alert 70, `protocol version`**: recusou. As duas pontas agora recusam
versões antigas de forma independente, e qualquer uma delas sozinha protege toda conexão de que
participa.

## Proteção contra downgrade

Um ataque de downgrade não precisa que o servidor *prefira* uma versão antiga, só que *aceite* uma.
Um atacante no caminho interfere no primeiro handshake para que o cliente tente de novo com uma versão
mais antiga, e a conexão se acomoda na coisa mais fraca que os dois lados toleram. Dois mecanismos
fecham isso. Servidores TLS 1.3 escrevem um marcador fixo no seu valor aleatório quando negociam uma
versão mais antiga com um cliente que poderia fazer melhor, e assim um cliente TLS 1.3 detecta o
truque. E remover as versões antigas das duas pontas não deixa nada para onde rebaixar. **O segundo é
o que um administrador controla**, com uma linha.
