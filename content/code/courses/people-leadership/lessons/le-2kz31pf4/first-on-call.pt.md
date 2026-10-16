---
title: O primeiro plantão
version: 1
---

O plantão é a parte do trabalho de engenharia que pessoas novas mais temem, com razão: sozinhas, de
madrugada, responsáveis por algo que talvez mal entendam, com clínicas dependendo daquilo. A
experiência do Thiago na aula 6, acionado às três da manhã por um alerta que ninguém tinha explicado, é
o que acontece quando o primeiro plantão é tratado como uma entrada qualquer da escala. **Um primeiro
plantão é uma etapa de treinamento, construída em degraus, e a pessoa nova nunca fica de fato sozinha
até ter feito cada degrau com alguém.**

## Três degraus

O Agenda agora usa uma sequência que muitos times usam de alguma forma:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l18-oncall\" aria-label=\"Três degraus da esquerda para a direita. Sombra: a pessoa nova é acionada, mas quem tem experiência age; o Lucas com a Yara no segundo mês. Sombra invertida: a pessoa nova age e quem tem experiência observa, pronta para entrar; o Lucas com a Yara no terceiro mês. Titular com apoio nomeado: a pessoa nova fica de plantão sozinha, com alguém que aceitou atender a qualquer hora; o Lucas, com o Diego de apoio, depois dos noventa dias.\"><defs><marker id=\"l18-oncall-pl-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"130.0\" width=\"200.0\" height=\"125.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">sombra</text><text x=\"130.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">é acionado, observa;</text><text x=\"130.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a Yara age</text><text x=\"130.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">mês 2</text><path d=\"M234.0 160.0 L256.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-oncall-pl-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"90.0\" width=\"200.0\" height=\"165.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">sombra invertida</text><text x=\"360.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">age; a Yara observa,</text><text x=\"360.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pronta para entrar</text><text x=\"360.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">mês 3</text><path d=\"M464.0 120.0 L486.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l18-oncall-pl-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"50.0\" width=\"200.0\" height=\"205.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">titular, com apoio</text><text x=\"590.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sozinho, o Diego</text><text x=\"590.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">atende a qualquer hora</text><text x=\"590.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">depois de 90 dias</text><text x=\"30.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">o Lucas, nunca sozinho até cada degrau ter sido feito com alguém</text></svg>", "caption": "A primeira semana como titular vem depois da sombra e da sombra invertida, e não no lugar delas."}
```

1. **Sombra.** A pessoa nova é acionada junto com a titular por uma semana. Ela observa, pergunta e
   anota, mas quem age é a titular. O objetivo é ver alertas reais, runbooks reais e decisões reais.
2. **Sombra invertida.** A pessoa nova é a titular e age, com a pessoa experiente acionada junto,
   observando, pronta para entrar. O objetivo é tomar as decisões com uma rede de segurança.
3. **Titular, com apoio nomeado.** A pessoa nova fica de plantão sozinha, com um apoio que aceitou
   atender a qualquer hora, e uma página de runbook para cada alerta que pode acioná-la.

O Lucas fez a semana de sombra no segundo mês, com a Yara, e a de sombra invertida no terceiro, de novo
com a Yara. A primeira semana dele como titular veio depois dos noventa dias, com o Diego de apoio.

## O que precisa existir antes

Os degraus só funcionam se o sistema estiver pronto para uma pessoa nova estar de plantão:

- **Todo alerta que pode acionar alguém tem uma página de runbook**, dizendo o que significa e o que
  tentar primeiro. O que acordou o Thiago não tinha; agora tem, e o time combinou desde então que um
  alerta sem página não pode ser ligado.
- **O escalonamento está escrito**: quem é o apoio, como chegar a ele, e que ligar para ele é esperado,
  não um fracasso. A resposta do Thiago na aula 6, de que não queria acordar ninguém, é o problema que
  isso resolve.
- **Decisões que a pessoa pode precisar tomar de madrugada têm donos**, como a lista da aula 4 exigia.
  Quem está de plantão pode desligar uma feature flag sem pedir; isso agora está escrito no runbook.

## Depois da primeira semana como titular

A Renata usa parte da 1:1 seguinte para saber como foi, com as perguntas da aula 6: qual foi o pior
momento, de um a dez quão preparado você se sentiu, o que faria subir um ponto. A resposta do Lucas foi
sete, e o ponto a mais era uma página de runbook para o alerta de failover do banco de dados, que tinha
disparado uma vez e que ele não tinha entendido. Ele mesmo escreveu a página, com a ajuda do Fábio, e
essa foi a última linha do plano de noventa dias riscada.

## A sua tarefa

Para um time que você conhece, escreva no caderno a integração ao plantão de uma pessoa nova, nos três
degraus. Depois confira:

- Cada degrau tem uma pessoa experiente nomeada e uma semana.
- Todo alerta que pode acionar a pessoa nova tem uma página dizendo o que fazer.
- A pessoa nova sabe, por escrito, que ligar para o apoio de madrugada é esperado.
- Há uma conversa planejada depois da primeira semana como titular.
