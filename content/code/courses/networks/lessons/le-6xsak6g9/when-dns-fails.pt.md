---
title: Quatro jeitos de uma resposta dar errado
version: 1
---

O `status` do cabeçalho é a primeira coisa a ler quando um nome não funciona, porque cada valor aponta
para um lugar diferente.

**NXDOMAIN, o nome não existe.** Um erro de digitação:

```
ana@laptop:~$ dig ww.example.com | grep -E "status|SOA"
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 38652
example.com.            300     IN      SOA     ns1.example.com. hostmaster.example.com. 2026092502 3600 900 1209600 300
```

A linha `SOA` na resposta é a zona dizendo "eu sou `example.com`, e não tenho `ww`". O último número
dela, 300, é quanto tempo um resolver pode guardar a *ausência*: crie o nome um minuto depois e alguns
usuários ainda vão ouvir que ele não existe, por até cinco minutos.

**NOERROR sem resposta, o nome existe sem aquele tipo.** Muitas vezes chamado de NODATA:

```
ana@laptop:~$ dig mail.example.com AAAA | grep -E "status|ANSWER:"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 17568
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
```

`mail.example.com` existe e tem registro `A`; não tem `AAAA`. Não é erro, e um programa simplesmente
usa o endereço IPv4.

**REFUSED, você perguntou ao servidor errado.** O `ns1` responde só pelas próprias zonas e não faz
recursão, então perguntar a ele sobre o domínio de outra pessoa recebe uma recusa:

```
ana@laptop:~$ dig @192.0.2.53 www.example.org | grep -E "status|WARNING"
;; ->>HEADER<<- opcode: QUERY, status: REFUSED, id: 26030
;; WARNING: recursion requested but not available
```

**SERVFAIL, o resolver tentou e não conseguiu uma resposta.** Ele não diz por quê, e o porquê em geral
está no servidor de outra pessoa. Aqui, `old.example.com` foi entregue a um servidor que não responde
por ele, uma **delegação manca** (*lame delegation*):

```
ana@laptop:~$ dig old.example.com | grep -E "status|Query time"
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 57730
;; Query time: 4 msec
ana@laptop:~$ dig @192.0.2.20 old.example.com +norecurse | grep -E "status|flags|IN"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 1139
;; flags: qr; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2
; EDNS: version: 0, flags:; udp: 1232
;old.example.com.               IN      A
example.com.            172800  IN      NS      ns1.example.com.
ns1.example.com.        172800  IN      A       192.0.2.53
```

Perguntado direto, o servidor para o qual `old` foi delegado nem responde à pergunta: ele aponta de
volta para os servidores de `example.com`, que apontaram para ele. O resolver desistiu em 4
milissegundos. Um servidor autoritativo fora do ar também dá SERVFAIL, só que devagar; perguntado
direto, ele fica assim:

```
ana@laptop:~$ dig @192.0.2.53 www.example.com +tries=1 +time=2
;; communications error to 192.0.2.53#53: connection refused

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> @192.0.2.53 www.example.com +tries=1 +time=2
; (1 server found)
;; global options: +cmd
;; no servers could be reached
```

| status | quer dizer | problema de quem |
|---|---|---|
| `NXDOMAIN` | esse nome não existe | um erro de digitação, ou um registro que ninguém criou |
| `NOERROR`, `ANSWER: 0` | o nome não tem registro desse tipo | em geral de ninguém |
| `REFUSED` | este servidor não responde isso | perguntaram ao servidor errado |
| `SERVFAIL` | o resolver não conseguiu resposta | dos servidores de DNS do domínio |
