---
title: Escalonamento, quando ninguém responde
version: 1
---

Um chamado que ninguém atende é pior que nenhum chamado, porque todo mundo acredita que ele foi tratado.
**Escalonamento** é a regra do que acontece em seguida: se a pessoa chamada não reconheceu dentro de
um tempo definido, a próxima pessoa é chamada, e assim por diante, subindo uma escada curta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma linha do tempo de 0 a 20 minutos. Em 0 minuto o principal é chamado. Sem reconhecimento, aos 5 minutos o secundário é chamado. Ainda sem nada depois de mais 10, aos 15 minutos o líder é chamado. Uma nota sob a linha: um reconhecimento em qualquer degrau para a escada, quer dizer estou com ele, não consertei.\"><defs><marker id=\"esc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 140 L670 140\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M70 134 L70 146\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"70\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 min</text><path d=\"M220 134 L220 146\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"220\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5 min</text><path d=\"M370 134 L370 146\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"370\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10 min</text><path d=\"M520 134 L520 146\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"520\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">15 min</text><path d=\"M670 134 L670 146\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"670\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20 min</text><rect x=\"8\" y=\"62\" width=\"124\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">principal chamado</text><path d=\"M70 104 L70 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#esc-ah)\"></path><rect x=\"158\" y=\"62\" width=\"124\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"220.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">secundário chamado</text><path d=\"M220 104 L220 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#esc-ah)\"></path><rect x=\"458\" y=\"62\" width=\"124\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"520.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">líder chamado</text><path d=\"M520 104 L520 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#esc-ah)\"></path><text x=\"145.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem reconhecimento</text><text x=\"370\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ainda nada, mais 10</text><text x=\"360\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Um reconhecimento em qualquer degrau para a escada: \"estou com ele\", não \"consertei\".</text></svg>", "caption": "A escada só sobe enquanto ninguém reconheceu, e o último degrau é uma pessoa, nunca um grupo."}
```

| degrau | quem é chamado | depois de |
|---|---|---|
| 1 | o principal | na hora |
| 2 | o secundário | 5 minutos sem reconhecimento |
| 3 | o líder da equipe, que pode assumir o comando | mais 10 minutos |

Reconhecer é um único toque no telefone, e quer dizer *estou com ele*, não *consertei*. Isso para a
escada e começa o relógio do incidente, que dali em diante é assunto da lição 13. Cinco minutos é um
primeiro degrau comum: tempo para achar o telefone e acordar, curto o bastante para um chamado perdido
num bolso custar pouco. O último degrau é uma pessoa e nunca um grupo, porque um chamado para doze
pessoas é um chamado que cada uma espera que outra atenda.

## O que o SNS não faz

O tópico da lição 10 entrega. **Ele não sabe se alguém leu o que entregou**: um e-mail enviado e um SMS
enviado são o fim do trabalho dele, e nenhuma mensagem volta dizendo *estou com ele*. Não há nada no SNS
com base em que escalar, então a escada mora num **serviço de chamados**, um produto feito exatamente
para isso, assinado no tópico por um endpoint HTTPS. O alarme publica, o tópico entrega ao serviço, e o
serviço guarda o plantão, o reconhecimento e a escada, e toca o telefone com um som que acorda, coisa que
um e-mail não faz.

O laboratório não tem serviço de chamados, e ensinar as telas de um produto envelheceria tão rápido
quanto o produto, então este curso para no tópico. O que continua igual qualquer que seja o serviço
escolhido é o que configurar nele: o plantão da seção anterior, a escada acima e **um chamado de teste
por semana**, mandado de propósito na passagem, para uma rota quebrada ser achada por quem está
esperando por ela.

## Dois tipos de alerta

Nem tudo que vale saber vale acordar alguém. Uma equipe com um único destino para seus alarmes acaba
chamando por coisas que podiam esperar a manhã. **Dois destinos, dois tópicos**:

- **um chamado**: clientes são afetados agora, ou serão dentro de uma hora, e uma pessoa pode fazer algo;
  vai para `shop-page`, e de lá para o telefone;
- **um ticket**: algo para olhar no horário de trabalho, um disco enchendo devagar, um certificado que
  vence em três semanas; vai para `shop-ticket`, e de lá para a fila de trabalho da equipe.

Decidir qual dos dois um alarme é, alarme por alarme, é o trabalho da seção sobre fadiga, e mudá-lo é o
da última seção.
