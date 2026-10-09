---
title: "O laboratório, parte 2: um DNS pequeno"
version: 1
---

Os nomes da internet de verdade são respondidos por uma hierarquia de servidores, e o laboratório tem
a mesma hierarquia em tamanho menor. **O `dns.sh` monta quatro servidores de DNS**, cada um na sua
máquina:

- `rootns`, a **raiz**, que só sabe quem responde por cada domínio de topo: `.com`, `.net`, `.test` e
  as zonas reversas sob `.arpa`;
- `tldns`, o servidor de **`.com` e `.net`**, que só sabe que `example.com` e `example.net` são
  respondidos pelo `ns1`;
- `ns1`, o servidor **autoritativo** dos dois domínios, que guarda os registros em si:
  `www.example.com`, os servidores de e-mail, os nomes de que a aula 6 precisa e os nomes reversos,
  que transformam um endereço de volta num nome;
- `resolver`, o **resolvedor recursivo** do provedor, a quem as máquinas do escritório perguntam. Ele
  não sabe nada por conta própria e desce a partir da raiz a cada pergunta nova.

Esse é o assunto da aula 4, e a aula 4 lê estas zonas um registro por vez. Aqui, o formato basta.
`zone` escreve um arquivo de zona e o declara ao servidor; `named_conf` escreve a configuração do
próprio servidor, que responde perguntas e nunca faz recursão. O resolvedor é o Unbound, e não o
BIND, como muitas vezes é o de um provedor. A configuração dele o aponta para a raiz do laboratório, e
não para a real, e as linhas `local-zone` o impedem de responder ele mesmo por `.test` e pelos
endereços de documentação, o que ele faz por padrão porque na internet de verdade ninguém deveria
servi-los.

Os domínios de e-mail também precisam publicar suas **chaves DKIM**, e a aula 9 explica por quê. Então
o arquivo gera um par de chaves para cada domínio com o `opendkim-genkey` e acrescenta a metade
pública à zona. Cada montagem gera chaves novas, e por isso os registros DKIM nas transcrições da
aula 9 não vão bater caractere por caractere com os seus.

Salve-o como `~/netlab/dns.sh`, do mesmo jeito que o primeiro arquivo:

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
