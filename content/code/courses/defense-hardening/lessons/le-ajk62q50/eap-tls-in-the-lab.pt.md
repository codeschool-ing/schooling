---
title: EAP-TLS no switch do laboratório
version: 1
---

**O EAP-TLS precisa de três certificados: o da autoridade, o do switch e o do dispositivo.** Uma rede
de verdade usa a autoridade certificadora da própria organização; o laboratório faz uma pequena no
`sw` com `openssl`, o que basta para mostrar cada parte da troca. Mantenha os shells no `sw` e no
`desk` das seções anteriores, e lembre que o filtro de MAC saiu: o `desk` alcança tudo agora.

## Os certificados

No `sw`, a autoridade assina a si mesma, e depois assina um certificado para o switch com a
finalidade `serverAuth`:

```
ana@sw:~$ cd nac && openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 365 -subj "/CN=Jatoba NAC CA" -keyout ca.key -out ca.crt 2>/dev/null && openssl x509 -in ca.crt -noout -subject
subject=CN = Jatoba NAC CA
ana@sw:~$ cd nac && openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=sw.jatoba.example" -keyout sw.key -out sw.csr 2>/dev/null && openssl x509 -req -in sw.csr -CA ca.crt -CAkey ca.key -days 365 -extfile <(echo extendedKeyUsage=serverAuth) -out sw.crt
Certificate request self-signature ok
subject=CN = sw.jatoba.example
```

O certificado do dispositivo é feito ao contrário, e a ordem é o ponto. **A chave privada é gerada no
`desk` e nunca sai de lá**: o `desk` manda só um pedido de assinatura de certificado, a autoridade o
assina com a finalidade `clientAuth`, e o `desk` busca o certificado assinado e o da própria
autoridade.

```
ana@desk:~$ cd nac && openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=desk.jatoba.example" -keyout desk.key -out desk.csr 2>/dev/null && scp -q desk.csr sw:nac/ && ls
desk.csr
desk.key
wpa.conf
ana@sw:~$ cd nac && openssl x509 -req -in desk.csr -CA ca.crt -CAkey ca.key -days 365 -extfile <(echo extendedKeyUsage=clientAuth) -out desk.crt
Certificate request self-signature ok
subject=CN = desk.jatoba.example
ana@desk:~$ cd nac && scp -q sw:nac/desk.crt sw:nac/ca.crt . && openssl x509 -in desk.crt -noout -subject -issuer -ext extendedKeyUsage
subject=CN = desk.jatoba.example
issuer=CN = Jatoba NAC CA
X509v3 Extended Key Usage: 
    TLS Web Client Authentication
```

O `ls` mostra o que o `desk` tem antes de a assinatura voltar: a chave e o pedido. Uma chave feita em
outro lugar e copiada é uma chave que também existe em outro lugar.

## O autenticador

Três arquivos no `sw`. O `hostapd.conf` faz o `hostapd` agir como autenticador na `port-desk`, com o
driver `wired` porque não há rádio, e com o servidor EAP embutido no lugar do RADIUS. O `eap_user`
aceita qualquer identidade que complete o TLS, porque o certificado é a identidade. O `nac.nft` fecha
a porta para tudo menos EAPOL, até o endereço estar no conjunto `authorised`. E o `port-control.sh` é
a cola: o `hostapd_cli` o chama a cada login e logoff, e ele acrescenta ou tira o endereço do
dispositivo e escreve uma linha no journal.

```
ana@sw:~$ cat nac/hostapd.conf; echo "* TLS" > nac/eap_user
interface=port-desk
driver=wired
ieee8021x=1
eap_server=1
eap_user_file=/home/ana/nac/eap_user
ca_cert=/home/ana/nac/ca.crt
server_cert=/home/ana/nac/sw.crt
private_key=/home/ana/nac/sw.key
ctrl_interface=/run/hostapd
logger_stdout=-1
logger_stdout_level=2
ana@sw:~$ cat nac/nac.nft nac/port-control.sh
table netdev nac {
	set authorised {
		type ether_addr
	}

	chain desk_port {
		type filter hook ingress device "port-desk" priority filter; policy drop;
		ether type 0x888e accept
		ether saddr @authorised accept
		counter
	}
}
#!/bin/bash
# called by hostapd_cli -a: $1 interface, $2 event, $3 the client's MAC
case $2 in
  AP-STA-CONNECTED)
    nft add element netdev nac authorised "{ $3 }"
    logger -t nac "$1 $3 authorised" ;;
  AP-STA-DISCONNECTED)
    nft delete element netdev nac authorised "{ $3 }"
    logger -t nac "$1 $3 closed" ;;
esac
```

Carregue o filtro, inicie o `hostapd` em segundo plano e inicie o `hostapd_cli` com o script:

```
ana@sw:~$ sudo nft -f nac/nac.nft && chmod +x nac/port-control.sh && sudo hostapd -B -P /run/hostapd.pid nac/hostapd.conf
port-desk: interface state UNINITIALIZED->ENABLED
port-desk: AP-ENABLED 
ana@sw:~$ sudo hostapd_cli -B -a /home/ana/nac/port-control.sh && sudo hostapd_cli status | grep ^state
state=ENABLED
ana@desk:~$ ping -c1 -W1 web | tail -2
1 packets transmitted, 0 received, 100% packet loss, time 0ms
```

O `hostapd` informa a porta habilitada, e o `desk` perdeu a rede: o ping é descartado, porque ninguém
fez login na `port-desk`.

## O suplicante

O lado do `desk` é um arquivo. `key_mgmt=IEEE8021X` e `ap_scan=0` querem dizer 802.1X cabeado, e os
três caminhos dizem em que autoridade ele confia, o próprio certificado e a chave:

```
ana@desk:~$ cat nac/wpa.conf
ctrl_interface=/run/wpa_supplicant
ap_scan=0
network={
    key_mgmt=IEEE8021X
    eap=TLS
    identity="desk.jatoba.example"
    ca_cert="/home/ana/nac/ca.crt"
    client_cert="/home/ana/nac/desk.crt"
    private_key="/home/ana/nac/desk.key"
    eapol_flags=0
}
ana@desk:~$ sudo wpa_supplicant -B -D wired -i eth0 -c nac/wpa.conf; sleep 3; sudo wpa_cli status | grep -E "PAE|PortStatus|EAP state|selectedMethod"
Successfully initialized wpa_supplicant
Supplicant PAE state=AUTHENTICATED
suppPortStatus=Authorized
EAP state=SUCCESS
selectedMethod=13 (EAP-TLS)
ana@desk:~$ ping -c1 -W1 web | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.070/0.070/0.070/0.000 ms
```

O `wpa_cli status` informa o login nas palavras do próprio padrão: a máquina de estados do suplicante
está `AUTHENTICATED`, a porta está `Authorized`, e o método foi EAP-TLS, número 13. O ping volta a
passar. No `sw`, o conjunto tem o endereço do `desk` e o journal cita a porta e o endereço que a
abriu:

```
ana@sw:~$ sudo nft list set netdev nac authorised
table netdev nac {
	set authorised {
		type ether_addr
		elements = { 52:54:00:a8:3c:14 }
	}
}
ana@sw:~$ sudo journalctl -t nac --no-pager -o cat
port-desk 52:54:00:a8:3c:14 authorised
```

## O endereço agora está preso ao login

A porta abriu para o endereço que fez login, e só para ele. Mude o endereço do `desk` com ele logado,
para o da impressora como na seção anterior:

```
ana@desk:~$ sudo ip link set eth0 address 52:54:00:a8:3c:63; ping -c1 -W1 web | tail -2
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@desk:~$ sudo ip link set eth0 address 52:54:00:a8:3c:14; ping -c1 -W1 web | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.073/0.073/0.073/0.000 ms
```

Recusado, e de volta assim que o endereço é de novo o autenticado. O endereço continua podendo ser
escrito pelo dispositivo, mas agora precisa bater com um login feito com uma chave que a rede
assinou.

## Fazendo logoff

```
ana@desk:~$ sudo wpa_cli logoff >/dev/null; sleep 2; ping -c1 -W1 web | tail -2
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@sw:~$ sudo journalctl -t nac --no-pager -o cat
port-desk 52:54:00:a8:3c:14 authorised
port-desk 52:54:00:a8:3c:14 closed
```

Um logoff fecha a porta na hora, e o journal tem as duas linhas. Esse journal é onde também mora a
evidência de uma rede de verdade, no servidor RADIUS: que credencial abriu que porta, quando, e para
que endereço, que é o inventário da aula 18 visto pelo lado da rede.
