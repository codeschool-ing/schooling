---
title: Quando a resposta é não
version: 1
---

Um controle se prova pelo caso que ele recusa. O `visitor` tem um certificado, mas um que ele mesmo
assinou, como faria qualquer coisa não emitida pela empresa:

```
root@visitor:~# openssl x509 -in client.crt -noout -subject -issuer -enddate
subject=CN = visitor
issuer=CN = visitor
notAfter=Oct 28 21:33:52 2026 GMT
```

Titular e emissor têm o mesmo nome: ninguém responde por ele além dele mesmo. Ele passa pela mesma troca:

```
root@visitor:~# wpa_supplicant -B -D wired -i eth0 -c wpa.conf -f /var/log/lab/wpa.log -P /root/wpa.pid
root@visitor:~# grep -o "CTRL-EVENT-EAP-[A-Z-]*.*" /var/log/lab/wpa.log
CTRL-EVENT-EAP-STARTED EAP authentication started
CTRL-EVENT-EAP-PROPOSED-METHOD vendor=0 method=13
CTRL-EVENT-EAP-METHOD EAP vendor 0 method 13 (TLS) selected
CTRL-EVENT-EAP-PEER-CERT depth=2 subject='/O=Example Corp/CN=Example Corp Root CA' hash=4e468466047a2a0d3e41dea919a03f501aa8e4fbc729ca24b48b0a5958d9b6d1
CTRL-EVENT-EAP-PEER-CERT depth=1 subject='/O=Example Corp/CN=Example Corp Issuing CA' hash=0ce47ebee9d7875955b7c437837e25ef259f4cf795f8bbfbd8dbaa02bbbb67b3
CTRL-EVENT-EAP-PEER-CERT depth=0 subject='/CN=nac.corp.example.com' hash=7f9e686cbcc1c26742e54841dd6322b2ffe516642d3ee01baa205686839541cb
CTRL-EVENT-EAP-PEER-ALT depth=0 DNS:nac.corp.example.com
CTRL-EVENT-EAP-FAILURE EAP authentication failed
```

O cliente conferiu o certificado da rede e ficou satisfeito, o que está certo; a rede é legítima. Quem
recusou foi o **servidor**, e o log do switch diz por quê:

```
root@sw:~# grep -E "^p2: |verification failed" /var/log/lab/hostapd.log
p2: interface state UNINITIALIZED->ENABLED
p2: AP-ENABLED 
p2: CTRL-EVENT-EAP-STARTED 52:54:00:a8:0a:1f
p2: CTRL-EVENT-EAP-PROPOSED-METHOD vendor=0 method=1
p2: CTRL-EVENT-EAP-PROPOSED-METHOD vendor=0 method=13
TLS: Certificate verification failed, error 18 (self-signed certificate) depth 0 for '/CN=visitor'
p2: CTRL-EVENT-EAP-FAILURE 52:54:00:a8:0a:1f
p2: STA 52:54:00:a8:0a:1f IEEE 802.1X: authentication failed - EAP type: 0 (unknown)
p2: STA 52:54:00:a8:0a:1f IEEE 802.1X: Supplicant used different EAP type: 13 (TLS)
```

`error 18 (self-signed certificate)` é o motivo, e `CTRL-EVENT-EAP-FAILURE` é o veredito. As duas linhas
depois dela são a contabilidade do hostapd; o `EAP type: 0 (unknown)` nelas não é uma segunda falha. Nada
foi acrescentado ao conjunto, então a porta está tão fechada quanto antes:

```
ana@visitor:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1020ms
```

A reação costumeira a uma porta fechada é pegar emprestado um endereço que já é permitido. O `visitor`
para o seu suplicante e assume o endereço MAC do `newpc`:

```
root@visitor:~# kill $(cat wpa.pid)
root@visitor:~# ip link set eth0 down; ip link set eth0 address 52:54:00:a8:0a:1e; ip link set eth0 up
ana@visitor:~$ ip -br link show eth0
eth0@if1858      UP             52:54:00:a8:0a:1e <BROADCAST,MULTICAST,UP,LOWER_UP> 
ana@visitor:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1004ms

ana@newpc:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.
64 bytes from 192.168.10.1: icmp_seq=1 ttl=64 time=0.045 ms
64 bytes from 192.168.10.1: icmp_seq=2 ttl=64 time=0.062 ms

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1022ms
rtt min/avg/max/mdev = 0.045/0.053/0.062/0.008 ms
```

Continua fechada, e o `newpc` não é afetado, porque o conjunto guarda o par **porta e endereço**,
`"p1" . 52:54:00:a8:0a:1e`, e o `visitor` está na `p2`. Um filtro indexado só pelo endereço MAC o teria
deixado passar.

É também aí que o 802.1X para, e um defensor deve conhecer os limites:

| lacuna | o que acontece | o que a fecha |
|---|---|---|
| um dispositivo atrás de uma porta autorizada | o 802.1X autentica a porta uma vez; um switch pequeno posto entre o laptop e a parede pode levar uma segunda máquina, usando o endereço do laptop | o **MACsec** (802.1AE), que cifra e autentica cada quadro no link, não só o início dele |
| dispositivos que não conseguem se autenticar | impressoras e telefones sem suplicante costumam entrar só pelo endereço MAC (**MAB**, MAC authentication bypass) | um segmento separado para eles, com as regras da aula 21; um endereço MAC vem escrito numa etiqueta e não é segredo |
| uma falha que ainda precisa de um lugar para ir | um convidado recusado ou um laptop sem boa saúde | uma **VLAN de convidados ou de quarentena** atribuída pelo servidor RADIUS, em vez de uma porta fechada |

Cada lacuna é algo a testar de propósito numa auditoria, do jeito que esta seção testou o endereço
emprestado. Nenhuma delas exige desligar o 802.1X para conferir.
