---
title: Os registros que um domínio guarda
version: 1
---

Um domínio é uma lista de **registros**, e cada um tem um tipo. `dig NOME TIPO` pede um; `+noall
+answer` imprime só as linhas de resposta. Tudo o que `example.com` guarda, um tipo por vez:

```
ana@laptop:~$ dig +noall +answer example.com A
example.com.            3600    IN      A       192.0.2.80
ana@laptop:~$ dig +noall +answer www.example.com AAAA
www.example.com.        300     IN      AAAA    2001:db8:10::80
ana@laptop:~$ dig +noall +answer shop.example.com
shop.example.com.       3600    IN      CNAME   www.example.com.
www.example.com.        300     IN      A       192.0.2.80
ana@laptop:~$ dig +noall +answer example.com MX
example.com.            3600    IN      MX      10 mail.example.com.
ana@laptop:~$ dig +noall +answer example.com TXT
example.com.            3600    IN      TXT     "v=spf1 mx -all"
ana@laptop:~$ dig +noall +answer _dmarc.example.com TXT
_dmarc.example.com.     3600    IN      TXT     "v=DMARC1; p=reject; rua=mailto:dmarc@example.com"
ana@laptop:~$ dig +noall +answer example.com NS
example.com.            3600    IN      NS      ns1.example.com.
ana@laptop:~$ dig +noall +answer example.com SOA
example.com.            3600    IN      SOA     ns1.example.com. hostmaster.example.com. 2026092501 3600 900 1209600 300
ana@laptop:~$ dig +noall +answer -x 192.0.2.80
80.2.0.192.in-addr.arpa. 3600   IN      PTR     www.example.com.
```

| tipo | guarda | usado por |
|---|---|---|
| `A` | um endereço IPv4 | toda conexão com o nome |
| `AAAA` | um endereço IPv6 | o mesmo, por IPv6 |
| `CNAME` | outro nome: "este é um apelido daquele" | `shop` → `www` |
| `MX` | o servidor de e-mail do domínio, com uma prioridade | aula 9 |
| `TXT` | texto livre, usado para regras sobre o domínio | SPF e DMARC, aula 9 |
| `NS` | os servidores que respondem pelo domínio | o resolver, seção 04 |
| `SOA` | o número de série da zona e os temporizadores | servidores secundários, seção 06 |
| `PTR` | o nome de um endereço, no sentido contrário | logs, servidores de e-mail |

Duas coisas nas respostas merecem uma segunda olhada. **Pedir `shop.example.com` devolveu duas
linhas**: o `CNAME` que diz que ele é apelido de `www`, e depois o `A` de `www`. O resolver seguiu o
apelido sozinho. Um `CNAME` não pode ficar ao lado de outros registros com o mesmo nome, e por isso o
domínio puro, `example.com`, tem um `A` próprio em vez de um apelido.

A **consulta reversa**, `-x 192.0.2.80`, pediu um nome sob `in-addr.arpa`, com o endereço escrito de
trás para a frente: `80.2.0.192.in-addr.arpa`. Zonas reversas pertencem a quem é dono do bloco de
endereços, em geral o provedor, e servidores de e-mail as conferem (aula 9).
