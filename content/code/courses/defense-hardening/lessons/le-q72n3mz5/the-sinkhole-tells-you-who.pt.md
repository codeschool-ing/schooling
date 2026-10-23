---
title: O sinkhole diz quem foi
version: 1
---

**Um sinkhole é um endereço que recebe o tráfego destinado a um lugar perigoso.** A zona de política
já manda todo nome abaixo de `cobranca-urgente.example.org` para `192.168.60.53`. O programa que
perguntou vai se conectar ali achando que chegou ao site verdadeiro, e um pequeno servidor nesse
endereço pode registrar cada visita: quando, de que máquina, para que nome e que caminho.

O servidor são poucas linhas da biblioteca padrão do Python. Escreva-o como root no `dns` e suba-o
como serviço temporário com o `systemd-run`, que lhe dá um nome de unidade, um journal e um jeito de
pará-lo:

```
root@dns:~# cat > /root/sinkhole.py <<'EOF'
#!/usr/bin/env python3
"""Answers every web request with one line, and logs who asked for which name."""
import datetime
import http.server

class Sinkhole(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        now = datetime.datetime.now().isoformat(timespec="seconds")
        print(now, self.client_address[0], self.headers.get("Host"), self.path, flush=True)
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.end_headers()
        self.wfile.write(b"Blocked by Jatoba: this address is on the list of dangerous sites.\n")

    def log_message(self, *args):
        pass

http.server.ThreadingHTTPServer(("0.0.0.0", 80), Sinkhole).serve_forever()
EOF
root@dns:~# systemd-run --unit=sinkhole python3 /root/sinkhole.py; sleep 1; systemctl is-active sinkhole
Running as unit: sinkhole.service; invocation ID: daefbefabe6c4104ad15a13bc5eccc7a
active
ana@desk:~$ curl -s http://pagamento.cobranca-urgente.example.org/boleto.pdf
Blocked by Jatoba: this address is on the list of dangerous sites.
root@dns:~# journalctl -u sinkhole -o cat | grep -v systemd
Started sinkhole.service - /usr/bin/python3 /root/sinkhole.py.
2026-10-23T02:03:08 192.168.60.20 pagamento.cobranca-urgente.example.org /boleto.pdf
```

A visita do `desk` recebeu uma página de uma linha dizendo que o site está bloqueado, que é o que uma
pessoa diante de um navegador deve ver, em vez de um erro que ela vai tentar três vezes. O journal do
sinkhole registrou a visita: a hora, o endereço `192.168.60.20`, o nome que o navegador pediu no
cabeçalho `Host` e o arquivo que ele queria, `/boleto.pdf`.

**Essa última linha é a razão de existirem sinkholes.** O log do resolvedor dizia que o `desk`
consultou o nome; o sinkhole diz que o `desk` depois tentou baixar um boleto dali. Uma consulta pode
vir de uma pré-visualização, de um scanner de e-mail ou de um link em que ninguém clicou. Uma conexão
com caminho é um programa que queria buscar alguma coisa, e numa máquina onde há malware ligando para
casa é a própria ligação, caindo numa máquina sua em vez de na do atacante.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l14-sinkhole\" aria-label=\"O caminho de um download. Um: o desk pergunta ao dns por pagamento.cobranca-urgente.example.org. Dois: o dns responde 192.168.60.53, o próprio endereço, em vez do verdadeiro. Três: o desk conecta ali e pede /boleto.pdf. Quatro: o sinkhole responde com uma página dizendo que o site está bloqueado e grava uma linha de log com a hora, o endereço do desk, o nome e o caminho. O site verdadeiro, tracejado, nunca é alcançado.\"><defs><marker id=\"l14-sinkhole-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l14-sinkhole-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"90.0\" width=\"110.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><text x=\"85.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.60.20</text><rect x=\"300.0\" y=\"40.0\" width=\"200.0\" height=\"150.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dns  192.168.60.53</text><rect x=\"315.0\" y=\"75.0\" width=\"170.0\" height=\"36.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"400.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">unbound, com a lista</text><rect x=\"315.0\" y=\"125.0\" width=\"170.0\" height=\"50.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.1\"></rect><text x=\"400.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sinkhole na porta 80</text><text x=\"400.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">anota quem, que nome, que caminho</text><path d=\"M140.0 100.0 L315.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-sinkhole-dh-ah-paper-dim)\"></path><text x=\"225.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 o nome?</text><path d=\"M315.0 100.0 L140.0 112.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-sinkhole-dh-ah-paper-dim)\"></path><text x=\"225.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 é o .53</text><path d=\"M140.0 128.0 L315.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-sinkhole-dh-ah-amber)\"></path><text x=\"225.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">3 GET /boleto.pdf</text><rect x=\"570.0\" y=\"80.0\" width=\"130.0\" height=\"60.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"635.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o site verdadeiro</text><text x=\"635.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nunca alcançado</text><text x=\"400.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4 uma página para a pessoa, uma linha de log para quem defende</text></svg>", "caption": "O resolvedor mudou uma resposta; o sinkhole transformou a visita num achado.", "same": ["3 GET /boleto.pdf"]}
```

## O que um sinkhole não faz

Ele não limpa nada. O `desk` continua sendo o que era; o sinkhole só tornou um destino inalcançável e
avisou você. O achado vai para onde a aula 8 manda os achados: a máquina é examinada, e se alguma
coisa nela está chamando um domínio do sinkhole a cada cinco minutos, é uma máquina para isolar e
reconstruir, não uma linha de log para admirar.

Ele também só vê o que entende. Este fala HTTP simples na porta 80. Um programa que se conecta com
TLS na porta 443 chega ao sinkhole e não encontra serviço ali, então a conexão falha e o log do
resolvedor é tudo o que você tem. Sinkholes comerciais respondem em mais portas, e alguns apresentam
um certificado, o que só funciona em máquinas que confiam em quem o emitiu, a limitação que toda
inspeção de tráfego cifrado encontra.

E ele recebe o que lhe mandarem, o que pode incluir dados que um programa tentava enviar para fora.
**Um sinkhole é uma máquina que coleta o tráfego de outras pessoas, então é tratado como tal**: num
segmento próprio, sem mais nada nele, com os logs guardados pelo tempo que o incidente precisar e não
mais que isso.
