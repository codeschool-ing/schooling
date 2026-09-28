---
title: Um laptop atrás de NAT, e uma chave errada
version: 1
---

`remote` é o laptop da Ana em casa, `192.168.1.50`, atrás de um roteador doméstico, `homegw`, que o
traduz para `198.51.100.77`. O arquivo de `hq` não tem `Endpoint` para ela. O arquivo dela, escrito
quando o laboratório foi montado e não impresso aqui, aponta para `hq` como `vpn.example.com:51820` e
tem uma linha a mais, `PersistentKeepalive = 25`. Ela sobe o túnel e pinga o servidor de arquivos:

```
ana@remote:~$ ping -c 1 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.
64 bytes from 192.168.10.10: icmp_seq=1 ttl=63 time=1.02 ms

--- 192.168.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.018/1.018/1.018/0.000 ms
ana@hq:~$ sudo wg show wg0 endpoints
FYBqYy68QPdITaZcZGko576tjvRUt5cUWsMsdGzbgkE=	198.51.100.77:40817
n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8=	198.51.100.2:51820
```

O ping funciona, e **`hq` agora sabe onde ela está: `198.51.100.77:40817`**, o endereço público do
roteador de casa e uma porta que o NAT dele escolheu. Ninguém digitou isso. `hq` aprendeu com o primeiro
pacote que se decifrou corretamente com a chave dela, e continua aprendendo: todo pacote autenticado
vindo de um endereço novo move o endpoint para lá.

Isso é roaming. Um laptop que sai de casa para um hotel, ou um celular que passa do Wi-Fi para os dados
móveis, manda o próximo pacote de um endereço novo, e `hq` responde no novo. **Não há reconexão, porque
a sessão nunca esteve presa a um endereço**, só a uma chave e ao índice de receptor da seção do
handshake. O laboratório não mudou o laptop de lugar, então isto é o mecanismo, e não uma captura dele.

## Por que o laptop manda pacotes sem nada dentro

O NAT tem uma pegadinha. `homegw` mantém o mapeamento da porta 40817 para `192.168.1.50` só enquanto há
tráfego usando-o, e um roteador doméstico geralmente esquece um mapeamento UDP ocioso depois de um ou
dois minutos. O WireGuard não manda nada quando não tem o que mandar, então depois de um tempo quieto um
pacote de `hq` para `198.51.100.77:40817` chegaria a uma porta que não existe mais, e o escritório não
alcançaria a Ana até ela mandar alguma coisa primeiro.

**`PersistentKeepalive = 25` faz o laptop mandar um pacote autenticado vazio a cada 25 segundos**, o
bastante para manter o mapeamento vivo. Só o lado atrás do NAT precisa disso. `hq` e `branch` têm
endereços públicos fixos, e os arquivos deles não têm essa linha.

## A chave errada

Para a próxima captura, o arquivo de `remote` recebeu a chave pública errada para `hq`: a de `branch`,
uma chave real do laboratório e a errada. O provedor escutou os pacotes dela enquanto ela pingava:

```
ana@remote:~$ ping -c 7 -W 1 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.

--- 192.168.10.10 ping statistics ---
7 packets transmitted, 0 received, 100% packet loss, time 6124ms

ana@isp:~$ sudo tcpdump -n -ttt -i eth1 -c 2 udp port 51820 and host 198.51.100.77
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
 00:00:00.000000 IP 198.51.100.77.58867 > 203.0.113.2.51820: UDP, length 148
 00:00:05.277388 IP 198.51.100.77.58867 > 203.0.113.2.51820: UDP, length 148
2 packets captured
2 packets received by filter
0 packets dropped by kernel
ana@remote:~$ sudo wg show wg0 latest-handshakes
n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8=	0
```

Sete pings em 6124 ms, todos perdidos. No fio, nesse tempo, **só dois pacotes, os dois vindos da Ana e
os dois com 148 bytes: iniciações de handshake**, o mesmo tamanho de carga do pacote 1 da captura do
handshake. O segundo veio 5,277388 segundos depois do primeiro, porque uma iniciação sem resposta é
reenviada mais ou menos a cada cinco segundos.

E `hq` não mandou nada de volta. A iniciação foi montada para a chave que a Ana achava ser a de `hq`.
`hq` não consegue autenticá-la com a própria chave, e **uma ponta WireGuard não responde a um pacote que
não consegue autenticar**, nem com um erro. Um scanner de portas recebe exatamente o silêncio que
receberia se nada estivesse escutando, o que é uma defesa; é também por isso que essa falha precisa ser
diagnosticada de uma das pontas.

O `latest-handshakes` dá o diagnóstico numa linha. `0` quer dizer nunca, e a chave listada é
`n/CGaD63…`, que o `wg show` em `hq` disse ser da filial. **O par para o qual a Ana está configurada não
é a máquina do outro lado.**

| o que você vê | onde olhar |
|---|---|
| iniciações a cada ~5 s, nenhuma resposta, latest handshake `0` | a chave pública de um dos lados, ou UDP 51820 bloqueado no caminho |
| um handshake recente, e parte do tráfego ainda se perde | o `AllowedIPs` do lado que recebe não inclui a origem |
| funciona, depois fica mudo após um tempo ocioso, atrás de NAT | falta `PersistentKeepalive` no lado atrás do NAT |
| transferências grandes travam, pequenas passam | o MTU, aula 21 |
