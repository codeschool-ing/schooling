---
title: FTPS: FTP dentro do TLS
version: 1
---

O mesmo servidor sabe falar **FTPS**, o FTP embrulhado no TLS das aulas 5 e 6, com o mesmo certificado
do site. O `--ssl-reqd` faz o curl insistir nele:

```
ana@laptop:~$ curl -sS -v --ssl-reqd -u example:Sunflower-77 ftp://www.example.com/ 2>&1 | grep -E "^[<>] (AUTH|234|USER|230)|SSL connection|^-rw"
> AUTH SSL
< 234 Proceed with negotiation.
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / prime256v1 / id-ecPublicKey
> USER example
< 230 Login successful.
* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384 / prime256v1 / UNDEF
-rw-r--r--    1 1001     1001          109 Sep 25 18:26 index.html
ana@isp:~$ sudo timeout 6 tcpdump -i eth0 -n -l "tcp port 21" 2>/dev/null | grep -aoE "FTP: (220|AUTH|234|USER|PASS)[ -~]*"
FTP: 220 (vsFTPd 3.0.5)
FTP: AUTH SSL
FTP: 234 Proceed with negotiation.
```

Antes de entrar, o curl mandou `AUTH SSL` e o servidor respondeu `234 Proceed with negotiation`; depois
um handshake TLS 1.3, e só então o `USER`. Na máquina do ISP, só dava para ler a saudação e essas duas
linhas. Tudo depois delas, senha inclusive, vai cifrado.

Oferecer cifragem não é o mesmo que exigir: um cliente que não pede ainda entra do jeito antigo. O
servidor pode recusar isso:

```
ana@www:~$ grep -E "^(ssl_enable|force_local)" /etc/vsftpd.conf
ssl_enable=YES
force_local_logins_ssl=YES
force_local_data_ssl=YES
ana@laptop:~$ curl -sS -v -u example:Sunflower-77 ftp://www.example.com/ 2>&1 | grep -E "^< 530|curl:"
< 530 Non-anonymous sessions must use encryption.
curl: (67) Access denied: 530
```

Com `force_local_logins_ssl=YES`, um login sem TLS recebe `530` e não passa disso.

Duas coisas para saber sobre o FTPS. Este é o FTPS **explícito**, que começa puro na porta 21 e sobe
com o `AUTH`; uma forma mais antiga, o FTPS implícito, fala TLS desde o primeiro byte, na porta 990. E o
FTPS mantém as duas conexões e a faixa passiva: um firewall tem a mesma faixa para abrir, e não consegue
mais ler as respostas `229` para ajudar, porque elas também vão cifradas.
