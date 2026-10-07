---
title: Um login, quatro registros
version: 1
---

Hora de produzir evidência. A `ana` precisa de uma chave para entrar; ela cria uma no `soc` e a autoriza
para a própria conta:

```
ana@soc:~$ ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519
ana@soc:~$ cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys
```

As máquinas do laboratório compartilham o disco e as contas deste computador, coisa que uma rede de
verdade não faria, então essa mesma chave funciona no `gw`. Depois ela entra no `gw` como entraria alguém
na internet: o comando roda dentro do `outside`, como `ana`, e pergunta ao `gw` o nome dele. Enquanto
rodava, o `tcpdump` gravava o lado da internet do `fw` em `one.pcap`; o root do laboratório o iniciou
antes com `ip netns exec fw tcpdump -U -i eth0 -w one.pcap tcp port 22 &` e o parou depois.

```
root@soc:~# ip netns exec outside runuser -u ana -- ssh -o StrictHostKeyChecking=accept-new ana@198.51.100.22 hostname
Warning: Permanently added '198.51.100.22' (ED25519) to the list of known hosts.
gw
```

Esse único login agora está em quatro lugares. Primeiro, no **log do próprio host**, escrito pelo `sshd`
do `gw`:

```
root@soc:~# cat /var/log/soclab/gw-auth.log
2026-10-07T04:24:40-0300 gw sshd: Server listening on 198.51.100.22 port 22.
2026-10-07T04:24:43-0300 gw sshd: Accepted publickey for ana from 203.0.113.66 port 33586 ssh2: ED25519 SHA256:wH5OyvHWekSstXkiQV4wCGLaBYWHvDNfxKaFcEdIdKs
2026-10-07T04:24:43-0300 gw sshd: Received disconnect from 203.0.113.66 port 33586:11: disconnected by user
2026-10-07T04:24:43-0300 gw sshd: Disconnected from user ana 203.0.113.66 port 33586
```

Ele diz a conta, o método (`publickey`), a impressão digital da chave e o endereço e a porta de onde
veio a conexão. Segundo, no **firewall**, que registrou o primeiro pacote da conexão nova ao encaminhá-lo:

```
root@soc:~# cat /var/log/soclab/fw.log
Oct  7 04:24:43 fw fw-new  IN=eth0 OUT=eth1 MAC=d6:32:9e:91:b7:8a:4e:52:5a:70:5f:25:08:00 SRC=203.0.113.66 DST=198.51.100.22 LEN=60 TOS=10 PREC=0x00 TTL=63 ID=32724 DF PROTO=TCP SPT=33586 DPT=22 SEQ=1796475749 ACK=0 WINDOW=64240 SYN URGP=0 MARK=0x0 
```

Sem conta, sem resultado; mas com as interfaces por onde entrou e por onde saiu, e a mesma porta de
origem, `33586`. Repare também que esta linha **não tem ano**: é o formato antigo de hora do syslog, e a
aula 2 volta ao porquê de isso importar. Terceiro, nos **registros de fluxo**, um por sentido, que o
`nfpcapd` escreveu depois que a conversa ficou quinze segundos em silêncio:

```
root@soc:~# nfdump -R /var/log/soclab/flows -o line 'port 22'
Date first seen             Duration     Proto      Src IP Addr:Port          Dst IP Addr:Port   Packets    Bytes Flows
2026-10-07 04:24:43.017     00:00:00.238 TCP      198.51.100.22:22    ->     203.0.113.66:33586       19     5387     1
2026-10-07 04:24:43.017     00:00:00.238 TCP       203.0.113.66:33586 ->    198.51.100.22:22          22     4895     1
Summary: total flows: 2, total bytes: 10282, total packets: 41, avg bps: 345613, avg pps: 172, avg bpp: 250
Time window: 2026-10-07 04:24:00 - 2026-10-07 04:25:00
Total flows processed: 2, passed: 2, Blocks skipped: 0, Bytes read: 152
Sys: 0.0000s User: 0.0054s Wall: 0.0006s flows/second: 3159.6 Runtime: 0.0006s
```

Eles somam o que nenhum dos dois logs sabia: a conversa durou 0,238 segundo e moveu 41 pacotes, 10.282
bytes nos dois sentidos juntos. Quarto, nos próprios **pacotes**:

```
root@soc:~# tcpdump -nr one.pcap | head -4
reading from file one.pcap, link-type EN10MB (Ethernet), snapshot length 262144
04:24:43.017414 IP 203.0.113.66.33586 > 198.51.100.22.22: Flags [S], seq 1796475749, win 64240, options [mss 1460,sackOK,TS val 336062012 ecr 0,nop,wscale 10], length 0
04:24:43.017652 IP 198.51.100.22.22 > 203.0.113.66.33586: Flags [S.], seq 3384481466, ack 1796475750, win 65160, options [mss 1460,sackOK,TS val 2225653318 ecr 336062012,nop,wscale 10], length 0
04:24:43.017662 IP 203.0.113.66.33586 > 198.51.100.22.22: Flags [.], ack 1, win 63, options [nop,nop,TS val 336062012 ecr 2225653318], length 0
04:24:43.017896 IP 203.0.113.66.33586 > 198.51.100.22.22: Flags [P.], seq 1:44, ack 1, win 63, options [nop,nop,TS val 336062012 ecr 2225653318], length 43: SSH: SSH-2.0-OpenSSH_9.6p1 Ubuntu-3ubuntu13.19
root@soc:~# tcpdump -nr one.pcap | wc -l
reading from file one.pcap, link-type EN10MB (Ethernet), snapshot length 262144
41
```

Os mesmos 41 pacotes, a mesma porta e, no quarto, algo que nenhum outro registro guarda: a versão do
cliente SSH, que o `outside` anunciou em texto claro antes de a criptografia começar. Tudo depois desse
pacote é cifrado, e a captura mostra só o tamanho.

**É a porta de origem que amarra os quatro.** Os horários quase batem, mas a linha do `sshd` recebe do
`ts` um carimbo com precisão de segundo, na hora em que foi escrita, enquanto a captura carimba cada
pacote com precisão de microssegundo, na hora em que chegou. Dois relógios, duas precisões; juntar só
pelo horário é como um analista pendura o login errado na conexão errada.

E o custo, medido neste único login:

```
root@soc:~# wc -c /var/log/soclab/gw-auth.log /var/log/soclab/fw.log one.pcap
  429 /var/log/soclab/gw-auth.log
  250 /var/log/soclab/fw.log
11536 one.pcap
12215 total
```

O firewall precisou de **250 bytes** para dizer que a conexão aconteceu, e a captura de **11.536** para
reproduzi-la. Um ano do primeiro cabe num disco pequeno; um ano do segundo, numa rede movimentada, é um
projeto de armazenamento. Essa proporção é o motivo de a aula 3 falar de retenção antes de qualquer outra
coisa.
