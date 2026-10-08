---
title: A single way in, and a key that knows where it lives
version: 1
---

Administration is the most powerful access on the network, so it gets the narrowest path. The
pattern is a **jump host** (also called a bastion): one hardened machine on the management segment,
the only source any server accepts SSH from, where every administrative session starts and is logged.
In the lab it is `admin`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Administrative access to db. From laptop on the staff LAN, SSH is blocked by the firewall. From app on the servers segment, SSH is blocked by db&#x27;s own firewall; only port 5432 is open to it. From admin, the jump host, SSH is accepted, and the key is valid only from that address. From admin2, holding a copy of the same key, SSH reaches db and the key is refused.\"><defs><marker id=\"jh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"jh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"jh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"560\" y=\"80\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">db</text><text x=\"570\" y=\"113\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">host firewall, from=</text><rect x=\"20\" y=\"20\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"35.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><path d=\"M130 35 L560 103\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#jh-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"150\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">SSH: blocked at fw</text><rect x=\"20\" y=\"70\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><path d=\"M130 85 L560 103\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jh-ah-paper-dim)\"></path><text x=\"150\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5432 only; SSH blocked at db</text><rect x=\"20\" y=\"120\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin</text><path d=\"M130 135 L560 103\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#jh-ah-phosphor)\"></path><text x=\"150\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">SSH accepted: the jump host</text><rect x=\"20\" y=\"170\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">admin2</text><path d=\"M130 185 L560 103\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#jh-ah-amber)\" stroke-dasharray=\"4 3\"></path><text x=\"150\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">same key, wrong place: refused</text></svg>", "caption": "One way in for administration, and a key that only works from it."}
```

The firewall's matrix already sends SSH to the servers only from management;
`db`'s host firewall narrowed that to `admin`'s address alone.

Addresses can be borrowed, though, and keys can be copied. SSH lets a server tie a key to the place it
may be used from, in the `authorized_keys` file on `db`. In the lab you make the key on `admin`, as
yourself, and then, from your own computer, install its public half on `db` with the restriction in
front of it:

```sh
# on admin, as you
mkdir -p ~/.ssh; ssh-keygen -q -t ed25519 -N "" -C "$USER@admin" -f ~/.ssh/id_ed25519
printf "Host *\n  StrictHostKeyChecking accept-new\n  UserKnownHostsFile /dev/null\n  LogLevel ERROR\n  BatchMode yes\n" > ~/.ssh/config
# on your own computer
sudo mkdir -p /lab/db/home/$USER/.ssh
printf 'from="192.168.99.10",no-agent-forwarding,no-port-forwarding,no-X11-forwarding %s\n' "$(sudo cat /lab/admin/home/$USER/.ssh/id_ed25519.pub)" | sudo tee /lab/db/home/$USER/.ssh/authorized_keys >/dev/null
sudo chown -R $USER: /lab/db/home/$USER/.ssh; sudo chmod 700 /lab/db/home/$USER/.ssh
```

The line it wrote:

```
root@db:~# cut -c1-96 /home/ana/.ssh/authorized_keys
from="192.168.99.10",no-agent-forwarding,no-port-forwarding,no-X11-forwarding ssh-ed25519 AAAAC3
```

`from="192.168.99.10"`: this key is accepted only from the jump host. The other options remove what an
administrative login rarely needs: forwarding the SSH agent, forwarding ports, forwarding X11. Each is a
way to turn one login into a path onward. From the jump host:

```
ana@admin:~$ ssh db hostname
db
```

`db`. Now the same private key, copied to a second machine on the management segment, `admin2`, and
the host firewall told to let `admin2` connect so that only the key's restriction stands in the way.
From your own computer, and then on `db` as root:

```sh
sudo bash nslab.sh plug admin2 mgmt 192.168.99.11/24 52:54:00:a8:63:0b; sudo ip -n admin2 route add default via 192.168.99.1
sudo mkdir -p /lab/admin2/home/$USER/.ssh
sudo cp /lab/admin/home/$USER/.ssh/id_ed25519 /lab/admin/home/$USER/.ssh/id_ed25519.pub /lab/admin/home/$USER/.ssh/config /lab/admin2/home/$USER/.ssh/
sudo chown -R $USER: /lab/admin2/home/$USER/.ssh; sudo chmod 700 /lab/admin2/home/$USER/.ssh
# on db, as root
nft add rule inet host input ip saddr 192.168.99.11 tcp dport 22 accept
```

```
ana@admin2:~$ ssh db hostname; echo "exit $?"
ana@db: Permission denied (publickey).
exit 255
```

**`Permission denied (publickey)`**: the key was right and the place was wrong. Copied keys are a common way for
administrative access to leak, and this one is useless anywhere but the jump host.

The jump host itself then becomes the thing to protect best: multi-factor authentication for the
people who log in to it, its own logs shipped elsewhere as lesson 16 asked, nothing else installed on
it, and no way to reach it from the staff LAN, which the matrix of lesson 4 already guarantees.
