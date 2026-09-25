---
title: A key instead of a password
version: 1
---

A password can be guessed, reused on another site, or read over somebody's shoulder. **A key pair
can't be guessed and never leaves the laptop.** `ssh-keygen` makes one:

```
ana@laptop:~$ ssh-keygen -t ed25519 -N "blue kettle on the roof" -C "ana@laptop" -f ~/.ssh/id_ed25519
Generating public/private ed25519 key pair.
Your identification has been saved in /home/ana/.ssh/id_ed25519
Your public key has been saved in /home/ana/.ssh/id_ed25519.pub
The key fingerprint is:
SHA256:zfl5ZHAnI6jUGx24CKDEDD+bU0nPBtLwrf8P2WPFLXg ana@laptop
The key's randomart image is:
+--[ED25519 256]--+
|.++o+.     ..    |
| oo=.*.  ..o .   |
|  + + =...+.+ + .|
|   = o ..+.* = + |
|  + .   S * E +  |
|   . .   o + =   |
|      . o + o .  |
|       . o . .   |
|        ...      |
+----[SHA256]-----+
ana@laptop:~$ ls -l ~/.ssh
total 12
-rw------- 1 ana ana 444 Sep 25 15:10 id_ed25519
-rw-r--r-- 1 ana ana  92 Sep 25 15:10 id_ed25519.pub
-rw-r--r-- 1 ana ana 142 Sep 25 15:10 known_hosts
```

Two files. `id_ed25519` is the **private key**, `-rw-------`, readable only by its owner. `id_ed25519.pub`
is the **public key**, and it is safe to hand to any server, or to anybody. Ed25519 is the modern
type, short and fast, and the default of recent OpenSSH; RSA keys still work and are much longer. The
`-C` comment is only a label, so a list of keys says whose each one is.

The **passphrase** encrypts the private key on disk. Without one, anybody who copies the file, from a
stolen laptop or a backup, can log in as Ana on every server that trusts the key. With one, the file alone
is useless. `-N` gave it on the command line here so the session could be recorded; typed at the
prompt, it would not end up in the shell's history.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two key pairs, working in opposite directions. On the laptop: the private key id_ed25519, locked by a passphrase; its public half, id_ed25519.pub; and known_hosts, the server keys already accepted. On the server: the private host key in /etc/ssh, and ana&#x27;s authorized_keys, the public keys allowed to log in as ana. The server&#x27;s host key is checked against the laptop&#x27;s known_hosts, which proves the server to the laptop. ssh-copy-id copies the public key into authorized_keys, and at each login the laptop&#x27;s private key proves Ana to the server. No private key ever crosses.\"><defs><marker id=\"ky-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"280\" height=\"250\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"22\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><rect x=\"430\" y=\"20\" width=\"280\" height=\"250\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"442\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">server</text><rect x=\"22\" y=\"56\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">~/.ssh/id_ed25519</text><text x=\"34\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">your private key, locked by a passphrase</text><rect x=\"22\" y=\"128\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">~/.ssh/id_ed25519.pub</text><text x=\"34\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its public half</text><rect x=\"22\" y=\"200\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">~/.ssh/known_hosts</text><text x=\"34\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the server keys you accepted</text><rect x=\"442\" y=\"200\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"454\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/etc/ssh/ssh_host_ed25519_key</text><text x=\"454\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the server&#x27;s private host key</text><rect x=\"442\" y=\"128\" width=\"256\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"454\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">~/.ssh/authorized_keys</text><text x=\"454\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the public keys let in as ana</text><path d=\"M442 232 L280 232\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ky-ah)\"></path><text x=\"360\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">proves the server to you</text><path d=\"M278 153 L440 153\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ky-ah)\"></path><text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ssh-copy-id</text><path d=\"M278 90 L440 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ky-ah)\"></path><text x=\"360\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">proves you to the server</text></svg>", "caption": "Two pairs, two directions. The host key answers \"is this really the server?\" and your key answers \"is this really Ana?\". Only public halves travel; each private key stays on the machine it was made on."}
```

The picture has two pairs, and they are easy to confuse. The server's **host key** proves the server
to Ana, and `known_hosts` is where she keeps the ones she trusts. Her own key proves Ana to the server,
and the server keeps the public half in `authorized_keys`. The next section puts it there.
