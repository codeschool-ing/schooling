---
title: Closing the other doors
version: 1
---

**The bastion becomes a control on the day the servers refuse everybody else.** Until then `desk`
can still go straight to `web`, and a key stolen from `desk` still works there. The rule belongs on
`web` itself, in its own firewall: SSH from `jump`, and from nowhere else.

```
root@web:~# nft -f - <<'EOF'
table inet admin {
    chain input {
        type filter hook input priority filter; policy accept;
        tcp dport 22 ip saddr 192.168.60.40 accept
        tcp dport 22 counter reject with tcp reset
    }
}
EOF
ana@desk:~$ ssh web hostname; echo "exit $?"
ssh: connect to host web port 22: Connection refused
exit 255
ana@admin:~$ ssh web hostname
web
```

The first rule accepts port 22 from `192.168.60.40`; the second refuses every other attempt on port
22 and counts it. `reject with tcp reset` answers the refusal at once, which is why `desk` saw
`Connection refused` instead of waiting for a timeout: inside your own network a fast, clear refusal
saves the administrator who made a mistake a minute of wondering. Toward the internet, lesson 5
weighs dropping against rejecting. `admin` still reaches `web`, through `jump`, without typing
anything different, because of the configuration entry from the last section.

The same reasoning applies one step back. If any machine may reach the bastion, then a key stolen
from any machine reaches the bastion, and the bastion's list decides the rest. So `jump` accepts SSH
only from `admin`, the administrator's own workstation:

```
root@jump:~# nft -f - <<'EOF'
table inet admin {
    chain input {
        type filter hook input priority filter; policy accept;
        tcp dport 22 ip saddr 192.168.60.30 accept
        tcp dport 22 counter reject with tcp reset
    }
}
EOF
ana@desk:~$ ssh -J jump web hostname; echo "exit $?"
ssh: connect to host jump port 22: Connection refused
exit 255
root@web:~# nft list chain inet admin input | grep counter
		tcp dport 22 counter packets 1 bytes 60 reject with tcp reset
```

`desk` now fails at the first hop. And the counter on `web` shows the one connection it refused in
this lesson, the one from `desk` a moment ago. **That counter is worth watching**: on a network where
every administrator goes through the bastion, any packet it counts is somebody, or something, trying
the old way.

These rules live in nftables, as in lesson 5, and like everything typed at a prompt they disappear
at the next reboot unless they are written to `/etc/nftables.conf`; lesson 5 shows how they are made
to persist.

## The chain this makes

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l15-chain\" aria-label=\"The chain the rules make. admin connects to jump on port 22, allowed by jump's firewall. jump connects to web on port 22, allowed by web's firewall and by PermitOpen web:22 on jump. desk trying jump is refused by jump's firewall, and desk trying web directly is refused by web's firewall, which counts it.\"><defs><marker id=\"l15-chain-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-chain-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30.0\" y=\"50.0\" width=\"120.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">admin</text><text x=\"90.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.60.30</text><rect x=\"300.0\" y=\"50.0\" width=\"120.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">jump</text><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.60.40</text><rect x=\"570.0\" y=\"50.0\" width=\"120.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><text x=\"630.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.60.10</text><rect x=\"300.0\" y=\"160.0\" width=\"120.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><text x=\"360.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.60.20</text><path d=\"M150.0 72.0 L300.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-chain-dh-ah-phosphor)\"></path><text x=\"225.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">ssh, allowed</text><path d=\"M420.0 72.0 L570.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-chain-dh-ah-phosphor)\"></path><text x=\"495.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">only web:22</text><path d=\"M360.0 160.0 L360.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l15-chain-dh-ah-amber)\"></path><text x=\"370.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">refused by jump</text><path d=\"M420.0 182.0 L610.0 100.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l15-chain-dh-ah-amber)\"></path><text x=\"530.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">refused and counted by web</text></svg>", "caption": "Every arrow is a rule you can read, and every refusal is counted."}
```

Each arrow is permitted by one rule you can read, and each refusal is counted by one rule you can
read. **An access path you can draw from the rules is one you can audit**; one that exists because
nobody wrote a rule against it is one you will find out about from somebody else.
