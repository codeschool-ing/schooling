---
title: Sanidade ou fumaça
version: 1
---

As duas palavras costumam ser usadas como se fossem a mesma coisa, e alguns glossários, entre eles
edições antigas do glossário da ISTQB, registram *teste de sanidade* como outro nome para *teste de fumaça*.
As equipes que mantêm as duas palavras separadas usam cada uma para uma pergunta diferente, e este
curso faz o mesmo, porque **uma versão nova levanta as duas perguntas, e elas são respondidas por
verificações diferentes**.

## Duas perguntas sobre uma versão nova

**A fumaça pergunta se a versão vale a pena ser testada.** Ela é larga e rasa: a aplicação sobe, a
página inicial carrega, os caminhos principais respondem. A aula 8 montou uma lista de fumaça para o
boxoffice, e ela roda em toda versão, seja qual for o conteúdo prometido, em poucos minutos. Uma
falha de fumaça para tudo, porque não há o que testar numa versão que não sobe.

**A sanidade pergunta se uma mudança específica fez o que prometia.** Ela é estreita e mais funda:
olha para a correção ou para a pequena funcionalidade que motivou a versão, e para o que está logo
ao lado dela, e para mais nada. Ela roda depois que a fumaça passou, e só numa versão que promete uma
mudança. Uma falha de sanidade devolve a versão ao desenvolvedor antes que alguém gaste um dia de
teste de regressão com ela.

A diferença aparece num desenho, com o quanto da aplicação uma verificação toca num eixo e o quanto
ela pressiona cada parte no outro:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l09-depth-breadth\" aria-label=\"Dois eixos, abrangência na base e profundidade na lateral. A fumaça é uma faixa fina por toda a largura, embaixo: tudo, de leve. A regressão é um bloco largo de altura média sobre a mesma largura. A sanidade é uma coluna estreita e alta, em pé sobre o lugar onde a mudança foi feita.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><path d=\"M90.0 240.0 L650.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 240.0 L90.0 34.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">profundidade: quanto se pressiona cada parte</text><text x=\"370.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">abrangência: quanto da aplicação</text><rect x=\"100.0\" y=\"125.0\" width=\"540.0\" height=\"115.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"112.0\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">regressão</text><text x=\"112.0\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que funcionava ainda funciona?</text><rect x=\"100.0\" y=\"206.0\" width=\"540.0\" height=\"34.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"112.0\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">fumaça</text><text x=\"170.0\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a versão ao menos sobe?</text><rect x=\"440.0\" y=\"52.0\" width=\"50.0\" height=\"188.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"502.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">sanidade</text><text x=\"502.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">essa mudança funcionou?</text><path d=\"M465.0 260.0 L465.0 243.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"473.0\" y=\"260.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a mudança</text></svg>", "caption": "Três verificações sobre uma mesma versão nova. Fumaça e regressão cobrem a aplicação inteira em profundidades diferentes; a sanidade cobre uma mudança e seus vizinhos, mais fundo que as duas."}
```

## O reteste, e o passo além dele

O núcleo de uma verificação de sanidade é um **reteste**: os passos do relatório de defeito, rodados
de novo na versão nova, esperando o resultado que o relatório dizia faltar. A ISTQB chama isso de
*teste de confirmação*. Um relatório de defeito é um roteiro com o resultado esperado já escrito, e
é por isso que um bom relatório faz do reteste questão de minutos; a aula 15 trata de escrevê-lo
assim.

Sozinho, o reteste tem um ponto cego. **Ele prova que o caso relatado agora passa, e não diz nada
sobre o caso um passo adiante**, que é justamente onde uma correção apressada erra. A aula 4
descobriu que o boxoffice 1.0 recusa seis ingressos. Uma correção que aceita seis removendo o limite
superior de vez passa no reteste e deixa alguém reservar setecentos. Então a verificação de
sanidade acrescenta os vizinhos de cada correção:

- o limite do outro lado: seis agora é aceito, então sete ainda tem de ser recusado;
- o outro ramo da mesma regra: um sócio que reserva cinco agora ganha 15%, então um sócio que
  reserva quatro ainda tem de ganhar 10%;
- o outro caminho até a mesma tela: se o relatório usou o curl, o navegador também, e se um
  formulário e um link chegam à página, uma olhada nos dois.

A verificação é só isso. Em geral ela não é escrita como casos de teste próprios: o relatório de
defeito é o roteiro, e os vizinhos são uma ou duas linhas de anotação ao lado dele.

## Onde ela fica

Numa versão que promete uma correção, as três verificações rodam numa ordem, e cada uma decide se a
seguinte vale o tempo:

| ordem | verificação | a pergunta | quando falha |
|---|---|---|---|
| 1 | fumaça | a versão ao menos sobe? | a versão volta; nada mais roda |
| 2 | sanidade | a mudança prometida funcionou? | a versão volta com o resultado do reteste |
| 3 | regressão | o que funcionava ainda funciona? | um relatório por falha; a versão ainda pode sair |

A fumaça leva minutos e a sanidade leva minutos, enquanto uma rodada de regressão leva horas ou
dias, e é por isso que as perguntas baratas vêm primeiro. Uma equipe que pula a sanidade descobre à
tarde que a correção nunca funcionou, depois de uma manhã de resultados de regressão numa versão que
ninguém vai entregar.

**Uma verificação de sanidade aprovada é estreita de propósito, e o que ela permite dizer também.**
Ela diz que as duas correções do boxoffice 1.1 funcionam. Não diz nada sobre o resto da aplicação,
nem sobre o resto do código que a correção mexeu. Essa segunda pergunta é o teste de regressão, e a
aula 10 a faz à mesma versão.
