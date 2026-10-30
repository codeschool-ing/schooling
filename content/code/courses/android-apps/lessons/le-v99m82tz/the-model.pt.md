---
title: Três tipos de permissão, e o único que pergunta
version: 1
---

**A maior parte das permissões que um app tem nunca foi pedida.** A aula 18 encontrou quatro no
manifesto combinado, `WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `RECEIVE_BOOT_COMPLETED` e
`FOREGROUND_SERVICE`, e o estudante não viu nenhuma: são permissões *normais*, concedidas na
instalação porque o que protegem não é privado. O Android separa as permissões em três grupos pelo
que está em jogo, e só um deles envolve o estudante durante o uso.

| tipo | o que protege | como é concedida | exemplos |
|---|---|---|---|
| **normal** | nada privado | na instalação, ao ser declarada | `INTERNET`, `WAKE_LOCK` |
| **de execução**, que a documentação do Google também chama de *perigosa* | os dados do estudante ou os sensores do celular | pelo estudante, numa caixa de diálogo, com o app rodando | `POST_NOTIFICATIONS`, `CAMERA`, `ACCESS_FINE_LOCATION` |
| **especial** | algo poderoso o bastante para pedir uma tela de configurações | pelo estudante, numa página própria das Configurações | alarmes exatos, desenhar sobre outros apps |

Esta aula é sobre a linha do meio. O planner precisa de uma permissão de execução,
`POST_NOTIFICATIONS`, para os lembretes da aula 19, e o mesmo padrão serve para a câmera ou a
localização; a aula 12 de `mobile-fundamentals` discute quais delas um app deveria pedir.

## Uma permissão de execução tem história

A caixa de diálogo é do sistema, e o sistema lembra o que o estudante disse. **A partir do Android
11, duas recusas da mesma permissão são definitivas**: depois da segunda, um pedido recebe uma recusa
na hora, sem mostrar a caixa, e só a página do app nas Configurações pode mudar isso. É isso que a
figura acompanha:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l20-twice\" aria-label=\"A vida de uma permissão de execução no Android 11 e posteriores. Nunca pedida: o app pode mostrar a caixa do sistema. Se o estudante permite, ela é concedida. Se nega uma vez, o Android avisa que o app deveria explicar, e o app pode mostrar a caixa uma segunda vez. Se nega de novo, o sistema para de mostrar a caixa: o pedido do app é recusado na hora, e só a tela de configurações do app, onde o estudante pode permiti-la, muda a resposta.\"><defs><marker id=\"l20-twice-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-twice-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l20-twice-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"16\" y=\"30\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"76.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nunca pedida</text><rect x=\"236\" y=\"30\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"311.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">negada uma vez</text><text x=\"311.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">explicar, e pedir</text><rect x=\"486\" y=\"30\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"561.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">negada duas vezes</text><text x=\"561.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem mais caixas</text><rect x=\"236\" y=\"170\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"311.0\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">concedida</text><rect x=\"486\" y=\"170\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"561.0\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">configurações do app</text><path d=\"M136 53 L234 53\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-twice-ah-amber)\"></path><text x=\"185\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">negar</text><path d=\"M386 53 L484 53\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-twice-ah-amber)\"></path><text x=\"435\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">negar</text><path d=\"M76 76 L76 193 L234 193\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-twice-ah-phosphor)\"></path><text x=\"84\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">permitir</text><path d=\"M311 76 L311 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-twice-ah-phosphor)\"></path><text x=\"318\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">permitir</text><path d=\"M561 76 L561 168\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l20-twice-ah-wire)\"></path><text x=\"568\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o único caminho de volta</text><path d=\"M486 205 L388 205\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l20-twice-ah-wire)\"></path><text x=\"437\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">permitida lá</text></svg>", "caption": "Duas recusas encerram a conversa: depois da segunda, o pedido recebe um não antes de qualquer caixa aparecer, e só a tela de configurações pode mudar isso."}
```

Entre a primeira recusa e a segunda, o Android diz ao app algo útil.
`shouldShowRequestPermissionRationale` devolve `true`, o que quer dizer: o estudante disse não uma
vez, e uma explicação antes de pedir de novo é apropriada. Ela devolve `false` antes do primeiro
pedido e **também** depois da segunda recusa, o que torna os dois estados difíceis de separar; a
seção 04 é o código que faz isso, e a seção 06 testa o caminho inteiro.

## Quando pedir

**Peça quando o estudante faz algo que precisa da permissão, não quando o app abre.** Uma caixa na
primeira tela pede notificações antes de o estudante saber sobre o que o app notificaria, e uma
recusa ali gasta uma das duas chances. O planner pede quando o estudante toca em "Turn on
reminders", num cartão que já disse o que é um lembrete. A documentação do Google dá o mesmo
conselho, e a permissão de notificação do Android 13 é o caso mais claro: um app que mira 33 ou mais
decide esse momento sozinho, como a seção 05 da aula 19 descreveu.

A ordem que o resto da aula constrói, então. A seção 03 faz o pedido em si, e a seção 04 escreve uma função pura que transforma as respostas do Android no que o cartão deve oferecer. A seção 05 desenha o cartão nos seus três estados, e a seção 06 é um teste que percorre o caminho inteiro: recusa, explicação, segunda recusa, configurações.
