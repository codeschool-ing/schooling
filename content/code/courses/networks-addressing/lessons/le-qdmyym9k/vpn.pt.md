---
title: A VPN, um link privado pela rede de outra pessoa
version: 1
---

A matriz quer alcançar a filial: do pc1 ao pc2, de endereço privado a endereço privado. Não consegue, e
a operadora diz por quê:

```
ana@pc1:~$ ping -c 2 10.30.10.22
PING 10.30.10.22 (10.30.10.22) 56(84) bytes of data.
From 203.0.113.1 icmp_seq=1 Destination Net Unreachable
From 203.0.113.1 icmp_seq=2 Destination Net Unreachable

--- 10.30.10.22 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1003ms

```

`From 203.0.113.1 ... Destination Net Unreachable` é o roteador da operadora respondendo. A seção de WAN
já leu a tabela dele: dois links e mais nada, **nenhuma rota para `10.30.10.0/24`**, porque nenhuma
operadora roteia endereços privados. Alugar uma linha entre os dois escritórios resolveria, pelo preço
de uma linha dedicada. A solução mais barata usa a conexão de internet que cada escritório já tem.

Uma **VPN** (*virtual private network*, rede privada virtual) é **um link privado carregado dentro de
pacotes que a rede pública sabe entregar**. O roteador da matriz pega um pacote endereçado à filial,
embrulha-o num pacote novo, do seu próprio endereço público para o endereço público do roteador da
filial, e envia esse. A operadora roteia o pacote de fora, o que ela sabe fazer. O roteador da filial
o desembrulha e entrega o pacote original na sua LAN. Na maioria das VPNs, o pacote de dentro também é
**cifrado**, para que a rede que o carrega não consiga ler nem o conteúdo nem os endereços privados — a
última seção desta aula olha o que continua visível.

## Montando uma

O laboratório usa **WireGuard**, uma VPN embutida no kernel Linux. Cada roteador ganha uma interface
`wg0`, uma chave privada que nunca sai dele, e uma lista com um par (peer): a chave pública do outro
roteador, onde encontrá-lo, e quais endereços podem vir dele. Digitado nos prompts dos dois roteadores:

```
root@rhq:~# ip link add wg0 type wireguard
root@rhq:~# wg set wg0 listen-port 51820 private-key /run/lab/rhq/wg.key peer +JFzEjDfzTBIMYnsaG9+qGoe12VEnNzYlLvJ6Ftnojo= endpoint 198.51.100.2:51820 allowed-ips 10.30.10.0/24,10.255.255.2/32
root@rhq:~# ip addr add 10.255.255.1/30 dev wg0 && ip link set wg0 up && ip route add 10.30.10.0/24 dev wg0
root@rbr:~# ip link add wg0 type wireguard
root@rbr:~# wg set wg0 listen-port 51820 private-key /run/lab/rbr/wg.key peer PLKSQ+aPlVn+/rt1DVIP+p5D0RVtQLLwMulg682GHiA= endpoint 203.0.113.2:51820 allowed-ips 10.20.10.0/24,10.255.255.1/32
root@rbr:~# ip addr add 10.255.255.2/30 dev wg0 && ip link set wg0 up && ip route add 10.20.10.0/24 dev wg0
```

Leia as três linhas da matriz. A `wg0` é criada; depois o `wg set` dá a ela uma **porta de escuta**,
51820, uma chave privada tirada de um arquivo, e um **par**: a chave pública da filial (`+JFz…`), o
**endpoint** dela, `198.51.100.2:51820` — o endereço público do roteador da filial — e os **allowed
IPs**, `10.30.10.0/24,10.255.255.2/32`, os endereços que podem chegar por este túnel. A última linha dá
um endereço à `wg0`, sobe a interface e acrescenta a rota que manda a LAN da filial para dentro do túnel.
As linhas da filial são o espelho delas.

**Sobre essas chaves.** As duas chaves privadas foram escritas no `lab.sh` pelo autor dele, para que o
`wg show` imprima a mesma coisa toda vez que o laboratório é montado. Isso quer dizer que qualquer pessoa
pode lê-las, e elas não protegem nada. Um túnel de verdade usa chaves geradas na própria máquina com
`wg genkey`, e uma chave privada que foi impressa, colada ou commitada é uma chave a trocar.

## Usando

```
ana@pc1:~$ ping -c 2 10.30.10.22
PING 10.30.10.22 (10.30.10.22) 56(84) bytes of data.
64 bytes from 10.30.10.22: icmp_seq=1 ttl=62 time=27.7 ms
64 bytes from 10.30.10.22: icmp_seq=2 ttl=62 time=3.83 ms

--- 10.30.10.22 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1004ms
rtt min/avg/max/mdev = 3.826/15.747/27.668/11.921 ms
ana@pc1:~$ traceroute -n 10.30.10.22
traceroute to 10.30.10.22 (10.30.10.22), 30 hops max, 60 byte packets
 1  10.20.10.1  0.854 ms  0.232 ms  0.206 ms
 2  10.255.255.2  6.105 ms  5.594 ms  5.035 ms
 3  10.30.10.22  5.510 ms  4.284 ms  3.903 ms
root@rhq:~# wg show
interface: wg0
  public key: PLKSQ+aPlVn+/rt1DVIP+p5D0RVtQLLwMulg682GHiA=
  private key: (hidden)
  listening port: 51820

peer: +JFzEjDfzTBIMYnsaG9+qGoe12VEnNzYlLvJ6Ftnojo=
  endpoint: 198.51.100.2:51820
  allowed ips: 10.30.10.0/24, 10.255.255.2/32
  latest handshake: 2 seconds ago
  transfer: 1.46 KiB received, 1.61 KiB sent
```

O ping que falhou agora funciona. Três detalhes dizem que ele passou pelo túnel:

- **`ttl=62`.** O pc2 mandou a resposta com TTL 64, e dois roteadores tiraram um cada: o `rbr` e o
  `rhq`. O roteador da operadora encaminhou o pacote *de fora*, cujo TTL é outro número, e nunca tocou
  no de dentro.
- **O traceroute tem três saltos, e nenhum é a operadora.** O salto 2 é `10.255.255.2`, o endereço do
  roteador da filial dentro do túnel. De dentro da VPN, os dois escritórios estão a um roteador de
  distância.
- **O `wg show`** informa um `latest handshake: 2 seconds ago` com o par, e tráfego nos dois sentidos:
  `1.46 KiB received, 1.61 KiB sent`. `private key: (hidden)` é o WireGuard se recusando a imprimi-la,
  mesmo para o root.

Esta é uma VPN **site-to-site** (entre sedes): dois roteadores ligando duas LANs, e os PCs atrás deles
não precisam de configuração nenhuma. O outro tipo comum é o **acesso remoto**: um laptop rodando um
cliente de VPN que o junta à rede do escritório a partir de um hotel ou de casa. O mecanismo é o mesmo —
um pacote dentro de um pacote — com uma das pontas sendo o computador de uma pessoa em vez de um
roteador. Nenhum dos dois muda o ponto de fundo: **uma VPN não torna a internet privada; ela faz um link
privado com ela.**
