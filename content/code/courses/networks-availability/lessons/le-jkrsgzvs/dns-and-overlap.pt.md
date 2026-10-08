---
title: Nomes que se perdem e números que colidem
version: 1
---

Dois problemas são só do acesso remoto, porque o laptop está dentro de uma rede que a empresa não
administra.

## DNS, que as rotas não decidem

As rotas decidem para onde os pacotes vão; não dizem nada sobre nomes. **O servidor DNS da empresa responde os nomes
internos, e um laptop em casa pergunta ao resolvedor que o roteador de casa lhe entregou.** Esse
resolvedor nunca ouviu falar dos nomes internos da empresa, então eles falham. Um nome interno que
também existe no DNS público se resolve, sem aviso, para o endereço público.

A correção é o split DNS: consultas dos domínios da própria empresa vão para o resolvedor dela, pelo
túnel, e o resto para o local. No Linux, o `systemd-resolved` faz isso por interface, e o `wg-quick`
aceita uma linha `DNS =` que entrega um resolvedor ao sistema quando o túnel sobe. O arquivo da Ana não
tinha essa linha, e nada de DNS foi capturado nesta aula.

Um túnel completo também não resolve, e o motivo está nas regras capturadas na seção sobre túnel
dividido e completo. Se o resolvedor do laptop é o roteador de casa, `192.168.1.1`, esse endereço está
na LAN de casa, que o `suppress_prefixlength 0` mantém de propósito alcançável fora do túnel. **Toda
consulta vai então para o roteador de casa em claro, enquanto todo o resto vai criptografado**, e o
provedor de casa vê cada nome que ela procura. Isso se chama vazamento de DNS (DNS leak), e uma
configuração de túnel completo indica um resolvedor do lado da empresa exatamente por isso.

## Duas redes com os mesmos números

A LAN de casa aqui é `192.168.1.0/24`, um padrão muito comum de roteadores domésticos. Suponha que a
matriz tivesse mantido o mesmo padrão, como muitos escritórios pequenos fazem. Para montar a cena,
acrescente uma terceira faixa, `192.168.1.0/24`, ao `AllowedIPs` da Ana, representando essa rede do
escritório, com o túnel derrubado antes. Em `remote`:

```sh
sudo wg-quick down wg0
sudo sed -i 's|^AllowedIPs = .*|AllowedIPs = 10.20.0.0/24, 192.168.10.0/24, 192.168.1.0/24|' /etc/wireguard/wg0.conf
```

Depois olhe as rotas dela, e tente:

```
ana@remote:~$ ip route | grep 192.168.1.0
192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.50 
ana@remote:~$ sudo wg-quick up wg0
[#] ip link add wg0 type wireguard
Error: Unknown device type.
[!] Missing WireGuard kernel module. Falling back to slow userspace implementation.
[#] wireguard-go wg0
┌──────────────────────────────────────────────────────┐
│                                                      │
│   Running wireguard-go is not required because this  │
│   kernel has first class support for WireGuard. For  │
│   information on installing the kernel module,       │
│   please visit:                                      │
│         https://www.wireguard.com/install/           │
│                                                      │
└──────────────────────────────────────────────────────┘
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.20.0.3/24 dev wg0
[#] ip link set mtu 1420 up dev wg0
[#] ip -4 route add 192.168.10.0/24 dev wg0
[#] ip -4 route add 192.168.1.0/24 dev wg0
RTNETLINK answers: File exists
[#] ip link delete dev wg0
```

O laptop já tem uma rota para `192.168.1.0/24`, na `eth0`: a própria LAN de casa. O `wg-quick` tenta
acrescentar o mesmo prefixo pelo `wg0`, e o kernel recusa, `RTNETLINK answers: File exists`. **O
`wg-quick` trata qualquer passo que falha como fatal e apaga o `wg0`**, então o túnel inteiro some, não
só aquela faixa. O mesmo `sed` com a lista que havia antes, `10.20.0.0/24, 192.168.10.0/24`, e um
`sudo wg-quick up wg0` a trazem de volta.

Aqui a falha é barulhenta, que é o caso bom. Um cliente que instala as rotas de outro jeito pode deixar
uma das duas vencer sem uma palavra, e aí ou a impressora de casa ou o servidor do escritório para de
responder. Mesmo quando os prefixos diferem, um endereço como `192.168.1.10` pode existir dos dois lados,
e o laptop só alcança um deles.

| correção | o que custa |
|---|---|
| numerar as redes da empresa longe dos padrões de roteador doméstico | uma renumeração, barata só antes de a rede crescer |
| traduzir a faixa do escritório, no concentrador, para uma que ninguém usa (NAT, visto em `networks-addressing`) | os nomes internos têm de apontar para os endereços traduzidos |
| rotear só os poucos hosts de que a pessoa precisa, como `/32` | serve para três servidores, não para uma rede |
| dar acesso por aplicação em vez de por rede | um produto diferente, na seção sobre a escolha |

A mesma colisão acontece entre dois locais quando duas empresas se fundem e as duas usavam
`192.168.1.0/24`. E a regra da aula 4, de que uma faixa pertence a um par de cada vez, quer dizer que
um concentrador nem conseguiria listar as duas.
