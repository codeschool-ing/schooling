---
title: Protocolos que mandam a senha como foi digitada
version: 1
---

**FTP, Telnet, HTTP, POP3, IMAP, SMTP e LDAP foram todos projetados para mandar tudo, inclusive
credenciais, como texto legível.** Eles são anteriores às ameaças da internet pública, e cada um
ganhou uma versão cifrada desde então. Os antigos ainda são encontrados rodando, em geral porque
alguma coisa depende deles e ninguém os desligou.

## FTP, como o servidor o recebe

O servidor de arquivos da Vereda ainda oferece FTP na porta 2121 para uma ferramenta de agendamento
antiga. O `curl -v` imprime os comandos que manda, que são exatamente os bytes que atravessam a rede:

```
ana@lab:~/lab$ curl -sv --user scheduler:V-db-s3cret-2026 ftp://files.vereda.example:2121/NOTES.txt 2>&1 | grep -E '^[<>] (USER|PASS|RETR|230)|^Vereda'
> USER scheduler
> PASS V-db-s3cret-2026
< 230 Login successful.
> RETR NOTES.txt
Vereda portal 2.4.1: booking reminders by SMS.
```

`USER` e `PASS` levam o nome da conta e a senha como foram digitados, e o arquivo também vem em texto
claro. Qualquer um no caminho, um switch comprometido, uma rede Wi-Fi compartilhada, uma porta de
espelhamento mal configurada, lê os dois sem quebrar nada. Não há criptografia a derrotar.

## Pedindo uma cifragem que o servidor não consegue dar

Um cliente pode insistir na cifragem. Com `--ssl-reqd`, o curl primeiro pede ao servidor para passar
para TLS, que é como o **FTPS** funciona, e se recusa a continuar quando o servidor não consegue:

```
ana@lab:~/lab$ curl -sv --ssl-reqd --user scheduler:V-db-s3cret-2026 ftp://files.vereda.example:2121/NOTES.txt 2>&1 | grep -E '^[<>] (AUTH|USER|PASS|5)|^curl:'; echo "exit status ${PIPESTATUS[0]}"
> AUTH SSL
< 500 Command "AUTH" not understood.
> AUTH TLS
< 500 Command "AUTH" not understood.
exit status 64
```

O servidor responde `500` tanto ao `AUTH SSL` quanto ao `AUTH TLS`, então o curl para com código de
saída 64 **antes** de mandar `USER` ou `PASS`. Essa ordem é o sentido todo do `--ssl-reqd`: um
cliente que só *prefere* cifragem teria voltado ao FTP simples e mandado a senha mesmo assim, que é
o problema de rebaixamento da seção 04.

## Os pares a conhecer

| protocolo simples | porta | substituto cifrado | porta |
|---|---|---|---|
| FTP | 21 | **SFTP** (transferência de arquivos sobre SSH), ou FTPS (FTP sobre TLS) | 22, ou 990 / 21 |
| Telnet | 23 | **SSH** | 22 |
| HTTP | 80 | **HTTPS** | 443 |
| LDAP | 389 | **LDAPS**, ou LDAP com StartTLS | 636, ou 389 |
| SMTP de envio | 25, 587 | SMTP com STARTTLS, ou TLS implícito | 587, 465 |
| IMAP, POP3 | 143, 110 | IMAPS, POP3S | 993, 995 |

O inseguro não deveria simplesmente estar **disponível ao lado** do seguro: ele deveria estar
**desligado**, ou se recusar a autenticar, como faz o servidor LDAP no fim desta aula. Um servidor
que oferece os dois deixa todo cliente a uma configuração errada da versão simples.
