---
title: Lendo e-mail com IMAP
version: 1
---

O Bruno respondeu. A resposta dele fez o caminho inverso, para o que o MX do `example.com` indicar:

```
ana@laptop:~$ dig +short MX example.com
10 mail.example.com.
```

A Ana lê a caixa dela a partir do laptop com **IMAP**, na porta 993, onde o TLS começa na hora. À mão,
pelo `openssl s_client`:

```
ana@laptop:~$ openssl s_client -connect mail.example.com:993 -crlf -quiet
depth=2 O = Example Trust Services, CN = Example Root CA
verify return:1
depth=1 O = Example Trust Services, CN = Example Issuing CA 1
verify return:1
depth=0 CN = mail.example.com
verify return:1
* OK [CAPABILITY IMAP4rev1 SASL-IR LOGIN-REFERRALS ID ENABLE IDLE LITERAL+ AUTH=PLAIN AUTH=LOGIN] Dovecot (Ubuntu) ready.
a1 LOGIN ana office-2026
a1 OK [CAPABILITY IMAP4rev1 SASL-IR LOGIN-REFERRALS ID ENABLE IDLE SORT SORT=DISPLAY THREAD=REFERENCES THREAD=REFS THREAD=ORDEREDSUBJECT MULTIAPPEND URL-PARTIAL CATENATE UNSELECT CHILDREN NAMESPACE UIDPLUS LIST-EXTENDED I18NLEVEL=1 CONDSTORE QRESYNC ESEARCH ESORT SEARCHRES WITHIN CONTEXT=SEARCH LIST-STATUS BINARY MOVE SNIPPET=FUZZY PREVIEW=FUZZY PREVIEW STATUS=SIZE SAVEDATE LITERAL+ NOTIFY] Logged in
a2 SELECT INBOX
* FLAGS (\Answered \Flagged \Deleted \Seen \Draft)
* OK [PERMANENTFLAGS (\Answered \Flagged \Deleted \Seen \Draft \*)] Flags permitted.
* 1 EXISTS
* 1 RECENT
* OK [UNSEEN 1] First unseen.
* OK [UIDVALIDITY 1790362002] UIDs valid
* OK [UIDNEXT 2] Predicted next UID
a2 OK [READ-WRITE] Select completed (0.003 + 0.000 + 0.002 secs).
a3 FETCH 1 (BODY[HEADER.FIELDS (FROM SUBJECT DATE)])
* 1 FETCH (FLAGS (\Seen \Recent) BODY[HEADER.FIELDS (FROM SUBJECT DATE)] {99}
Date: Fri, 25 Sep 2026 10:15:00 -0300
From: Bruno <bruno@example.net>
Subject: Re: Order 2231

)
a3 OK Fetch completed (0.001 + 0.000 secs).
a4 FETCH 1 BODY[TEXT]
* 1 FETCH (BODY[TEXT] {32}
Confirmed, it ships on Monday.
)
a4 OK Fetch completed (0.001 + 0.000 secs).
a5 LOGOUT
* BYE Logging out
a5 OK Logout completed (0.001 + 0.000 secs).
```

Todo comando IMAP começa com uma **etiqueta** (*tag*) escolhida pelo cliente, `a1` a `a5`, e a resposta
final do servidor repete a etiqueta, então um programa pode mandar vários de uma vez e casar as
respostas. O `SELECT INBOX` abriu a caixa e disse o que havia nela: `1 EXISTS`, uma mensagem. O `FETCH`
leu os cabeçalhos pedidos, e depois o texto.

**Com IMAP o e-mail fica no servidor.** O programa mostra uma cópia e a mantém em sincronia: lida no
celular, aparece como lida no laptop, porque a marca `\Seen` da resposta do `FETCH` fica guardada no
servidor. É por isso que o IMAP é o padrão para quem tem mais de um aparelho.
