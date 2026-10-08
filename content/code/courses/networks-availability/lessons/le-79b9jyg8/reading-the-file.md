---
title: Asking the server, and reading a file of a failure
version: 1
---

A capture shows what crossed the wire, and the certificate did not cross it in a form anybody could
read. **`openssl s_client` connects as a client would and prints what it was shown**, which makes it
the complement to the capture:

```
ana@laptop:~$ openssl s_client -connect 192.0.2.21:8443 -servername www.example.com </dev/null 2>/dev/null | grep -E "subject=|issuer=|NotAfter|Verify return code"
   v:NotBefore: Jan  1 00:00:00 2025 GMT; NotAfter: Jan  1 00:00:00 2026 GMT
subject=CN = www.example.com
issuer=O = Example Lab, CN = Example Lab Root CA
Verify return code: 10 (certificate has expired)
ana@laptop:~$ openssl s_client -connect 192.0.2.21:9443 -servername www.example.com </dev/null 2>/dev/null | grep -E "subject=|Verify return code"
subject=CN = shop.example.net
Verify return code: 0 (ok)
ana@laptop:~$ openssl s_client -connect 192.0.2.21:10443 -servername www.example.com </dev/null 2>/dev/null | grep -E "subject=|issuer=|Verify return code"
subject=CN = www.example.com
issuer=O = Nobody, CN = Nobody Root CA
Verify return code: 21 (unable to verify the first certificate)
```

The expired one is the easy read: `NotAfter: Jan  1 00:00:00 2026 GMT`, and verify code **10,
certificate has expired**. The unknown authority is named in full, `Nobody Root CA`, with code **21,
unable to verify the first certificate**: `openssl` could not build a chain from this certificate to
anything it trusts. Two tools, two wordings, one cause.

**The one in the middle is the trap.** Port 9443 answered `Verify return code: 0 (ok)` for a
certificate issued to `shop.example.net`, when the laptop asked for `www.example.com`. Code 0 means
the chain is good: a trusted authority signed it and it is in date. **It says nothing about the
name**, because `s_client` checks the name only when asked to, with `-verify_hostname`, which was not
run here. `-servername` only sends the SNI. The `subject=` line is where the mismatch shows, and
reading it is your job.

## The file as data

The expired case was captured once more, whole, to a file, and read back line by line. While the
four-second capture ran, the laptop made the request to port 8443 again, with `-s` this time so that
`curl` printed nothing:
`curl -s --resolve www.example.com:8443:192.0.2.21 https://www.example.com:8443/`.

```
ana@laptop:~$ tshark -n -q -i eth0 -a duration:4 -f "host 192.0.2.21" -w failing.pcap
Capturing on 'eth0'
10 packets captured
ana@laptop:~$ tshark -r failing.pcap
    1 0.000000000 192.168.10.20 → 192.0.2.21   TCP 74 41122 → 8443 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM TSval=3105821767 TSecr=0 WS=1024
    2 0.000076393   192.0.2.21 → 192.168.10.20 TCP 74 8443 → 41122 [SYN, ACK] Seq=0 Ack=1 Win=65160 Len=0 MSS=1460 SACK_PERM TSval=885483827 TSecr=3105821767 WS=1024
    3 0.000088252 192.168.10.20 → 192.0.2.21   TCP 66 41122 → 8443 [ACK] Seq=1 Ack=1 Win=64512 Len=0 TSval=3105821767 TSecr=885483827
    4 0.001797118 192.168.10.20 → 192.0.2.21   TLSv1 583 Client Hello (SNI=www.example.com)
    5 0.001844791   192.0.2.21 → 192.168.10.20 TCP 66 8443 → 41122 [ACK] Seq=1 Ack=518 Win=65536 Len=0 TSval=885483829 TSecr=3105821769
    6 0.002697896   192.0.2.21 → 192.168.10.20 TLSv1.3 1509 Server Hello, Change Cipher Spec, Application Data, Application Data, Application Data, Application Data
    7 0.002707083 192.168.10.20 → 192.0.2.21   TCP 66 41122 → 8443 [ACK] Seq=518 Ack=1444 Win=67584 Len=0 TSval=3105821770 TSecr=885483830
    8 0.026241284 192.168.10.20 → 192.0.2.21   TLSv1.3 73 Alert (Level: Fatal, Description: Certificate Expired)
    9 0.026495654   192.0.2.21 → 192.168.10.20 TCP 66 8443 → 41122 [FIN, ACK] Seq=1444 Ack=525 Win=65536 Len=0 TSval=885483854 TSecr=3105821793
   10 0.026835405 192.168.10.20 → 192.0.2.21   TCP 66 41122 → 8443 [RST, ACK] Seq=525 Ack=1445 Win=67584 Len=0 TSval=3105821794 TSecr=885483854
```

Ten packets, and every one of them can be accounted for.

| frames | what happened |
|---|---|
| 1 to 3 | the TCP handshake to port 8443, as in the first section |
| 4 | the Client Hello, 583 bytes, with the SNI |
| 5 | `web1` acknowledges it: `Ack=518`, the next byte after 517 bytes of TLS counted from 1 |
| 6 | the Server Hello and the encrypted certificate, 1509 bytes |
| 7 | the laptop acknowledges them, `Ack=1444` |
| 8 | the laptop's alert: `Certificate Expired`, 7 bytes of TLS |
| 9 | `web1` closes its side, `FIN` |
| 10 | the laptop answers with `RST`: it had already closed the connection |

**The gap between frames 7 and 8 is 23 milliseconds, and it is not the network.** In this lab every
link is one computer talking to itself, and frames 6 and 7 are nine microseconds apart; the 23 ms is
the laptop checking the certificate before it answered. The good handshake paused about as long before
its frame 8.

**A file like this is data, and it can be handed on**, as lesson 12 did: to a colleague, to a vendor, to
the ticket. Anybody can read it to the same conclusion without having been there. That is the point
of capturing the failure rather than describing it: "TLS fails" is an opinion, and frame 8 is a fact.
