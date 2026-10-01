---
title: Uma sessão BGP, e o roteador que se recusa a falar
version: 1
---

**Vizinhos BGP são configurados, não descobertos.** O OSPF achava seus vizinhos com hellos em toda
interface; o BGP só fala com os endereços que você nomeia, cada um com o AS que você espera do outro lado,
por uma **conexão TCP na porta 179**. Por ser TCP, ganha de graça entrega confiável e em ordem, e manda a
tabela inteira uma vez e depois só as mudanças.

A configuração de edge nomeia seu AS, um ID de roteador, os dois provedores, e a única rede que ele vai
anunciar:

```
root@edge:~# vtysh -c "configure terminal" -c "router bgp 64500" -c "bgp router-id 192.0.2.1" -c "neighbor 192.0.2.2 remote-as 64501" -c "neighbor 192.0.2.6 remote-as 64502" -c "address-family ipv4 unicast" -c "network 203.0.113.0/24"
```

`neighbor 192.0.2.2 remote-as 64501` diz *o roteador naquele endereço está no AS 64501*. Um vizinho num AS
diferente é uma sessão **eBGP** (*external*); no mesmo AS seria iBGP, que redes grandes usam para levar
rotas BGP entre seus próprios roteadores de borda e de que esta aula não precisa. `network 203.0.113.0/24`
é o bloco da empresa, o prefixo que edge vai originar.

Alguns segundos depois:

```
root@edge:~# vtysh -c "show bgp summary"

IPv4 Unicast Summary (VRF default):
BGP router identifier 192.0.2.1, local AS number 64500 vrf-id 0
BGP table version 1
RIB entries 1, using 192 bytes of memory
Peers 2, using 1448 KiB of memory

Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
192.0.2.2       4      64501         5         3        0    0    0 00:00:05     (Policy) (Policy) N/A
192.0.2.6       4      64502         5         3        0    0    0 00:00:05     (Policy) (Policy) N/A

Total number of neighbors 2
```

Leia as duas linhas. `V 4` é o BGP versão 4. `MsgRcvd 5` e `MsgSent 3` mostram mensagens circulando, e
`Up/Down 00:00:05` é há quanto tempo a sessão está no ar. A coluna de estado traz uma palavra enquanto a
sessão não está estabelecida (`Idle`, `Connect`, `Active`) e o número de prefixos recebidos quando está.

**Aqui ela traz `(Policy)`, nos dois sentidos.** A sessão está estabelecida e nada está sendo trocado,
porque o FRR segue o RFC 8212: **uma sessão eBGP sem política configurada não aceita nada e não anuncia
nada**. É uma recusa proposital, escrita num padrão depois que redes demais anunciaram coisas que nunca
quiseram anunciar porque o padrão de um roteador era *mandar tudo*. A próxima seção escreve essa política.

## O que verificar quando uma sessão não sobe

A coluna de estado é a primeira coisa a ler:

- `Active` ou `Connect` por muito tempo: a conexão TCP não está se completando. Verifique se o endereço
  do vizinho é alcançável, se o outro lado tem uma linha `neighbor` correspondente apontando de volta, e se
  nada filtra a porta TCP 179.
- *Uma sessão que sobe e cai*: os dois lados discordam de algo na troca inicial, na maioria das vezes o
  número de AS. Um `remote-as` que não bate com o que o vizinho diz ser fecha a sessão.
- `(Policy)`: funciona, e está esperando você dizer o que pode atravessá-la.

Nenhuma dessas falhas foi encenada neste laboratório; a sessão aqui subiu na primeira tentativa.
