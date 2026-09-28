---
title: O que um túnel não esconde
version: 1
---

Um túnel liga duas redes. Ele não torna o tráfego privado, e quem chama um túnel GRE de "a VPN" às vezes
acredita que torna. O roteador do provedor lê tudo o que vai dentro. Eis o caixa buscando uma página no
servidor de arquivos da matriz, `files`, do jeito que o provedor vê, com `-A` para imprimir o conteúdo de
cada pacote como texto:

```
ana@isp:~$ sudo tcpdump -l -n -t -A -i eth0 -c 8 ip proto 47 | grep --line-buffered -E "GRE|GET|Host|served"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 198.51.100.2 > 203.0.113.2: GREv0, key=0x2a, length 68: IP 192.168.20.30.54502 > 192.168.10.10.80: Flags [S], seq 903736331, win 64240, options [mss 1460,sackOK,TS val 3994382340 ecr 0,nop,wscale 10], length 0
IP 203.0.113.2 > 198.51.100.2: GREv0, key=0x2a, length 68: IP 192.168.10.10.80 > 192.168.20.30.54502: Flags [S.], seq 2813130645, ack 903736332, win 65160, options [mss 1460,sackOK,TS val 134118023 ecr 3994382340,nop,wscale 10], length 0
IP 198.51.100.2 > 203.0.113.2: GREv0, key=0x2a, length 60: IP 192.168.20.30.54502 > 192.168.10.10.80: Flags [.], ack 1, win 63, options [nop,nop,TS val 3994382341 ecr 134118023], length 0
IP 198.51.100.2 > 203.0.113.2: GREv0, key=0x2a, length 136: IP 192.168.20.30.54502 > 192.168.10.10.80: Flags [P.], seq 1:77, ack 1, win 63, options [nop,nop,TS val 3994382341 ecr 134118023], length 76: HTTP: GET / HTTP/1.1
..p...z.GET / HTTP/1.1
Host: 192.168.10.10
IP 203.0.113.2 > 198.51.100.2: GREv0, key=0x2a, length 60: IP 192.168.10.10.80 > 192.168.20.30.54502: Flags [.], ack 77, win 64, options [nop,nop,TS val 134118023 ecr 3994382341], length 0
IP 203.0.113.2 > 198.51.100.2: GREv0, key=0x2a, length 305: IP 192.168.10.10.80 > 192.168.20.30.54502: Flags [P.], seq 1:246, ack 77, win 64, options [nop,nop,TS val 134118024 ecr 3994382341], length 245: HTTP: HTTP/1.1 200 OK
served by files
IP 198.51.100.2 > 203.0.113.2: GREv0, key=0x2a, length 60: IP 192.168.20.30.54502 > 192.168.10.10.80: Flags [.], ack 246, win 63, options [nop,nop,TS val 3994382342 ecr 134118024], length 0
IP 198.51.100.2 > 203.0.113.2: GREv0, key=0x2a, length 60: IP 192.168.20.30.54502 > 192.168.10.10.80: Flags [F.], seq 77, ack 246, win 63, options [nop,nop,TS val 3994382342 ecr 134118024], length 0
8 packets captured
10 packets received by filter
0 packets dropped by kernel
```

**A conversa inteira está ali**: os endereços internos, o handshake TCP, a linha de requisição `GET /` e
a página que voltou, `served by files`. A página diz pouco aqui porque o servidor do laboratório não tem
nada a dizer. Numa rede de verdade, a mesma captura mostraria o que os escritórios trocam em texto
claro: um formulário de login, uma planilha, o prontuário de um paciente.

Um enlace entre escritórios precisa responder três perguntas, e um túnel simples responde só a primeira:

| | um túnel simples | o que é necessário |
|---|---|---|
| o pacote chega ao outro escritório? | **sim** | roteamento pelo túnel |
| alguém no caminho consegue lê-lo? | sim, inteiro | criptografia |
| veio mesmo do outro escritório, sem alteração? | ninguém confere | autenticação e integridade |

`branch` aceitaria de qualquer um um pacote GRE com os endereços externos certos e a chave certa, e a
chave está impressa em cada linha acima. **Criptografia e autenticação são o que transformam um túnel
numa VPN.** Dá para acrescentá-las de dois jeitos: em volta do túnel, que é o IPsec da aula 2, ou
embutidas no túnel desde o começo, que são as VPNs baseadas em TLS da aula 3 e o WireGuard da aula 4.

O GRE simples ainda tem seu lugar. Dentro de uma conexão IPsec ele leva o que o IPsec sozinho não leva,
como o multicast de um protocolo de roteamento, e dentro de um datacenter leva tráfego entre redes que
nunca saem de um enlace privado. **Um túnel que atravessa uma rede que você não controla é
criptografado.**
