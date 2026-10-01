---
title: O primeiro e o último endereço de uma faixa
version: 1
---

Toda faixa tem dois endereços que pertencem a ela e a nenhuma máquina. **O endereço de rede tem todos
os bits de host em 0, e o endereço de broadcast tem todos os bits de host em 1.** Tudo o que fica entre
eles está disponível para máquinas. Dado qualquer endereço e o seu prefixo, dá para achar as duas
pontas, e esta seção faz isso para o eng1, que está na LAN do meio do laboratório:

```
ana@sales1:~$ ipcalc -b 10.20.32.140/26
Address:   10.20.32.140         
Netmask:   255.255.255.192 = 26 
Wildcard:  0.0.0.63             
=>
Network:   10.20.32.128/26      
HostMin:   10.20.32.129         
HostMax:   10.20.32.190         
Broadcast: 10.20.32.191         
Hosts/Net: 62                    Class A, Private Internet

```

Faça à mão antes de ler a resposta no ipcalc. `/26` são 26 uns, então o último octeto da máscara é
`11000000`, 192, e o último octeto tem 2 bits de rede e 6 de host. O último octeto do endereço é 140,
que é `10001100`.

- **Rede**: mantenha os 2 bits de rede e zere os 6 de host. `10001100` vira `10000000`, 128, então a
  rede é `10.20.32.128`.
- **Broadcast**: mantenha os 2 bits de rede e ponha os 6 de host em 1. `10111111`, 191, então o
  broadcast é `10.20.32.191`.
- **Hosts**: tudo o que fica entre eles, de `10.20.32.129` a `10.20.32.190`.

O ipcalc concorda nos três, e o seu `Hosts/Net: 62` é a contagem dessa última faixa. No laboratório, a
`eth2` do r1 tem `10.20.32.129`, o primeiro endereço de host, e o eng1 tem `.140`. **Dar ao gateway o
primeiro endereço utilizável é uma convenção, não uma regra**: ela deixa o gateway fácil de adivinhar,
e este laboratório a segue nas três LANs.

A LAN do ops1, o `/27` da seção anterior, funciona do mesmo jeito. O último octeto da máscara é 224,
`11100000`, três bits de rede e cinco de host. 200 é `11001000`; zerar os cinco bits de host dá
`11000000`, 192, e pô-los em 1 dá `11011111`, 223. O `Network: 10.20.32.192/27` e o
`Broadcast: 10.20.32.223` do ipcalc dizem o mesmo.

Há um padrão nessas respostas que os bits escondem. Desenhado numa linha, o último octeto vai de 0 a
255, e um prefixo o corta em blocos iguais:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"O último octeto de 10.20.32.x desenhado como uma linha de 0 a 256, cortada de três jeitos. Em blocos de 128, para /25, o bloco .0–.127 está destacado, com o sales1 em .10. Em blocos de 64, para /26, o bloco .128–.191 está destacado, com o eng1 em .140. Em blocos de 32, para /27, o bloco .192–.223 está destacado, com o ops1 em .200. Todo bloco começa num múltiplo do seu próprio tamanho.\"><text x=\"40\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/25: blocos de 128</text><rect x=\"41\" y=\"34\" width=\"318\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.0–.127</text><rect x=\"361\" y=\"34\" width=\"318\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M65 64 L65 74\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"69\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sales1 .10</text><text x=\"40\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/26: blocos de 64</text><rect x=\"41\" y=\"110\" width=\"158\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"201\" y=\"110\" width=\"158\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"361\" y=\"110\" width=\"158\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"366\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.128–.191</text><rect x=\"521\" y=\"110\" width=\"158\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M390 140 L390 150\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"394\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">eng1 .140</text><text x=\"40\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/27: blocos de 32</text><rect x=\"41\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"121\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"201\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"281\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"361\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"441\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"521\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"526\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">.192–.223</text><rect x=\"601\" y=\"186\" width=\"78\" height=\"30\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M540 216 L540 226\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"536\" y=\"232\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ops1 .200</text><path d=\"M40 246 L40 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"40\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M120 246 L120 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">32</text><path d=\"M200 246 L200 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"200\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">64</text><path d=\"M280 246 L280 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"280\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">96</text><path d=\"M360 246 L360 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">128</text><path d=\"M440 246 L440 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"440\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">160</text><path d=\"M520 246 L520 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"520\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192</text><path d=\"M600 246 L600 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"600\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">224</text><path d=\"M680 246 L680 252\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"680\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">256</text><text x=\"40\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o último octeto de 10.20.32.x</text></svg>", "caption": "As três LANs deste laboratório numa régua só. Um prefixo fixa o tamanho do bloco, e o bloco em que o endereço cai é a sua rede."}
```

**Toda faixa começa num múltiplo do próprio tamanho.** Um `/26` tem 64 endereços, então as redes `/26`
dentro de um `/24` começam em 0, 64, 128 e 192; 140 está entre 128 e 191, então a sua rede é `.128`. Um
`/27` tem 32 endereços, então as suas redes começam em múltiplos de 32; 200 cai entre 192 e 223. Com
isso claro, o trabalho com bits da lista acima vira uma conferência em vez de método, e a seção sobre
fazer à mão transforma o padrão num procedimento de segundos.

A regra também diz quais faixas não podem existir. `10.20.32.100/26` é um endereço de host, não uma
rede: a rede `/26` que o contém é `10.20.32.64`. Quem escreve `10.20.32.100/26` num plano querendo dizer
uma rede cometeu um erro que o ipcalc mostraria na hora, na linha `Network`. **Um endereço de rede é
aquele cujos bits de host são todos zero**, e um teste rápido de qualquer plano é conferir se cada rede
listada nele é mesmo uma.
