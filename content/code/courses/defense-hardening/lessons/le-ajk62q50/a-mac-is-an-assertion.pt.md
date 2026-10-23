---
title: Um endereço MAC é uma afirmação
version: 1
---

**O endereço num quadro é escrito pelo dispositivo que o envia.** A seção anterior mudou o endereço do
`desk` com um comando, como root, na própria máquina, e o switch acreditou no que lhe disseram. Um
filtro de MAC confere uma afirmação, não uma identidade. Qualquer dispositivo cujo dono conheça um
endereço da lista pode usar esse endereço, e a lista não consegue distingui-lo do dispositivo a que o
endereço pertence.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-assertion\" aria-label=\"Por que um filtro de MAC acredita no que lhe dizem. Dois quadros chegam à port-desk. O primeiro vem da impressora da recepção e traz o endereço dela, 52:54:00:a8:3c:63. O segundo vem do desk depois que o desk pôs a própria placa no mesmo endereço. A porta compara o endereço de origem com a lista, acha nos dois casos e deixa os dois passarem: o endereço é escrito pelo dispositivo que envia o quadro.\"><defs><marker id=\"l04-assertion-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"160.0\" height=\"70.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a impressora</text><text x=\"100.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o próprio endereço</text><rect x=\"220.0\" y=\"55.0\" width=\"210.0\" height=\"40.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"232.0\" y=\"69.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">origem</text><text x=\"232.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">52:54:00:a8:3c:63</text><path d=\"M180.0 75.0 L220.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-assertion-dh-ah-paper-dim)\"></path><path d=\"M430.0 75.0 L490.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-assertion-dh-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"140.0\" width=\"160.0\" height=\"70.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><text x=\"100.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">endereço posto pelo dono</text><rect x=\"220.0\" y=\"155.0\" width=\"210.0\" height=\"40.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"232.0\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">origem</text><text x=\"232.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">52:54:00:a8:3c:63</text><path d=\"M180.0 175.0 L220.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-assertion-dh-ah-paper-dim)\"></path><path d=\"M430.0 175.0 L490.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-assertion-dh-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"85.0\" width=\"210.0\" height=\"80.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"595.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">port-desk</text><text x=\"595.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a origem está na lista?</text><text x=\"595.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">sim, das duas vezes</text></svg>", "caption": "O filtro confere um valor que o próprio dispositivo escreve.", "same": ["desk"]}
```

O endereço que passou foi o da impressora, e esse é o ponto fraco de costume. Impressoras, leitores
de crachá, câmeras e telefones são os dispositivos cujos endereços acabam em listas, porque não
conseguem rodar nada melhor. Os endereços deles também estão impressos em etiquetas, aparecem nas
próprias páginas de status e ficam visíveis para tudo no segmento, já que cada quadro que enviam os
traz.

Então um filtro de MAC é um **controle de conveniência**: barra enganos e deixa o uso deliberado da
tomada intocado. Trate-o como tal, e não o deixe sozinho entre uma tomada pública e o portal.

## O que o switch consegue notar

Os switches podem dificultar o uso da afirmação sem uma credencial, e quem defende deveria ligar
estes recursos onde existem:

- **um endereço visto em duas portas**, ou mudando de uma porta para outra enquanto o primeiro
  dispositivo continua ligado, que é o que acontece quando algo copia o endereço da impressora com a
  impressora ainda ligada em outro lugar;
- **uma porta que muda de endereço**, que o sticky MAC transforma em desligamento da porta e alerta;
- **um dispositivo que se comporta diferente do seu tipo**: uma "impressora" que abre conexões SSH
  para o portal, que um monitor de rede ou o EDR da aula 8 enxerga e um filtro de porta não.

Nenhum deles foi executado para este curso; são recursos de switches gerenciáveis e de sistemas de
monitoramento, configurados pela interface de cada fabricante.

## MAC authentication bypass

Redes que usam 802.1X, assunto do resto desta aula, ainda têm dispositivos que não conseguem
participar dele, e a impressora é o caso clássico. A resposta comum é o **MAC authentication bypass**
(MAB): se uma porta não ouve 802.1X nenhum, o switch manda o endereço MAC do dispositivo ao servidor
de autenticação como se fosse um nome de usuário, e o servidor pode deixá-lo entrar, normalmente num
segmento de rede restrito. O MAB é a mesma afirmação com um servidor atrás. Só é seguro quando o que
o endereço recebe se limita ao que aquele tipo de dispositivo precisa: um segmento de impressoras que
alcança o servidor de impressão e mais nada, para que um notebook fingindo ser a impressora não ganhe
nada que uma impressora não ganharia.
