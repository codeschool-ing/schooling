---
title: EAP-TLS, um certificado na porta
version: 1
---

O EAP é uma moldura para muitos métodos. Os mais comuns são o **PEAP** e o **EAP-TTLS**, que abrem um
túnel TLS e mandam uma senha dentro dele, e o **EAP-TLS**, em que os dois lados apresentam um certificado
e não existe senha nenhuma. O EAP-TLS é o mais forte deles, porque não há nada que um usuário possa
digitar numa página de login falsa, e nada para adivinhar. O custo é que todo dispositivo precisa de um
certificado, e é a CA da aula 12 que os emite.

O `newpc` tem um, emitido pela CA emissora do laboratório:

```
root@newpc:~# openssl x509 -in client.crt -noout -subject -issuer -enddate
subject=CN = newpc.corp.example.com
issuer=O = Example Corp, CN = Example Corp Issuing CA
notAfter=Dec 28 00:00:00 2026 GMT
```

A configuração do suplicante nomeia o método, o certificado e, tão importante quanto, a CA até a qual o
certificado **da rede** precisa formar cadeia:

```schooling-example
{"language": "conf", "file": "wpa.conf", "parts": [{"code": "ctrl_interface=/root/wpa-ctrl\nap_scan=0", "note": "Um socket de controle para o wpa_cli, e ap_scan=0 porque num cabo não há pontos de acesso para procurar."}, {"code": "network={\n    key_mgmt=IEEE8021X\n    eap=TLS\n    identity=\"newpc.corp.example.com\"", "note": "Autenticação de porta com EAP-TLS. A identidade é o nome que a máquina anuncia; o certificado é o que o prova."}, {"code": "    ca_cert=\"/root/ca.crt\"", "note": "A CA até a qual o certificado do switch precisa formar cadeia. Sem ela, o laptop completaria a troca com qualquer autenticador, inclusive um que outra pessoa tivesse ligado."}, {"code": "    client_cert=\"/root/client.crt\"\n    private_key=\"/root/client.key\"", "note": "O certificado e a chave do próprio laptop, que o servidor confere contra a sua CA."}, {"code": "    eapol_flags=0\n}", "note": "Nenhuma chave é derivada para o link depois. O Wi-Fi as usa para cifrar, e um cabo aqui não."}]}
```

O administrador inicia o suplicante e, depois de alguns segundos, o log mostra a troca:

```
root@newpc:~# wpa_supplicant -B -D wired -i eth0 -c wpa.conf -f /var/log/lab/wpa.log -P /root/wpa.pid
root@newpc:~# grep -o "CTRL-EVENT-EAP-[A-Z-]*.*" /var/log/lab/wpa.log
CTRL-EVENT-EAP-STARTED EAP authentication started
CTRL-EVENT-EAP-PROPOSED-METHOD vendor=0 method=13
CTRL-EVENT-EAP-METHOD EAP vendor 0 method 13 (TLS) selected
CTRL-EVENT-EAP-PEER-CERT depth=2 subject='/O=Example Corp/CN=Example Corp Root CA' hash=4e468466047a2a0d3e41dea919a03f501aa8e4fbc729ca24b48b0a5958d9b6d1
CTRL-EVENT-EAP-PEER-CERT depth=1 subject='/O=Example Corp/CN=Example Corp Issuing CA' hash=0ce47ebee9d7875955b7c437837e25ef259f4cf795f8bbfbd8dbaa02bbbb67b3
CTRL-EVENT-EAP-PEER-CERT depth=0 subject='/CN=nac.corp.example.com' hash=7f9e686cbcc1c26742e54841dd6322b2ffe516642d3ee01baa205686839541cb
CTRL-EVENT-EAP-PEER-ALT depth=0 DNS:nac.corp.example.com
CTRL-EVENT-EAP-SUCCESS EAP authentication completed successfully
```

Leia as linhas de certificado de baixo para cima na cadeia. `depth=0` é o próprio certificado do switch,
`nac.corp.example.com`, e `depth=1` e `depth=2` são as CAs emissora e raiz acima dele. O suplicante
conferiu a rede antes de oferecer qualquer coisa; o servidor então conferiu o certificado do laptop do
mesmo jeito, e a última linha é a resposta dele.

No switch, o script de controle fez o seu trabalho:

```
root@sw:~# nft list set netdev ports authorised
table netdev ports {
	set authorised {
		type ifname . ether_addr
		elements = { "p1" . 52:54:00:a8:0a:1e }
	}
}
```

E o `newpc`, com o mesmo endereço e o mesmo cabo de antes, agora alcança a LAN:

```
ana@newpc:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.
64 bytes from 192.168.10.1: icmp_seq=1 ttl=64 time=0.226 ms
64 bytes from 192.168.10.1: icmp_seq=2 ttl=64 time=0.090 ms

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.090/0.158/0.226/0.068 ms
```

**A autenticação aqui é mútua, e é para isso que serve o `ca_cert`.** Um suplicante configurado para
aceitar qualquer certificado de servidor entregaria a sua troca a quem quer que respondesse no cabo. Com
EAP-TLS isso não vaza senha nenhuma, mas com PEAP entrega um desafio e uma resposta que podem ser atacados
offline para recuperar a senha. Conferir o servidor não é opcional em método nenhum, e a aula 13 fez o
mesmo argumento sobre TLS no navegador.
