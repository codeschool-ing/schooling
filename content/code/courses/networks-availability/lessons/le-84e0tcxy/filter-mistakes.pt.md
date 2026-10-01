---
title: Quando um filtro surpreende
version: 1
---

O erro mais comum é também o único que é pego: um filtro de captura digitado onde se esperava um
filtro de exibição.

```
ana@mon:~$ tshark -r files.pcap -Y "port 80"
tshark: "80" was unexpected in this context.
    port 80
         ^~
  Note: That read filter code looks like a valid capture filter;
        maybe you mixed them up?
```

`port 80` é BPF válido e não quer dizer nada para o filtro de exibição, que quer um campo:
`tcp.port == 80`. **A mensagem de erro já diz a causa provável**, e na janela a barra fica vermelha
antes de se apertar Enter, então esse custa segundos.

O segundo não produz erro nenhum. Todo pacote IP leva dois endereços, `ip.src` e `ip.dst`, e
`ip.addr` corresponde a qualquer um deles. Então o que `ip.addr != 192.0.2.21` deveria querer dizer:
que algum endereço do pacote é diferente, ou que nenhum endereço é igual? As duas leituras escolhem
pacotes bem diferentes, e o arquivo foi consultado das duas formas:

```
ana@mon:~$ tshark -r files.pcap -Y "ip.addr != 192.0.2.21" | wc -l
18
ana@mon:~$ tshark -r files.pcap -Y "!(ip.addr == 192.0.2.21)" | wc -l
18
```

**Na versão gravada aqui as duas deram os mesmos 18 pacotes**, então `!=` quer dizer "nenhum endereço
é igual", exatamente `!(ip.addr == 192.0.2.21)`. A conta fecha: o arquivo tinha 45 pacotes, e as
estatísticas de conversa da próxima seção contam 27 deles de ou para `192.0.2.21`. Versões antigas do
Wireshark liam `!=` do outro jeito, como "algum endereço é diferente", o que vale para quase todo
pacote, porque um pacote para `192.0.2.21` tem uma origem que é outra. Guias daquela época mandam
digitar `!(ip.addr == …)`, e **essa forma quer dizer o mesmo em qualquer versão**, então é ela que vale
a pena guardar nos dedos.

Mais dois, e os dois encontraram o que procuravam:

```
ana@mon:~$ tshark -r files.pcap -Y "dns.qry.name == www.example.com" | head -n 2
   11 0.008987287 192.168.10.10 → 192.0.2.53   DNS 98 Standard query 0x9ce1 A www.example.com OPT
   12 0.009225585   192.0.2.53 → 192.168.10.10 DNS 130 Standard query response 0x9ce1 A www.example.com A 192.0.2.80 OPT
ana@mon:~$ tshark -r files.pcap -Y "http.request.uri contains \"nothing\""
   39 1.105093152 192.168.10.10 → 192.0.2.23   HTTP 151 GET /nothing-here HTTP/1.1 
```

Um nome comparado com `==` precisa bater inteiro, e achou a consulta no quadro 11 e a resposta no
quadro 12. **`contains` procura um pedaço de um campo**, e achou a requisição de `/nothing-here` por
uma palavra do caminho. As barras invertidas são do shell: o filtro inteiro está entre aspas duplas
para o `bash`, então as aspas em volta do texto dentro dele vão escapadas. Na janela, sem shell no
meio, ele é digitado como `http.request.uri contains "nothing"`.

Um filtro de captura erra de um jeito ainda mais quieto, porque um filtro válido que não seleciona
nada não grava nada, e uma captura vazia se lê exatamente como "o tráfego nunca aconteceu". A captura
do laptop na primeira seção era um filtro correto no lugar errado, e pegou um pedido ARP. **Antes de
concluir que algo não foi enviado, confira se a captura poderia tê-lo visto**: a interface certa, a
porta certa do switch e um filtro testado uma vez em tráfego que você sabe que existe.
