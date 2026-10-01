---
title: A TLS session that works, and three that fail
version: 1
---

Lesson 5 of `networks` described the TLS handshake from the client's side. From the wire, **TLS 1.3
shows much less than it used to, and that is the design.** Here it is working, on port 443 of `web1`:

```
ana@laptop:~$ curl -sS --resolve www.example.com:443:192.0.2.21 --resolve www.example.com:8443:192.0.2.21 --resolve www.example.com:9443:192.0.2.21 --resolve www.example.com:10443:192.0.2.21 https://www.example.com/
ok
ana@laptop:~$ tshark -n -i eth0 -c 12 -f "host 192.0.2.21 and tcp port 443" -Y tls
Capturing on 'eth0'
6 packets captured
    4 0.001819318 192.168.10.20 → 192.0.2.21   TLSv1 583 Client Hello (SNI=www.example.com)
    6 0.003707199   192.0.2.21 → 192.168.10.20 TLSv1.3 1509 Server Hello, Change Cipher Spec, Application Data, Application Data, Application Data, Application Data
    8 0.026236990 192.168.10.20 → 192.0.2.21   TLSv1.3 146 Change Cipher Spec, Application Data
    9 0.026388693 192.168.10.20 → 192.0.2.21   TLSv1.3 166 Application Data
   10 0.026541364   192.0.2.21 → 192.168.10.20 TLSv1.3 369 Application Data
   11 0.026605534   192.0.2.21 → 192.168.10.20 TLSv1.3 369 Application Data
```

Frame 4 is the Client Hello, and the name the laptop wants, `www.example.com`, is in clear text as
the SNI. The server needs it before any encryption exists, to pick a certificate, so anyone on the
path can read which site is being visited. `TLSv1` in that column is not the version in use: a
Client Hello's outer record says 1.0 for the sake of old middleboxes, and the real versions are
offered inside it.

Frame 6 is the whole of the server's reply in one packet: the Server Hello, then four records marked
`Application Data`. **In TLS 1.3 everything after the Server Hello is encrypted, the certificate
included.** Those four records are the rest of the server's handshake, and a capture cannot say which
certificate the server sent. The `Change Cipher Spec` records mean nothing in TLS 1.3; they are sent
so that old equipment on the path sees what it expects. Frame 8 is the laptop's own `Finished`,
encrypted too, and from frame 9 on it is the request and the answers.

## Three certificates the laptop refused

`web1` served three more certificates on three more ports: one expired, one for another name, and one
signed by an authority the laptop does not trust. The first:

```
ana@laptop:~$ curl -sS --resolve www.example.com:443:192.0.2.21 --resolve www.example.com:8443:192.0.2.21 --resolve www.example.com:9443:192.0.2.21 --resolve www.example.com:10443:192.0.2.21 https://www.example.com:8443/
curl: (60) SSL certificate problem: certificate has expired
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ tshark -n -i eth0 -c 8 -f "host 192.0.2.21 and tcp port 8443" -Y tls -d tcp.port==8443,tls
Capturing on 'eth0'
3 packets captured
    4 0.001872089 192.168.10.20 → 192.0.2.21   TLSv1 583 Client Hello (SNI=www.example.com)
    6 0.003155064   192.0.2.21 → 192.168.10.20 TLSv1.3 1509 Server Hello, Change Cipher Spec, Application Data, Application Data, Application Data, Application Data
    8 0.026663340 192.168.10.20 → 192.0.2.21   TLSv1.3 73 Alert (Level: Fatal, Description: Certificate Expired)
```

**Frame 8 is readable: `Alert (Level: Fatal, Description: Certificate Expired)`, sent by the
laptop.** The certificate itself was encrypted, but the client's verdict about it was not. It is 73
bytes, and an empty TCP segment on this link is 66, so it carries 7 bytes of TLS: a 5-byte record
header and a 2-byte alert, level and description, in clear. The laptop rejected the certificate
before it had started encrypting its own side of the handshake, and said why.

The certificate for the wrong name:

```
ana@laptop:~$ curl -sS --resolve www.example.com:443:192.0.2.21 --resolve www.example.com:8443:192.0.2.21 --resolve www.example.com:9443:192.0.2.21 --resolve www.example.com:10443:192.0.2.21 https://www.example.com:9443/
curl: (60) SSL: no alternative certificate subject name matches target host name 'www.example.com'
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ tshark -n -i eth0 -c 8 -f "host 192.0.2.21 and tcp port 9443" -Y tls -d tcp.port==9443,tls
Capturing on 'eth0'
3 packets captured
    4 0.001831433 192.168.10.20 → 192.0.2.21   TLSv1 583 Client Hello (SNI=www.example.com)
    6 0.003085279   192.0.2.21 → 192.168.10.20 TLSv1.3 1511 Server Hello, Change Cipher Spec, Application Data, Application Data, Application Data, Application Data
    8 0.026775708 192.168.10.20 → 192.0.2.21   TLSv1.3 146 Change Cipher Spec, Application Data
```

**On the wire this is the good handshake again.** Frame 8 is `Change Cipher Spec, Application Data`,
146 bytes, the same as the laptop's `Finished` when everything worked. The certificate was valid and
signed by an authority the laptop trusts, so the handshake completed, and only then did `curl` compare
the name in it with the name it asked for. Anything the laptop said after that, an alert included,
travelled inside the encryption and would show as `Application Data`, indistinguishable from a
request. This capture stopped at frame 8, so what followed is not shown.

And the unknown authority:

```
ana@laptop:~$ curl -sS --resolve www.example.com:443:192.0.2.21 --resolve www.example.com:8443:192.0.2.21 --resolve www.example.com:9443:192.0.2.21 --resolve www.example.com:10443:192.0.2.21 https://www.example.com:10443/
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ tshark -n -i eth0 -c 8 -f "host 192.0.2.21 and tcp port 10443" -Y tls -d tcp.port==10443,tls
Capturing on 'eth0'
3 packets captured
    4 0.001872793 192.168.10.20 → 192.0.2.21   TLSv1 583 Client Hello (SNI=www.example.com)
    6 0.003189474   192.0.2.21 → 192.168.10.20 TLSv1.3 1499 Server Hello, Change Cipher Spec, Application Data, Application Data, Application Data, Application Data
    8 0.026791460 192.168.10.20 → 192.0.2.21   TLSv1.3 73 Alert (Level: Fatal, Description: Unknown CA)
```

**`Unknown CA`, readable, 73 bytes, like the expired one.** `curl` words it as `unable to get local
issuer certificate`: the certificate's issuer is not in any trust store on the laptop.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 770 254\" role=\"img\" aria-label=\"A grid of four TLS sessions to web1, on ports 443, 8443, 9443 and 10443: one that works, an expired certificate, a certificate for the wrong name and one from an unknown authority. Frame 4 from the laptop is the same in all four, a Client Hello with SNI www.example.com, and frame 6 from web1 is the same, a Server Hello and four Application Data records with the certificate encrypted inside. Frame 8 differs: Change Cipher Spec and Application Data of 146 bytes when it works and for the wrong name, which therefore looks like it worked; a readable alert of 73 bytes, Certificate Expired or Unknown CA, in the other two, which say why in clear.\"><text x=\"232.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">works</text><text x=\"232.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">443</text><text x=\"384.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">expired</text><text x=\"384.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8443</text><text x=\"536.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">wrong name</text><text x=\"536.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9443</text><text x=\"688.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">unknown CA</text><text x=\"688.0\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10443</text><text x=\"10\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">frame 4, laptop</text><rect x=\"160\" y=\"48\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"232.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Client Hello</text><text x=\"232.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SNI=www.example.com</text><rect x=\"312\" y=\"48\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"384.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Client Hello</text><text x=\"384.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SNI=www.example.com</text><rect x=\"464\" y=\"48\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"536.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Client Hello</text><text x=\"536.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SNI=www.example.com</text><rect x=\"616\" y=\"48\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"688.0\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Client Hello</text><text x=\"688.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">SNI=www.example.com</text><text x=\"10\" y=\"122.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">frame 6, web1</text><rect x=\"160\" y=\"100\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"232.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Server Hello</text><text x=\"232.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 × Application Data</text><rect x=\"312\" y=\"100\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"384.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Server Hello</text><text x=\"384.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 × Application Data</text><rect x=\"464\" y=\"100\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"536.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Server Hello</text><text x=\"536.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 × Application Data</text><rect x=\"616\" y=\"100\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"688.0\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Server Hello</text><text x=\"688.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 × Application Data</text><text x=\"10\" y=\"174.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">frame 8, laptop</text><rect x=\"160\" y=\"152\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"232.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Change Cipher Spec,</text><text x=\"232.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Application Data 146</text><rect x=\"312\" y=\"152\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"384.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Alert: Certificate</text><text x=\"384.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Expired, 73 bytes</text><rect x=\"464\" y=\"152\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"536.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Change Cipher Spec,</text><text x=\"536.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Application Data 146</text><rect x=\"616\" y=\"152\" width=\"144\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"688.0\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Alert: Unknown CA,</text><text x=\"688.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">73 bytes</text><text x=\"10\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the capture says</text><text x=\"232.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">it worked</text><text x=\"384.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">why, in clear</text><text x=\"536.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">looks like it worked</text><text x=\"688.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">why, in clear</text><text x=\"160\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">The certificate is inside frame 6 in all four, encrypted.</text></svg>", "caption": "The three captures of this section and the good one, frame by frame. Two failures announce themselves; the wrong name ends exactly like a success, as far as the capture reached."}
```

So a capture of a failing TLS session answers two questions and not a third. **Where it stopped is
always visible**, because the frames stop. **Why is visible when the client says so in clear**, which
this client did for an expired certificate and an unknown authority. A wrong name is invisible, and
for that one the next section asks the server directly.
