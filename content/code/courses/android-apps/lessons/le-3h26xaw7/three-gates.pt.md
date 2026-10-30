---
title: Três portões entre o seu código e a tela
version: 1
---

**Uma notificação é um pedido, não uma ordem.** O seu código monta uma e a entrega ao sistema, e o
sistema decide se alguém a vê. Boa parte da confusão sobre notificações vem de tratar o `notify` como
uma função que mostra algo: ela não devolve nada, não lança nada e, num celular que disse não, não faz
nada, em silêncio.

O planner quer um tipo de notificação: num dia com sessão planejada, uma linha curta dizendo qual
curso e quantos minutos, e um toque que abre aquele curso. O worker da aula 18 é um lugar natural
para chamá-la, uma vez por dia. Esta aula monta a notificação e as verificações em volta dela, e a
aula 20 pede ao estudante a permissão de que ela precisa.

## Os portões

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l19-gates\" aria-label=\"Um fluxo da esquerda para a direita. showReminder é chamada. Primeira pergunta: no Android 13 ou mais novo, POST_NOTIFICATIONS foi concedida? Se não, nada aparece. Segunda: as notificações do app estão ligadas nas configurações? Se não, nada aparece. Terceira: o canal que a notificação nomeia, e a importância dele, que o estudante pode mudar: alta mostra por cima da tela, padrão mostra na gaveta com som, baixa sem som, e nenhuma bloqueia.\"><defs><marker id=\"l19-gates-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l19-gates-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"16\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"76\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">showReminder()</text><rect x=\"166\" y=\"34\" width=\"150\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"241\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Android 13+:</text><text x=\"241\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">permissão concedida?</text><rect x=\"346\" y=\"34\" width=\"150\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"421\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">notificações ligadas</text><text x=\"421\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nas configurações?</text><rect x=\"526\" y=\"34\" width=\"178\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a importância</text><text x=\"615\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">do canal</text><path d=\"M136 60 L164 60\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-gates-ah-wire)\"></path><path d=\"M316 60 L344 60\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-gates-ah-wire)\"></path><path d=\"M496 60 L524 60\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-gates-ah-wire)\"></path><rect x=\"166\" y=\"170\" width=\"330\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"331\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">nada aparece, e nenhum erro</text><path d=\"M241 86 L241 168\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-gates-ah-amber)\"></path><path d=\"M421 86 L421 168\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l19-gates-ah-amber)\"></path><text x=\"250\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não</text><text x=\"430\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">não</text><text x=\"540\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">alta: por cima da tela</text><text x=\"540\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">padrão: gaveta, com som</text><text x=\"540\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">baixa: gaveta, sem som</text><text x=\"540\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nenhuma: bloqueada</text><path d=\"M532 100 L532 196\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"615\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o estudante pode baixá-la</text></svg>", "caption": "Três portões ficam entre o notify e a tela, e o último é do estudante: o app escolhe a importância inicial de um canal, e só o estudante pode mudá-la depois.", "same": ["Android 13+:"]}
```

Leia a figura da esquerda para a direita, porque a ordem é a ordem que o Android aplica:

1. **No Android 13 e posteriores, o app precisa ter `POST_NOTIFICATIONS`.** É uma permissão de
   tempo de execução: declarada no manifesto e depois concedida pelo estudante numa caixa de diálogo.
   Antes do Android 13 essa permissão não existia e todo app podia postar. A seção 05 trata dos dois
   casos.
2. **O estudante pode desligar todas as notificações de um app** nas configurações dele, seja qual
   for a permissão concedida. `areNotificationsEnabled()` é como o app descobre.
3. **Toda notificação pertence a um canal**, e a importância do canal decide com que força ela chega,
   de aparecer por cima do que estiver na tela até não aparecer. O app define a primeira importância
   de um canal; depois disso, ela é do estudante.

**Os dois primeiros portões falham sem avisar ninguém.** Nenhuma exceção, nenhuma linha de log no seu
app, nenhum valor de retorno do `notify`. Por isso o `showReminder` desta aula confere os dois sozinho
e responde `true` ou `false`: quem chama sabe então se o estudante foi alcançado, e pode mostrar o
lembrete dentro do app no lugar.

## O que esta aula consegue mostrar, e o que não consegue

A gaveta de notificações, o banner por cima da tela e a caixa de diálogo de permissão são desenhados
pela interface do sistema do celular, não pelo seu app, então nem o Robolectric nem o Roborazzi
conseguem fotografá-los. O que um teste consegue é perguntar ao sistema o que ele recebeu: o
Robolectric guarda cada notificação que o app postou, com título, texto, canal e o intent que o toque
dispararia. As seções 03 a 06 leem isso. A seção 07 descreve o que só um celular mostra, marcado como
**não executado**.

**Uma notificação mandada por um servidor é outro mecanismo**: uma mensagem push chega pelo Firebase
Cloud Messaging e o app a transforma numa notificação como esta. A aula 17 de `mobile-fundamentals`
explica como os pushes chegam e por que não são um canal para abusar; isso precisa de um projeto no
Firebase e de um aparelho, e não é construído aqui.
