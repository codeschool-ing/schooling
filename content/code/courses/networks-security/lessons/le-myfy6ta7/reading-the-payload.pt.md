---
title: Lendo além dos cabeçalhos
version: 1
---

A **inspeção profunda de pacotes** (*deep packet inspection*, DPI) lê a carga útil (*payload*) além
dos cabeçalhos, e reconhece protocolos pelo que eles dizem, e não por onde dizem. Um **firewall de
nova geração** (*next-generation firewall*, NGFW) é um firewall com essa capacidade embutida, de
modo que uma regra pode nomear uma aplicação em vez de uma porta.

O laboratório não tem NGFW comercial, e não precisa de um para mostrar o mecanismo. O **Suricata** é
um motor de código aberto que lê o tráfego e identifica o protocolo dele; a aula 15 o usa para
detectar, e aqui ele só observa. Ele roda no `fw`, escutando na interface da LAN, com um arquivo de
regras vazio:

```
root@fw:~# cat /etc/suricata/rules/local.rules; grep -A1 "^rule-files" /etc/suricata/suricata.yaml
rule-files:
  - local.rules
root@fw:~# suricata -c /etc/suricata/suricata.yaml --af-packet=eth2 -D --pidfile /var/log/suricata/suricata.pid
i: suricata: This is Suricata version 7.0.3 RELEASE running in SYSTEM mode
```

Depois o `laptop` faz três coisas: busca a página web por HTTPS, tenta SSH no `remote` pela 443 e
pede ao `app` a página dele por HTTP puro na 8080. O login SSH falha porque a `ana` não tem chave no
`remote`, e isso não importa: a conversa aconteceu do mesmo jeito.

```
ana@laptop:~$ curl -s -o /dev/null https://www.example.com/
ana@laptop:~$ ssh -p 443 -o BatchMode=yes 203.0.113.50 true; echo "exit $?"
ana@203.0.113.50: Permission denied (publickey).
exit 255
ana@laptop:~$ curl -s -o /dev/null http://192.168.20.10:8080/
```

Quando o Suricata para, ele escreve um **registro de fluxo** (*flow record*) para cada conversa que
viu, com o protocolo que ele concluiu que a conversa carregava:

```
root@fw:~# jq -c "select(.event_type==\"flow\") | [.src_ip, .dest_ip, .dest_port, .app_proto]" /var/log/suricata/eve.json
["192.168.10.20","203.0.113.50",443,"ssh"]
["192.168.10.20","192.0.2.80",443,"tls"]
["192.168.10.20","192.168.20.10",8080,"http"]
```

**Dois fluxos foram para a porta 443 e o Suricata os nomeou de forma diferente**: `ssh` e `tls`. O
terceiro, na 8080, ele nomeou `http`, embora nada diga que a 8080 é para HTTP. Ele decidiu cada um
pelos primeiros bytes da conversa, que é exatamente o que a regra baseada em porta não conseguia
fazer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três fluxos do laptop, comparados em duas colunas. Na primeira, o que uma regra de porta vê: porta 443, porta 443 e porta 8080, todas permitidas. Na segunda, os primeiros bytes da carga e o protocolo que o Suricata nomeou a partir deles: SSH-2.0-OpenSSH, chamado ssh; um ClientHello TLS para www.example.com, chamado tls; GET / HTTP/1.1, chamado http.\"><defs></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">fluxo</text><text x=\"230\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o que uma regra de porta vê</text><text x=\"430\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o que a carga diz</text><rect x=\"20\" y=\"40\" width=\"680\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"30\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">→ 203.0.113.50</text><text x=\"230\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tcp dport 443</text><text x=\"230\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">permitido</text><text x=\"430\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SSH-2.0-OpenSSH_9.6p1</text><text x=\"430\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">ssh</text><rect x=\"20\" y=\"104\" width=\"680\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"30\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">→ 192.0.2.80</text><text x=\"230\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tcp dport 443</text><text x=\"230\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">permitido</text><text x=\"430\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ClientHello, SNI www.example.com</text><text x=\"430\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">tls</text><rect x=\"20\" y=\"168\" width=\"680\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">laptop</text><text x=\"30\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">→ 192.168.20.10</text><text x=\"230\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tcp dport 8080</text><text x=\"230\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">permitido</text><text x=\"430\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET / HTTP/1.1</text><text x=\"430\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">http</text></svg>", "caption": "Mesmos cabeçalhos, conversas diferentes. A coluna da porta não distingue as duas primeiras linhas."}
```

## Como o reconhecimento funciona

Todo protocolo abre de um jeito reconhecível. O SSH começa com uma linha de texto, `SSH-2.0-` e o
nome do software, dos dois lados. O TLS começa com um *ClientHello*, um registro binário cujos
primeiros bytes são fixados pelo padrão. O HTTP começa com um método, um caminho e `HTTP/1.1`. Um
motor mantém um analisador para cada um e testa todos nos primeiros bytes de cada fluxo novo.

**Por isso o veredito chega alguns pacotes atrasado.** O
*handshake* precisa acontecer antes de haver algo para ler, então um NGFW deixa os primeiros pacotes
passarem pela regra de porta e decide sobre a aplicação quando já viu o suficiente. Um produto que
"bloqueia SSH" bloqueia depois da saudação do SSH, não antes da conexão.
