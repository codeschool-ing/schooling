---
title: O guardião, e por que o trabalho não é um portão
version: 1
---

**A imagem mais comum de quem testa é a de um guarda na porta: nada sobe até o QA deixar.** É uma imagem
lisonjeira, e há quem seja contratado para ela de propósito. É também, em quase todo time que tenta, o
arranjo que piora o software. Esta aula defende essa posição; você é livre para discordar, e convém
conhecer o argumento antes.

## Como o portão deveria funcionar

Os desenvolvedores constroem. Quando acham que uma funcionalidade está pronta, entregam a quem testa. Quem
testa confere e, ou devolve com defeitos, ou aprova para a entrega. A qualidade está garantida porque nada
passa do portão sem a aprovação de quem testa, e se um defeito chega aos clientes, todo mundo sabe de quem
era a assinatura na entrega.

Cada frase disso soa responsável. Veja o que cada uma faz com um time em seis meses.

## O que o portão faz com todo o resto

**Os desenvolvedores deixam de ser donos da qualidade.** Se alguém mais adiante vai conferir tudo,
conferir você mesmo é esforço duplicado, e sempre há um prazo que torna razoável pular. O Rafael, sob o
portão, manda o `tickets.py` depois de tentar quatro entradas, porque a Lia vai tentar o resto. Cada
pessoa baixa a própria régua exatamente na altura da régua seguinte.

**O trabalho chega tarde e todo de uma vez.** O portão fica no fim, então toda funcionalidade chega a quem
testa quando está pronta, ou seja, nos últimos dias de cada ciclo. Quem testa vira o gargalo atrás do qual
a entrega espera, e a pressão para aprovar é maior exatamente quando houve menos tempo para olhar.

**A relação vira adversária.** Quem testa e tem como trabalho achar motivos para recusar vira a pessoa com
quem os desenvolvedores discutem. Defeitos são relatados como sentenças e defendidos como acusações. A
informação que teria ajudado antes, *não tenho certeza de que esta regra está certa*, deixa de ser
compartilhada, porque compartilhá-la dá um motivo ao guardião.

**E a promessa nunca foi cumprível.** Quem testa não consegue garantir que uma entrega não tem defeitos; a
aula 1 citou Dijkstra sobre o porquê. Uma assinatura numa entrega é uma afirmação que ninguém pode fazer
honestamente, e no dia em que um defeito escapa, o time descobre que o que o portão de fato fornecia era
alguém para culpar.

## Jogar por cima do muro

O portão tem uma postura correspondente do outro lado, e ela tem nome: **jogar por cima do muro.** O
trabalho termina, é passado adiante e esquecido; o que volta é um problema novo. O muro é o verdadeiro
defeito desse arranjo. De um lado, pessoas que sabem como o código funciona e não o testam; do outro,
pessoas que o testam e não sabem como ele funciona. Nenhum lado enxerga o todo, e os dois podem apontar
para o outro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 330\" role=\"img\" data-fig=\"l05-gate-or-loop\" aria-label=\"Dois arranjos. Em cima: um portão no fim. Regra, código e pronto vão da esquerda para a direita; depois um muro, depois uma caixa marcada QA aprova, depois entrega; uma seta com o rótulo defeitos, devolvidos volta do portão para o código. Embaixo: quem testa em cada passo. Regra, código, pronto e entrega vão da esquerda para a direita, e sob cada um quem testa faz algo: pergunta, pareia, explora, informa; na entrega, a Joana decide.\"><defs><marker id=\"qa-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um portão no fim</text><rect x=\"20.0\" y=\"40.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">regra</text><rect x=\"130.0\" y=\"40.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">código</text><rect x=\"240.0\" y=\"40.0\" width=\"90.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pronto</text><path d=\"M111.0 58.0 L129.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M221.0 58.0 L239.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M352.0 32.0 L352.0 84.0\" stroke=\"var(--amber)\" stroke-width=\"4\" fill=\"none\"></path><text x=\"352.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o muro</text><path d=\"M331.0 58.0 L380.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"382.0\" y=\"40.0\" width=\"110.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"437.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">QA aprova?</text><path d=\"M493.0 58.0 L539.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"541.0\" y=\"40.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">entrega</text><path d=\"M437 77 L437 118 L175 118 L175 78\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#qa-ah-amber)\"></path><text x=\"306.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">defeitos, devolvidos</text><text x=\"20.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">quem testa em cada passo</text><rect x=\"20.0\" y=\"194.0\" width=\"125.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"82.5\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">regra</text><path d=\"M82.0 231.0 L82.0 256.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"32.0\" y=\"258.0\" width=\"101.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"82.5\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pergunta</text><rect x=\"185.0\" y=\"194.0\" width=\"125.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"247.5\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">código</text><path d=\"M146.0 212.0 L184.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M247.0 231.0 L247.0 256.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"197.0\" y=\"258.0\" width=\"101.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"247.5\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pareia</text><rect x=\"350.0\" y=\"194.0\" width=\"125.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"412.5\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pronto</text><path d=\"M311.0 212.0 L349.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M412.0 231.0 L412.0 256.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"362.0\" y=\"258.0\" width=\"101.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"412.5\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">explora</text><rect x=\"515.0\" y=\"194.0\" width=\"125.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"577.5\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">entrega</text><path d=\"M476.0 212.0 L514.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M577.0 231.0 L577.0 256.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"527.0\" y=\"258.0\" width=\"101.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"577.5\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">informa</text><text x=\"577.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">a Joana decide</text></svg>", "caption": "Em cima, tudo chega a quem testa de uma vez, no fim, por cima de um muro. Embaixo, quem testa está em cada passo, e a entrega é decisão da dona do produto com a informação de quem testa dentro."}
```

## O que entra no lugar do portão

Não é nada. A decisão de entregar ainda precisa ser tomada, por alguém, com a melhor informação
disponível. O que muda é quem a toma, o que quem testa contribui para ela, e quando.

- **A decisão de entregar é de quem é dono do produto.** No Cine Aurora, é a Joana. Ela pesa o que quem
  testa achou contra o que o cinema precisa, e é ela quem conhece as duas coisas.
- **A contribuição de quem testa é informação**, entregue o mais cedo possível, sobre o que se sabe, o que
  não se sabe e quais são os riscos. A próxima seção trata do que isso quer dizer na prática.
- **A qualidade é trabalho do time todo**, e a habilidade particular de quem testa é tornar mais fácil
  que todos os outros façam a sua parte. A seção seguinte descreve como isso fica numa semana.

Nada disso torna quem testa menos importante. Torna importante por outro motivo: não porque pode barrar
uma entrega, mas porque a entrega é uma decisão melhor com essa pessoa na sala.
