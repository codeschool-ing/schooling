---
title: "The lab, part 2: a small DNS"
version: 1
---

The real internet's names are answered by a hierarchy of servers, and the lab has the same
hierarchy at a smaller size. **`dns.sh` builds four DNS servers**, each on its own machine:

- `rootns`, the **root**, which knows only who answers for each top-level domain: `.com`, `.net`,
  `.test` and the reverse zones under `.arpa`;
- `tldns`, the server for **`.com` and `.net`**, which knows only that `example.com` and
  `example.net` are answered by `ns1`;
- `ns1`, the **authoritative** server for both domains, which holds the records themselves:
  `www.example.com`, the mail servers, the names lesson 6 needs, and the reverse names that turn an
  address back into a name;
- `resolver`, the provider's **recursive resolver**, which the office's machines ask. It knows
  nothing of its own and walks down from the root on each new question.

That is lesson 4's subject, and lesson 4 reads these zones one record at a time. Here, the shape
is enough. `zone` writes one zone file and declares it to the server; `named_conf` writes the
server's own configuration, which answers questions and never recurses. The resolver is Unbound
rather than BIND, as an internet provider's often is. Its configuration points it at the lab's
root instead of the real one, and its `local-zone` lines stop it from answering `.test` and the
documentation addresses itself, which it does by default because on the real internet nobody should
be serving them.

The mail domains also need their **DKIM keys** published, and lesson 9 explains why. So the file
generates a key pair for each domain with `opendkim-genkey`, and appends the public half to the
zone. Each build generates new keys, which is why the DKIM records in lesson 9's transcripts will
not match yours character for character.

Save it as `~/netlab/dns.sh`, the same way as the first file:

```sh
nano ~/netlab/dns.sh
```

```bash
# ~/netlab/dns.sh: the lab's DNS. A root, the servers for .com and .net, the
# server for example.com and example.net, and the ISP's resolver. netlab reads
# this file; on its own it does nothing.

# ------------------------------------------------------------------------ DNS
SERIAL=2026092501
zone() {  # zone HOST NAME  (body on stdin)
  local d="$LAB/$1/etc/bind"
  mkdir -p "$d"; cat > "$d/db.${2%.}"
  printf 'zone "%s" { type primary; file "/etc/bind/db.%s"; };\n' "$2" "${2%.}" >> "$d/zones.conf"
}
named_conf() {  # named_conf HOST ADDRESS
  local d="$LAB/$1/etc/bind"
  mkdir -p "$d" "$LAB/$1/var/cache/bind" "$LAB/$1/run/named"
  cat > "$d/named.conf" <<CONF
options {
  directory "/var/cache/bind";
  listen-on { $2; };
  listen-on-v6 { none; };
  recursion no;
  allow-query { any; };
  dnssec-validation no;
  pid-file "/run/named/named.pid";
};
include "/etc/bind/zones.conf";
CONF
  : > "$d/zones.conf"
  chown -R bind:bind "$LAB/$1/var/cache/bind" "$LAB/$1/run/named"
}
build_dns() {
  named_conf rootns 192.0.2.10
  zone rootns . <<Z
\$TTL 86400
.                     SOA   a.root-servers.test. hostmaster.root-servers.test. $SERIAL 1800 900 604800 86400
.                     NS    a.root-servers.test.
com.         172800   NS    a.gtld-servers.test.
net.         172800   NS    a.gtld-servers.test.
test.        172800   NS    a.root-servers.test.
arpa.        172800   NS    a.root-servers.test.
a.root-servers.test.  A     192.0.2.10
a.gtld-servers.test.  A     192.0.2.20
Z
  zone rootns test. <<Z
\$TTL 86400
@                     SOA   a.root-servers.test. hostmaster.root-servers.test. $SERIAL 1800 900 604800 86400
@                     NS    a.root-servers.test.
a.root-servers        A     192.0.2.10
a.gtld-servers        A     192.0.2.20
Z
  zone rootns arpa. <<Z
\$TTL 86400
@                     SOA   a.root-servers.test. hostmaster.root-servers.test. $SERIAL 1800 900 604800 86400
@                     NS    a.root-servers.test.
2.0.192.in-addr       NS    ns1.example.com.
113.0.203.in-addr     NS    ns1.example.com.
100.51.198.in-addr    NS    ns1.example.com.
Z
  named_conf tldns 192.0.2.20
  for tld in com net; do
    zone tldns "$tld." <<Z
\$TTL 86400
@                     SOA   a.gtld-servers.test. hostmaster.gtld-servers.test. $SERIAL 1800 900 604800 86400
@                     NS    a.gtld-servers.test.
example      172800   NS    ns1.example.com.
Z
  done
  printf 'ns1.example.com. 172800 A 192.0.2.53\n' >> "$LAB/tldns/etc/bind/db.com"

  named_conf ns1 192.0.2.53
  zone ns1 example.com. <<Z
\$TTL 3600
@            SOA    ns1.example.com. hostmaster.example.com. $SERIAL 3600 900 1209600 300
@            NS     ns1.example.com.
@            A      192.0.2.80
@            MX     10 mail.example.com.
@            TXT    "v=spf1 mx -all"
ns1          A      192.0.2.53
www    300   A      192.0.2.80
www    300   AAAA   2001:db8:10::80
shop         CNAME  www.example.com.
mail         A      192.0.2.25
office       A      203.0.113.2
_dmarc       TXT    "v=DMARC1; p=reject; rua=mailto:dmarc@example.com"
; names for lesson 6's broken certificates, all on the web server
expired      A      192.0.2.80
selfsigned   A      192.0.2.80
nochain      A      192.0.2.80
intranet     A      192.0.2.80
; a subdomain handed to a server that does not answer for it: a lame delegation
old          NS     ns2.example.com.
ns2          A      192.0.2.20
Z
  zone ns1 example.net. <<Z
\$TTL 3600
@            SOA    ns1.example.com. hostmaster.example.net. $SERIAL 3600 900 1209600 300
@            NS     ns1.example.com.
@            MX     10 mail.example.net.
@            TXT    "v=spf1 mx -all"
mail         A      192.0.2.26
_dmarc       TXT    "v=DMARC1; p=reject; rua=mailto:dmarc@example.net"
Z
  # DKIM: each domain's public key, published under the selector "mail".
  local d
  for d in example.com example.net; do
    mkdir -p "$LAB/dkim/$d"
    opendkim-genkey -b 2048 -d "$d" -s mail -D "$LAB/dkim/$d"
    cat "$LAB/dkim/$d/mail.txt" >> "$LAB/ns1/etc/bind/db.$d"
  done
  zone ns1 2.0.192.in-addr.arpa. <<Z
\$TTL 3600
@            SOA    ns1.example.com. hostmaster.example.com. $SERIAL 3600 900 1209600 300
@            NS     ns1.example.com.
1            PTR    core.example.net.
10           PTR    a.root-servers.test.
20           PTR    a.gtld-servers.test.
25           PTR    mail.example.com.
26           PTR    mail.example.net.
53           PTR    ns1.example.com.
80           PTR    www.example.com.
Z
  zone ns1 113.0.203.in-addr.arpa. <<Z
\$TTL 3600
@            SOA    ns1.example.com. hostmaster.example.com. $SERIAL 3600 900 1209600 300
@            NS     ns1.example.com.
1            PTR    gw.isp.example.net.
2            PTR    office.example.com.
Z
  zone ns1 100.51.198.in-addr.arpa. <<Z
\$TTL 3600
@            SOA    ns1.example.com. hostmaster.example.com. $SERIAL 3600 900 1209600 300
@            NS     ns1.example.com.
1            PTR    bb1.isp.example.net.
53           PTR    resolver.isp.example.net.
254          PTR    core.example.net.
Z
  for h in rootns tldns ns1; do chown -R root:bind "$LAB/$h/etc/bind"; done

  # The ISP's resolver: recursive, for its customers, starting from the root.
  local u="$LAB/resolver/etc/unbound"
  mkdir -p "$u"
  cat > "$u/root.hints" <<'H'
.                        3600000  NS  a.root-servers.test.
a.root-servers.test.     3600000  A   192.0.2.10
H
  cat > "$u/unbound.conf" <<'C'
server:
  interface: 198.51.100.53
  interface: 127.0.0.1
  access-control: 0.0.0.0/0 allow
  do-ip6: no
  root-hints: "/etc/unbound/root.hints"
  module-config: "iterator"
  chroot: ""
  username: "unbound"
  pidfile: "/run/unbound-resolver.pid"
  do-not-query-localhost: no
  qname-minimisation: no
  # Unbound answers these itself by default, because on the real internet
  # nobody should be serving them. In the lab they are the whole internet.
  local-zone: "test." nodefault
  local-zone: "2.0.192.in-addr.arpa." nodefault
  local-zone: "100.51.198.in-addr.arpa." nodefault
  local-zone: "113.0.203.in-addr.arpa." nodefault
  val-log-level: 0
  verbosity: 0
remote-control:
  control-enable: yes
  control-interface: 127.0.0.1
  control-use-cert: no
C
}

```
