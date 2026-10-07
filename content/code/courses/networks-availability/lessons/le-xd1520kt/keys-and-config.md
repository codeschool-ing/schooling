---
title: Two keys and a short file
version: 1
---

Most VPNs begin with a certificate authority, a user database and pages of settings. **WireGuard begins
with two keys per machine and a file of about a dozen lines.** There is no user, no password and no
negotiation of algorithms. Each end is known by its public key, and the cryptography is fixed by the
protocol: Curve25519 to agree keys, ChaCha20-Poly1305 to encrypt and authenticate the data.

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
its owner alone. `ls -l` shows the result: **`hq.key` is `-rw-------`, root's and nobody else's**,
while `hq.pub` is readable by everybody. Both are 45 bytes, 44 characters of base64 and a newline.

The public key was printed because it is the half that gets handed to other machines. The private key
never appeared on the screen, and **it does not belong in a chat window, a ticket or a repository
either**: whoever has it is `hq`, as far as every peer is concerned.

Make `branch`'s and `remote`'s pairs the same way, each on its own machine and with its own name in
place of `hq`: `branch.key` and `branch.pub` on `branch`, `remote.key` and `remote.pub` on `remote`.
Each machine then gets a configuration file, `/etc/wireguard/wg0.conf`, naming its own private key and
the public key of every peer it talks to. Write each with `sudo nano` on its machine. This is `hq`'s,
with the private key hidden, since the real file holds it in clear:

```schooling-example
{"language": "ini", "file": "wg0.conf", "parts": [{"code": "[Interface]\nAddress = 10.20.0.1/24\nListenPort = 51820", "note": "This machine. `Address` is `hq`'s own address inside the tunnel, which `wg-quick` puts on the interface. `ListenPort` is the UDP port it waits on, 51820 by convention."}, {"code": "PrivateKey = (hidden here, in the file it is the key)", "note": "The private key, in clear in the real file. That is why the file is root's and readable by nobody else, like the key it was copied from."}, {"code": "# the branch office\n[Peer]\nPublicKey = n/CGaD63Wk0H9pfG6sbwBbJdh+XswYcDf0wmiU4zFT8=", "note": "One block per peer, and the public key is the peer's whole identity: whoever holds the matching private key is `branch`, as far as `hq` is concerned. The comment is for people."}, {"code": "Endpoint = 198.51.100.2:51820", "note": "Where to send. `branch` has a fixed public address, so `hq` can start the conversation."}, {"code": "AllowedIPs = 10.20.0.2/32, 192.168.20.0/24", "note": "The addresses behind this peer: its tunnel address and the branch LAN. Packets for them go to `branch`, and packets from `branch` have to come from them."}, {"code": "# Ana, at home\n[Peer]\nPublicKey = FYBqYy68QPdITaZcZGko576tjvRUt5cUWsMsdGzbgkE=", "note": "The second peer, Ana's laptop at home."}, {"code": "AllowedIPs = 10.20.0.3/32", "note": "One address, hers, and no `Endpoint`: `hq` learns where she is from her first packet."}]}
```

**The keys in these listings are the ones this recording made, and yours are different.** On each
`PrivateKey` line goes that machine's own private key, which `sudo cat /etc/wireguard/hq.key` prints on
`hq`; on each `PublicKey` line goes the peer's public key, from its `.pub` file on its own machine. A
public key copied from this page would name a machine you do not have.

`branch` has one peer, `hq`:

```schooling-example
{"language": "ini", "file": "wg0.conf", "parts": [{"code": "[Interface]\nAddress = 10.20.0.2/24\nListenPort = 51820\nPrivateKey = (hidden here, in the file it is the key)", "note": "`branch`, the same shape as `hq`: its own tunnel address, the same port, and its own private key on the last line."}, {"code": "[Peer]\nPublicKey = B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I=\nEndpoint = 203.0.113.2:51820\nAllowedIPs = 10.20.0.1/32, 192.168.10.0/24", "note": "One peer, `hq`, by its public key, at its fixed public address. Behind it are `hq`'s tunnel address and the head-office LAN."}]}
```

And `remote`, Ana's laptop, also has one, `hq` again:

```schooling-example
{"language": "ini", "file": "wg0.conf", "parts": [{"code": "[Interface]\nAddress = 10.20.0.3/24\nPrivateKey = (hidden here, in the file it is the key)", "note": "Ana's laptop. No `ListenPort`: nobody starts a conversation with a laptop at home, so any free port will do."}, {"code": "[Peer]\nPublicKey = B6qH2hb1U5hsBki+4mN/m7AxAAKMeL7maFXl3uAeH2I=\nEndpoint = vpn.example.com:51820\nAllowedIPs = 10.20.0.0/24, 192.168.10.0/24", "note": "`hq`, found by name, which the network's DNS server answers. Through the tunnel go the tunnel's own network and the head-office LAN, and nothing else."}, {"code": "PersistentKeepalive = 25", "note": "The one line a laptop behind NAT needs and a router does not. The section on roaming says why."}]}
```

**A peer has no name in the protocol, only a public key.** `# the branch office` and `# Ana, at home`
are comments for whoever reads the file; `wg` never prints them, and the section on OpenVPN comes back
to what that costs.

Two lines decide nearly everything in the rest of this lesson. `Endpoint` says where to send packets for
a peer, and the peer at home has none, because nobody knows in advance where Ana will be. `AllowedIPs`
says which addresses belong to a peer, and the section on cryptokey routing shows that it means two
things at once.
