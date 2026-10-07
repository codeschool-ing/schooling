---
title: DNSSEC, uma assinatura em cada resposta
version: 1
---

O **DNSSEC** assina os registros de uma zona. O dono da zona guarda uma chave privada; cada conjunto
de registros recebe uma assinatura, publicada como um registro `RRSIG` ao lado dele; a chave pública
também é publicada, como um `DNSKEY`. Um **resolvedor que valida** (*validating resolver*) confere a
assinatura contra uma chave em que confia antes de acreditar em uma resposta.

É a origem da chave confiável que faz isso funcionar pela internet. Cada zona pai publica uma
impressão digital das chaves das zonas filhas, e assim a confiança desce a partir da raiz, cuja chave
todo resolvedor que valida já vem configurado para conhecer. O laboratório não tem raiz, então o
resolvedor é instruído a confiar diretamente na chave da zona da empresa, que é o mesmo mecanismo com
a cadeia encurtada.

O laboratório da aula 1 não tem zona assinada. Este script acrescenta uma, e o resolvedor que valida
e a confere. Salve-o ao lado do `nslab.sh` e rode-o num laboratório de pé, com `sudo bash dnssec.sh`:

```schooling-example
{"language": "sh", "file": "dnssec.sh", "parts": [{"code": "#!/bin/bash\n# dnssec.sh: run after nslab.sh up, from the same directory.\n#   sudo bash dnssec.sh\nset -euo pipefail\nLAB=/lab\nNSLAB=\"bash $(dirname \"$(readlink -f \"$0\")\")/nslab.sh\"\n[ -e /run/netns/wire ] || { echo \"the lab is not up: sudo bash nslab.sh up\" >&2; exit 1; }\n[ -e \"$LAB/dns/etc/bind\" ] && { echo \"the signed zone is already there: sudo bash nslab.sh reset, then run this again\" >&2; exit 1; }\nb=\"$LAB/dns/etc/bind\" c=\"$LAB/dns/var/cache/bind\"\nmkdir -p \"$b\" \"$c\"\ncp -a /etc/bind/. \"$b/\"", "note": "A zona assinada da aula 8, acrescentada a um laboratório em funcionamento. O `dns` continua respondendo pelos nomes da empresa com o dnsmasq na porta 53; ao lado dele, o BIND serve a mesma zona **assinada**, na porta 5300."}, {"code": "cat > \"$b/db.example.com\" <<'Z'\n$TTL 300\n@        SOA  dns.example.com. hostmaster.example.com. 2026092801 3600 900 1209600 300\n@        NS   dns.example.com.\ndns      A    192.0.2.53\nwww      A    192.0.2.80\nZ\n( cd \"$b\" && dnssec-keygen -q -a ECDSAP256SHA256 -f KSK example.com >/dev/null && dnssec-keygen -q -a ECDSAP256SHA256 example.com >/dev/null\n  for k in Kexample.com.*.key; do echo \"\\$INCLUDE $k\" >> db.example.com; done\n  dnssec-signzone -q -S -K . -o example.com -N keep -s 20260901000000 -e 20261231000000 -f db.example.com.signed db.example.com >/dev/null )", "note": "A zona tem quatro registros. Duas chaves são criadas do zero a cada execução, uma chave de assinatura de chaves e uma de assinatura da zona, então os identificadores de chave e as assinaturas que você vê diferem dos da aula; o `dnssec-signzone` assina a zona com elas."}, {"code": "cat > \"$b/named.conf\" <<'CONF'\noptions {\n  directory \"/var/cache/bind\";\n  listen-on port 5300 { 192.0.2.53; };\n  listen-on-v6 { none; };\n  recursion no;\n  dnssec-validation no;\n  trust-anchor-telemetry no;\n  pid-file \"/var/cache/bind/named.pid\";\n};\nzone \"example.com\" { type primary; file \"/etc/bind/db.example.com.signed\"; };\nCONF\nchown -R bind:bind \"$b\" \"$c\"", "note": "O BIND responde só por esta zona e não pergunta nada à internet de verdade: sem recursão, e sem validação ou telemetria próprias, que o mandariam aos servidores raiz reais."}, {"code": "u=\"$LAB/laptop/etc/unbound\"\nmkdir -p \"$u\" \"$LAB/laptop/var/lib/unbound\"\ngrep 'DNSKEY 257' \"$b\"/Kexample.com.*.key | sed 's/^[^:]*://' > \"$u/example.com.key\"\ncat > \"$u/unbound.conf\" <<'CONF'\nserver:\n  interface: 127.0.0.1\n  port: 53\n  do-not-query-localhost: no\n  username: \"\"\n  chroot: \"\"\n  pidfile: \"/var/lib/unbound/unbound.pid\"\n  use-syslog: no\n  logfile: \"/var/lib/unbound/unbound.log\"\n  verbosity: 1\n  val-log-level: 2\n  module-config: \"validator iterator\"\n  trust-anchor-file: \"/etc/unbound/example.com.key\"\nremote-control:\n  control-enable: yes\n  control-interface: 127.0.0.1\n  control-use-cert: no\nstub-zone:\n  name: \"example.com\"\n  stub-addr: 192.0.2.53@5300\nCONF", "note": "No `laptop`, um resolvedor que valida, o Unbound, escuta no seu próprio loopback. Ele manda toda pergunta sobre `example.com` ao BIND, e confia na zona porque recebeu a chave de assinatura de chaves: esse arquivo é a **âncora de confiança**."}, {"code": "$NSLAB exec dns root \"setsid named -u bind -c /etc/bind/named.conf </dev/null >/dev/null 2>&1 &\"\n$NSLAB exec laptop root \"setsid unbound -d -c /etc/unbound/unbound.conf </dev/null >/dev/null 2>&1 &\"", "note": "Os dois sobem dentro das suas máquinas, pelo `nslab.sh exec`."}]}
```

Assim, o `dns` serve a zona assinada na porta 5300, e o `laptop` roda um resolvedor que valida, o Unbound, no
seu próprio loopback:

```
ana@laptop:~$ grep -E "server:|trust-anchor|stub-addr" /etc/unbound/unbound.conf
server:
  trust-anchor-file: "/etc/unbound/example.com.key"
  stub-addr: 192.0.2.53@5300
```

A âncora de confiança (*trust anchor*) é a chave pública da zona; o endereço do stub diz ao Unbound
onde a zona é servida. Perguntando a ele o endereço da loja, com `+dnssec` para que a assinatura
apareça:

```
ana@laptop:~$ dig +dnssec @127.0.0.1 www.example.com | grep -E "flags:|IN.A|RRSIG"
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1
; EDNS: version: 0, flags: do; udp: 1232
;www.example.com.		IN	A
www.example.com.	300	IN	A	192.0.2.80
www.example.com.	300	IN	RRSIG	A 13 3 300 20261231000000 20260901000000 63346 example.com. cRghjqyAuxVDYFMyd2M4M+lUN/+pKmeoc8eB2lXcgKHArwkkzPO6J4De M3LZLWAhcLrF6lM0HUOWGfeI458UWA==
```

A resposta, `192.0.2.80`, chega com o seu `RRSIG`: algoritmo 13, que é ECDSA com P-256, válido de 1º
de setembro a 31 de dezembro de 2026, feito com a chave cuja tag a assinatura nomeia. E entre as flags
está **`ad`, dados autenticados** (*authenticated data*): o resolvedor conferiu a assinatura e diz
isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"À esquerda, a cadeia de confiança na internet: o resolvedor confia na chave da raiz; a zona raiz publica uma impressão digital da chave de .com; .com publica uma impressão digital da chave de example.com; a chave de example.com assina os registros. À direita, o laboratório: o resolvedor no laptop recebe a chave de example.com direto como âncora de confiança, e essa chave assina o registro www.example.com A 192.0.2.80.\"><defs><marker id=\"dn-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"dn-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">na internet</text><rect x=\"20\" y=\"34\" width=\"300\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.</text><text x=\"30\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chave da raiz, configurada em todo resolvedor</text><rect x=\"20\" y=\"94\" width=\"300\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">com.</text><text x=\"30\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chave dela, com impressão digital na raiz</text><rect x=\"20\" y=\"154\" width=\"300\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com.</text><text x=\"30\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chave dela, com impressão digital em .com</text><path d=\"M170 80 L170 94\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dn-ah-phosphor)\"></path><path d=\"M170 140 L170 154\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dn-ah-phosphor)\"></path><text x=\"20\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada pai garante a chave do filho</text><path d=\"M360 20 L360 235\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></path><text x=\"390\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">no laboratório</text><rect x=\"390\" y=\"34\" width=\"310\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop: Unbound</text><text x=\"400\" y=\"67\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">âncora de confiança: a chave de example.com</text><rect x=\"390\" y=\"154\" width=\"310\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www.example.com A 192.0.2.80</text><text x=\"400\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RRSIG feita com essa chave</text><path d=\"M545 80 L545 154\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#dn-ah-phosphor)\"></path><text x=\"555\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">confere a assinatura</text></svg>", "caption": "A cadeia da internet começa na raiz. A do laboratório começa na zona, que é a mesma verificação com menos elos."}
```

Um cliente que confia no `ad` está confiando na palavra do seu resolvedor, então o trecho entre os
dois também precisa ser confiável: aqui é o loopback, na mesma máquina. Numa rede, esse último
salto também precisa de proteção, e ela vem da criptografia: DNS sobre TLS ou sobre HTTPS.
