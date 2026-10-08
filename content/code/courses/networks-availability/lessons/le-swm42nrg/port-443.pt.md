---
title: A porta 443, e o que ela custa
version: 1
---

A rede de hóspedes de um hotel, o escritório de um cliente, algumas operadoras móveis: muitas redes
deixam sair tráfego web e pouco mais. Transforme o roteador doméstico numa dessas, em `homegw`:

```sh
sudo nft add table ip filter
sudo nft add chain ip filter forward '{ type filter hook forward priority 0; policy drop; }'
sudo nft add rule ip filter forward ct state established,related accept
sudo nft add rule ip filter forward iifname eth0 tcp dport 443 accept
sudo nft add rule ip filter forward iifname eth0 udp dport 53 accept
```

Esta é a cadeia de encaminhamento dele:

```
ana@homegw:~$ sudo nft list chain ip filter forward
table ip filter {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related accept
		iifname "eth0" tcp dport 443 accept
		iifname "eth0" udp dport 53 accept
	}
}
```

Política `drop`, com três exceções: respostas a conversas já abertas, TCP para a porta 443 e DNS. **UDP
para a porta 1194 não é nenhuma delas**, e o cliente, com oito segundos, chegou só até dizer o nome do
servidor:

```
ana@remote:~$ cd /etc/openvpn && sudo timeout 8 openvpn --config client.conf | grep -E "link remote|Initialization"
2026-09-28 18:08:10 UDPv4 link remote: [AF_INET]203.0.113.2:1194
```

Nenhum erro, nenhuma recusa, nenhum `Initialization Sequence Completed`. Os pacotes saíram do laptop e
morreram no roteador doméstico, que é o que um firewall com política `drop` faz, e o cliente ficou
esperando resposta. Os dois arquivos mudam então em duas linhas cada: o servidor para `proto tcp-server`
e `port 443`, o cliente para `proto tcp-client` e `remote vpn.example.com 443`. O servidor só lê o
arquivo quando começa, então pare-o antes, na máquina virtual, com `sudo bash netlab.sh kill hq openvpn`.
Depois, em `hq`:

```sh
sudo sed -i 's/^proto udp$/proto tcp-server/; s/^port 1194$/port 443/' /etc/openvpn/server.conf
sudo setsid openvpn --cd /etc/openvpn --config server.conf >/dev/null 2>&1 &
```

E em `remote`, antes de tentar de novo:

```sh
sudo sed -i 's/^proto udp$/proto tcp-client/; s/ 1194$/ 443/' /etc/openvpn/client.conf
```

```
ana@remote:~$ cd /etc/openvpn && sudo timeout 6 openvpn --config client.conf | grep -E "TCP connection|Peer Connection|Initialization"
2026-09-28 18:08:20 Attempting to establish TCP connection with [AF_INET]203.0.113.2:443
2026-09-28 18:08:20 TCP connection established with [AF_INET]203.0.113.2:443
2026-09-28 18:08:20 [vpn.example.com] Peer Connection Initiated with [AF_INET]203.0.113.2:443
2026-09-28 18:08:20 Initialization Sequence Completed
```

**De pé no mesmo segundo.** Para o roteador doméstico, é só mais uma conexão TCP para a porta 443, que
ele deixa sair porque deixa sair toda página web. Esse é o motivo de a maioria das VPNs TLS poder recuar
para TCP 443, e o motivo de firewalls que levam isso a sério olharem além da porta. **A porta 443 passa
por um firewall que filtra por porta, e não faz o túnel parecer uma página web.** A primeira mensagem do
cliente é o `HARD_RESET` do OpenVPN, como a captura do handshake mostrou sobre UDP, e não um `Client
Hello` do TLS. Um firewall que lê o que encaminha percebe a diferença.

## TCP dentro de TCP

Sobre TCP o túnel funciona, e é o pior jeito de rodar um, por um motivo que este laboratório não
consegue mostrar: nenhum enlace aqui perde pacote ou demora. **O que dá errado são duas camadas de
retransmissão empilhadas.** As conexões TCP do próprio laptop, um download por exemplo, passam a viajar
dentro da conexão TCP do túnel. Quando o caminho perde um pacote do túnel, o TCP do túnel para de
entregar tudo o que vem atrás até o perdido ser reenviado. O download lá dentro vê os dados travarem,
acha que a perda é dele e retransmite também, numa conexão que já está se recuperando. Cada camada
recua, com temporizadores ajustados para um enlace, e não para outro TCP.

Num caminho limpo ninguém percebe. Num caminho com perda, a vazão pode desabar muito abaixo do que
qualquer das camadas conseguiria sozinha, o que o pessoal chama de **TCP meltdown**. Por isso o conselho
de costume é UDP primeiro, e TCP 443 só onde o UDP é bloqueado. Alguns clientes de VPN TLS fazem isso
sozinhos, tentando DTLS, TLS sobre UDP, e recuando para TCP 443 quando falha; este laboratório rodou o
OpenVPN e não testou nenhum deles.

## O portal no navegador

A outra coisa vendida como VPN SSL não precisa de cliente nenhum. A pessoa abre `https://` num navegador,
entra num portal e recebe uma página de links para aplicações web internas. **Não há túnel nem rota**: o
gateway busca cada página interna em nome da pessoa e a repassa, um proxy reverso com um login na
frente. Funciona numa máquina em que ninguém instalou nada, alcança só o que o portal publica, e o que não
for aplicação web precisa de um plug-in ou de um cliente de verdade. Isto não rodou no laboratório; a aula
5 volta ao acesso por aplicação como alternativa a uma VPN.
