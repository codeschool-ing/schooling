---
title: Um gateway que ninguém tem
version: 2
---

O jeito mais comum de configurar mal um host à mão é digitar o gateway errado. O sintoma é fácil de
ler errado, porque metade da rede continua funcionando. Neste bloco a rota padrão do pc2 foi
trocada, num prompt de root no pc2, com `ip route replace default via 10.20.10.254`: um endereço
dentro da rede do escritório que nenhuma máquina tem.

```
ana@pc2:~$ ip route
default via 10.20.10.254 dev eth0 
10.20.10.0/24 dev eth0 proto kernel scope link src 10.20.10.22 
ana@pc2:~$ ping -c 1 10.20.10.10
PING 10.20.10.10 (10.20.10.10) 56(84) bytes of data.
64 bytes from 10.20.10.10: icmp_seq=1 ttl=64 time=11.8 ms

--- 10.20.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 1ms
rtt min/avg/max/mdev = 11.774/11.774/11.774/0.000 ms
```

A rota parece certa, e o pc2 alcança o servidor. **Tudo na própria rede funciona**, porque esse
tráfego nunca usa o gateway: a segunda linha da tabela o manda direto pela `eth0`. Um usuário no
pc2 consegue imprimir na impressora do escritório e abrir o servidor de arquivos, e vai dizer que
"a internet caiu".

```
ana@pc2:~$ ping -c 2 192.0.2.80
PING 192.0.2.80 (192.0.2.80) 56(84) bytes of data.
From 10.20.10.22 icmp_seq=1 Destination Host Unreachable
From 10.20.10.22 icmp_seq=2 Destination Host Unreachable

--- 192.0.2.80 ping statistics ---
2 packets transmitted, 0 received, +2 errors, 100% packet loss, time 1037ms
pipe 2
ana@pc2:~$ ip neigh
10.20.10.254 dev eth0 FAILED 
10.20.10.10 dev eth0 lladdr 02:9e:43:3e:ca:ae REACHABLE 
```

Dois detalhes da falha contam o que aconteceu.

**O erro vem do endereço do próprio pc2**: `From 10.20.10.22 ... Destination Host Unreachable`.
Nenhum roteador disse isso. Foi o kernel do pc2, sobre um host que ele tentava alcançar no próprio
enlace, e esse host não era 192.0.2.80. Era o gateway. Para mandar qualquer pacote a 192.0.2.80, o
pc2 primeiro precisa do endereço MAC de 10.20.10.254, perguntou com ARP, não teve resposta, e
desistiu. (`+2 errors` conta esses dois avisos, e `pipe 2` é o ping registrando que as duas sondas
estavam pendentes ao mesmo tempo.)

**A tabela de vizinhos confirma**: `10.20.10.254 dev eth0 FAILED`. FAILED é o estado de um
endereço sobre o qual o ARP perguntou e ninguém respondeu. A linha do servidor ao lado é
`REACHABLE`, e essa é a diferença entre as duas metades do sintoma.

## Lendo o sintoma

O padrão vale guardar porque separa esta falha das vizinhas:

| o que você vê | onde está a falha |
|---|---|
| máquinas locais respondem, remotas dão "unreachable" vindo do seu próprio endereço | o gateway está errado ou fora; confira `ip route` e `ip neigh` |
| máquinas locais respondem, e o "unreachable" vem do endereço do gateway | o gateway responde mas não tem rota adiante |
| nada responde, nem as máquinas locais | o enlace ou o endereço, abaixo do gateway |

**O endereço de origem de uma mensagem de erro diz quem desistiu.** Uma mensagem vinda do seu
próprio endereço quer dizer que a sua máquina não conseguiu entregar o pacote adiante; uma mensagem
de um roteador quer dizer que o roteador não conseguiu. Esse único hábito reduz uma reclamação vaga
a uma linha de configuração.

O conserto aqui é o endereço, `10.20.10.1`, no que quer que configure o pc2: um arquivo, um
gerenciador de rede, ou, na maioria das redes de escritório, o servidor DHCP que entrega a cada
máquina o gateway junto com o endereço, o que é a aula 10. Um gateway digitado errado numa máquina é
problema de um usuário; o mesmo erro num escopo DHCP é problema de todos, na próxima vez que as
concessões forem renovadas.
