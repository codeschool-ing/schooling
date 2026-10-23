---
title: EAP-TLS on the lab's switch
version: 1
---

**EAP-TLS needs three certificates: the authority's, the switch's and the device's.** A real network
uses the organisation's own certificate authority; the lab makes a small one on `sw` with `openssl`,
which is enough to show every part of the exchange. Keep the shells on `sw` and `desk` from the last
sections, and remember that the MAC filter is gone: `desk` currently reaches everything.

## The certificates

On `sw`, the authority signs itself, and then signs a certificate for the switch with the purpose
`serverAuth`:

```
ana@sw:~$ cd nac && openssl req -x509 -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -days 365 -subj "/CN=Jatoba NAC CA" -keyout ca.key -out ca.crt 2>/dev/null && openssl x509 -in ca.crt -noout -subject
subject=CN = Jatoba NAC CA
ana@sw:~$ cd nac && openssl req -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -subj "/CN=sw.jatoba.example" -keyout sw.key -out sw.csr 2>/dev/null && openssl x509 -req -in sw.csr -CA ca.crt -CAkey ca.key -days 365 -extfile <(echo extendedKeyUsage=serverAuth) -out sw.crt
Certificate request self-signature ok
subject=CN = sw.jatoba.example
```

The device's certificate is made the other way round, and the order is the point. **The private key
is generated on `desk` and never leaves it**: `desk` sends only a certificate signing request, the
authority signs it with the purpose `clientAuth`, and `desk` fetches the signed certificate and the
authority's own.

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

`ls` shows what `desk` holds before the signature comes back: its key and its request. A key that
was made elsewhere and copied over is a key that also exists elsewhere.

## The authenticator

Three files on `sw`. `hostapd.conf` makes `hostapd` act as the authenticator on `port-desk`, with
the `wired` driver because there is no radio, and with its built-in EAP server standing in for
RADIUS. `eap_user` accepts any identity that completes TLS, because the certificate is the
identity. `nac.nft` closes the port to everything except EAPOL, until the address is in the set
`authorised`. And `port-control.sh` is the glue: `hostapd_cli` calls it on every login and logoff,
and it adds or removes the device's address and writes a line to the journal.

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

Load the filter, start `hostapd` in the background, and start `hostapd_cli` with the script:

```
ana@sw:~$ sudo nft -f nac/nac.nft && chmod +x nac/port-control.sh && sudo hostapd -B -P /run/hostapd.pid nac/hostapd.conf
port-desk: interface state UNINITIALIZED->ENABLED
port-desk: AP-ENABLED 
ana@sw:~$ sudo hostapd_cli -B -a /home/ana/nac/port-control.sh && sudo hostapd_cli status | grep ^state
state=ENABLED
ana@desk:~$ ping -c1 -W1 web | tail -2
1 packets transmitted, 0 received, 100% packet loss, time 0ms
```

`hostapd` reports the port enabled, and `desk` has lost the network: its ping is dropped, because
nothing has logged in on `port-desk`.

## The supplicant

`desk`'s side is one file. `key_mgmt=IEEE8021X` and `ap_scan=0` mean wired 802.1X, and the three
paths name the authority it trusts, its own certificate and its key:

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

`wpa_cli status` reports the login in the standard's own words: the supplicant's state machine is
`AUTHENTICATED`, the port is `Authorized`, and the method was EAP-TLS, number 13. The ping goes
through again. On `sw`, the set holds `desk`'s address and the journal names the port and the
address that opened it:

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

## The address is now bound to the login

The port opened for the address that logged in, and only for it. Change `desk`'s address while it is
logged in, to the printer's as in the last section:

```
ana@desk:~$ sudo ip link set eth0 address 52:54:00:a8:3c:63; ping -c1 -W1 web | tail -2
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@desk:~$ sudo ip link set eth0 address 52:54:00:a8:3c:14; ping -c1 -W1 web | tail -2
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.073/0.073/0.073/0.000 ms
```

Refused, and back as soon as the address is the authenticated one again. The address can still be
written by the device, but it now has to match a login made with a key the network signed.

## Logging off

```
ana@desk:~$ sudo wpa_cli logoff >/dev/null; sleep 2; ping -c1 -W1 web | tail -2
1 packets transmitted, 0 received, 100% packet loss, time 0ms

ana@sw:~$ sudo journalctl -t nac --no-pager -o cat
port-desk 52:54:00:a8:3c:14 authorised
port-desk 52:54:00:a8:3c:14 closed
```

A logoff closes the port at once, and the journal has both lines. That journal is where a real
network's evidence lives too, on the RADIUS server: which credential opened which port, when, and for
which address, which is the inventory of lesson 18 seen from the network's side.
