---
title: EAP-TLS, a certificate at the door
version: 1
---

EAP is a frame for many methods. The ones met most often are **PEAP** and **EAP-TTLS**, which open a
TLS tunnel and send a password inside it, and **EAP-TLS**, where both sides present a certificate and
no password exists at all. EAP-TLS is the strongest of them, because there is nothing a user can type
into a fake login page, and nothing to guess. Its cost is that every device needs a certificate, and
lesson 12's CA is what issues them.

`newpc` has one, issued by the lab's issuing CA:

```
root@newpc:~# openssl x509 -in client.crt -noout -subject -issuer -enddate
subject=CN = newpc.corp.example.com
issuer=O = Example Corp, CN = Example Corp Issuing CA
notAfter=Dec 28 00:00:00 2026 GMT
```

The supplicant's configuration names the method, the certificate and, just as important, the CA that
the **network's** certificate must chain to:

```schooling-example
{"language": "conf", "file": "wpa.conf", "parts": [{"code": "ctrl_interface=/root/wpa-ctrl\nap_scan=0", "note": "A control socket for wpa_cli, and ap_scan=0 because there are no access points to scan for on a cable."}, {"code": "network={\n    key_mgmt=IEEE8021X\n    eap=TLS\n    identity=\"newpc.corp.example.com\"", "note": "Port authentication with EAP-TLS. The identity is the name the machine announces; the certificate is what proves it."}, {"code": "    ca_cert=\"/root/ca.crt\"", "note": "The CA the switch's certificate must chain to. Without it, the laptop would complete the exchange with any authenticator, including one somebody else plugged in."}, {"code": "    client_cert=\"/root/client.crt\"\n    private_key=\"/root/client.key\"", "note": "The laptop's own certificate and key, which the server checks against its CA."}, {"code": "    eapol_flags=0\n}", "note": "No keys are derived for the link afterwards. Wi-Fi uses them to encrypt, and a cable here does not."}]}
```

The administrator starts the supplicant, and after a few seconds the log shows the exchange:

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

Read the certificate lines from the bottom of the chain up. `depth=0` is the switch's own certificate,
`nac.corp.example.com`, and `depth=1` and `depth=2` are the issuing and root CAs above it. The
supplicant checked the network before it offered anything; the server then checked the laptop's
certificate the same way, and the last line is its answer.

On the switch, the control script has done its job:

```
root@sw:~# nft list set netdev ports authorised
table netdev ports {
	set authorised {
		type ifname . ether_addr
		elements = { "p1" . 52:54:00:a8:0a:1e }
	}
}
```

And `newpc`, with the same address and the same cable as before, now reaches the LAN:

```
ana@newpc:~$ ping -c 2 -W 1 192.168.10.1
PING 192.168.10.1 (192.168.10.1) 56(84) bytes of data.
64 bytes from 192.168.10.1: icmp_seq=1 ttl=64 time=0.226 ms
64 bytes from 192.168.10.1: icmp_seq=2 ttl=64 time=0.090 ms

--- 192.168.10.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1003ms
rtt min/avg/max/mdev = 0.090/0.158/0.226/0.068 ms
```

**Authentication is mutual here, and that is the point of `ca_cert`.** A supplicant set up to accept
any server certificate would hand its exchange to whatever answered on the cable. With EAP-TLS that
leaks no password, but with PEAP it hands over a challenge and response that can be attacked offline to
recover the password. Checking
the server is not optional in any method, and lesson 13 made the same argument about TLS in a browser.
