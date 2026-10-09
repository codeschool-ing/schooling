---
title: Gravando a captura num arquivo
version: 1
---

Ler linhas enquanto elas rolam funciona para quatro pacotes. Para o resto, **o `tcpdump` grava um
arquivo pcap, e a leitura acontece depois**, no servidor ou na máquina de outra pessoa. O laptop fez
quatro requisições, três da página inicial e uma de uma página que não existe. Comece a captura em
`web1`, depois digite isto em `laptop`:

```sh
for i in 1 2 3; do curl -s http://192.0.2.21/ >/dev/null; done; curl -s http://192.0.2.21/missing >/dev/null
```

```
ana@web1:~$ sudo tcpdump -n -i eth0 -c 40 -Z ana -w web1.pcap tcp port 80
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
40 packets captured
40 packets received by filter
0 packets dropped by kernel
ana@web1:~$ ls -l web1.pcap
-rw-r--r-- 1 ana ana 4690 Sep 28 18:10 web1.pcap
```

`-w web1.pcap` grava os pacotes em vez de imprimi-los, e `-c 40` para em quarenta. **`-Z ana` é a flag
que mais importa**: o `tcpdump` abre a interface como root, depois abre mão do root e vira `ana` antes
de gravar um byte. O arquivo é dela, e o programa que passou o tempo interpretando o que a rede mandou
não roda mais como root.

O arquivo foi criado `-rw-r--r--`, **legível por qualquer conta do servidor**. O `tshark` deixou o
arquivo dele legível só pelo dono; o `tcpdump` aqui não, e uma captura guarda tudo o que passou pelo
fio. Num servidor em que outras pessoas entram, um `chmod 600 web1.pcap` logo depois, ou um `umask 077`
antes, faz parte de tirar a captura.

O `capinfos`, que vem com o Wireshark, descreve um arquivo sem abrir os pacotes:

```
ana@web1:~$ capinfos web1.pcap
File name:           web1.pcap
File type:           Wireshark/tcpdump/... - pcap
File encapsulation:  Ethernet
File timestamp precision:  microseconds (6)
Packet size limit:   file hdr: 262144 bytes
Number of packets:   40
File size:           4690 bytes
Data size:           4026 bytes
Capture duration:    0.018971 seconds
First packet time:   2026-09-28 18:10:03.429832
Last packet time:    2026-09-28 18:10:03.448803
Data byte rate:      212 kBps
Data bit rate:       1697 kbps
Average packet size: 100.65 bytes
Average packet rate: 2108 packets/s
SHA256:              91afae27f69e71b0e5364189b07c2edee3d536762a4ed0cf92970339487ae63f
SHA1:                fe4e7f425596642253896c5a280b63c66bf04646
Strict time order:   True
Number of interfaces in file: 1
Interface #0 info:
                     Encapsulation = Ethernet (1 - ether)
                     Capture length = 262144
                     Time precision = microseconds (6)
                     Time ticks per second = 1000000
```

Quarenta pacotes, capturados em 0.018971 segundo, entre dois horários gravados com microssegundos.
**`File size` tem 664 bytes a mais que `Data size`**, e isso é o próprio formato pcap. Ele põe um cabeçalho de 24 bytes no início do arquivo, e 16 bytes na frente de cada pacote registrando quando ele chegou e qual era o tamanho: 24 + 40 × 16 = 664. `Packet size limit: 262144` é o snap length, quanto de cada pacote
foi guardado, e a seção sobre snap length o diminui de propósito.

**Os dois hashes são para depois.** Quem receber este arquivo pode rodar o `capinfos` na própria cópia
e comparar o `SHA256`; a mesma linha quer dizer os mesmos bytes, e nada se perdeu nem foi editado no
caminho.
