---
title: "IKEv2: quatro mensagens antes do primeiro pacote"
version: 1
---

Quem configura a primeira conexão IPsec costuma achar que a chave pré-compartilhada cifra o tráfego.
**Não cifra: ela só prova quem está na outra ponta.** As chaves do tráfego são feitas na hora, a cada
negociação, por uma troca Diffie-Hellman, e nunca atravessam a rede. A negociação é o IKE, Internet Key
Exchange, aqui na versão 2, na porta UDP 500.

## A configuração

`hq` roda o strongSwan, cuja configuração de IPsec é um arquivo, `/etc/swanctl/swanctl.conf`. O `sudo
cat` o imprimiu, e aqui está ele cortado em pedaços:

```schooling-example
{"language": "conf", "file": "swanctl.conf", "parts": [{"code": "connections {\n  offices {\n    version = 2\n    local_addrs = 203.0.113.2\n    remote_addrs = 198.51.100.2\n    mobike = no", "note": "Uma conexão, `offices`, em IKEv2, entre os endereços públicos dos dois roteadores. `mobike = no` desliga a extensão que deixa um par trocar de endereço no meio da conexão; ligada, ela faz o strongSwan passar o IKE para a porta 4500 assim que a primeira troca termina, mesmo sem NAT no caminho, e esta aula quer que a porta 500 continue sendo a 500 até a seção sobre NAT."}, {"code": "    proposals = aes256-sha256-modp2048", "note": "Os algoritmos da própria conexão IKE, não do tráfego: AES com chave de 256 bits para cifrar, SHA-256 para integridade e para derivar chaves, e o grupo Diffie-Hellman MODP 2048 para combinar um segredo. O outro lado precisa aceitar pelo menos uma proposta, ou nada começa."}, {"code": "    local {\n      auth = psk\n      id = hq.example.com\n    }\n    remote {\n      auth = psk\n      id = branch.example.com\n    }", "note": "Quem cada lado é e como prova isso. `auth = psk` quer dizer com chave pré-compartilhada; os valores de `id` são nomes, e cada lado confere se o outro apresentou o nome que ele espera. Eles não precisam existir no DNS."}, {"code": "    children {\n      lans {\n        local_ts = 192.168.10.0/24\n        remote_ts = 192.168.20.0/24\n        esp_proposals = aes256gcm16\n        start_action = trap\n      }\n    }", "note": "O túnel em si, uma CHILD SA chamada `lans`. As duas linhas `_ts` são os seletores de tráfego, as redes que ele une, e precisam espelhar as do outro lado. `esp_proposals` diz o algoritmo do tráfego, AES-GCM com chave de 256 bits. `start_action = trap` espera o primeiro pacote que precise do túnel."}, {"code": "  }\n}", "note": "O fim da conexão. O que vem depois é um bloco separado, que o `swanctl` carrega no depósito de segredos do daemon."}, {"code": "secrets {\n  ike-offices {\n    id-1 = hq.example.com\n    id-2 = branch.example.com\n    secret = \"Tide-Lantern-Orbit-7294-Quill\"\n  }\n}", "note": "A chave pré-compartilhada e as duas identidades entre as quais ela vale. O segredo do laboratório aparece aqui porque é do laboratório; num roteador de verdade, este bloco é a única parte do arquivo que ninguém cola num chamado."}]}
```

`branch` tem a imagem espelhada. `swanctl --load-all` entrega o arquivo ao daemon que está rodando, o
`charon`, e `--list-conns` mostra o que o daemon entendeu:

```
ana@hq:~$ sudo swanctl --load-all
loaded ike secret 'ike-offices'
no authorities found, 0 unloaded
no pools found, 0 unloaded
loaded connection 'offices'
successfully loaded 1 connections, 0 unloaded
ana@hq:~$ sudo swanctl --list-conns
offices: IKEv2, no reauthentication, rekeying every 14400s
  local:  203.0.113.2
  remote: 198.51.100.2
  local pre-shared key authentication:
    id: hq.example.com
  remote pre-shared key authentication:
    id: branch.example.com
  lans: TUNNEL, rekeying every 3600s
    local:  192.168.10.0/24
    remote: 192.168.20.0/24
```

`no authorities found` e `no pools found` não são erros: esta conexão não usa certificados e não
distribui endereços. O arquivo não definiu tempos de vida, então estes são os padrões do strongSwan: **a
conexão IKE é renegociada a cada 14400 segundos, quatro horas, e as chaves do túnel a cada 3600.**

## O primeiro pacote paga pela negociação

Com `start_action = trap`, nada é negociado quando o arquivo é carregado. O primeiro pacote entre as duas
redes dispara a negociação. O laptop pingou o caixa enquanto o roteador do provedor capturava as portas
UDP 500 e 4500:

```
ana@laptop:~$ ping -c 3 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=2 ttl=62 time=1.64 ms
64 bytes from 192.168.20.30: icmp_seq=3 ttl=62 time=1.14 ms

--- 192.168.20.30 ping statistics ---
3 packets transmitted, 2 received, 33.3333% packet loss, time 2033ms
rtt min/avg/max/mdev = 1.139/1.390/1.642/0.251 ms
ana@isp:~$ sudo tcpdump -n -t -i eth0 -c 4 udp port 500 or udp port 4500
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), snapshot length 262144 bytes
IP 203.0.113.2.500 > 198.51.100.2.500: isakmp: parent_sa ikev2_init[I]
IP 198.51.100.2.500 > 203.0.113.2.500: isakmp: parent_sa ikev2_init[R]
IP 203.0.113.2.500 > 198.51.100.2.500: isakmp: child_sa  ikev2_auth[I]
IP 198.51.100.2.500 > 203.0.113.2.500: isakmp: child_sa  ikev2_auth[R]
4 packets captured
4 packets received by filter
0 packets dropped by kernel
```

**O `icmp_seq=1` nunca voltou.** Ele disparou a negociação e foi descartado enquanto ela rodava; os dois
seguintes encontraram o túnel pronto. O provedor viu quatro pacotes: um `ikev2_init` de `hq` e a
resposta, depois um `ikev2_auth` e a resposta. Uma verificação de saúde que manda um ping só dá um túnel
em armadilha como fora do ar toda vez que ele sobe.

O `tshark`, o motor do Wireshark na linha de comando, que a aula 11 usa bastante, dá nome às mensagens.
Esta é uma segunda rodada, depois de a conexão ser derrubada, e ela perdeu o primeiro ping do mesmo
jeito:

```
ana@laptop:~$ ping -c 2 192.168.20.30
PING 192.168.20.30 (192.168.20.30) 56(84) bytes of data.
64 bytes from 192.168.20.30: icmp_seq=2 ttl=62 time=0.947 ms

--- 192.168.20.30 ping statistics ---
2 packets transmitted, 1 received, 50% packet loss, time 1029ms
rtt min/avg/max/mdev = 0.947/0.947/0.947/0.000 ms
ana@isp:~$ tshark -n -i eth0 -c 4 -f "udp port 500"
Capturing on 'eth0'
4 packets captured
    1 0.000000000  203.0.113.2 → 198.51.100.2 ISAKMP 506 IKE_SA_INIT MID=00 Initiator Request
    2 0.001103213 198.51.100.2 → 203.0.113.2  ISAKMP 514 IKE_SA_INIT MID=00 Responder Response
    3 0.004374601  203.0.113.2 → 198.51.100.2 ISAKMP 314 IKE_AUTH MID=01 Initiator Request
    4 0.007878151 198.51.100.2 → 203.0.113.2  ISAKMP 266 IKE_AUTH MID=01 Responder Response
```

As colunas são o número do pacote, o tempo em segundos, origem, destino, protocolo, tamanho do quadro e
mensagem. A negociação levou **7,9 milissegundos**, num laboratório em que todo enlace é um computador
conversando consigo mesmo. Numa internet de verdade, cada uma das duas trocas custa uma ida e volta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"Uma sequência entre hq em 203.0.113.2 e branch em 198.51.100.2. Primeiro, IKE_SA_INIT de hq, 464 bytes, levando SA, KE, No e duas notificações de detecção de NAT, e a resposta IKE_SA_INIT de branch, 472 bytes, com as mesmas cargas. Estas vão em claro: ofertas, valores Diffie-Hellman e nonces; depois delas os dois lados calculam o mesmo segredo e nenhuma chave passou pelo fio. Depois, IKE_AUTH de hq, 272 bytes, com IDi, AUTH, SA, TSi e TSr, e a resposta, 224 bytes, com IDr, AUTH, SA, TSi e TSr, as duas cifradas. Por último, ESP nos dois sentidos levando o tráfego do laptop, com SPIs 9ab696f9 de entrada e 4ad97b9d de saída.\"><defs><marker id=\"ike-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"12\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"110.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"540\" y=\"12\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">branch</text><text x=\"610.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.2</text><path d=\"M110 52 L110 372\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M610 52 L610 372\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M110 82 L610 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ike-ah)\"></path><text x=\"360.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">IKE_SA_INIT</text><text x=\"360.0\" y=\"73\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SA KE No N(NATD_S_IP) N(NATD_D_IP)</text><text x=\"622\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">464 bytes</text><path d=\"M610 132 L110 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ike-ah)\"></path><text x=\"360.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">IKE_SA_INIT</text><text x=\"360.0\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SA KE No N(NATD_S_IP) N(NATD_D_IP)</text><text x=\"98\" y=\"132\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">472 bytes</text><path d=\"M110 222 L610 222\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ike-ah)\"></path><text x=\"360.0\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">IKE_AUTH</text><text x=\"360.0\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">IDi AUTH SA TSi TSr</text><text x=\"622\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">272 bytes</text><path d=\"M610 272 L110 272\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ike-ah)\"></path><text x=\"360.0\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">IKE_AUTH</text><text x=\"360.0\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">IDr AUTH SA TSi TSr</text><text x=\"98\" y=\"272\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">224 bytes</text><text x=\"360.0\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">em claro: ofertas, valores Diffie-Hellman, nonces</text><rect x=\"130\" y=\"172\" width=\"460\" height=\"22\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os dois calculam o mesmo segredo; nenhuma chave passou pelo fio</text><text x=\"360.0\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cifrado: quem cada lado é, a prova, as redes</text><path d=\"M110 334 L610 334\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ike-ah)\" marker-start=\"url(#ike-ah)\"></path><text x=\"360.0\" y=\"322\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ESP, protocolo 50: o tráfego do laptop</text><text x=\"360.0\" y=\"352\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SPIs 9ab696f9_i 4ad97b9d_o</text></svg>", "caption": "As quatro mensagens do IKEv2, com as cargas e os tamanhos que o strongSwan registrou no `swanctl --initiate`. A segunda troca já vai cifrada com chaves derivadas da primeira."}
```

**O IKE_SA_INIT vai em claro, e o IKE_AUTH já vai cifrado.** A primeira troca leva a oferta de
algoritmos de cada lado, o valor público Diffie-Hellman dele e um nonce aleatório. A partir dos dois
valores públicos, os dois roteadores calculam o mesmo segredo, que ninguém olhando consegue calcular, e
toda chave seguinte é derivada dele. A segunda troca, `MID=01`, vai cifrada com essas chaves. Ela leva as
identidades, a prova feita com a chave pré-compartilhada e as redes a unir, então o provedor nunca vê o
nome `hq.example.com`.

Essa troca constrói duas coisas. A IKE SA é a conexão de controle entre os roteadores, e a CHILD
SA é o túnel que o tráfego usa; cada uma é renegociada no próprio relógio, os 14400 e 3600 segundos
acima. O IKEv1 as chamava de "fase 1" e "fase 2", e o pessoal ainda chama.
