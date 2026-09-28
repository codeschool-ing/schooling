---
title: Wireshark sem janela
version: 1
---

**Não há tela neste laboratório, então toda captura desta aula é feita com o `tshark`.** Isso muda
menos do que parece. O `tshark` é o Wireshark com um terminal na frente: os mesmos dissectors
decodificam cada pacote, as mesmas duas linguagens de filtro escolhem o que guardar e o que mostrar, e
um arquivo salvo por um abre no outro. Onde esta aula digita `-f "tcp port 80"`, a janela tem a caixa
do filtro de captura; onde digita `-Y "http.request"`, a janela tem a barra do filtro de exibição acima
da lista de pacotes. As palavras digitadas nelas são idênticas.

A primeira coisa a verificar é quem está capturando:

```
ana@mon:~$ id -nG; tshark -D
ana wireshark
1. eth0
2. any
3. lo (Loopback)
4. bluetooth-monitor
5. nflog
6. nfqueue
7. dbus-system
8. dbus-session
9. ciscodump (Cisco remote capture)
10. dpauxmon (DisplayPort AUX channel monitor capture)
11. randpkt (Random packet generator)
12. sdjournal (systemd Journal Export)
13. sshdump (SSH remote capture)
14. udpdump (UDP Listener remote capture)
15. wifidump (Wi-Fi remote capture)
```

`ana` está no grupo `wireshark`, e é por isso que nenhum comando desta aula começa com `sudo`.
**Capturar exige um privilégio, e decodificar um pacote não.** Então o pacote do Ubuntu dá o
privilégio ao pequeno auxiliar que abre a interface e deixa os membros de um grupo rodá-lo. Os
dissectors, o código que interpreta o que um estranho resolveu mandar, rodam como `ana`. Rodar o
Wireshark inteiro como root, para não ter de pôr alguém num grupo, deixa todo esse código ao alcance
dos pacotes que ele está lendo.

`tshark -D` lista onde dá para capturar: `eth0`, a pseudo-interface `any`, que escuta em todas as
interfaces ao mesmo tempo, e extras que o pacote traz, de Bluetooth a captura remota por SSH. Em `mon`
só a `eth0` leva alguma coisa.

## Salvar primeiro, olhar depois

O hábito que compensa é **gravar a captura num arquivo e analisar o arquivo**, em vez de ler uma tela
rolando. `mon` capturou por oito segundos enquanto `files` fazia uma manhã de trabalho em miniatura:
uma página web, duas consultas DNS, um ping, uma requisição HTTPS e uma página que não existe.

```
ana@mon:~$ tshark -n -q -i eth0 -f "not arp" -a duration:8 -w files.pcap
Capturing on 'eth0'
45 packets captured
ana@mon:~$ ls -l files.pcap
-rw------- 1 ana ana 8904 Sep 28 18:09 files.pcap
ana@mon:~$ tshark -r files.pcap | head -n 12
    1 0.000000000 192.168.10.10 → 192.0.2.21   TCP 74 59928 → 80 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3641093702 TSecr=0 WS=1024
    2 0.000062359   192.0.2.21 → 192.168.10.10 TCP 74 80 → 59928 [SYN, ACK] Seq=0 Ack=1 Win=65160 Len=0 MSS=1460 SACK_PERM TSval=82424114 TSecr=3641093702 WS=1024
    3 0.000077303 192.168.10.10 → 192.0.2.21   TCP 66 59928 → 80 [ACK] Seq=1 Ack=1 Win=64512 Len=0 TSval=3641093702 TSecr=82424114
    4 0.000137514 192.168.10.10 → 192.0.2.21   HTTP 139 GET / HTTP/1.1 
    5 0.000150015   192.0.2.21 → 192.168.10.10 TCP 66 80 → 59928 [ACK] Seq=1 Ack=74 Win=65536 Len=0 TSval=82424114 TSecr=3641093702
    6 0.000308278   192.0.2.21 → 192.168.10.10 HTTP 309 HTTP/1.1 200 OK  (text/html)
    7 0.000337410 192.168.10.10 → 192.0.2.21   TCP 66 59928 → 80 [ACK] Seq=74 Ack=244 Win=64512 Len=0 TSval=3641093703 TSecr=82424115
    8 0.000454293 192.168.10.10 → 192.0.2.21   TCP 66 59928 → 80 [FIN, ACK] Seq=74 Ack=244 Win=64512 Len=0 TSval=3641093703 TSecr=82424115
    9 0.000520927   192.0.2.21 → 192.168.10.10 TCP 66 80 → 59928 [FIN, ACK] Seq=244 Ack=75 Win=65536 Len=0 TSval=82424115 TSecr=3641093703
   10 0.000534840 192.168.10.10 → 192.0.2.21   TCP 66 59928 → 80 [ACK] Seq=75 Ack=245 Win=64512 Len=0 TSval=3641093703 TSecr=82424115
   11 0.008987287 192.168.10.10 → 192.0.2.53   DNS 98 Standard query 0x9ce1 A www.example.com OPT
   12 0.009225585   192.0.2.53 → 192.168.10.10 DNS 130 Standard query response 0x9ce1 A www.example.com A 192.0.2.80 OPT
```

`-w files.pcap` grava cada pacote no arquivo em vez de imprimi-lo, `-q` deixa a tela quieta a não ser
pela contagem, e `-a duration:8` para depois de oito segundos. **45 pacotes em 8904 bytes**, e o
arquivo foi criado com modo `-rw-------`, legível por `ana` e por mais ninguém. Um arquivo de captura
guarda tudo o que passou pelo fio, então esse é o padrão certo, e a aula 12 volta a ele.

Lido de volta com `-r`, ele imprime uma linha por pacote, nas colunas que a janela mostra: o número do
quadro, os segundos desde o primeiro pacote, origem e destino, o protocolo que o Wireshark concluiu
que era, o tamanho no fio e um resumo. **Todo tempo deste laboratório é um computador falando consigo
mesmo**, então a página inteira, quadros 1 a 10, levou menos de um milissegundo. Numa rede de verdade,
o intervalo entre o quadro 1 e o quadro 2 é a ida e volta até o servidor, e muitas vezes é o primeiro
número que vale a pena ler.
