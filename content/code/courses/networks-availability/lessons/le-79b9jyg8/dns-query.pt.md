---
title: Uma consulta DNS e a resposta
version: 1
---

Uma consulta DNS é a menor conversa completa numa rede: **um pacote UDP de ida, um de volta, e nada
para abrir ou fechar.** A aula 4 de `networks` explicou o que ela pergunta. Aqui ela está no fio.

O laptop consultou um nome que existe e um que não existe, enquanto uma captura imprimia cinco campos
de cada pacote DNS: o id da transação, se é uma resposta, o código de resposta, o nome consultado e o
endereço na resposta.

```
ana@laptop:~$ dig +short www.example.com; dig +short nosuch.example.com
192.0.2.80
ana@laptop:~$ tshark -n -i eth0 -c 4 -f "udp port 53" -T fields -e dns.id -e dns.flags.response -e dns.flags.rcode -e dns.qry.name -e dns.a
Capturing on 'eth0'
4 packets captured
0x301b	False		www.example.com	
0x301b	True	0	www.example.com	192.0.2.80
0x26af	False		nosuch.example.com	
0x26af	True	3	nosuch.example.com	
```

O `dig +short` imprimiu um endereço para `www.example.com` e nada para `nosuch.example.com`, e uma linha
vazia é um jeito ruim de descobrir o motivo. A captura diz com todas as letras.

**O id da transação casa cada resposta com a sua consulta.** `0x301b` perguntou por `www` e `0x301b`
respondeu, com código de resposta 0 e o endereço `192.0.2.80`. `0x26af` perguntou por `nosuch` e
recebeu o código 3, que é NXDOMAIN, "nome inexistente", e nenhum endereço. O UDP não tem conexão para
manter pergunta e resposta juntas, então é o id que faz isso, e uma resposta cujo id não corresponde a
nenhuma consulta pendente é jogada fora pelo cliente.

Para uma resposta inteira, `-O dns` imprime a camada DNS completa. O mesmo nome inexistente foi
consultado mais uma vez para isso, então o id é novo:

```
ana@laptop:~$ tshark -n -i eth0 -c 2 -f "udp port 53" -O dns 2>/dev/null | sed -n "/^Frame 2/,/Authority RRs/p"
Frame 2: 167 bytes on wire (1336 bits), 167 bytes captured (1336 bits) on interface eth0, id 0
Ethernet II, Src: 52:54:00:a8:0a:01, Dst: 52:54:00:a8:0a:14
Internet Protocol Version 4, Src: 192.0.2.53, Dst: 192.168.10.20
User Datagram Protocol, Src Port: 53, Dst Port: 38734
Domain Name System (response)
    Transaction ID: 0xbd0d
    Flags: 0x8583 Standard query response, No such name
        1... .... .... .... = Response: Message is a response
        .000 0... .... .... = Opcode: Standard query (0)
        .... .1.. .... .... = Authoritative: Server is an authority for domain
        .... ..0. .... .... = Truncated: Message is not truncated
        .... ...1 .... .... = Recursion desired: Do query recursively
        .... .... 1... .... = Recursion available: Server can do recursive queries
        .... .... .0.. .... = Z: reserved (0)
        .... .... ..0. .... = Answer authenticated: Answer/authority portion was not authenticated by the server
        .... .... ...0 .... = Non-authenticated data: Unacceptable
        .... .... .... 0011 = Reply code: No such name (3)
    Questions: 1
    Answer RRs: 0
    Authority RRs: 1
```

O campo de flags tem dezesseis bits, e o `tshark` os põe um por linha. **Esta resposta é autoritativa,
`.1..`: veio de `ns`, o servidor que guarda `example.com`**, e não de um cache repetindo o que outro
disse. O laptop pediu recursão e o servidor a oferece. Os últimos quatro bits são o código de resposta,
`0011`, 3, No such name. A seção de respostas está vazia e a de autoridade tem um registro, o SOA da
zona, que diz aos resolvedores por quanto tempo podem lembrar que o nome não existe; a captura da aula
11 o mostrou como `SOA ns.example.com`.

Duas linhas no topo merecem uma segunda olhada. A origem IP é `192.0.2.53`, o servidor DNS no data
center. A origem Ethernet é `52:54:00:a8:0a:01`, que no esquema deste laboratório é o MAC de
`192.168.10.1`, o roteador do escritório. **Os endereços IP dizem quem conversou; os endereços MAC
dizem só o último salto**, e são reescritos a cada roteador do caminho.
