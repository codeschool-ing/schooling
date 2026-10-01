---
title: Para que serve cada porta, e o que ela está fazendo
version: 1
---

Duas coisas diferentes se dizem de uma porta no spanning tree, e misturá-las é a confusão comum. O
**papel** dela é o que a eleição decidiu que ela *é*: porta raiz, porta designada ou porta
bloqueada. O **estado** dela é o que ela está *fazendo* agora: bloqueando, escutando, aprendendo,
encaminhando ou desabilitada. O papel de uma porta pode ser decidido num instante, e o estado depois
leva o seu tempo para alcançá-lo.

## Papéis: uma porta raiz por switch, uma porta designada por cabo

Depois que a raiz é eleita, as outras portas recebem os papéis em duas passadas.

- **Porta raiz.** Cada switch, menos a raiz, escolhe a porta com o menor custo total até a raiz. É
  por ela que esse switch alcança o resto da árvore.
- **Porta designada.** Em cada cabo, as duas pontas comparam o que oferecem, e a ponta com o menor
  custo até a raiz vira a porta designada: a que encaminha tráfego para aquele cabo, no sentido
  contrário ao da raiz. **Toda porta da própria raiz é designada**, porque nada está mais perto da
  raiz do que a raiz.
- **Porta bloqueada.** Uma porta que não é nenhuma das duas fica bloqueada. Ela continua ouvindo
  BPDUs, que é como vai perceber quando for necessária, e não encaminha mais nada.

O kernel mostra cada porta do `sw3` com a ponta designada do cabo dela:

```
root@sw3:~# ip -d link show p1 | grep -oE "(state|port_id|designated_bridge|designated_port) [^ ]*"
state UP
state forwarding
port_id 0x8001
designated_port 32770
designated_bridge 8000.2:6a:dc:93:3b:8a
root@sw3:~# ip -d link show p2 | grep -oE "(state|port_id|designated_bridge|designated_port) [^ ]*"
state UP
state forwarding
port_id 0x8002
designated_port 32770
designated_bridge 8000.2:a5:9d:31:2a:8c
```

O primeiro `state UP` é a interface, e o segundo é o estado do spanning tree. Na `p1`, o cabo para o
`sw1`, a ponte designada é `8000.2:6a:dc:93:3b:8a`: o ID de ponte do `sw1`, impresso sem os zeros à
esquerda. A ponta designada desse cabo está na raiz, como tem de ser, então **a `p1` é a porta raiz
do `sw3`**, a porta número 1 que o `root_port:1` apontou na seção anterior.

Na `p2`, o cabo para o `sw2`, a ponte designada é o próprio `sw3`, `8000.2:a5:9d:31:2a:8c`, e a porta
designada `32770` é `0x8002`, o próprio `port_id` da `p2`. **A `p2` do `sw3` é a porta designada do
cabo `sw2`–`sw3`.**

Por que o `sw3` e não o `sw2`? Os dois estão a um cabo da raiz, com custo 2, então o custo empata. O
desempate vai para o menor ID de ponte, e o `02a59d312a8c` do `sw3` é menor que o `02e0779de790` do
`sw2`. Isso deixa a ponta do `sw2` nesse cabo, a `p3`, sem papel, e é ela a porta que apareceu em
`state blocking`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"O triângulo depois da eleição. O sw1, ID de ponte 8000.026adc933b8a, é a ponte raiz, e as duas portas dele para os outros switches, p2 e p3, são designadas. O sw2, ID de ponte 8000.02e0779de790, chega à raiz pela p1, a porta raiz dele. O sw3, ID de ponte 8000.02a59d312a8c, chega pela própria p1, também porta raiz. No cabo entre sw2 e sw3, a p2 do sw3 é designada, porque o sw3 tem o ID de ponte menor, e a p3 do sw2 fica bloqueada. Essa porta bloqueada é a única que não encaminha nada.\"><path d=\"M360 40 L360 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170 254 L170 282\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 254 L550 282\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 114 L210 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M400 114 L510 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M230 232 L490 232\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"298\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><text x=\"422\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><text x=\"214\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><text x=\"506\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><text x=\"238\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><text x=\"482\" y=\"221\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><text x=\"368\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><text x=\"178\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><text x=\"558\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><rect x=\"320\" y=\"10\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><rect x=\"130\" y=\"282\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><rect x=\"510\" y=\"282\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><rect x=\"300\" y=\"70\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sw1</text><text x=\"360.0\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8000.026adc933b8a</text><rect x=\"110\" y=\"210\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sw2</text><text x=\"170.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8000.02e0779de790</text><rect x=\"490\" y=\"210\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sw3</text><text x=\"550.0\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8000.02a59d312a8c</text><text x=\"428\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">ponte raiz</text><text x=\"278\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">designada</text><text x=\"440\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">designada</text><text x=\"198\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">porta raiz</text><text x=\"522\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">porta raiz</text><text x=\"482\" y=\"250\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">designada</text><text x=\"240\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">bloqueada</text><path d=\"M258 225 L272 239\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M258 239 L272 225\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path></svg>", "caption": "Os papéis depois da eleição com as prioridades padrão. Cada switch tem uma porta raiz, cada cabo uma ponta designada, e a única porta que sobra, a p3 do sw2, bloqueia. O triângulo encaminha como uma linha: sw2, sw1, sw3."}
```

## Estados: como uma porta chega a encaminhar

O 802.1D original tem cinco estados, e uma porta passa por eles num sentido só:

| estado | BPDUs | aprende endereços MAC | encaminha dados |
| --- | --- | --- | --- |
| blocking (bloqueando) | recebe | não | não |
| listening (escutando) | envia e recebe | não | não |
| learning (aprendendo) | envia e recebe | sim | não |
| forwarding (encaminhando) | envia e recebe | sim | sim |
| disabled (desabilitada) | nenhum | não | não |

**Listening e learning duram cada um um *forward delay*, 15 segundos por padrão.** O listening dá
tempo para a eleição terminar na rede inteira antes de a porta fazer qualquer coisa. O learning
enche a tabela MAC primeiro, para que a porta, quando começar a encaminhar, não inunde cada quadro
para todas as portas. Então uma porta que precisa entrar em uso espera uns 30 segundos, e é por isso
que a `p3` do `sw1` estava em `listening` logo depois de o cabo entrar, e por isso o laboratório
esperou 40 segundos antes de ler o resultado.

`disabled` não é uma decisão do protocolo. É uma porta sem sinal, ou uma que um administrador
desligou. A `p3` desconectada da primeira seção estava em `state disabled` ao lado de `NO-CARRIER`, e
a última seção desta lição mostra uma porta posta ali de propósito.
