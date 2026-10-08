---
title: A segunda máquina
version: 2
---

A ana ganha uma segunda máquina sem um segundo computador: um **namespace de rede** chamado `remote`, com interface de rede e endereço próprios, `203.0.113.10`, alcançado do lado da ana por um cabo virtual cuja ponta é `203.0.113.1`. Dois nomes apontam para ele, `mcp.marginalia.test` e `auth.marginalia.test`. O `second_machine.sh` o constrói, como root, e implanta lá os dois programas que as próximas seções leem: o `auth_metadata.py` (seção 04) e o servidor que a ana escreveu, o `remote_mcp.py` (seção 05). Eles rodam como o usuário `mcpd`, com **um Python próprio e uma cópia própria da loja**. Salve os dois em `~/agents` antes; o script os copia de lá.

```bash
# second_machine.sh up|down: a second machine on this one, for lesson 16. Run it from ~/agents, with sudo.
#
# "remote" is a network namespace: an interface and an address of its own, 203.0.113.10 (an address
# kept for documentation, RFC 5737), reached from here through a virtual cable whose end is 203.0.113.1.
# Two names point at it. The servers run there as the user mcpd, from /srv/mcp, with their own Python
# and their own copy of the shop: nothing there reads /home.
set -euo pipefail
ME=${SUDO_USER:?run it with sudo, from your own account}
SRV=/srv/mcp

down() {
  ip netns pids remote 2>/dev/null | xargs -r kill || true
  ip netns del remote 2>/dev/null || true   # the cable goes with it
  sed -i '/marginalia[.]test/d' /etc/hosts
}

up() {
  down
  ip netns add remote
  ip link add mcp0 type veth peer name mcp1 netns remote
  ip addr add 203.0.113.1/24 dev mcp0
  ip link set mcp0 up
  ip -n remote addr add 203.0.113.10/24 dev mcp1
  ip -n remote link set mcp1 up
  ip -n remote link set lo up
  echo "203.0.113.10 mcp.marginalia.test auth.marginalia.test" >> /etc/hosts

  id mcpd >/dev/null 2>&1 || useradd --system --home-dir $SRV --shell /usr/sbin/nologin mcpd
  rm -rf $SRV
  install -d -o mcpd -g mcpd -m 0700 $SRV $SRV/tls
  install -o mcpd -g mcpd -m 0644 remote_mcp.py auth_metadata.py shop.py make_shop.py $SRV/
  runuser -u mcpd -- sh -c "cd $SRV && python3 -m venv .venv && .venv/bin/pip install -q mcp==2.3.0 uvicorn==0.54.0 &&
                            .venv/bin/python make_shop.py > /dev/null"

  # A certificate authority of this machine's own, which signs the servers' certificate and is then
  # thrown away. Its certificate is the one file you need: your clients are told to trust it.
  local ca; ca=$(mktemp -d)
  openssl req -x509 -newkey rsa:2048 -nodes -days 3650 -subj "/CN=Marginalia lab CA" \
    -keyout $ca/ca.key -out $ca/ca.crt 2>/dev/null
  openssl req -newkey rsa:2048 -nodes -subj "/CN=mcp.marginalia.test" \
    -keyout $SRV/tls/server.key -out $ca/server.csr 2>/dev/null
  printf 'subjectAltName=DNS:mcp.marginalia.test,DNS:auth.marginalia.test\n' > $ca/san.ext
  openssl x509 -req -in $ca/server.csr -CA $ca/ca.crt -CAkey $ca/ca.key -CAcreateserial -days 825 \
    -extfile $ca/san.ext -out $SRV/tls/server.crt 2>/dev/null
  install -o "$ME" -g "$ME" -m 0644 $ca/ca.crt marginalia-ca.crt
  rm -rf $ca

  # The tokens an authorization server would have issued: each value to tokens/NAME, readable by you
  # only, and its SHA-256, with what it grants, to the server's table. Never printed.
  install -d -o "$ME" -g "$ME" -m 0700 tokens
  local name client scopes resource expires value sep=""
  echo "{" > $SRV/tokens.json
  while read -r name client scopes resource expires; do
    value=lab-$(openssl rand -hex 24)
    printf '%s' "$value" > tokens/$name
    chown "$ME:$ME" tokens/$name
    chmod 0600 tokens/$name
    printf '%s "%s": {"client_id": "%s", "scopes": %s, "resource": "%s", "expires_at": %s}\n' "$sep" \
      "$(printf '%s' "$value" | sha256sum | cut -d' ' -f1)" "$client" "$scopes" "$resource" \
      "$(date -d "$expires" +%s)" >> $SRV/tokens.json
    sep=","
  done <<'TOKENS'
support support-agent ["orders:read"] https://mcp.marginalia.test:8443/mcp +90days
refunds refunds-desk ["orders:read","orders:refund"] https://mcp.marginalia.test:8443/mcp +90days
billing billing-agent ["orders:read"] https://billing.marginalia.test/mcp +90days
expired old-agent ["orders:read"] https://mcp.marginalia.test:8443/mcp -1day
TOKENS
  echo "}" >> $SRV/tokens.json
  chown -R mcpd:mcpd $SRV
  chmod 0600 $SRV/tokens.json $SRV/tls/server.key

  local p
  for p in remote_mcp auth_metadata; do
    ip netns exec remote runuser -u mcpd -- env -i HOME=$SRV PATH=/usr/bin:/bin \
      setsid sh -c "cd $SRV && exec .venv/bin/python $p.py" > /dev/null 2>> $SRV/servers.log < /dev/null &
  done
  for _ in $(seq 50); do
    if (exec 3<> /dev/tcp/203.0.113.10/8443) 2> /dev/null; then echo "remote is up"; return; fi
    sleep 0.2
  done
  echo "the server did not start; sudo tail $SRV/servers.log says why" >&2
  exit 1
}

case ${1:-} in
  up) up ;;
  down) down ;;
  *) echo "usage: sudo bash second_machine.sh up|down" >&2; exit 2 ;;
esac
```

Ele precisa do `ip` e do `openssl`, que o Ubuntu Server já instala, e da rede uma vez, para o `pip` baixar `mcp` e `uvicorn` no ambiente próprio da segunda máquina. Quando o servidor responde na porta 8443 ele diz `remote is up`; quando não responde, diz para onde foi o erro do servidor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Duas máquinas. Na da ana, um hospedeiro com um arquivo de token e o certificado da CA do laboratório. Na segunda, o namespace de rede remote em 203.0.113.10, o usuário mcpd roda o servidor MCP na porta 8443 e os metadados do servidor de autorização na porta 9443, com uma cópia própria da loja. Entre elas, HTTPS: TLS conferido contra a CA do laboratório, e um token de portador em todo pedido.\"><defs><marker id=\"l16mach-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">máquina da ana, 203.0.113.1</text><rect x=\"40\" y=\"60\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote_client.py</text><text x=\"50\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um hospedeiro, como ana</text><rect x=\"40\" y=\"130\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tokens/, marginalia-ca.crt</text><text x=\"50\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que ele leva e em que confia</text><rect x=\"440\" y=\"20\" width=\"260\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"456\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">remote, 203.0.113.10</text><rect x=\"460\" y=\"60\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote_mcp.py :8443</text><text x=\"470\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">como mcpd, shop.db próprio</text><rect x=\"460\" y=\"130\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">auth_metadata.py :9443</text><text x=\"470\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só metadados</text><path d=\"M260 85 L460 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l16mach-ah-phosphor)\"></path><text x=\"360\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTTPS + token de portador</text></svg>", "caption": "A fronteira agora é a rede: um certificado diz quem o servidor é, um token diz quem está pedindo.", "same": ["remote, 203.0.113.10"]}
```

```
ana@lab:~/agents$ sudo bash second_machine.sh up
remote is up
ana@lab:~/agents$ getent hosts mcp.marginalia.test auth.marginalia.test; ip -brief address show mcp0
203.0.113.10    mcp.marginalia.test auth.marginalia.test
203.0.113.10    mcp.marginalia.test auth.marginalia.test
mcp0@if2         UP             203.0.113.1/24 
ana@lab:~/agents$ ls /srv/mcp 2>&1; ls -l tokens marginalia-ca.crt
ls: cannot open directory '/srv/mcp': Permission denied
-rw-r--r-- 1 ana ana 1135 Oct  7 23:37 marginalia-ca.crt

tokens:
total 16
-rw------- 1 ana ana 52 Oct  7 23:37 billing
-rw------- 1 ana ana 52 Oct  7 23:37 expired
-rw------- 1 ana ana 52 Oct  7 23:37 refunds
-rw------- 1 ana ana 52 Oct  7 23:37 support
```

Os nomes resolvem para o endereço da segunda máquina, e a ponta do cabo do lado da ana está no ar. O `ls /srv/mcp` é recusado: os arquivos do servidor pertencem ao `mcpd`, e a ana não consegue lê-los, nem a tabela de tokens lá dentro. A outra direção também vale: o `remote_mcp.py` lê o próprio `data/shop.db`, não nada em `/home/ana`. O diretório `tokens` guarda quatro tokens de portador que o script escreveu para a ana, legíveis só por ela; a seção 06 usa cada um. O `marginalia-ca.crt` é o único arquivo da autoridade certificadora da segunda máquina que a ana tem, e o próximo bloco o usa.

Um namespace separa redes, e o usuário e os diretórios separados separam arquivos. Não é um segundo computador de verdade (os dois dividem um kernel), e para os fins desta aula não precisa ser: tudo o que o cliente e o servidor conseguem observar é o que observariam numa rede de verdade.

**O TLS vem primeiro.** O certificado do servidor foi assinado por uma autoridade certificadora que o script criou e cuja chave depois apagou, e nada na máquina da ana confia nessa autoridade a menos que seja mandado:

```
ana@lab:~/agents$ curl -s -o /dev/null https://mcp.marginalia.test:8443/mcp; echo "curl exit code: $?"
curl exit code: 60
ana@lab:~/agents$ openssl s_client -connect mcp.marginalia.test:8443 -servername mcp.marginalia.test -CAfile marginalia-ca.crt < /dev/null 2>/dev/null | grep -E "^subject=|^issuer=|Verify return code"
subject=CN = mcp.marginalia.test
issuer=CN = Marginalia lab CA
Verify return code: 0 (ok)
```

Sem essa CA, o `curl` recusou a conexão com o código de saída `60`, que é o código do curl para um certificado que ele não conseguiu verificar. Com o `-CAfile` apontando para `marginalia-ca.crt`, o mesmo certificado foi verificado: assunto `mcp.marginalia.test`, emissor `Marginalia lab CA`, código de retorno `0`. Esse arquivo é a única mudança do lado do cliente. **Nada nesta aula desliga a verificação**: um cliente que pula a checagem conversaria igualmente feliz com qualquer um que respondesse naquele endereço, que é exatamente o que o TLS existe para impedir.
