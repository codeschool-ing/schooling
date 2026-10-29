---
title: "INP: quanto um toque espera"
version: 1
---

**O Interaction to Next Paint é quanto a página levou para mostrar uma resposta a uma interação, pego
para a interação mais lenta da visita inteira.** Uma interação é um clique, um toque ou uma tecla;
rolar e passar o mouse por cima não são. A resposta é o próximo quadro que o navegador pinta depois
dela, mostre ele o que mostrar. Um botão que fica cinza na hora e carrega dados por um segundo tem um
INP curto, porque a pessoa viu algo acontecer; um botão que não mostra nada por um segundo tem um
longo.

## Três partes de uma interação

O tempo de cada interação é a soma de três partes, e a biblioteca `web-vitals` informa as três:

1. **input delay**, o atraso de entrada: do toque até o código da página para ele começar, que é longo
   quando a thread principal está ocupada com outra coisa, como hidratar;
2. **processing**, o processamento: os próprios tratadores de evento da página, rodando;
3. **presentation delay**, o atraso de apresentação: do fim dos tratadores até o quadro ser pintado:
   estilo, layout e pintura do que quer que os tratadores tenham mudado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Uma interação desenhada como uma barra ao longo do tempo, em três partes: o input delay, do toque até o tratador começar; o processamento, enquanto o tratador roda; e o presentation delay, até o próximo quadro ser pintado. O INP é o comprimento da barra inteira.\"><rect x=\"60\" y=\"60\" width=\"120\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><text x=\"120.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">input delay</text><rect x=\"180\" y=\"60\" width=\"330\" height=\"34\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"345.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">processamento: os tratadores</text><rect x=\"510\" y=\"60\" width=\"160\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"590.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">apresentação</text><line x1=\"60\" y1=\"50\" x2=\"60\" y2=\"104\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></line><text x=\"60\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">toque</text><line x1=\"670\" y1=\"50\" x2=\"670\" y2=\"104\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"670\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">próxima pintura</text><line x1=\"60\" y1=\"124\" x2=\"670\" y2=\"124\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"365.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">INP: tudo isso, para a interação mais lenta da visita</text></svg>", "caption": "O que a pessoa espera é a pintura, não o fim do código.", "same": ["input delay"]}
```

**A thread principal faz uma coisa de cada vez**, e essa é a história inteira do INP. Um tratador que
roda por um segundo bloqueia todo outro toque durante esse segundo, e bloqueia a pintura que mostraria
o resultado. As correções saem das partes: fazer menos no tratador, dividir um trabalho longo para o
navegador poder pintar no meio, e mudar menos da página para haver menos layout a fazer.

## A mais lenta, quase

Uma visita pode ter centenas de interações. O INP pega a mais lenta, só que numa página com muitas
interações ele ignora uma a cada cinquenta, para que um atraso esquisito isolado numa visita longa não
decida o número. **O limite é 200 milissegundos para bom e 500 para ruim.** Uma página sem interação
não tem INP nenhum, e nem uma cujas interações foram todas mais rápidas do que o navegador se dá ao
trabalho de informar, como a seção "Dados de campo: o número do visitante" mostra.
