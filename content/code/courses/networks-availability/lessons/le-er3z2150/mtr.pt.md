---
title: mtr, e a perda que não é real
version: 1
---

O mtr é um traceroute que não para. Ele manda sondas para todos os saltos, rodada após rodada, e mantém
uma tabela do que voltou: `-r` imprime a tabela como relatório no fim, `-c` diz quantas rodadas e `-i`
define o intervalo entre elas. Duas rodadas a partir do laptop. Na primeira, o descarte aleatório para o
web2 da seção do ping ainda estava ativo; antes da segunda ele foi removido:

```
ana@laptop:~$ sudo mtr -n -r -c 20 192.0.2.22
Start: 2026-09-28T18:17:16-0300
HOST: laptop                      Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.10.1               0.0%    20    0.1   0.1   0.1   0.1   0.0
  2.|-- 203.0.113.1                0.0%    20    0.1   0.1   0.0   0.3   0.1
  3.|-- 192.0.2.22                10.0%    20    0.1   0.1   0.1   0.1   0.0
ana@laptop:~$ sudo mtr -n -r -c 50 -i 0.1 192.0.2.21
Start: 2026-09-28T18:17:40-0300
HOST: laptop                      Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.10.1              80.0%    50    0.0   0.0   0.0   0.1   0.0
  2.|-- 203.0.113.1               80.0%    50    0.0   0.1   0.0   0.3   0.1
  3.|-- 192.0.2.21                 0.0%    50    0.1   0.0   0.0   0.1   0.0
ana@hq:~$ sysctl net.ipv4.icmp_ratelimit net.ipv4.icmp_ratemask
net.ipv4.icmp_ratelimit = 1000
net.ipv4.icmp_ratemask = 6168
```

**O primeiro relatório mostra perda real.** O web2, o destino, perdeu 10.0%, 2 de 20 sondas, para uma
regra que descarta 20% ao acaso: a amostragem da seção do ping agindo de novo. Os saltos 1 e 2 não
perderam nada, porque as sondas que expiram neles nunca chegam à regra, que age sobre o que o provedor
encaminha. **Perda que aparece num salto e continua em todos os saltos seguintes, até o destino, é real**,
e começa no primeiro salto que a mostra ou depois dele.

**O segundo relatório mostra perda que não é real.** `hq` e o roteador do provedor perderam cada um
80.0% de 50 sondas, e o destino não perdeu nenhuma. Se `hq` estivesse mesmo descartando quatro pacotes
em cinco, nada depois dele poderia ter mais que um em cinco, e o web2 recebeu todos. O que os dois
roteadores perderam foram as próprias respostas, e o `sysctl` em `hq` diz por quê:

- `icmp_ratelimit = 1000` é um intervalo em milissegundos: depois de uma pequena rajada, o kernel manda
  para um mesmo destino no máximo um erro ICMP por segundo.
- `icmp_ratemask = 6168` é o conjunto de tipos ICMP a que o limite se aplica, um bit por tipo. 6168 é
  4096 + 2048 + 16 + 8, os bits 12, 11, 4 e 3, e **o bit 11 é o "time exceeded"**, a resposta que todo
  salto intermediário manda. O echo reply que o destino manda é o tipo 0, e não é limitado.

A primeira rodada mandou uma sonda por segundo, e o limite nunca agiu. A segunda mandou dez por segundo
durante uns cinco segundos, e cada roteador respondeu dez: a rajada, depois uma por segundo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 780 216\" role=\"img\" aria-label=\"Dois relatórios do mtr desenhados como barras de perda por salto. À esquerda, com o descarte aleatório para o web2 e uma sonda por segundo: salto 1 192.168.10.1 0.0%, salto 2 203.0.113.1 0.0%, salto 3 192.0.2.22 10.0%; o destino perde, então a perda é real. À direita, com o descarte removido e dez sondas por segundo: salto 1 80.0%, salto 2 80.0%, salto 3 192.0.2.21 0.0%; o destino não perde nada, então os saltos só seguraram as próprias respostas.\"><rect x=\"20\" y=\"10\" width=\"360\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">descarte para o web2, uma sonda por segundo</text><text x=\"34\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mtr -c 20 192.0.2.22</text><text x=\"34\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.</text><text x=\"50\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">192.168.10.1</text><rect x=\"148\" y=\"70\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><text x=\"326\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.0%</text><text x=\"34\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.</text><text x=\"50\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">203.0.113.1</text><rect x=\"148\" y=\"100\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><text x=\"326\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.0%</text><text x=\"34\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.</text><text x=\"50\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">192.0.2.22</text><rect x=\"148\" y=\"130\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><rect x=\"148\" y=\"130\" width=\"17.0\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"326\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">10.0%</text><text x=\"34\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">perda por salto, de 0 a 100%</text><text x=\"34\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o destino perde: a perda é real</text><rect x=\"400\" y=\"10\" width=\"360\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"414\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">descarte removido, dez sondas por segundo</text><text x=\"414\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mtr -c 50 -i 0.1 192.0.2.21</text><text x=\"414\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.</text><text x=\"430\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">192.168.10.1</text><rect x=\"528\" y=\"70\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><rect x=\"528\" y=\"70\" width=\"136.0\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"3 2\"></rect><text x=\"706\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">80.0%</text><text x=\"414\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.</text><text x=\"430\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">203.0.113.1</text><rect x=\"528\" y=\"100\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><rect x=\"528\" y=\"100\" width=\"136.0\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"3 2\"></rect><text x=\"706\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">80.0%</text><text x=\"414\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.</text><text x=\"430\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">192.0.2.21</text><rect x=\"528\" y=\"130\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><text x=\"706\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.0%</text><text x=\"414\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">perda por salto, de 0 a 100%</text><text x=\"414\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o destino não perde nada: os saltos só seguraram as respostas</text></svg>", "caption": "Os dois relatórios acima, desenhados em escala. Leia a linha de baixo primeiro: perda que chega ao destino é real, e perda que para antes dele é um roteador deixando de responder."}
```

Para ler um relatório do mtr, a regra é uma só: **olhe a última linha
primeiro.** Se o destino não perde nada, a perda nos saltos acima dele é esses roteadores deixando de
responder, por maior que seja a porcentagem. Se o destino perde, suba a tabela até o primeiro salto em que
a perda começa e fica; aquele enlace, ou o seguinte, é onde procurar. Um trace que termina num firewall
que descarta as sondas de vez pede `-T` ou `-u`, a mesma escolha que o traceroute oferecia.
