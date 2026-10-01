---
title: Associações de segurança, e o que o provedor ainda vê
version: 1
---

O que o IKE produziu pode ser listado em `hq`. Isto rodou alguns segundos depois do ping em armadilha da
seção anterior:

```
ana@hq:~$ sudo swanctl --list-sas
offices: #1, ESTABLISHED, IKEv2, a765344132816bcb_i* e1e4340708b3cac9_r
  local  'hq.example.com' @ 203.0.113.2[500]
  remote 'branch.example.com' @ 198.51.100.2[500]
  AES_CBC-256/HMAC_SHA2_256_128/PRF_HMAC_SHA2_256/MODP_2048
  established 3s ago, rekeying in 13907s
  lans: #2, reqid 1, INSTALLED, TUNNEL, ESP:AES_GCM_16-256
    installed 3s ago, rekeying in 3288s, expires in 3957s
    in  7fdf3ac6,    168 bytes,     2 packets,     1s ago
    out 41b696e1,    168 bytes,     2 packets,     1s ago
    local  192.168.10.0/24
    remote 192.168.20.0/24
```

**Uma associação de segurança é um sentido do tráfego protegido, então um túnel são duas.** Debaixo de
`lans`, `in 7fdf3ac6` é o que `branch` manda para `hq`, e `out 41b696e1` é o contrário. Cada um é um
SPI, Security Parameter Index, 32 bits escolhidos pelo lado que recebe com ele. Os dois contadores dizem
`168 bytes, 2 packets`: os dois pings que passaram, **84 bytes cada, contados antes da cifragem.**

Acima deles está a IKE SA. Os dois SPIs dela são marcados `_i` e `_r`, quem iniciou e quem respondeu, e
o `*` marca o deste lado, então foi `hq` que começou. A CHILD SA usa `ESP:AES_GCM_16-256`. O GCM cifra e
calcula um ICV de 16 bytes numa passada só, e é por isso que a proposta não nomeia um algoritmo de
integridade à parte.

A CHILD SA foi instalada 3 segundos antes da listagem, então `rekeying in 3288s, expires in 3957s` quer
dizer 3291 e 3960 segundos depois da instalação. **Renegociar faz chaves novas enquanto as antigas ainda
funcionam**, e o tráfego nunca espera por uma negociação depois da primeira. A expiração, 3600 × 1,1, é
um limite rígido que só é atingido se a renegociação falhar. A renegociação vem antes de 3600 porque o
strongSwan subtrai um valor aleatório, para que dois pares não renegociem no mesmo instante.

## No fio

O roteador do provedor, enquanto o laptop mandava mais um ping:

```
ana@isp:~$ sudo tcpdump -n -t -v -i eth0 -c 2 esp
tcpdump: listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP (tos 0x0, ttl 64, id 342, offset 0, flags [DF], proto ESP (50), length 140)
    203.0.113.2 > 198.51.100.2: ESP(spi=0x41b696e1,seq=0x3), length 120
IP (tos 0x0, ttl 63, id 38130, offset 0, flags [DF], proto ESP (50), length 140)
    198.51.100.2 > 203.0.113.2: ESP(spi=0x7fdf3ac6,seq=0x3), length 120
2 packets captured
2 packets received by filter
0 packets dropped by kernel
```

**`spi=0x41b696e1` é a SA `out` de `hq`, e a resposta leva `0x7fdf3ac6`, a `in` dele.** O SPI diz a
`branch` qual chave usar antes de ter decifrado qualquer coisa. `seq=0x3` vem depois dos dois pings
contados acima.

O ping de 84 bytes tem 140 no fio: **56 bytes de IPsec, contra 20 do IP-in-IP** da aula 1. Vinte são o
cabeçalho IP novo. `length 120` é a parte do ESP, e os 36 bytes de custo dele se dividem como a figura da
primeira seção desenha. O enchimento depende do tamanho do que vai dentro, então **o custo do ESP não é
um número fixo**, e a conta de MTU da aula 1 precisa de uma folga.

## Nada legível

A aula 1 leu um túnel GRE com `tcpdump -A`. O mesmo teste contra o ESP conta as linhas com `GET` ou
`served` em dez pacotes, enquanto o caixa buscava a página; ele a buscou de novo para a transcrição:

```
ana@isp:~$ sudo tcpdump -l -n -t -A -i eth0 -c 10 esp | grep -c -E "GET|served"
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
10 packets captured
10 packets received by filter
0 packets dropped by kernel
0
ana@till:~$ curl -s http://192.168.10.10/
served by files
```

**Zero.** A página atravessou o roteador do provedor dentro desses pacotes, e nem uma linha imprimível
dela estava lá. O provedor ainda sabe quais escritórios conversaram, quando, com que frequência e quanto:
**a cifragem esconde o conteúdo de uma conversa, não o fato de ela ter acontecido.**
