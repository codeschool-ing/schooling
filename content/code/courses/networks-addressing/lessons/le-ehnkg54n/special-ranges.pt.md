---
title: As faixas que significam algo por si só
version: 1
---

Alguns endereços dizem algo antes de você mandar um pacote sequer. Um PC mostrando `169.254.10.10`
tem um problema, um servidor que escuta em `0.0.0.0` aceita conexões em todos os endereços que tem, e
um endereço que começa com 224 é um grupo, e não uma máquina. **Reconhecer essas faixas é metade de
ler um endereço**, e esta seção as reúne.

A que mais aparece no suporte:

```
ana@pc1:~$ ipcalc -b 169.254.10.10
Address:   169.254.10.10        
Netmask:   255.255.255.0 = 24   
Wildcard:  0.0.0.255            
=>
Network:   169.254.10.0/24      
HostMin:   169.254.10.1         
HostMax:   169.254.10.254       
Broadcast: 169.254.10.255       
Hosts/Net: 254                   Class B, APIPA

```

`169.254.0.0/16` é **link-local**. Uma máquina que pediu endereço por DHCP e não ouviu resposta escolhe
um desta faixa para si, confere que ninguém no enlace o usa, e passa a usá-lo. O Windows chama o
mecanismo de APIPA (*Automatic Private IP Addressing*), e é esse o rótulo que este ipcalc imprime. O
`Class B` ao lado é a regra do primeiro octeto da segunda seção desta aula e aqui não significa nada.
**Um PC com endereço 169.254 não alcançou o seu servidor DHCP**: ele conversa com outras máquinas do
mesmo cabo que fizeram o mesmo, e com nada além delas, porque roteadores não encaminham endereços
link-local. A aula 10 trata de por que o servidor DHCP não respondeu.

Agora, um endereço que não pertence a nenhuma rede local:

```
ana@pc1:~$ ip route get 8.8.8.8
8.8.8.8 via 10.20.10.1 dev eth0 src 10.20.10.21 uid 1000 
    cache 
```

O `ip route get` pergunta à tabela de rotas o que ela faria com um pacote, e não manda nada. `8.8.8.8`
é um endereço público da internet de verdade, que este laboratório não alcança; a resposta é a mesma
de qualquer jeito: **um endereço que não está em nenhuma rede ligada ao pc1 vai para o gateway**,
`via 10.20.10.1`, pela `eth0`, a partir de `10.20.10.21`. A aula 14 lê tabelas de rotas por inteiro.

`0.0.0.0` quer dizer "nenhum endereço em particular", e o sentido depende de onde aparece. Uma máquina
ainda sem endereço o usa como origem quando pede um ao DHCP. Como rota, `0.0.0.0/0` é a rota padrão,
a que casa com tudo. E numa lista de sockets quer dizer "qualquer um":

```
ana@pc1:~$ ss -tln
State Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
root@srv:~# ss -tln
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      5        10.20.10.10:80        0.0.0.0:*          
```

O pc1 não escuta em nada, então a sua lista é só o cabeçalho. O srv roda o servidor web do escritório,
e `10.20.10.10:80` diz que ele escuta na porta 80 só desse endereço. A coluna do outro lado,
`0.0.0.0:*`, quer dizer que **qualquer endereço, em qualquer porta, pode se conectar**. Um serviço
ligado a `0.0.0.0:80` aceitaria conexões em todos os endereços da máquina, inclusive o loopback, o
oposto da ligação a `127.0.0.1` da seção de loopback.

Tudo numa tabela:

| faixa | o que é | onde aparece neste curso |
|---|---|---|
| `0.0.0.0/8` | "esta rede"; `0.0.0.0` como "nenhum endereço" ou "qualquer um" | esta seção; aula 14 para `0.0.0.0/0` |
| `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | privados (RFC 1918) | esta aula; NAT na aula 11 |
| `100.64.0.0/10` | compartilhado, para NAT de operadora (RFC 6598) | aula 11 |
| `127.0.0.0/8` | loopback | esta aula |
| `169.254.0.0/16` | link-local, a escolha da própria máquina quando o DHCP falha | aula 10 |
| `192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24` | documentação (RFC 5737) | o laboratório todo |
| `224.0.0.0/4` | multicast, a antiga classe D | aula 16 |
| `240.0.0.0/4` | reservado, a antiga classe E | — |
| `255.255.255.255` | broadcast limitado | aula 10 |

Todo o resto é espaço público comum, distribuído pelos registros regionais a provedores e
organizações. **Nenhuma das faixas da tabela identifica uma máquina que se alcance pela internet pública**, e esse
é o teste prático. Se um pacote com origem numa delas chega à sua rede vindo de fora, algo está mal
configurado no caminho ou alguém o falsificou, e uma regra de firewall que descarta esses pacotes na
borda não custa nada.
