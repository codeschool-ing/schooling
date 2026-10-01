---
title: Os dois ao mesmo tempo
version: 1
---

No cliente-servidor, os papéis são fixos para o serviço inteiro: navegadores são clientes, o servidor
web é servidor. **No ponto a ponto, cada máquina faz os dois papéis**: escuta os outros e conecta nos
outros, e nenhuma máquina sozinha guarda o serviço. Um arquivo compartilhado pelo BitTorrent é o
exemplo que mais gente já viu: cada computador que o baixa também serve aos outros os pedaços que já
tem.

O laboratório mostra a forma com dois PCs. Cada um abre um socket escutando na porta 8000, e depois
cada um conecta no do outro. Os dois listam suas conexões TCP com `ss -tn`:

```
ana@pc1:~$ ss -tn
State Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
ESTAB 0      0        10.20.10.21:8000   10.20.10.22:40206       
ESTAB 0      0        10.20.10.21:35592  10.20.10.22:8000        
ana@pc2:~$ ss -tn
State Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
ESTAB 0      0        10.20.10.22:8000   10.20.10.21:35592       
ESTAB 0      0        10.20.10.22:40206  10.20.10.21:8000        
```

O pc1 tem duas conexões, e elas têm papéis diferentes. Na primeira, o lado do pc1 é
`10.20.10.21:8000`, a porta em que ele escuta: o pc2 conectou nela a partir da porta `40206`, então
nesta conversa o pc1 é o servidor e o pc2 o cliente. Na segunda, o lado do pc1 é a porta efêmera
`35592` e o outro lado é `10.20.10.22:8000`: o pc1 conectou para fora, e aqui ele é o cliente.

A listagem do pc2 são as mesmas duas conexões vistas da outra ponta. `10.20.10.22:8000` com o outro
lado `10.20.10.21:35592` é a segunda linha do pc1 com os lados trocados, e `10.20.10.22:40206` com o
outro lado `10.20.10.21:8000` é a primeira. **O papel pertence a cada conexão, não à máquina**: o pc1
é servidor e cliente no mesmo segundo, e nada no computador mudou entre uma linha e outra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 186\" role=\"img\" aria-label=\"Dois pares do laboratório do escritório, pc1 em 10.20.10.21 e pc2 em 10.20.10.22. Cada um escuta na porta 8000. A conexão 1 vai da porta efêmera 35592 do pc1 para a porta 8000 do pc2; a conexão 2 vai da porta efêmera 40206 do pc2 para a porta 8000 do pc1. Cada máquina é o servidor de uma conexão e o cliente da outra.\"><defs><marker id=\"peer-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"240\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><text x=\"80\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.10.21</text><rect x=\"34\" y=\"56\" width=\"212\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">:35592</text><text x=\"116\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lado cliente</text><rect x=\"34\" y=\"108\" width=\"212\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">:8000</text><text x=\"116\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escutando</text><rect x=\"460\" y=\"20\" width=\"240\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"474\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><text x=\"520\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10.20.10.22</text><rect x=\"474\" y=\"56\" width=\"212\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"486\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">:8000</text><text x=\"556\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">escutando</text><rect x=\"474\" y=\"108\" width=\"212\" height=\"36\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"486\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">:40206</text><text x=\"556\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lado cliente</text><path d=\"M234 74 L470 74\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#peer-ah)\"></path><text x=\"352\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">conexão 1: pc1 pede</text><path d=\"M474 126 L238 126\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#peer-ah)\"></path><text x=\"352\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">conexão 2: pc2 pede</text></svg>", "caption": "As duas conexões que as duas listagens mostram. Cada par é servidor numa e cliente na outra."}
```

O que o ponto a ponto ganha é que nenhuma máquina é indispensável. Se o pc2 sumir, o pc1 continua
escutando e pode falar com qualquer outro que rode o programa, e quanto mais pares houver, mais
máquinas estão servindo. O que ele precisa resolver em troca é a **descoberta**. O pc1 achou o pc2
porque o laboratório escreveu o endereço do pc2 no `/etc/hosts` do pc1; entre desconhecidos na
internet não existe esse arquivo. Os sistemas P2P reais acham seus pares de um de três jeitos:

- por um servidor que mantém a lista de quem tem o quê, que é o que um tracker do BitTorrent é;
- pelos próprios pares, numa tabela hash distribuída (DHT), em que cada par conhece alguns outros e
  pergunta a eles, um depois do outro;
- pelos dois, tentando o tracker e a DHT juntos.

Em outras palavras, a maioria guarda um pouco de cliente-servidor para a parte que é difícil de
dividir.
