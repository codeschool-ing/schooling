---
title: What IPsec adds to a tunnel
version: 1
---

Lesson 1 ended with a tunnel that showed every byte it carried to the ISP. IPsec is the usual answer, and people call it a VPN protocol, as if it were one thing. **IPsec is a family: ESP protects packets,
AH is an older way of protecting them, and IKE is how two machines agree on the keys.** This section is
about the first two.

## ESP

ESP, Encapsulating Security Payload, is IP protocol 50. It keeps lesson 1's packet inside a packet and
answers the questions a plain tunnel left open:

| | a plain tunnel | ESP |
|---|---|---|
| can anybody on the path read it? | yes, all of it | no: the payload is encrypted |
| did it come from the other office? | nobody checks | only a holder of the key could have made its check value |
| was it changed on the way? | nobody checks | the check value covers every byte |
| is it a copy of an old packet? | nobody checks | a sequence number, and a record of those already seen |

The check value is the **ICV**, integrity check value: a few bytes at the end of each packet, computed
with a key only the two ends hold. **The receiver drops a packet whose ICV does not match before
decrypting anything, and does not tell the sender.** The sequence number goes up with every packet, so a
packet somebody recorded and sends again arrives with a number already used. The receiver drops that one
too.

## AH

AH, Authentication Header, is IP protocol 51. It authenticates without encrypting, and it also covers
the addresses in the outer IP header. **NAT rewrites exactly the addresses AH protects**, so AH does not
survive a NAT. ESP can authenticate without encrypting if that is ever wanted, so AH lost the one thing
it did alone. Since RFC 4301, support for AH has been optional, and ESP is what you will configure.

## Tunnel mode and transport mode

In **tunnel mode** the whole original packet is encrypted and carried inside a new packet between two
gateways: lesson 1's tunnel with the inside locked. **The ISP sees `hq` and `branch`, and not which
laptop is talking to which till.** Site-to-site VPNs are this, and so is every capture in this lesson.

In **transport mode** the original IP header stays in front and ESP protects what follows it. It saves
20 bytes, and it protects only traffic between the two machines running IPsec, whose addresses stay
readable. Its commonest use is underneath GRE: two routers run GRE so a routing protocol's multicast can
cross, and protect the GRE with ESP in transport mode.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 266\" role=\"img\" aria-label=\"Two packets drawn as rows of fields. Tunnel mode, the captured ping of 140 bytes: a new IP header of 20 bytes, an ESP header of 8, an IV of 8, the laptop&#x27;s whole packet of 84 bytes, 4 bytes of padding and trailer, and a 16-byte ICV. The encrypted span runs from the inner packet to the trailer; the span covered by the ICV starts at the ESP header. Transport mode, drawn and not captured: the laptop&#x27;s original IP header stays in front, followed by ESP, IV, the ICMP message and data, padding and trailer, and the ICV; only the ICMP message, data and trailer are encrypted.\"><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tunnel mode: the captured ping, 140 bytes on the wire</text><rect x=\"20\" y=\"40\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"60.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new IP</text><text x=\"60.0\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20 bytes</text><rect x=\"104\" y=\"40\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"132.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ESP</text><text x=\"132.0\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8 bytes</text><rect x=\"164\" y=\"40\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"192.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IV</text><text x=\"192.0\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">8 bytes</text><rect x=\"224\" y=\"40\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"324.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">inner IP + ICMP + data</text><text x=\"324.0\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">84 bytes</text><rect x=\"428\" y=\"40\" width=\"126\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"491.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pad + trailer</text><text x=\"491.0\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 bytes</text><rect x=\"558\" y=\"40\" width=\"64\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ICV</text><text x=\"590.0\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">16 bytes</text><path d=\"M224 87 L224 92 L554 92 L554 87\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"389.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">encrypted</text><path d=\"M104 115 L104 120 L554 120 L554 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"329.0\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">covered by the ICV</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Transport mode: the same ping, drawn and not captured</text><rect x=\"20\" y=\"174\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"65.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">original IP</text><rect x=\"114\" y=\"174\" width=\"56\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"142.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ESP</text><rect x=\"174\" y=\"174\" width=\"56\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"202.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IV</text><rect x=\"234\" y=\"174\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"309.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ICMP + data</text><rect x=\"388\" y=\"174\" width=\"126\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"451.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pad + trailer</text><rect x=\"518\" y=\"174\" width=\"64\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"550.0\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ICV</text><path d=\"M234 215 L234 220 L514 220 L514 215\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"374.0\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">encrypted</text><rect x=\"20\" y=\"247\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"40\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">added by IPsec</text><rect x=\"190\" y=\"247\" width=\"14\" height=\"10\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"210\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the laptop's own packet</text></svg>", "caption": "In tunnel mode the laptop's addresses are inside the encrypted part; in transport mode they stay in front, readable, and no second IP header is added. The tunnel row is the captured packet: 140 bytes around an 84-byte ping. The split of ESP's 36 bytes follows from AES-GCM, with an 8-byte IV and a 16-byte ICV."}
```

**Transport mode is drawn here and not captured.** The kernel this course was recorded on has no ESP, so
the network of lesson 1 has strongSwan do ESP itself, with its user-space `kernel-libipsec`, which
speaks tunnel mode only. Your Ubuntu has ESP in its kernel, but `netlab.sh` switches the same plugin on,
so your tunnels behave exactly like the ones captured here.
The tunnel row is a real packet, the laptop's 84-byte ping as the ISP captured it, and the section on
security associations reads that capture.
