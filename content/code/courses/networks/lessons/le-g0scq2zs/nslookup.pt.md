---
title: nslookup, o que está em todo sistema
version: 1
---

O `dig` é a ferramenta melhor e nem sempre está lá. **O `nslookup` existe no Windows, no macOS e no
Linux igualmente**, então é o que se usa no computador dos outros:

```
ana@laptop:~$ nslookup www.example.com
Server:         198.51.100.53
Address:        198.51.100.53#53

Non-authoritative answer:
Name:   www.example.com
Address: 192.0.2.80
Name:   www.example.com
Address: 2001:db8:10::80

ana@laptop:~$ nslookup -type=mx example.net
Server:         198.51.100.53
Address:        198.51.100.53#53

Non-authoritative answer:
example.net     mail exchanger = 10 mail.example.net.

Authoritative answers can be found from:

ana@laptop:~$ nslookup 192.0.2.80
80.2.0.192.in-addr.arpa name = www.example.com.

Authoritative answers can be found from:
```

As duas primeiras linhas são o servidor que respondeu, o equivalente da linha `SERVER:` do `dig`.
`Non-authoritative answer` quer dizer que a resposta veio de um resolvedor e não do servidor do próprio
domínio, o que é normal. `www.example.com` tem dois endereços, IPv4 e IPv6, e o nslookup pede os dois se
ninguém disser outra coisa. `-type=mx` pede os servidores de e-mail, como na aula 9, e um endereço
sozinho é consultado ao contrário, na zona `in-addr.arpa` da aula 4.

`nslookup www.example.com 198.51.100.53` pergunta a um servidor específico, como o `dig @`. O que o
nslookup não mostra é o TTL e as flags, o `aa` entre elas, então para qualquer coisa além de "para onde
este nome resolve", a ferramenta é o `dig`.
