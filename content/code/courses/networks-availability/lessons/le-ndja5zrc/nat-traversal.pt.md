---
title: Travessia de NAT, e um laptop em casa
version: 1
---

`remote` é um laptop em casa, `192.168.1.50`, atrás de um roteador doméstico, `homegw`, que divide um
endereço público, `198.51.100.77`, entre tudo o que há na casa. **O ESP não atravessa esse roteador
como está, porque o ESP não tem portas.** Um roteador que divide um endereço separa as conversas pelo
número de porta, como mostrou `networks-addressing`, e um pacote ESP não lhe dá nada com
que trabalhar.

A resposta do IPsec é a **travessia de NAT**: detectar o NAT durante a primeira troca e depois levar IKE
e ESP, os dois, em UDP na porta 4500. `hq` ganha uma segunda conexão, `home`, que distribui endereços a
partir de `10.30.0.0/24`. Acrescente-a no fim do `/etc/swanctl/swanctl.conf` de `hq`, depois do que já
está lá:

```schooling-example
{"language": "conf", "file": "swanctl.conf", "parts": [{"code": "connections {\n  home {\n    version = 2\n    local_addrs = 203.0.113.2\n    pools = homes", "note": "Uma segunda conexão em `hq`, `home`, acrescentada no fim do mesmo arquivo. Ela cita só o endereço do próprio `hq`: o laptop pode chegar de qualquer endereço, que é a razão de ser do acesso remoto. `pools = homes` diz de onde vem o endereço dele."}, {"code": "    local {\n      auth = psk\n      id = hq.example.com\n    }\n    remote {\n      auth = psk\n      id = ana@example.com\n    }", "note": "`hq` se prova como antes; do outro lado agora está uma pessoa, `ana@example.com`, não um roteador."}, {"code": "    children {\n      office {\n        local_ts = 192.168.10.0/24\n        esp_proposals = aes256gcm16\n      }\n    }\n  }\n}", "note": "Só o lado de `hq` do túnel é nomeado, a rede do escritório. O outro lado é o endereço que o pool distribuir."}, {"code": "pools {\n  homes {\n    addrs = 10.30.0.0/24\n  }\n}", "note": "O pool: um endereço por laptop, de `10.30.0.0/24`, uma faixa que nenhum escritório e nenhuma casa daqui usa."}, {"code": "secrets {\n  ike-ana {\n    id-1 = hq.example.com\n    id-2 = ana@example.com\n    secret = \"Harbour-Violet-Candle-3381\"\n  }\n}", "note": "O segredo da própria Ana. Numa empresa de verdade cada pessoa teria o seu, ou um certificado, ao que o fim desta seção volta."}]}
```

Em `remote`, o laptop, o `/etc/swanctl/swanctl.conf` é novo, e pede um endereço próprio com
`vips = 0.0.0.0`:

```schooling-example
{"language": "conf", "file": "swanctl.conf", "parts": [{"code": "connections {\n  office {\n    version = 2\n    remote_addrs = 203.0.113.2\n    vips = 0.0.0.0", "note": "O lado do laptop. Ele sabe onde fica o escritório, `remote_addrs`, e não onde ele mesmo está. `vips = 0.0.0.0` pede um endereço ao escritório."}, {"code": "    local {\n      auth = psk\n      id = ana@example.com\n    }\n    remote {\n      auth = psk\n      id = hq.example.com\n    }", "note": "As mesmas duas identidades da conexão `home` de `hq`, ao contrário."}, {"code": "    children {\n      office {\n        remote_ts = 192.168.10.0/24\n        esp_proposals = aes256gcm16\n      }\n    }\n  }\n}", "note": "O túnel leva o que vai para a rede do escritório, e mais nada: o resto do tráfego da Ana continua saindo pelo roteador de casa. A aula 5 chama isso de split tunnelling."}, {"code": "secrets {\n  ike-ana {\n    id-1 = hq.example.com\n    id-2 = ana@example.com\n    secret = \"Harbour-Violet-Candle-3381\"\n  }\n}", "note": "O mesmo segredo que em `hq`."}]}
```

Inicie o `charon` em `remote` como nos roteadores, com
`sudo setsid /usr/lib/ipsec/charon >/dev/null 2>&1 &`, depois rode `sudo swanctl --load-all` em `hq` e
em `remote`. O laptop começou a conexão, e o log foi filtrado até as linhas que importam:

```
ana@remote:~$ sudo swanctl --initiate --child office | grep -E "NAT|sending|received|virtual|established"
[ENC] generating IKE_SA_INIT request 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(REDIR_SUP) ]
[NET] sending packet: from 192.168.1.50[500] to 203.0.113.2[500] (972 bytes)
[NET] received packet: from 203.0.113.2[500] to 192.168.1.50[500] (280 bytes)
[ENC] parsed IKE_SA_INIT response 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(CHDLESS_SUP) N(MULT_AUTH) ]
[IKE] local host is behind NAT, sending keep alives
[NET] sending packet: from 192.168.1.50[4500] to 203.0.113.2[4500] (304 bytes)
[NET] received packet: from 203.0.113.2[4500] to 192.168.1.50[4500] (256 bytes)
[IKE] installing new virtual IP 10.30.0.1
[IKE] IKE_SA office[1] established between 192.168.1.50[ana@example.com]...203.0.113.2[hq.example.com]
[IKE] CHILD_SA office{1} established with SPIs 8d6d0dca_i 0d6d6c89_o and TS 10.30.0.1/32 === 192.168.10.0/24
ana@isp:~$ sudo tcpdump -n -t -i eth1 -c 6 udp and host 198.51.100.77
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 198.51.100.77.500 > 203.0.113.2.500: isakmp: parent_sa ikev2_init[I]
IP 203.0.113.2.500 > 198.51.100.77.500: isakmp: parent_sa ikev2_init[R]
IP 198.51.100.77.4500 > 203.0.113.2.4500: NONESP-encap: isakmp: child_sa  ikev2_auth[I]
IP 203.0.113.2.4500 > 198.51.100.77.4500: NONESP-encap: isakmp: child_sa  ikev2_auth[R]
IP 198.51.100.77.4500 > 203.0.113.2.4500: UDP-encap: ESP(spi=0x0d6d6c89,seq=0x1), length 120
IP 203.0.113.2.4500 > 198.51.100.77.4500: UDP-encap: ESP(spi=0x8d6d0dca,seq=0x1), length 120
6 packets captured
6 packets received by filter
0 packets dropped by kernel
```

Cada lado calcula um hash dos endereços e portas que acredita que o pacote levava e manda os hashes como
`N(NATD_S_IP)` e `N(NATD_D_IP)`. `remote` usou `192.168.1.50`, enquanto `hq` viu o pacote chegar de
`198.51.100.77`, como mostra a captura do provedor. Os hashes não bateram, e **os dois lados concluíram
`local host is behind NAT` antes de qualquer chave ser combinada.** A primeira troca rodou na porta 500
e a segunda na 4500.

IKE e ESP agora dividem a porta 4500, então quem recebe precisa separá-los. Uma mensagem IKE ali começa
com quatro bytes zero, mostrada como `NONESP-encap`, e o ESP começa com o SPI, que nunca é zero,
mostrado como `UDP-encap: ESP`. Os keepalives do log existem porque um roteador doméstico esquece uma
conversa UDP que fica em silêncio, e uma conversa esquecida cortaria o túnel do lado do escritório.

O primeiro pedido teve 972 bytes, contra 464 do dos escritórios: nenhum dos lados nomeou propostas nesta
conexão, então `remote` ofereceu a lista padrão inteira do strongSwan. Depois o laptop alcançou o
servidor de arquivos:

```
ana@remote:~$ ping -c 2 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.
64 bytes from 192.168.10.10: icmp_seq=1 ttl=63 time=0.668 ms
64 bytes from 192.168.10.10: icmp_seq=2 ttl=63 time=0.829 ms

--- 192.168.10.10 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1013ms
rtt min/avg/max/mdev = 0.668/0.748/0.829/0.080 ms
ana@hq:~$ sudo swanctl --list-sas --ike home
home: #6, ESTABLISHED, IKEv2, b02568a07bd2d4ff_i a5fd5cdcbf0d6f7c_r*
  local  'hq.example.com' @ 203.0.113.2[4500]
  remote 'ana@example.com' @ 198.51.100.77[4500] [10.30.0.1]
  AES_CBC-128/HMAC_SHA2_256_128/PRF_HMAC_SHA2_256/ECP_256
  established 2s ago, rekeying in 13644s
  office: #9, reqid 2, INSTALLED, TUNNEL-in-UDP, ESP:AES_GCM_16-256
    installed 2s ago, rekeying in 3260s, expires in 3958s
    in  0d6d6c89,    252 bytes,     3 packets,     0s ago
    out 8d6d0dca,    252 bytes,     3 packets,     0s ago
    local  192.168.10.0/24
    remote 10.30.0.1/32
```

**`hq` conhece o laptop pelo endereço do roteador doméstico, `198.51.100.77[4500]`, e pelo endereço que
lhe deu, `10.30.0.1`.** O modo é `TUNNEL-in-UDP`, e o `*` desta vez está no `_r`, porque `hq` respondeu.
`252 bytes, 3 packets` são três pings de 84 bytes: um mandado enquanto a captura rodava e os dois acima.
A resposta veio com `ttl=63`, porque `files` a mandou com 64 e `hq` a roteou uma vez; o roteador
doméstico só viu o pacote externo.

Os seletores são `10.30.0.1/32` e `192.168.10.0/24`. **O laptop entra no escritório com o endereço que o
escritório lhe deu, nunca com o endereço de casa**, então `hq` não precisa de rota para uma
`192.168.1.0/24` que milhares de casas usam. A aula 5 mostra o que acontece quando uma rede doméstica e
uma rede do escritório colidem mesmo assim.

## Chave pré-compartilhada ou certificados

Uma chave pré-compartilhada serve para dois roteadores: um segredo longo e aleatório, digitado nas duas
pontas. Para pessoas, não serve. **Uma chave dividida por cinquenta pessoas não pode ser trocada sem
trocá-la para as cinquenta**, e quem sai da empresa fica com ela.

| | chave pré-compartilhada | certificados | EAP dentro do IKEv2 |
|---|---|---|---|
| o que cada lado tem | o mesmo segredo | a própria chave privada, assinada por uma autoridade em que o outro confia | o gateway um certificado, a pessoa um login |
| tirar um par | trocar o segredo em todo lugar onde ele é dividido | revogar aquele certificado | desativar aquela conta |
| serve para | dois roteadores | roteadores, e laptops gerenciados | pessoas, com o diretório da empresa e um segundo fator |

Certificados são a aula 6 de `networks`; no `swanctl.conf` a mudança é `auth = pubkey` e um certificado
onde estava o segredo. O EAP viaja dentro do IKE_AUTH, então o gateway se prova com um certificado e a
pessoa com um login e um segundo fator vindos do diretório da empresa. A aula 5 põe esse tipo de acesso
remoto ao lado do site a site.
