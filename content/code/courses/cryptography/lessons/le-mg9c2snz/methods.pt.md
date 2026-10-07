---
title: Métodos EAP: EAP-TLS, PEAP e EAP-TTLS
version: 1
---

**O EAP é uma moldura para autenticação, não um método em si. O que um aparelho prova de fato, e
como, é decidido pelo método EAP, e três deles cobrem quase toda rede em uso.** Os três começam do
mesmo jeito: uma sessão TLS entre o aparelho e o servidor RADIUS, levada dentro do EAP, por um ponto
de acesso que não vê nada dela.

| método | o servidor se prova com | a pessoa ou o aparelho se prova com |
| --- | --- | --- |
| EAP-TLS | um certificado | um certificado próprio, no mesmo handshake TLS |
| PEAP | um certificado | uma senha, por MSCHAPv2 dentro do túnel TLS |
| EAP-TTLS | um certificado | uma senha ou outro método, dentro do túnel |

## EAP-TLS: certificados dos dois lados

O EAP-TLS é o handshake TLS da aula 10 com um acréscimo, o certificado do cliente: o aparelho
apresenta um certificado e prova que tem a chave privada, exatamente como o servidor faz. Nenhuma
senha atravessa a rede, então não há nenhuma para chutar, pescar com phishing ou reaproveitar. O custo
é um certificado em cada aparelho, emitido e renovado por uma AC, que é a PKI da aula 8 posta para
trabalhar. Organizações que gerenciam os notebooks com uma ferramenta de gestão de aparelhos emitem
esses certificados automaticamente, e aí o EAP-TLS é a escolha mais forte e a que menos dá trabalho à
equipe.

## PEAP: uma senha dentro de um túnel

O PEAP mantém o certificado do servidor e troca o do cliente por uma senha. A sessão TLS vira um
túnel, e dentro dele roda o **MSCHAPv2**, o protocolo de desafio e resposta da Microsoft, de 1999. O
PEAP com MSCHAPv2 é o padrão do Windows e o Wi-Fi corporativo mais comum do mundo, porque funciona com
as contas que a organização já tem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"O PEAP desenhado em camadas aninhadas. A camada de fora é o EAP, que leva só a identidade externa, anonymous@vereda.example, legível por todo ponto de acesso e proxy no caminho. Dentro dela, um túnel TLS até o servidor RADIUS, aberto só depois de conferido o certificado do servidor. Dentro do túnel, o MSCHAPv2 com a identidade real, ana, e o desafio e a resposta da senha, desenhados em vermelho porque são o que um túnel não conferido entregaria a um impostor.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">EAP, legível no caminho: identidade externa</text><text x=\"684\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">anonymous@vereda.example</text><rect x=\"50\" y=\"56\" width=\"620\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"66\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">túnel TLS, depois de conferir o certificado do servidor</text><rect x=\"80\" y=\"92\" width=\"560\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">MSCHAPv2: identidade real, desafio e resposta</text><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ana</text></svg>", "caption": "PEAP: o que cada camada leva. O miolo vermelho só é tão seguro quanto a conferência do certificado em volta dele."}
```

## O PEAP na sua própria máquina

Não é preciso rádio para ver o PEAP funcionar. O ponto de acesso só repassa o EAP entre o notebook e
um servidor RADIUS, então um programa que faz o papel do notebook e do ponto de acesso, o
`eapol_test`, consegue conversar direto com um servidor RADIUS. O Ubuntu empacota os dois. Instalar
o FreeRADIUS também o põe para rodar como serviço em todos os endereços, e o laboratório roda dois
servidores próprios no lugar dele, então a segunda linha para aquele de vez:

```sh
sudo apt-get install -y freeradius eapoltest
sudo systemctl disable --now freeradius
```

Os dois servidores são o da Vereda, em `127.0.0.1`, e um impostor, em `127.0.0.2`, de que a seção 04
precisa. Um script sobe os dois, a partir da configuração padrão do próprio FreeRADIUS com um punhado
de linhas mudadas, cada uma comentada:

```sh
#!/usr/bin/env bash
# ~/lab/bin/radius-servers
# sudo radius-servers start | stop: lesson 16's two RADIUS servers.
#
#   127.0.0.1  Vereda's own, with pki/radius-chain.pem; knows the user ana
#   127.0.0.2  an impostor, with pki/radius-impostor.pem: the same names,
#              issued by another root; knows nobody
#
# Both are FreeRADIUS, configured from Ubuntu's defaults in
# /etc/freeradius/3.0, offer PEAP, and accept the RADIUS secret
# lab-only-radius-secret from the loopback network. They listen on IPv4
# only: the defaults' IPv6 listeners would have the two fight over one
# address.
set -euo pipefail
lab=$(cd "$(dirname "$0")/.." && pwd)
run=/run/vereda-radius   # not in ~/lab: root writes here

server() {  # server NAME ADDRESS CERTIFICATE KEY INNER-PORT USERS
  local d=$run/$1
  rm -rf "$d"
  cp -r /etc/freeradius/3.0 "$d"
  printf 'client loopback {\n\tipaddr = 127.0.0.0/8\n\tsecret = lab-only-radius-secret\n}\n' > "$d/clients.conf"
  printf '%s\n' "$6" > "$d/mods-config/files/authorize"
  # run as root, so that it can read the keys in ~/lab
  sed -i 's/^\tuser = freerad/#&/; s/^\tgroup = freerad/#&/' "$d/radiusd.conf"
  sed -i "s|^\t\tprivate_key_password = whatever|#&|
          s|private_key_file = /etc/ssl/private/ssl-cert-snakeoil.key|private_key_file = $4|
          s|certificate_file = /etc/ssl/certs/ssl-cert-snakeoil.pem|certificate_file = $3|
          s|ca_file = /etc/ssl/certs/ca-certificates.crt|ca_file = $lab/pki/root.pem|
          s|default_eap_type = md5|default_eap_type = peap|" "$d/mods-available/eap"
  sed -i "s/port = 18120/port = $5/" "$d/sites-available/inner-tunnel"
  # Every IPv4 listener on ADDRESS instead of on all addresses; every IPv6
  # listener left out. A listener is a `listen { ... }` block, so this
  # counts braces rather than lines.
  python3 - "$d/sites-available/default" "$2" <<'PY'
import re
import sys
path, address = sys.argv[1], sys.argv[2]
text, out, i = open(path).read(), [], 0
while (j := text.find("listen {", i)) >= 0:
    depth, k = 0, j
    while True:
        depth += {"{": 1, "}": -1}.get(text[k], 0)
        if depth == 0 and text[k] == "}":
            break
        k += 1
    block = text[j:k + 1]
    out.append(text[i:j])
    if not re.search(r"^\s*ipv6addr", block, re.M):
        out.append(block.replace("ipaddr = *", f"ipaddr = {address}"))
    i = k + 1
out.append(text[i:])
open(path, "w").write("".join(out))
PY
  freeradius -d "$d" -l "$d/radius.log"
}

stop() {
  pkill -f "freeradius -d $run/" || true
}

start() {
  stop
  sleep 1
  mkdir -p "$run"
  server real 127.0.0.1 "$lab/pki/radius-chain.pem" "$lab/pki/radius.key" 18120 \
    'ana	Cleartext-Password := "lab only: ana na rede da equipe"'
  server impostor 127.0.0.2 "$lab/pki/radius-impostor.pem" "$lab/pki/radius-impostor.key" 18121 ''
  echo "RADIUS on 127.0.0.1 (Vereda's) and 127.0.0.2 (the impostor)"
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  *) echo "usage: sudo radius-servers start | stop" >&2; exit 2 ;;
esac
```

```sh
cd ~/lab
chmod +x bin/radius-servers
sudo ~/lab/bin/radius-servers start
```

Eles rodam até a máquina reiniciar ou até você digitar `sudo ~/lab/bin/radius-servers stop`, e
`start` de novo os reinicia.

O lado do notebook é um perfil no formato que o `wpa_supplicant` lê, o mesmo arquivo que um notebook
com Linux usaria. Ele diz o método, a pessoa, a senha e, nas duas últimas linhas, o servidor com
quem o aparelho aceita conversar:

```sh
cd ~/lab
cat > peap.conf <<'EOF'
network={
	ssid="Vereda-Equipe"
	key_mgmt=WPA-EAP
	eap=PEAP
	identity="ana"
	anonymous_identity="anonymous@vereda.example"
	password="lab only: ana na rede da equipe"
	phase2="auth=MSCHAPV2"
	ca_cert="pki/root.pem"
	domain_suffix_match="radius.vereda.example"
}
EOF
```

O `eapol_test` faz o papel do ponto de acesso e do notebook ao mesmo tempo, contra o servidor
FreeRADIUS da Vereda. A saída de depuração dele passa de mil linhas, então ela passa pelo `vcrypt
eap-log`, que guarda os eventos de que esta aula fala e nenhuma das chaves da sessão. Como o
`tls-flow` da aula 10, ele é um leitor e nada mais:

```py
# ~/lab/tools/eap-log.py
"""vcrypt eap-log: read the debug output of `eapol_test` on standard input
and print what lesson 16 talks about: the identity sent in clear, the
method, the certificate the server presented and whether it was accepted,
what crossed inside the tunnel, and the result. The keys and nonces, which
differ on every run, are left out; the debug output itself is the evidence,
and this is a way of reading it."""
import re
import sys


def summary(lines):
    out, seen = [], set()

    def put(label, text):
        if text in seen:
            return
        seen.add(text)
        out.append(f"{label:27}{text}" if label else f"{'':27}{text}")

    attribute, certs = None, 0
    for raw in lines:
        line = raw.rstrip("\n")
        m = re.match(r"\s+Value: '(.+)'$", line)
        if m and attribute == "User-Name":
            put("outer identity, in clear:", m.group(1))
        m = re.match(r"\s+Attribute \d+ \(([\w-]+)\)", line)
        if m:
            attribute = m.group(1)
        m = re.search(r"CTRL-EVENT-EAP-METHOD EAP vendor 0 method \d+ \((\w+)\) selected", line)
        if m:
            put("method:", m.group(1))
        m = re.match(r"SSL: Using TLS version (\S+)", line)
        if m:
            put("TLS version:", m.group(1))
        m = re.search(r"CTRL-EVENT-EAP-PEER-CERT depth=(\d) subject='([^']+)'", line)
        if m:
            put("" if certs else "server certificate:", f"depth {m.group(1)}  {m.group(2)}")
            certs += 1
        m = re.search(r"CTRL-EVENT-EAP-PEER-ALT depth=(\d) (\S+)", line)
        if m:
            put("", f"depth {m.group(1)}  name {m.group(2)}")
        m = re.search(r"CTRL-EVENT-EAP-TLS-CERT-ERROR reason=\d+ depth=(\d) .* err='([^']+)'", line)
        if m:
            put("certificate REFUSED:", f"depth {m.group(1)}, {m.group(2)}")
        m = re.search(r"EAP: Status notification: local TLS alert \(param=(.+)\)", line)
        if m:
            put("", f"alert sent to the server: {m.group(1)}")
        if "EAP-PEAP: Phase 2 Request: type=1" in line:
            put("inside the tunnel:", "inner identity sent")
        if "EAP-MSCHAPV2: Generating Challenge Response" in line:
            put("", "MSCHAPv2 challenge answered")
        if "EAP-MSCHAPV2: Authentication succeeded" in line:
            put("", "MSCHAPv2: the server proved it knows the password")
        if line.startswith("PMK from EAPOL"):
            put("PMK:", "32 bytes, made by this session (not shown)")
        if line in ("SUCCESS", "FAILURE"):
            put("result:", line)
    return out


for line in summary(sys.stdin):
    print(line)
```

O PEAP, lido por ele:

```
ana@lab:~/lab$ eapol_test -c peap.conf -a 127.0.0.1 -s lab-only-radius-secret | vcrypt eap-log
outer identity, in clear:  anonymous@vereda.example
method:                    PEAP
TLS version:               TLSv1.2
server certificate:        depth 2  /C=BR/O=Vereda Fisioterapia/CN=Vereda Root CA
                           depth 1  /C=BR/O=Vereda Fisioterapia/CN=Vereda Issuing CA 1
                           depth 0  /C=BR/O=Vereda Fisioterapia/CN=radius.vereda.example
                           depth 0  name DNS:radius.vereda.example
inside the tunnel:         inner identity sent
                           MSCHAPv2 challenge answered
                           MSCHAPv2: the server proved it knows the password
PMK:                       32 bytes, made by this session (not shown)
result:                    SUCCESS
```

Leia de cima para baixo:

- A **identidade externa**, `anonymous@vereda.example`, é o único nome enviado antes de o túnel
  existir, e todo ponto de acesso e todo proxy RADIUS no caminho conseguem lê-la. A verdadeira,
  `ana`, só passou dentro do túnel. Preencher `anonymous_identity` mantém a lista de nomes da equipe
  fora do ar.
- O **certificado do servidor** veio com a cadeia, e o aparelho o aceitou. A seção 04 é sobre essa
  linha.
- **O MSCHAPv2 deu certo nos dois sentidos**: o aparelho respondeu ao desafio do servidor, e o servidor
  respondeu ao do aparelho, provando que também conhecia a senha.
- A **PMK** saiu desta sessão. Duas sessões seguidas dão duas PMKs diferentes:

```
ana@lab:~/lab$ for i in 1 2; do eapol_test -c peap.conf -a 127.0.0.1 -s lab-only-radius-secret | grep 'PMK from EAPOL'; done | sort -u | wc -l
2
```

## Por que o MSCHAPv2 nunca pode rodar fora de um túnel

O MSCHAPv2 é construído sobre o hash de senha do NT e o DES. Em 2012, pesquisadores mostraram que uma
troca MSCHAPv2 gravada se reduz a achar uma única chave DES de 56 bits, o que uma máquina dedicada
fazia em menos de um dia, e desde então a Microsoft orienta que o MSCHAPv2 só é seguro dentro de um túnel. **O PEAP é
esse túnel, e ele só protege o MSCHAPv2 se o aparelho conferiu quem está na outra ponta.** Um túnel
para o servidor errado entrega a troca justamente a quem ela devia ser escondida.

O EAP-TTLS tem o mesmo formato do PEAP e a mesma dependência. Dentro do túnel ele pode levar uma senha
pura (PAP), o que não é pior que o MSCHAPv2 quando o túnel é sólido, e não é melhor quando não é.
