---
title: A VPN whose handshake is TLS
version: 1
---

"SSL VPN" suggests a web page in a browser, and some products are exactly that. Most of what is sold
under the name is something else: **a program on the laptop that opens a tunnel, and uses TLS only to
check certificates and agree on keys.** The name is historical. SSL was replaced by TLS long ago, and the
handshake in this lesson is TLS 1.3, the version lesson 5 of `networks` took apart for HTTPS.

What it changes, compared with IPsec, is where the VPN lives. IPsec is part of the operating system's
network layer, with its own IP protocol, 50, and its own UDP ports, 500 and 4500. **A TLS VPN is an
ordinary program talking over one ordinary port**, UDP or TCP, and its certificates are the same kind a
web server uses. That makes it easy to install on anything, and easy to get through a firewall, which is
the subject of the section on port 443.

OpenVPN is the TLS VPN this lab runs: a server on `hq`, and a client on `remote`, the laptop at home
behind the home router. Both configuration files were printed with `cat`. The server's:

```schooling-example
{"language": "conf", "file": "server.conf", "parts": [{"code": "dev tun\nproto udp\nport 1194\nserver 10.8.0.0 255.255.255.0\ntopology subnet", "note": "A routed tunnel, `tun`, carrying IP packets, over UDP port 1194. `server` hands out addresses from `10.8.0.0/24` and takes the first for itself, and `topology subnet` gives every client one address on that network, like a LAN."}, {"code": "ca ca.crt\ncert vpn-server.crt\nkey vpn-server.key", "note": "The authority that signed every certificate in this VPN, and the server's own certificate and key. A client whose certificate that authority did not sign is refused during the handshake."}, {"code": "dh none", "note": "No file of classic Diffie-Hellman parameters: the key exchange is done with elliptic curves only, which is what the client later reports as X25519."}, {"code": "push \"route 192.168.10.0 255.255.255.0\"", "note": "A route the server pushes to every client, so that the head office's network goes into the tunnel. The client did not have to know it."}, {"code": "keepalive 10 60", "note": "Sends a keepalive every 10 seconds, and treats 60 seconds of silence as a dead tunnel."}]}
```

And the client's, which is shorter because the server pushes what the client needs to know:

```schooling-example
{"language": "conf", "file": "client.conf", "parts": [{"code": "client\ndev tun\nproto udp\nremote vpn.example.com 1194", "note": "A client, on the same kind of device and transport as the server, pointed at the server's name and port."}, {"code": "ca ca.crt\ncert vpn-ana.crt\nkey vpn-ana.key", "note": "The same authority, and this person's own certificate and key: the server checks this certificate as the client checks the server's."}, {"code": "remote-cert-tls server\nverify-x509-name vpn.example.com name", "note": "The two lines that make the client refuse an impostor. `remote-cert-tls server` demands a certificate issued for a server, so another person's client certificate cannot pose as one; `verify-x509-name` demands the name `vpn.example.com`."}, {"code": "verb 3", "note": "How much to log. Level 3 is what prints the lines read in the next section."}]}
```

**Both sides prove who they are with a certificate**, signed by the lab's own authority, `ca.crt`.
**There is no shared secret anywhere in either file**, so removing one person means revoking one
certificate, the problem the last lesson ended on. The server's certificate says `vpn.example.com`, and
the client refuses any other name, exactly as a browser refuses a web server whose certificate names
somebody else.

The device, `dev tun`, is a TUN interface like the one lesson 1's `tunnel.py` used: IP packets in and
out, routed, one subnet at each end. OpenVPN can also run `dev tap`, which carries Ethernet frames
instead, and the section on stretching a LAN says when that is worth it.
