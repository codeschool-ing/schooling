---
title: A resolver for the firm
version: 1
---

**A resolver answers questions about names it does not own by asking the servers that do.** Jatobá
owns `jatoba.example`, so its resolver can answer for `web` and `desk` from its own configuration.
Everything else, `example.net` and the rest of the internet, it has to look up elsewhere.

The lab has no internet, so for this lesson **`trap` plays the internet's name servers**. It answers
for a handful of outside names, some of which the firm will later decide are dangerous. Write its
configuration as root on `trap`, whole, and start Unbound, the resolver that is already installed
on every machine of the lab:

```
root@trap:~# cat > /etc/unbound/unbound.conf.d/internet.conf <<'EOF'
server:
    interface: 0.0.0.0
    access-control: 0.0.0.0/0 allow
    module-config: "iterator"
    local-zone: "example.net." static
    local-data: "boletos-jatoba.example.net. A 198.51.100.23"
    local-data: "jatoba.contabil-nuvem.example.net. A 198.51.100.80"
    local-data: "outro.contabil-nuvem.example.net. A 198.51.100.81"
    local-zone: "example.org." static
    local-data: "pagamento.cobranca-urgente.example.org. A 198.51.100.66"
EOF
root@trap:~# rm /etc/unbound/unbound.conf.d/root-auto-trust-anchor-file.conf; systemctl enable --now unbound 2>&1 | tail -1; systemctl is-active unbound
Created symlink /etc/systemd/system/multi-user.target.wants/unbound.service → /usr/lib/systemd/system/unbound.service.
active
```

`local-zone ... static` makes `trap` answer for those two domains from the lines below it and for
nothing else. The file `root-auto-trust-anchor-file.conf` is removed because it asks Unbound to
fetch and validate the root of DNSSEC, the signatures that prove an answer is genuine, and with no
internet that fetch fails and the service will not start. **On a real resolver that file stays**,
and the validation it enables is one more reason to run your own.

## The firm's resolver

Now `dns`, the machine whose job this is. Its configuration says who may ask, what it answers itself,
and where it sends everything else:

```
root@dns:~# cat > /etc/unbound/unbound.conf.d/jatoba.conf <<'EOF'
server:
    interface: 0.0.0.0
    access-control: 192.168.60.0/24 allow
    module-config: "respip iterator"
    log-queries: yes
    local-zone: "jatoba.example." static
    local-data: "web.jatoba.example. A 192.168.60.10"
    local-data: "desk.jatoba.example. A 192.168.60.20"
    local-data: "dns.jatoba.example. A 192.168.60.53"
forward-zone:
    name: "."
    forward-addr: 192.168.60.66
EOF
root@dns:~# rm /etc/unbound/unbound.conf.d/root-auto-trust-anchor-file.conf; unbound-checkconf
unbound-checkconf: no errors in /etc/unbound/unbound.conf
root@dns:~# systemctl enable --now unbound 2>&1 | tail -1; systemctl is-active unbound
Created symlink /etc/systemd/system/multi-user.target.wants/unbound.service → /usr/lib/systemd/system/unbound.service.
active
```

Each block does one thing:

| line | what it does |
|---|---|
| `interface: 0.0.0.0` | listen on every interface, not only on the machine's own loopback |
| `access-control: 192.168.60.0/24 allow` | answer the firm's segment and refuse everybody else, so the resolver is not open to the world |
| `module-config: "respip iterator"` | the processing chain; `respip` is what the next section needs to apply a blocklist |
| `log-queries: yes` | one line per question, with the asking address |
| `local-zone` and `local-data` | the firm's own names, answered here |
| `forward-zone` with `name: "."` | everything else is sent to `192.168.60.66`, which stands in for the internet |

`unbound-checkconf` reads the whole configuration and complains before anything restarts, the same
habit as `sshd -t` in lesson 1.

## Pointing desk at it

A machine finds its resolver in `/etc/resolv.conf`. On a real network that file is written by DHCP
or by systemd-resolved; here you write it by hand, as root on `desk`, and ask again:

```
root@desk:~# printf "nameserver 192.168.60.53\nsearch jatoba.example\n" > /etc/resolv.conf
ana@desk:~$ dig +short web.jatoba.example; dig +short boletos-jatoba.example.net
192.168.60.10
198.51.100.23
ana@desk:~$ dig www.ubuntu.com | grep status
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 62612
```

The firm's own name comes from `dns` itself, an outside name comes through the forwarder, and a name
nobody in the lab answers for fails with `SERVFAIL`, which is what a resolver says when it could not
get an answer at all.

## The log is the first win

Every one of those questions is now in one place:

```
root@dns:~# journalctl -u unbound -o cat | grep "info: 192" | cut -d" " -f3-
192.168.60.20 web.jatoba.example. A IN
192.168.60.20 boletos-jatoba.example.net. A IN
192.168.60.20 www.ubuntu.com. A IN
```

**Who asked, and for what**, one line each. Before this, the same questions went from `desk` to
Google and left no trace on any machine Jatobá owns. A resolver log is the cheapest telemetry a
small company can have: it costs no agent on any machine, and when lesson 8's question comes up,
"which machines talked to this domain last week", it is the place that can answer.
