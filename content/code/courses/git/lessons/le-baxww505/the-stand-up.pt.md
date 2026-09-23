---
title: A daily
version: 1
---

A **daily** (*daily stand-up*, a reunião diária em pé) são quinze minutos no mesmo horário todo dia, com a
equipe inteira. As pessoas ficavam em pé para ninguém se acomodar e deixar a reunião se arrastar, e é daí
que vem o nome. Muitas equipes hoje fazem numa chamada, sentadas, e os quinze minutos continuam valendo.

## Para que serve

**Coordenação, não relatório.** A daily responde a uma pergunta para a equipe: *tem alguma coisa
atrapalhando terminar o que começamos?* É assim que o #36 bloqueado do Bruno é notado no dia em que
bloqueia, e não no fim do sprint, e é assim que a Ana descobre que a Carla já conhece a API do serviço de
pagamento.

Não é um relatório de status para um gestor. Se todo mundo olha para uma pessoa enquanto fala, e essa
pessoa não é da equipe, a reunião virou isso.

## Dois jeitos de conduzir

O formato clássico são três perguntas para cada um: *o que fiz ontem, o que vou fazer hoje, tem algo me
bloqueando?* Funciona, e tem um ponto fraco: vai pessoa por pessoa, então a conversa é sobre quem está
ocupado, e não sobre o que está parado.

A alternativa é **percorrer o quadro**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"As quatro colunas do quadro, a fazer, em andamento, em revisão e pronto, com uma seta correndo da direita para a esquerda por cima delas. A daily começa em em revisão, perguntando quem consegue revisar hoje; passa para em andamento, perguntando o que está atrapalhando; e termina em a fazer, perguntando quem está livre para puxar o próximo. O pronto não é discutido.\"><defs><marker id=\"wk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">percorrendo o quadro, da direita para a esquerda</text><path d=\"M640 50 L60 50\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#wk-ah)\"></path><text x=\"520\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">comece aqui</text><rect x=\"20\" y=\"70\" width=\"165\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">a fazer</text><rect x=\"28\" y=\"110\" width=\"149\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"38\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quem está livre para</text><text x=\"38\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">puxar o próximo?</text><text x=\"102.5\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper-dim)\">3</text><rect x=\"198\" y=\"70\" width=\"165\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">em andamento</text><rect x=\"206\" y=\"110\" width=\"149\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"216\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o que está</text><text x=\"216\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">atrapalhando?</text><text x=\"280.5\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper-dim)\">2</text><rect x=\"376\" y=\"70\" width=\"165\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"386\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">em revisão</text><rect x=\"384\" y=\"110\" width=\"149\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"394\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quem consegue</text><text x=\"394\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">revisar hoje?</text><text x=\"458.5\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"16\" font-weight=\"600\" fill=\"var(--amber)\">1</text><rect x=\"554\" y=\"70\" width=\"165\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 4\"></rect><text x=\"564\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">pronto</text></svg>", "caption": "Começar perto do pronto põe a atenção da equipe em terminar, que é o que os limites de WIP da aula 15 pediam."}
```

Comece pela coluna mais perto do *pronto* e pergunte o que cada card precisa para andar para a direita. Um
card em revisão pede alguém para revisar; um card em andamento pergunta o que está atrapalhando; só depois
alguém fala em começar algo novo. Ninguém presta contas do dia, e os cards que ninguém menciona chamam a
atenção.

## Uma atualização útil, e uma que não é

> Ontem trabalhei nos alergênicos. Hoje vou continuar nos alergênicos.

> O #34 está em revisão e precisa de alguém hoje. Estou travada no #35: ainda não sabemos qual empresa de
> pagamento. Carla, podemos falar depois daqui?

A primeira é verdade e não diz nada à equipe. A segunda cita cards, pede alguma coisa e leva uma conversa
para fora da reunião.

## Mantendo em quinze minutos

**Problemas são citados na daily e resolvidos depois dela.** Quando duas pessoas começam a discutir como
corrigir algo, o útil é dizer *"vamos ver isso depois"*, e as duas que precisam ficam. As equipes costumam
chamar isso de *parking lot* (estacionamento). Uma daily que chega sempre a trinta minutos custa a quatro
pessoas uma hora por semana cada, e em geral é porque está resolvendo problemas na frente de quem não está
envolvido.
