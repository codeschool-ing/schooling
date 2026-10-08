---
title: OpenVPN com o handshake escondido, e os dois lado a lado
version: 1
---

A aula 3 subiu o OpenVPN e leu o handshake TLS dele no fio, com Client Hello e tudo. Aqui ele está
configurado do jeito que um servidor de acesso remoto costuma estar, em `hq`, para a Ana. Derrube o
WireGuard em `hq` antes, `sudo wg-quick down wg0`, para que só uma VPN esteja rodando. Este é o arquivo
do servidor, `/etc/openvpn/server.conf`, para escrever em `hq` com `sudo nano`:

```schooling-example
{"language": "conf", "file": "server.conf", "parts": [{"code": "dev tun\nproto udp\nport 1194", "note": "Um túnel de camada 3, `tun`, sobre UDP na porta registrada do OpenVPN."}, {"code": "server 10.8.0.0 255.255.255.0\ntopology subnet", "note": "Um pool para os clientes. O servidor fica com `10.8.0.1` e distribui o resto, um endereço por conexão, todos numa sub-rede só."}, {"code": "ca ca.crt\ncert vpn-server.crt\nkey vpn-server.key", "note": "A autoridade em que os dois lados confiam, e o certificado e a chave do próprio servidor. Cada cliente tem um certificado seu, da mesma autoridade, e essa é a identidade dele."}, {"code": "dh none", "note": "Nenhum arquivo de parâmetros Diffie-Hellman: a troca de chaves é feita com curvas elípticas."}, {"code": "tls-crypt tc.key", "note": "Uma chave compartilhada pelo servidor e por todos os clientes, que criptografa e autentica o canal de controle, handshake incluído."}, {"code": "push \"route 192.168.10.0 255.255.255.0\"", "note": "Enviado a cada cliente quando ele conecta: rotear a LAN da matriz para o túnel, e mais nada. Um túnel dividido, que é o assunto da aula 5."}, {"code": "keepalive 10 60", "note": "Um ping pelo túnel a cada 10 segundos, e o cliente reinicia a conexão depois de 60 sem resposta. O servidor espera o dobro."}, {"code": "status /run/openvpn-status.log 5\nverb 3", "note": "Regravar num arquivo, a cada 5 segundos, a lista de quem está conectado, e registrar no nível de log de costume."}]}
```

**Onde o WireGuard identifica um par por uma chave escrita no arquivo do servidor, o OpenVPN identifica
uma pessoa por um certificado que o servidor nunca viu antes.** Qualquer cliente cujo certificado a
autoridade do laboratório assinou consegue conectar, e o servidor não precisa de uma linha por usuário.
Essa é a diferença que o resto desta seção encontra várias vezes.

O `/etc/openvpn/client.conf` da Ana em `remote` é o da aula 3 com uma linha a mais, `tls-crypt tc.key`,
escrita depois da linha `key vpn-ana.key`. Os certificados são copiados como na aula 3, e o `tls-crypt`
precisa de uma chave própria, gerada uma vez no servidor. Em `hq`:

```sh
sudo cp /lab/tls/ca.crt /lab/tls/vpn-server.crt /lab/tls/vpn-server.key /etc/openvpn/
sudo chmod 600 /etc/openvpn/vpn-server.key
sudo openvpn --genkey tls-crypt /etc/openvpn/tc.key
```

Depois cada cliente recebe uma cópia. Entre máquinas de verdade isso é uma cópia por SSH ou uma
ferramenta de gerência de configuração. Aqui o `/etc/openvpn` de cada máquina mora em `/lab` na máquina
virtual, como dizem as notas do `netlab.sh` na aula 1, então `remote` pode pegar o de `hq` direto. Em
`remote`:

```sh
sudo cp /lab/tls/ca.crt /lab/tls/vpn-ana.crt /lab/tls/vpn-ana.key /etc/openvpn/
sudo chmod 600 /etc/openvpn/vpn-ana.key
sudo cp /lab/hq/etc/openvpn/tc.key /etc/openvpn/
```

O arquivo da chave começa assim:

```
ana@hq:~$ sudo head -3 /etc/openvpn/tc.key
#
# 2048 bit OpenVPN static key
#
```

Ela não é uma identidade, já que todo cliente tem o mesmo arquivo. **O trabalho dela é tornar inútil,
antes de o TLS começar, um pacote que não a tenha.** Inicie o servidor em `hq`, gravando o log em
`/run/openvpn.log`, onde o fim desta seção o lê:

```sh
sudo sh -c 'setsid openvpn --cd /etc/openvpn --config server.conf > /run/openvpn.log 2>&1 &'
```

O provedor capturou o cliente conectando, com o `tshark` iniciado antes em `isp` e depois o cliente em
`remote`, em segundo plano como o servidor:

```sh
sudo setsid openvpn --cd /etc/openvpn --config client.conf >/dev/null 2>&1 &
```

Depois a Ana pingou o servidor de arquivos pelo túnel:

```
ana@isp:~$ tshark -n -i eth1 -c 6 -f "udp port 1194"
Capturing on 'eth1'
6 packets captured
    1 0.000000000 198.51.100.77 → 203.0.113.2  OpenVPN 96 MessageType: P_CONTROL_HARD_RESET_CLIENT_V2
    2 0.000193540  203.0.113.2 → 198.51.100.77 OpenVPN 108 MessageType: P_CONTROL_HARD_RESET_SERVER_V2
    3 0.000432890 198.51.100.77 → 203.0.113.2  SSL 385 Continuation Data
    4 0.001937144  203.0.113.2 → 198.51.100.77 SSL 1248 Continuation Data
    5 0.001976314  203.0.113.2 → 198.51.100.77 SSL 1248 Continuation Data
    6 0.001991326  203.0.113.2 → 198.51.100.77 SSL 231 Continuation Data
ana@remote:~$ ping -c 1 192.168.10.10
PING 192.168.10.10 (192.168.10.10) 56(84) bytes of data.
64 bytes from 192.168.10.10: icmp_seq=1 ttl=63 time=0.859 ms

--- 192.168.10.10 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.859/0.859/0.859/0.000 ms
```

O `tshark` ainda sabe que é OpenVPN: os dois primeiros pacotes, o `HARD_RESET` do cliente e o do
servidor, levam o tipo de mensagem onde ele consegue ler. **Depois disso não há Client Hello, nem Server
Hello, nem versão, nem lista de cifras**, só `Continuation Data`, que é o `tshark` encontrando bytes onde
esperava registros TLS que conseguisse interpretar. A captura da aula 3, sem `tls-crypt`, nomeava cada
passo.

O que um observador deixa de ler importa menos do que o que o servidor deixa de fazer. O servidor descarta um
pacote cuja autenticação `tls-crypt` falha antes de o código TLS do OpenVPN o ver. **Quem não tem o
`tc.key` nem consegue começar um handshake**: é o silêncio que o WireGuard obtém das chaves dele,
comprado aqui com um arquivo compartilhado. Um cliente que sai da empresa continua com esse arquivo, e
é por isso que ele protege a porta e quem decide quem entra continua sendo o certificado.

O arquivo de status, regravado dez segundos depois de ela conectar, dizia quem estava lá:

```
ana@hq:~$ sudo cat /run/openvpn-status.log
OpenVPN CLIENT LIST
Updated,2026-09-28 18:09:09
Common Name,Real Address,Bytes Received,Bytes Sent,Connected Since
ana,198.51.100.77:35979,3583,3611,2026-09-28 18:08:59
ROUTING TABLE
Virtual Address,Common Name,Real Address,Last Ref
10.8.0.2,ana,198.51.100.77:35979,2026-09-28 18:09:03
GLOBAL STATS
Max bcast/mcast queue length,0
END
ana@hq:~$ sudo grep -E "Peer Connection|primary virtual" /run/openvpn.log
2026-09-28 18:08:59 198.51.100.77:35979 [ana] Peer Connection Initiated with [AF_INET]198.51.100.77:35979
2026-09-28 18:08:59 ana/198.51.100.77:35979 MULTI: primary virtual IP for ana/198.51.100.77:35979: 10.8.0.2
```

**O OpenVPN dá nome à pessoa.** `ana` é o Common Name do certificado com que ela conectou. Ao lado estão o
endereço real de onde veio, `198.51.100.77:35979`, o roteador de casa de novo, e o endereço de túnel
que ela recebeu do pool, `10.8.0.2`. O log diz o mesmo, com horário. Tirar a Ana significa revogar o
certificado dela, com uma lista de revogação que o servidor consulta (`crl-verify`, não configurado
aqui), e o acesso de mais ninguém muda. Com o WireGuard significa apagar a chave pública dela do arquivo
de `hq`; o nome *Ana* sempre foi só um comentário.

## Os dois lado a lado

| | WireGuard | OpenVPN |
|---|---|---|
| um par é | uma chave pública escrita no arquivo do outro | um certificado assinado por uma autoridade |
| transporte | só UDP | UDP, ou TCP quando um firewall insiste (aula 3) |
| criptografia | fixada pelo protocolo | negociada pelo TLS |
| handshake | dois pacotes, 190 e 134 bytes aqui | TLS dentro do canal de controle do OpenVPN |
| onde roda | no kernel (aqui `wireguard-go`, um plano B) | num programa, `openvpn` |
| para um estranho sem a chave | nenhuma resposta | nenhuma resposta, com `tls-crypt` |
| endereços de túnel | escritos por par | um pool, enviado junto com as rotas |
| quem está conectado | chaves e o último handshake | nomes, no arquivo de status |

**A escolha segue quem está do outro lado.** Entre roteadores que a equipe de rede controla, uma lista
de chaves é mais simples que uma autoridade certificadora, e as poucas linhas do WireGuard são difíceis
de errar de um jeito sutil. Para pessoas que entram e saem, os certificados e nomes do OpenVPN servem ao
trabalho, e o modo TCP dele também, em redes que bloqueiam tudo menos as portas web. Produtos feitos
sobre o WireGuard acrescentam a metade que falta, um serviço que distribui chaves por usuário; a aula 5
trata dessa diferença entre um local e uma pessoa.
