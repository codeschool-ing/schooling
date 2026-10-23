---
title: Quem tocou
version: 1
---

**O alerta de um honeypot é uma linha, e essa linha já responde à primeira pergunta: qual máquina.**
Toque a isca a partir do `desk`, como faria um programa numa estação comprometida olhando em volta na
rede. A máquina é sua, o honeypot é seu, e uma conexão basta:

```
ana@desk:~$ nc -zv -w2 trap 445 2>&1
Connection to trap (192.168.60.66) 445 port [tcp/microsoft-ds] succeeded!
```

Para o `desk`, nada aconteceu: a porta estava aberta e a conexão fechou. No `trap`, o log do sistema e
o arquivo JSON registraram:

```
ana@trap:~$ sudo journalctl -t bait -o short-iso --no-pager
2026-10-23T10:13:47-03:00 trap bait[88]: touched: 192.168.60.20 on port 445
ana@trap:~$ cat /var/log/bait.jsonl
{"time": "2026-10-23T10:13:47-0300", "from": "192.168.60.20", "port": 445}
```

`192.168.60.20` é o `desk`, na porta 445, naquele segundo. **Não há nada a ajustar, nenhum limite e
nenhum falso positivo para discutir**, porque o trabalho de ninguém conecta no `trap`. Num escritório
de verdade essa linha iria para o mesmo lugar que todo outro alerta, e a resposta começaria pelo
`desk`, a máquina que tocou: o que está rodando ali, quem está logado, a que mais ele se conectou. A
telemetria da aula 8 é o que responde a isso.

## É assim que uma varredura aparece

Quem explora uma rede raramente tenta uma porta só. Faz uma varredura, e uma varredura toca todos os
listeners de uma vez:

```
ana@desk:~$ nmap -Pn -p 1-3400 trap | grep -E "^[0-9]+/tcp"
22/tcp   open  ssh
23/tcp   open  telnet
445/tcp  open  microsoft-ds
1433/tcp open  ms-sql-s
3389/tcp open  ms-wbt-server
ana@trap:~$ sudo journalctl -t bait -o cat --no-pager | sort | uniq -c
      1 touched: 192.168.60.20 on port 1433
      1 touched: 192.168.60.20 on port 23
      1 touched: 192.168.60.20 on port 3389
      2 touched: 192.168.60.20 on port 445
```

A varredura achou o SSH e as quatro portas-isca, e o `trap` registrou um toque em cada uma das quatro,
um por porta, ao lado do toque anterior na 445 que deixa a contagem daquela linha em dois. Uma máquina
que conecta em quatro serviços sem relação entre si numa máquina que ninguém usa, em um segundo, não
está cometendo um engano.

**Enganos acontecem, e são o único falso positivo que um honeypot tem.** Um administrador que varre a
rede para fazer inventário, como a aula 18 faz, toca o honeypot também. A resposta não é ajustar o
honeypot, e sim saber da varredura: varreduras autorizadas são anotadas antes, a partir de máquinas
conhecidas, e um alerta vindo de uma delas naquela hora é fechado com uma nota. Um alerta vindo de
qualquer outro lugar não é.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l13-touch\" aria-label=\"Um toque e o registro dele. O desk conecta no trap na porta 445. O bait.py aceita e fecha a conexão na hora, e grava o horário, o endereço 192.168.60.20 e a porta no arquivo JSON e como aviso no log do sistema. Dali a linha vai para onde os alertas do escritório são lidos, e a resposta começa pela máquina que tocou a isca.\"><defs><marker id=\"l13-touch-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-touch-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"70.0\" width=\"120.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><rect x=\"220.0\" y=\"70.0\" width=\"160.0\" height=\"50.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"300.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">trap</text><text x=\"300.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bait.py na 445</text><path d=\"M140.0 95.0 L220.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l13-touch-dh-ah-paper-dim)\"></path><text x=\"180.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">conecta</text><rect x=\"450.0\" y=\"40.0\" width=\"250.0\" height=\"40.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">touched: 192.168.60.20 on port 445</text><rect x=\"450.0\" y=\"110.0\" width=\"250.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma pessoa, em minutos</text><path d=\"M380.0 90.0 L450.0 62.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-touch-dh-ah-paper-dim)\"></path><path d=\"M575.0 80.0 L575.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-touch-dh-ah-paper-dim)\"></path><path d=\"M575.0 150.0 L575.0 185.0 L80.0 185.0 L80.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-touch-dh-ah-amber)\"></path><text x=\"330.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a resposta começa pelo desk</text></svg>", "caption": "O trabalho de ninguém conecta no trap, então a única linha já é o achado."}
```
