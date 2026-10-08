---
title: tshark, e o Wireshark
version: 1
---

O **Wireshark** é o analisador de pacotes gráfico que quase todo analista usa: uma lista de pacotes, o
selecionado decodificado camada por camada, e os bytes dele. **Ele não foi rodado nesta aula**, porque o
laboratório não tem tela. A metade de linha de comando dele, o **tshark**, usa os mesmos decodificadores, chamados
**dissectors**, e os mesmos filtros; a aula 1 o instalou. Tudo abaixo pode ser feito nos menus do Wireshark, e o
menu vai indicado ao lado de cada comando.

A primeira pergunta sobre qualquer captura é **quem falou com quem**. As estatísticas do tshark respondem sem
listar um único pacote (Wireshark: *Statistics, Conversations*):

```
ana@soc:~$ tshark -r web.pcap -q -z conv,tcp
================================================================================
TCP Conversations
Filter:<No Filter>
                                                           |       <-      | |       ->      | |     Total     |    Relative    |   Duration   |
                                                           | Frames  Bytes | | Frames  Bytes | | Frames  Bytes |      Start     |              |
192.168.20.10:50542        <-> 203.0.113.200:8080               9 50 kB          11 829 bytes      20 51 kB         0.000000000         0.0045
================================================================================
```

Uma conversa TCP, entre o `files` na porta 50542 e a 8080 do servidor: 11 quadros, 829 bytes numa direção, e 9
quadros, 50 kB na outra, em 4,5 milissegundos. Leia as setas nos títulos das colunas: a direção grande é em direção
ao `files`. **A direção dos bytes é a primeira coisa a conferir** quando a pergunta é se dados saíram: os 612 MB da
quinta foram do `files` para fora, este download vem para dentro.

Depois, o conteúdo da conversa, como HTTP. `-Y` recebe um **filtro de exibição**, a linguagem do próprio
Wireshark, que é diferente do filtro de captura: não decide o que é guardado, só o que é mostrado, e pode citar
qualquer campo que um dissector conheça. `-T fields` imprime os campos escolhidos, um pacote por linha:

```
ana@soc:~$ tshark -r web.pcap -Y http -T fields -e frame.number -e ip.src -e ip.dst -e http.request.method -e http.request.uri -e http.response.code -e http.content_length
4	192.168.20.10	203.0.113.200	GET	/price-list.csv		
16	203.0.113.200	192.168.20.10			200	49524
```

O quadro 4 é a requisição: `GET /price-list.csv`. O quadro 16 é a resposta: `200`, e um `Content-Length` de
`49524`. Filtros de exibição valem ser aprendidos pelos nomes de campo: `http.request.method == "POST"`, `ip.addr
== 203.0.113.200`, `tcp.flags.syn == 1 and tcp.flags.ack == 0` só para conexões novas. O Wireshark mostra o nome
do campo de qualquer coisa em que você clica, no rodapé da janela.
