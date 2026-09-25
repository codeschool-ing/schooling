---
title: POP3: baixar e levar embora
version: 1
---

O **POP3** é mais velho e mais simples. Na porta 995, com TLS desde o começo:

```
ana@laptop:~$ openssl s_client -connect mail.example.com:995 -crlf -quiet
depth=2 O = Example Trust Services, CN = Example Root CA
verify return:1
depth=1 O = Example Trust Services, CN = Example Issuing CA 1
verify return:1
depth=0 CN = mail.example.com
verify return:1
+OK Dovecot (Ubuntu) ready.
USER ana
+OK
PASS office-2026
+OK Logged in.
STAT
+OK 1 1552
LIST
+OK 1 messages:
1 1552
.
QUIT
+OK Logging out.
```

O `STAT` respondeu `+OK 1 1552`: uma mensagem, 1552 bytes. O POP3 conhece uma caixa e
nenhuma pasta, e o modelo dele é baixar as mensagens e, em geral, apagá-las do servidor (`RETR` e
`DELE`); o `QUIT` é quando as exclusões acontecem.

**Esse modelo é o que dá errado para quem tem dois aparelhos**: o laptop baixa uma mensagem e a remove,
e o celular nunca a vê. Um programa configurado para POP3 costuma ter uma opção de "deixar uma cópia no
servidor", que ameniza isso. Para uma pessoa, o IMAP é quase sempre a melhor escolha. O POP3 ainda cabe
num programa único que recolhe e-mail e o guarda em outro lugar, como um sistema de chamados puxando de
um endereço de suporte.
