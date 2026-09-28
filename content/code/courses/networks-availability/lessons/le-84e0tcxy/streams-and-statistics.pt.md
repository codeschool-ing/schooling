---
title: Seguir um fluxo, e contar
version: 1
---

Uma lista de pacotes é o formato errado para a maioria das perguntas. "O que o cliente pediu e o que o
servidor respondeu" é uma conversa, e o Wireshark a remonta: **Follow TCP Stream** no menu da janela,
`-z follow` no `tshark`.

```
ana@mon:~$ tshark -r files.pcap -q -z follow,tcp,ascii,0

===================================================================
Follow: tcp,ascii
Filter: tcp.stream eq 0
Node 0: 192.168.10.10:59928
Node 1: 192.0.2.21:80
73
GET / HTTP/1.1
Host: 192.0.2.21
User-Agent: curl/8.5.0
Accept: */*


	243
HTTP/1.1 200 OK
Server: nginx
Date: Mon, 28 Sep 2026 21:09:39 GMT
Content-Type: text/html
Content-Length: 15
Last-Modified: Mon, 28 Sep 2026 21:09:30 GMT
Connection: keep-alive
ETag: "6abad78a-f"
Accept-Ranges: bytes

served by web1

===================================================================
```

O stream 0 é a primeira conexão TCP do arquivo, quadros 1 a 10. O `tshark` pôs os bytes dos dois
sentidos de volta em ordem: 73 vindos de `192.168.10.10:59928`, depois os 243 da resposta, marcados
com um tab antes da contagem, terminando na própria página, `served by web1`. **Isso é tudo o que o
HTTP simples sempre foi no fio**: cabeçalhos e corpo em texto claro, legíveis por quem conseguir copiar os pacotes. Depois da seção sobre portas espelho, isso quer dizer qualquer um que consiga
mudar a configuração de um switch. O mesmo comando na conexão HTTPS não foi rodado aqui; ele mostraria
registros de bytes que não significam nada sem as chaves da sessão.

Num arquivo com milhares de pacotes, a primeira pergunta costuma ser quem falou com quem, e quanto,
antes de qualquer pacote isolado. Duas estatísticas respondem:

```
ana@mon:~$ tshark -r files.pcap -q -z conv,ip
================================================================================
IPv4 Conversations
Filter:<No Filter>
                                               |       <-      | |       ->      | |     Total     |    Relative    |   Duration   |
                                               | Frames  Bytes | | Frames  Bytes | | Frames  Bytes |      Start     |              |
192.168.10.10        <-> 192.0.2.21                12 3265 bytes      15 1800 bytes      27 5065 bytes     0.000000000         1.0975
192.168.10.10        <-> 192.0.2.23                 4 566 bytes       6 489 bytes      10 1055 bytes     1.104894905         0.0008
192.168.10.10        <-> 192.0.2.53                 2 297 bytes       2 199 bytes       4 496 bytes     0.008987287         0.0196
192.168.10.10        <-> 192.0.2.22                 2 196 bytes       2 196 bytes       4 392 bytes     0.041952556         1.0204
================================================================================
ana@mon:~$ tshark -r files.pcap -q -z io,phs

===================================================================
Protocol Hierarchy Statistics
Filter: 

eth                                      frames:45 bytes:7008
  ip                                     frames:45 bytes:7008
    tcp                                  frames:37 bytes:6120
      http                               frames:4 bytes:959
        data-text-lines                  frames:2 bytes:669
      tls                                frames:8 bytes:3463
    udp                                  frames:4 bytes:496
      dns                                frames:4 bytes:496
    icmp                                 frames:4 bytes:392
===================================================================
```

A tabela de conversas tem uma linha por par de endereços. `web1` vem primeiro, com 27 quadros e 5065
bytes, porque serviu tanto a página quanto a requisição HTTPS. As setas se leem a partir do primeiro
endereço: `files` mandou 15 quadros, 1800 bytes, e recebeu 12 quadros, 3265 bytes. **Um cliente que
recebe mais do que manda é o formato normal de quem navega**, e uma máquina que de repente manda muito
mais do que recebe é uma das primeiras coisas que um analista olha.

A hierarquia de protocolos diz o mesmo arquivo de outro jeito. Dos 45 quadros, 37 eram TCP, e só 4
deles levavam HTTP e 8 levavam TLS; o resto eram os pacotes que abrem, confirmam e fecham conexões.
**Numa rede de verdade é aqui que o protocolo inesperado aparece primeiro**, uma linha que nem deveria
estar ali, antes que alguém pense em filtrar por ela.
