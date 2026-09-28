---
title: Two keys and a short file
version: 1
---

Most VPNs begin with a certificate authority, a user database and pages of settings. **WireGuard begins
with two keys per machine and a file of about a dozen lines.** There is no user, no password and no
negotiation of algorithms: each end is known by its public key, and the cryptography is fixed by the
protocol, Curve25519 to agree keys and ChaCha20-Poly1305 to encrypt and authenticate the data.

The key pair is made on the machine that will use it:

```
ana@hq:~$ sudo sh -c "umask 077; wg genkey > /etc/wireguard/hq.key"
ana@hq:~$ sudo cat /etc/wireguard/hq.key | wg pubkey | sudo tee /etc/wireguard/hq.pub
B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I=
ana@hq:~$ sudo ls -l /etc/wireguard
total 8
-rw------- 1 root root 45 Sep 28 18:08 hq.key
-rw-r--r-- 1 root root 45 Sep 28 18:08 hq.pub
```

`wg genkey` writes a private key and `wg pubkey` derives the public one from it. The reverse is not
possible, which is the whole point of the pair. The `umask 077` in front makes the new file readable by
its owner alone, and `ls -l` shows the result: **`hq.key` is `-rw-------`, root's and nobody else's**,
while `hq.pub` is readable by everybody. Both are 45 bytes, 44 characters of base64 and a newline.

The public key was printed because it is the half that gets handed to other machines. The private key
never appeared on the screen, and **it does not belong in a chat window, a ticket or a repository
either**: whoever has it is `hq`, as far as every peer is concerned.

`branch` and `remote` made their pairs the same way, which is not shown. Each machine then gets a
configuration file naming its own private key and the public key of every peer it talks to. This is
`hq`'s, printed with `sed` replacing the private key, since the real file holds it in clear:

```schooling-example
{"language": "ini", "file": "wg0.conf", "parts": [{"code": "[Interface]\nAddress = 10.20.0.1/24\nListenPort = 51820", "note": "This machine. `Address` is `hq`'s own address inside the tunnel, which `wg-quick` puts on the interface. `ListenPort` is the UDP port it waits on, 51820 by convention."}, {"code": "PrivateKey = (hidden here, in the file it is the key)", "note": "The private key, in clear in the real file. That is why the file is root's and readable by nobody else, like the key it was copied from."}, {"code": "# the branch office\n[Peer]\nPublicKey = n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8=", "note": "One block per peer, and the public key is the peer's whole identity: whoever holds the matching private key is `branch`, as far as `hq` is concerned. The comment is for people."}, {"code": "Endpoint = 198.51.100.2:51820", "note": "Where to send. `branch` has a fixed public address, so `hq` can start the conversation."}, {"code": "AllowedIPs = 10.20.0.2/32, 192.168.20.0/24", "note": "The addresses behind this peer: its tunnel address and the branch LAN. Packets for them go to `branch`, and packets from `branch` have to come from them."}, {"code": "# Ana, at home\n[Peer]\nPublicKey = FYBqYy68QPdITaZcZGko576tjvRUt5cUWsMsdGzbgkE=", "note": "The second peer, Ana's laptop at home."}, {"code": "AllowedIPs = 10.20.0.3/32", "note": "One address, hers, and no `Endpoint`: `hq` learns where she is from her first packet."}]}
```

**A peer has no name in the protocol, only a public key.** `# the branch office` and `# Ana, at home`
are comments for whoever reads the file; `wg` never prints them, and the section on OpenVPN comes back
to what that costs.

Two lines decide nearly everything in the rest of this lesson. `Endpoint` says where to send packets for
a peer, and the peer at home has none, because nobody knows in advance where Ana will be. `AllowedIPs`
says which addresses belong to a peer, and the section on cryptokey routing shows that it means two
things at once.
