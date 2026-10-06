---
title: A segunda máquina
version: 1
---

O laboratório dá à ana uma segunda máquina sem um segundo computador: um **namespace de rede** chamado `remote`, com interface de rede e endereço próprios, `203.0.113.10`, alcançado do lado da ana por um cabo virtual cuja ponta é `203.0.113.1`. Dois nomes apontam para ele, `mcp.marginalia.test` e `auth.marginalia.test`. O `lab.sh` o constrói, e o `lab.sh remote` implanta o servidor que a ana escreveu (seção 05) e o inicia lá como o usuário `mcpd`, com **uma cópia própria da loja**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Duas máquinas. Na da ana, um hospedeiro com um arquivo de token e o certificado da CA do laboratório. Na segunda, o namespace de rede remote em 203.0.113.10, o usuário mcpd roda o servidor MCP na porta 8443 e os metadados do servidor de autorização na porta 9443, com uma cópia própria da loja. Entre elas, HTTPS: TLS conferido contra a CA do laboratório, e um token de portador em todo pedido.\"><defs><marker id=\"l16mach-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">máquina da ana, 203.0.113.1</text><rect x=\"40\" y=\"60\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote_client.py</text><text x=\"50\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um hospedeiro, como ana</text><rect x=\"40\" y=\"130\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tokens/, marginalia-ca.crt</text><text x=\"50\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que ele leva e em que confia</text><rect x=\"440\" y=\"20\" width=\"260\" height=\"180\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"456\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">remote, 203.0.113.10</text><rect x=\"460\" y=\"60\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">remote_mcp.py :8443</text><text x=\"470\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">como mcpd, shop.db próprio</text><rect x=\"460\" y=\"130\" width=\"220\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">auth_metadata.py :9443</text><text x=\"470\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">só metadados</text><path d=\"M260 85 L460 85\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l16mach-ah-phosphor)\"></path><text x=\"360\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTTPS + token de portador</text></svg>", "caption": "A fronteira agora é a rede: um certificado diz quem o servidor é, um token diz quem está pedindo.", "same": ["remote, 203.0.113.10"]}
```

```
ana@lab:~/agents$ getent hosts mcp.marginalia.test auth.marginalia.test; ip -brief address show mcp0
203.0.113.10    mcp.marginalia.test auth.marginalia.test
203.0.113.10    mcp.marginalia.test auth.marginalia.test
mcp0@if7         UP             203.0.113.1/24 
ana@lab:~/agents$ ls /srv/mcp 2>&1; ls -l tokens
ls: cannot open directory '/srv/mcp': Permission denied
total 16
-rw------- 1 ana ana 52 Oct  6 00:55 billing
-rw------- 1 ana ana 52 Oct  6 00:55 expired
-rw------- 1 ana ana 52 Oct  6 00:55 refunds
-rw------- 1 ana ana 52 Oct  6 00:55 support
```

Os nomes resolvem para o endereço da segunda máquina, e a ponta do cabo do lado da ana está no ar. O `ls /srv/mcp` é recusado: os arquivos do servidor pertencem ao `mcpd`, e a ana não consegue lê-los, nem a tabela de tokens lá dentro. A outra direção também vale: o `remote_mcp.py` lê o próprio `data/shop.db`, não nada em `/home/ana`. O diretório `tokens` guarda quatro tokens de portador que o laboratório escreveu para a ana, legíveis só por ela; a seção 06 usa cada um.

Um namespace separa redes, e o usuário e os diretórios separados separam arquivos. Não é um segundo computador de verdade (os dois dividem um kernel), e para os fins desta aula não precisa ser: tudo o que o cliente e o servidor conseguem observar é o que observariam numa rede de verdade.

**O TLS vem primeiro.** O certificado do servidor foi assinado por uma autoridade certificadora que o laboratório criou para si, e nada na máquina da ana confia nessa autoridade a menos que seja mandado:

```
ana@lab:~/agents$ curl -s -o /dev/null https://mcp.marginalia.test:8443/mcp; echo "curl exit code: $?"
curl exit code: 60
ana@lab:~/agents$ openssl s_client -connect mcp.marginalia.test:8443 -servername mcp.marginalia.test -CAfile /opt/agents/share/marginalia-ca.crt < /dev/null 2>/dev/null | grep -E "^subject=|^issuer=|Verify return code"
subject=CN = mcp.marginalia.test
issuer=CN = Marginalia lab CA
Verify return code: 0 (ok)
```

Sem a CA do laboratório, o `curl` recusou a conexão com o código de saída `60`, que é o código do curl para um certificado que ele não conseguiu verificar. Com o `-CAfile` apontando para `/opt/agents/share/marginalia-ca.crt`, o mesmo certificado foi verificado: assunto `mcp.marginalia.test`, emissor `Marginalia lab CA`, código de retorno `0`. Esse arquivo é a única mudança do lado do cliente. **Nada nesta aula desliga a verificação**: um cliente que pula a checagem conversaria igualmente feliz com qualquer um que respondesse naquele endereço, que é exatamente o que o TLS existe para impedir.
