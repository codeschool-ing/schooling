---
title: nslookup, e o dig ao lado
version: 1
---

O nslookup faz uma pergunta a um servidor DNS e imprime a resposta, sob um cabeçalho que nomeia **o
servidor que respondeu**. Quatro perguntas do laptop, a última para o endereço para onde o `resolv.conf`
quebrado da aula 21 apontava:

```
ana@laptop:~$ nslookup www.example.com
Server:		192.0.2.53
Address:	192.0.2.53#53

Name:	www.example.com
Address: 192.0.2.80

ana@laptop:~$ nslookup -type=ns example.com
Server:		192.0.2.53
Address:	192.0.2.53#53

example.com	nameserver = ns.example.com.

ana@laptop:~$ nslookup nosuch.example.com
Server:		192.0.2.53
Address:	192.0.2.53#53

** server can't find nosuch.example.com: NXDOMAIN

ana@laptop:~$ nslookup www.example.com 192.0.2.54
;; communications error to 192.0.2.54#53: timed out
;; communications error to 192.0.2.54#53: timed out
;; communications error to 192.0.2.54#53: timed out
;; no servers could be reached

```

Leia o cabeçalho primeiro. `Server: 192.0.2.53` é o `ns`, e `#53` é a porta. A falha de DNS mais comum
é perguntar ao servidor errado, que foi o que a aula 21 encontrou, e **o cabeçalho diz a quem se
perguntou antes de a resposta dizer qualquer coisa**. `-type=ns` pede outro tipo de registro, aqui os
servidores de nome de `example.com`.

As duas últimas respostas são falhas, e são opostas. **NXDOMAIN é uma resposta**: o servidor foi
alcançado, procurou e diz que o nome não existe. Isso é um fato sobre os dados do DNS, e a correção é um
registro. Três timeouts e `no servers could be reached` são **nenhuma resposta**: nada respondeu de
`192.0.2.54`, então nada se sabe sobre o nome. Isso é um fato sobre o caminho até o DNS ou sobre a
configuração que escolheu o servidor. Um usuário descreve as duas do mesmo jeito, "o site não existe", e
por isso as palavras na tela importam mais que o chamado.

O nslookup existe em todo sistema, Windows incluído, e basta para perguntar em que um nome resolve. **O
dig é a ferramenta para perguntar por quê**, porque imprime a mensagem DNS inteira: o status, as flags,
as seções e o TTL de cada registro. Nenhuma das quatro perguntas acima foi feita ao dig aqui; a aula 21 o
usou, e as duas escrevem as mesmas perguntas assim:

| a pergunta | nslookup | dig |
|---|---|---|
| o endereço de um nome | `nslookup www.example.com` | `dig www.example.com`, ou `+short` só para o endereço |
| a um servidor escolhido | `nslookup www.example.com 192.0.2.53` | `dig @192.0.2.53 www.example.com` |
| outro tipo de registro | `nslookup -type=ns example.com` | `dig ns example.com` |
| veio alguma resposta? | `no servers could be reached` | nenhuma linha `status:`, como na aula 21 |
