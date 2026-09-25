---
title: mtr: perda por salto, e como ler
version: 1
---

O `mtr` roda o traceroute sem parar e conta, por salto, quantas sondas tiveram resposta. Para este
chamado, "o site fica lento às vezes", o laboratório foi montado com duas coisas erradas ao mesmo tempo.
O roteador do ISP responde só a parte das sondas que expiram nele, como roteadores ocupados fazem, e
depois o `core` passou a descartar um pacote em cada cinco no caminho para o `www`:

```
ana@laptop:~$ mtr -rwn -c 20 www.example.com
Start: 2026-09-25T15:58:46-0300
HOST: laptop         Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.10.1    0.0%    20    0.1   0.1   0.1   0.1   0.0
  2.|-- 203.0.113.1    60.0%    20    0.1   0.1   0.1   0.1   0.0
  3.|-- 198.51.100.254  0.0%    20    0.1   0.1   0.1   0.3   0.0
  4.|-- 192.0.2.80      0.0%    20    0.1   0.1   0.1   0.2   0.0
ana@laptop:~$ mtr -rwn -c 20 www.example.com
Start: 2026-09-25T15:59:11-0300
HOST: laptop         Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.10.1    0.0%    20    0.1   0.1   0.1   0.1   0.0
  2.|-- 203.0.113.1    45.0%    20    0.1   0.1   0.1   0.4   0.1
  3.|-- 198.51.100.254  0.0%    20    0.2   0.1   0.1   0.3   0.1
  4.|-- 192.0.2.80     10.0%    20    0.1   0.1   0.1   0.1   0.0
```

A primeira execução só tem o hábito do ISP: `203.0.113.1` mostra `60.0%`, e todo salto
depois dele `0.0%`. **Perda que não segue até o fim não é perda.** Os saltos 3 e 4 são alcançados através
do salto 2, então se o salto 2 estivesse mesmo descartando pacotes, eles também mostrariam. Ele só
estava deixando de responder a sondas endereçadas a ele.

A segunda execução acrescenta o defeito real, e `192.0.2.80` mostra `10.0%` enquanto o
`core`, logo antes, mostra `0.0%`. Vinte sondas são uma amostra pequena, e um em cinco
saiu como 10 em cem desta vez. **Perda que começa num salto e vai até o fim
é real**, e acontece logo antes do primeiro salto que a mostra: aqui, entre o `core` e o `www`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A segunda execução do mtr, desenhada como perda por salto. Salto 1, 192.168.10.1, 0.0 por cento. Salto 2, 203.0.113.1, 45.0 por cento, mas todo salto depois dele responde, então o roteador só estava deixando de responder a sondas mandadas a ele. Salto 3, 198.51.100.254, 0.0 por cento. Salto 4, 192.0.2.80, 10.0 por cento: perda que começa ali e chega ao fim do caminho, e que é real.\"><defs><marker id=\"mt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"40\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.168.10.1</text><rect x=\"170\" y=\"28\" width=\"300\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"480\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.0%</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text><text x=\"40\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">203.0.113.1</text><rect x=\"170\" y=\"78\" width=\"300\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"170\" y=\"78\" width=\"135.0\" height=\"20\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"480\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">45.0%</text><text x=\"20\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"40\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">198.51.100.254</text><rect x=\"170\" y=\"128\" width=\"300\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"480\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.0%</text><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4</text><text x=\"40\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.0.2.80</text><rect x=\"170\" y=\"178\" width=\"300\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"170\" y=\"178\" width=\"30.0\" height=\"20\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"480\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">10.0%</text><text x=\"540\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o roteador não respondeu a toda sonda</text><text x=\"540\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada depois dele se perde</text><text x=\"540\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">perda real</text><text x=\"540\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">começa aqui e vai até o fim</text></svg>", "caption": "Perda que para num salto é aquele roteador ocupado demais para responder; perda que segue até o destino é pacote sumindo de verdade, em algum ponto logo antes do primeiro salto que a mostra."}
```

Essa leitura é o que um provedor precisa ouvir. Um relatório do mtr mandado com o chamado, `-r` para
relatório e `-c` para a contagem, vale mais que qualquer descrição de "lento".
