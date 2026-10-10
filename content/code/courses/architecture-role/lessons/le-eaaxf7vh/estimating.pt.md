---
title: Faixas, não pontos
version: 1
---

Uma estimativa é uma afirmação sobre o que você ainda não sabe. **Escrita como um número só, ela
esconde a única parte de que uma decisão precisa: o tamanho do não saber.** Esta seção é sobre
dizer esse tamanho em voz alta, com um método que leva poucos minutos por parte do trabalho, e
sobre o que um arquiteto estima que um time não estima.

## A pergunta no corredor

Helena Prado, diretora de produto da Carreto, parou Renata na saída de uma reunião de
planejamento. Os motoristas vêm pedindo para receber no momento em que a entrega é comprovada, em
vez de esperar a próxima rodada de pagamentos, e um concorrente começou a oferecer exatamente isso.
"Pagamento instantâneo por Pix. Mais ou menos quanto tempo?"

A resposta tentadora é um número. Renata tinha um na cabeça, uns três meses, e ele estaria num
slide para o conselho até sexta. **Um número dito no corredor vira compromisso no momento em que
alguém o anota**, e ninguém que o lê depois sabe que ele saiu de trinta segundos de reflexão.

Três palavras se confundem nesse ponto, e o livro *Software Estimation* (2006), de Steve
McConnell, as mantém separadas:

- uma **estimativa** é uma previsão de quanto algo vai levar, com a sua incerteza;
- uma **meta** é uma data que o negócio quer, por razões próprias;
- um **compromisso** é a promessa de entregar até uma data, feita por quem conhece as duas.

A pergunta de Helena pede uma estimativa. O que vão perguntar a ela lá em cima é um compromisso, e
o conselho talvez já tenha uma meta em mente. Manter as três separadas é quase todo o trabalho, e
começa por não responder à primeira pergunta com a terceira.

Então Renata disse: "Hoje, algo entre um mês e um ano. Me dê uma semana com o time do Bruno e eu te
dou uma faixa com que dá para planejar." Parece evasivo. É a resposta honesta, e há uma figura que
mostra por quê.

## O cone da incerteza

Barry Boehm mediu, em 1981, quão longe do esforço realmente gasto caíam as estimativas feitas em
diferentes etapas de um projeto. Steve McConnell redesenhou depois o resultado como o **cone da
incerteza**. Na etapa da ideia inicial, o esforço real cai em qualquer ponto entre um quarto e
quatro vezes a estimativa. Com o produto definido, entre a metade e o dobro. Com os requisitos
fechados, entre uns dois terços e uma vez e meia. No projeto detalhado, cerca de dez por cento para
cada lado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 296\" role=\"img\" aria-label=\"O cone da incerteza, deitado. Na ideia inicial o esforço real pode ficar entre um quarto e quatro vezes a estimativa; com o produto definido, entre a metade e o dobro; com os requisitos fechados, entre dois terços e uma vez e meia; no projeto detalhado, cerca de dez por cento para cada lado. Aplicado a doze semanas: de 3 a 48 semanas na ideia inicial, de 8 a 18 semanas com os requisitos fechados.\"><defs><marker id=\"l14cone-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><path d=\"M80 245 L650 245\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M80 50.0 L650 50.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">4×</text><path d=\"M80 95.0 L650 95.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"95.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">2×</text><path d=\"M80 140.0 L650 140.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">1×</text><path d=\"M80 185.0 L650 185.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">0,5×</text><path d=\"M80 230.0 L650 230.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.8\" stroke-dasharray=\"3 4\"></path><text x=\"72\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">0,25×</text><path d=\"M120 50.0 L250 95.0 L380 113.7 L510 133.8 L630 140.0 L630 140.0 L510 146.8 L380 166.0 L250 185.0 L120 230.0 Z\" fill=\"var(--phosphor-dim)\" fill-opacity=\"0.25\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\"></path><path d=\"M120 140.0 L630 140.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M120 245 L120 250\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"120\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ideia</text><text x=\"120\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">inicial</text><path d=\"M250 245 L250 250\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"250\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">produto</text><text x=\"250\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">definido</text><path d=\"M380 245 L380 250\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"380\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">requisitos</text><text x=\"380\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fechados</text><path d=\"M510 245 L510 250\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"510\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">projeto</text><text x=\"510\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">detalhado</text><path d=\"M630 245 L630 250\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><text x=\"630\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pronto</text><text x=\"8\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">real ÷ estimativa</text><path d=\"M120 50.0 L120 230.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><text x=\"136\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">na ideia inicial, “12 semanas” quer dizer de 3 a 48</text><path d=\"M380 113.7 L380 166.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><text x=\"392\" y=\"203\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">depois de uma semana de detalhamento:</text><text x=\"392\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">“12 semanas” quer dizer de 8 a 18</text><path d=\"M398 194 L384 170.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#l14cone-ah)\"></path></svg>", "caption": "O cone da incerteza, com as doze semanas de Renata em cima dele. O mesmo número quer dizer de 3 a 48 semanas no corredor e de 8 a 18 uma semana depois, porque decisões foram tomadas no meio do caminho."}
```

Aplicado às doze semanas de Renata, o cone diz que a resposta do corredor queria dizer, na
verdade, **de 3 a 48 semanas**, e "entre um mês e um ano" é a mesma afirmação em palavras. Uma
semana depois, com o trabalho detalhado e os requisitos combinados com Helena, as mesmas doze
semanas querem dizer **de 8 a 18**.

**O cone se estreita porque decisões são tomadas, não porque o tempo passa.** Um mês sem decidir o
que um pagamento faz quando o banco está fora do ar deixa a faixa tão larga quanto estava. A aula 1
de `process-management` percorre o cone e as evidências por trás dele. O que importa aqui é a
consequência para um arquiteto: uma estimativa no começo é uma faixa, e o trabalho mais útil no
começo é o que remove primeiro a incerteza mais larga. A seção desta aula sobre alternativas volta
a isso na forma de um spike.

## Três números para cada parte

Para estreitar a faixa, Renata sentou por uma hora com Bruno Farias, tech lead de Payments, e dois
engenheiros do time dele. Eles dividiram o pagamento instantâneo em quatro partes de trabalho e,
para cada uma, deram três números em vez de um:

- **O**, a duração otimista: o que pode dar certo dá;
- **M**, a duração mais provável: o número em que eles apostariam;
- **P**, a duração pessimista: o que costuma dar errado dá. Um mês ruim, não um desastre.

O **PERT**, uma técnica criada para o programa Polaris da Marinha dos Estados Unidos em 1958,
transforma os três números numa média e numa dispersão:

```localised
média         = (O + 4M + P) / 6
desvio padrão = (P − O) / 6
```

A média dá ao valor mais provável quatro vezes o peso de cada extremo. O desvio padrão é um sexto da
faixa inteira, uma regra prática que trata O e P mais ou menos como as bordas. Esta é a tabela, em
semanas do time de Payments:

| parte do trabalho | O | M | P | média PERT | desvio padrão |
|---|---|---|---|---|---|
| integrar a API de pagamento por Pix do banco | 2 | 3 | 8 | 3,67 | 1,00 |
| lançamentos no razão e conciliação | 2 | 4 | 7 | 4,17 | 0,83 |
| uma API de status do pagamento para o app do motorista | 1 | 2 | 3 | 2,00 | 0,33 |
| verificações da prova de entrega | 1 | 3 | 9 | 3,67 | 1,33 |
| **total** | 6 | 12 | 27 | **13,50** | |

Três coisas nela valem mais que a fórmula.

**A soma dos valores mais prováveis é 12 semanas**, e esse é o número que o time do Bruno teria
dado se alguém pedisse um só. A soma das médias é 13,5, uma semana e meia a mais, e nada disso é
gordura. Vem do formato que quase todo trabalho de software tem: um pouco de espaço para terminar
antes do esperado e muito espaço para terminar depois, de modo que P fica mais longe de M do que O,
e cada média fica acima do seu valor mais provável. Um plano feito com valores mais prováveis é
feito de números que são, cada um, mais otimistas que o resultado médio.

**A dispersão do total não é a soma das dispersões.** Se as partes variam de forma independente,
as variâncias se somam, e o desvio padrão do total é a raiz quadrada da soma: cerca de 1,89 semana
aqui. Planejar mais ou menos no percentil 85 dá 13,5 + 1,04 × 1,89, ou **cerca de 15,5 semanas**. A
aula 9 de `process-management` faz essa conta e mostra a suposição que a quebra, então esta aula só
usa o resultado. O que Renata levou de volta para Helena foram três números: 12 semanas se quase
tudo sair como o planejado, 13,5 como valor esperado, 15,5 para planejar.

**A linha mais larga é a mais interessante.** As verificações da prova de entrega vão de 1 a 9
semanas, com desvio de 1,33, porque ninguém na mesa sabia o que o Tracking registra no momento em
que uma carga é entregue. As outras três partes são incertas por motivos comuns; essa é incerta por
causa de uma pergunta que alguém conseguiria responder. Perguntas assim são baratas de responder, e
a seção desta aula sobre alternativas compra a resposta.

## O que o arquiteto estima, e o que o time estima

Renata não preencheu a tabela. **Quem vai fazer o trabalho é quem o estima**, porque conhece o
código, e porque um time preso ao número de outra pessoa tem um motivo para não cumpri-lo. O que ela
fez foi perguntar: "O que faria isto levar nove semanas?" "Qual destas vocês fariam primeiro?" "O 3
supõe que o sandbox do banco funciona?" As respostas à primeira pergunta são a matéria-prima da
próxima seção, que as transforma em riscos.

As estimativas do próprio arquiteto servem a outra decisão. Um time estima para planejar a entrega:
qual sprint, qual data. Um arquiteto estima para **escolher entre opções antes que alguém esteja
comprometido com uma delas**: se o pagamento instantâneo será construído sobre a API do banco ou
comprado de um provedor, se ele cabe neste trimestre, se o custo estrutural de uma funcionalidade
(aula 10) é uma semana ou uma estação inteira. Essas estimativas são feitas mais cedo, então ficam
mais à esquerda no cone e são mais largas, e tudo bem, desde que sejam dadas como faixas.

Dois hábitos tornam essas faixas úteis para quem as lê:

- **Escreva as suposições ao lado dos números.** "Supõe que a API de pagamento do banco é a da
  documentação atual; supõe que o Tracking guarda a foto da entrega." Quando uma suposição cai, quem
  lê sabe que a estimativa caiu junto, em vez de descobrir isso no prazo.
- **Use a unidade em que a decisão é tomada.** Helena planeja em semanas de um time, e Sílvio Matos,
  o diretor financeiro, em reais. Horas de uma pessoa são o grão errado para escolher entre duas
  arquiteturas, e sugerem uma precisão que ninguém tem.

A pergunta que um aluno costuma fazer aqui é se tudo isso vale a pena para um projeto de três
meses. A tabela levou uma hora. A alternativa era um número do corredor, num slide para o conselho,
que na verdade era "de 3 a 48 semanas" e foi lido como "12".
