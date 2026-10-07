---
title: The handshake, and the two channels
version: 1
---

The client was started by hand for six seconds, with its log filtered to the lines that say what was
agreed, while the ISP's router captured UDP 1194. Start the capture on `isp` first, then the client on
`remote`:

```
ana@remote:~$ cd /etc/openvpn && sudo timeout 6 openvpn --config client.conf | grep -E "VERIFY OK|Control Channel:|Data Channel:|Initialization"
2026-09-28 18:07:59 VERIFY OK: depth=1, O=Example Lab, CN=Example Lab Root CA
2026-09-28 18:07:59 VERIFY OK: depth=0, CN=vpn.example.com
2026-09-28 18:07:59 Control Channel: TLSv1.3, cipher TLSv1.3 TLS_AES_256_GCM_SHA384, peer certificate: 2048 bits RSA, signature: RSA-SHA256, peer temporary key: 253 bits X25519
2026-09-28 18:07:59 Initialization Sequence Completed
2026-09-28 18:07:59 Data Channel: cipher 'AES-256-GCM', peer-id: 0
```

**`VERIFY OK` appears twice because a certificate is checked as a chain**, from the authority down.
`depth=1` is the lab's root, which the client trusts because `ca.crt` says so. `depth=0` is the server,
`CN=vpn.example.com`, signed by that root, and the name `verify-x509-name` asked for. Had either check
failed, the log would have said so here and the tunnel would not have started.

The next line is the whole of TLS's job: `Control Channel: TLSv1.3`, a 2048-bit RSA certificate on the
server, and an X25519 key exchange, the elliptic-curve Diffie-Hellman that `dh none` left as the only
kind. The last line is the other half. **`Data Channel: cipher 'AES-256-GCM'` is not TLS**: the traffic
does not travel as TLS records at all, but in OpenVPN's own packets, encrypted with keys the handshake
produced.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"remote at 198.51.100.77 and hq at 203.0.113.2, joined by one UDP conversation on port 1194. Inside it run two channels. The control channel carries P_CONTROL packets with TLS 1.3 inside: certificates in both directions and the key exchange. The data channel carries P_DATA packets encrypted with AES-256-GCM: the packets of tun0, which are not TLS records. An arrow labelled keys goes from the control channel to the data channel.\"><defs><marker id=\"ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"56\" width=\"120\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">remote</text><text x=\"80.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.77</text><rect x=\"580\" y=\"56\" width=\"120\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">hq</text><text x=\"640.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">203.0.113.2</text><rect x=\"160\" y=\"20\" width=\"400\" height=\"186\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one UDP conversation, port 1194</text><rect x=\"176\" y=\"50\" width=\"368\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">control channel</text><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P_CONTROL + TLSv1.3</text><text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">certificates both ways, key exchange</text><rect x=\"176\" y=\"128\" width=\"368\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">data channel</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">P_DATA, AES-256-GCM</text><text x=\"360\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the packets of tun0, not TLS records</text><path d=\"M500 114 L500 128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"508\" y=\"121\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">keys</text><path d=\"M140 82 L176 82\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M544 82 L580 82\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M140 160 L176 160\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M544 160 L580 160\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "OpenVPN's two channels. TLS does the handshake and nothing else; the traffic travels in OpenVPN's own packets, with keys the handshake produced."}
```

On the ISP's router, tshark decoded the same six seconds:

```
ana@isp:~$ tshark -n -i eth0 -c 12 -f "udp port 1194"
Capturing on 'eth0'
12 packets captured
    1 0.000000000 198.51.100.77 → 203.0.113.2  OpenVPN 56 MessageType: P_CONTROL_HARD_RESET_CLIENT_V2
    2 0.000164366  203.0.113.2 → 198.51.100.77 OpenVPN 68 MessageType: P_CONTROL_HARD_RESET_SERVER_V2
    3 0.000266724 198.51.100.77 → 203.0.113.2  TLSv1 345 Client Hello
    4 0.001805037  203.0.113.2 → 198.51.100.77 TLSv1.3 1264 Server Hello, Change Cipher Spec, Application Data, Application Data
    5 0.001838623  203.0.113.2 → 198.51.100.77 TLSv1.3 1264 Continuation Data
    6 0.001846940  203.0.113.2 → 198.51.100.77 TLSv1.3 79 Continuation Data
    7 0.002041436 198.51.100.77 → 203.0.113.2  OpenVPN 68 MessageType: P_ACK_V1
    8 0.002694277 198.51.100.77 → 203.0.113.2  OpenVPN 72 MessageType: P_ACK_V1
    9 0.003629784 198.51.100.77 → 203.0.113.2  TLSv1.3 1264 Change Cipher Spec
   10 0.003653049 198.51.100.77 → 203.0.113.2  TLSv1.3 1264 Continuation Data
   11 0.003661477 198.51.100.77 → 203.0.113.2  TLSv1.3 228 Continuation Data
   12 0.003777507  203.0.113.2 → 198.51.100.77 OpenVPN 68 MessageType: P_ACK_V1
```

Read it as a conversation. The two `HARD_RESET` messages are OpenVPN's own opening, each side
announcing a session. Then TLS begins inside OpenVPN's control packets: the laptop's `Client Hello`,
and the server's answer, `Server Hello, Change Cipher Spec, Application Data`. From that point **the
handshake is encrypted, and the server's certificate is inside what tshark can only call `Application
Data`.** TLS 1.3 encrypts certificates, and lesson 5 of `networks` saw the same thing in HTTPS.

`Continuation Data` is the rest of one record, split across packets of 1264 bytes. **The `P_ACK_V1`
packets are OpenVPN acknowledging its control packets itself, because UDP does not.** Packets 9 to 11
go the other way: the laptop's own certificate and proof, encrypted, about 2.7 kilobytes of them. They
are the check the server makes of the client. Twelve packets, 3.8 milliseconds, on one computer
talking to itself.

`tshark` labels the `Client Hello` `TLSv1`, and that is not a downgrade. A TLS 1.3 client writes an old
version number in the record's header, so that old middleboxes let it through, and names the version it
really wants inside. The server's answer settles it, and tshark labels everything after it `TLSv1.3`.

Started again and left running, in the background like the server, the client gives the laptop a
tunnel. On `remote`:

```sh
sudo setsid openvpn --cd /etc/openvpn --config client.conf >/dev/null 2>&1 &
```

A few seconds later:

```
ana@remote:~$ ip -br addr show tun0; ip route | grep tun0
tun0             UNKNOWN        10.8.0.2/24 
10.8.0.0/24 dev tun0 proto kernel scope link src 10.8.0.2 
192.168.10.0/24 via 10.8.0.1 dev tun0 
ana@remote:~$ curl -s http://192.168.10.10/
served by files
```

`tun0` got `10.8.0.2`, the first address the server hands out. **Nobody configured the route to
`192.168.10.0/24` on the laptop**: it is the `push` line of the server's file, and it arrived over the
control channel. Stop the client before the next section, on the virtual machine:
`sudo bash netlab.sh kill remote openvpn`.
