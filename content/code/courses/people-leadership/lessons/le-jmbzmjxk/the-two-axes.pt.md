---
title: Alinhamento e autonomia são dois eixos, não duas pontas
version: 1
---

A imagem habitual da liberdade de um time é um controle deslizante só. Numa ponta a gestão decide
tudo e o time executa; na outra o time decide tudo e a gestão fica fora do caminho. **Nessa imagem,
todo ganho de autonomia é uma perda de alinhamento, e o trabalho de quem gerencia é escolher um
ponto no controle.** Ela está errada, e o erro aparece como um time que ou recebe ordens ou fica à
deriva.

## O desenho que substituiu o controle deslizante

Henrik Kniberg desenhou a alternativa nos vídeos de 2014 sobre a cultura de engenharia do Spotify,
e o desenho se espalhou muito além do Spotify porque consertou a imagem. Ele põe o **alinhamento**
num eixo e a **autonomia** no outro, e os trata como independentes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l04-axes\" aria-label=\"Uma grade de dois por dois. O eixo horizontal é autonomia, de baixa a alta; o vertical é alinhamento, de baixo a alto. Embaixo à esquerda, baixos nos dois: recebe ordens sem saber por quê. Em cima à esquerda, alinhamento alto e autonomia baixa: o objetivo e a solução vêm da gestão. Embaixo à direita, alinhamento baixo e autonomia alta: todo mundo livre, ninguém puxando para o mesmo lado. Em cima à direita, altos nos dois: autonomia alinhada, em que a gestão explica o problema e o time encontra a solução.\"><defs><marker id=\"l04-axes-pl-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"110.0\" y=\"30.0\" width=\"270.0\" height=\"135.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">o objetivo e a solução</text><text x=\"245.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">vêm os dois da gestão</text><text x=\"245.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">“construam esta ponte, assim”</text><rect x=\"390.0\" y=\"30.0\" width=\"270.0\" height=\"135.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"525.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">autonomia alinhada</text><text x=\"525.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a gestão explica o problema</text><text x=\"525.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">“precisamos atravessar; eis o porquê”</text><rect x=\"110.0\" y=\"175.0\" width=\"270.0\" height=\"135.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"245.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">recebe ordens</text><text x=\"245.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sem saber por quê</text><text x=\"245.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">“faça isto”</text><rect x=\"390.0\" y=\"175.0\" width=\"270.0\" height=\"135.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"525.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">todo mundo livre</text><text x=\"525.0\" y=\"239.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ninguém puxando junto</text><text x=\"525.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-style=\"italic\" fill=\"var(--paper-dim)\">“façam o que acharem melhor”</text><path d=\"M110.0 330.0 L660.0 330.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-axes-pl-ah-paper-dim)\"></path><text x=\"385.0\" y=\"346.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">autonomia</text><path d=\"M88.0 310.0 L88.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-axes-pl-ah-paper-dim)\"></path><text x=\"70.0\" y=\"170.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">alinhamento</text></svg>", "caption": "A partir do desenho de Henrik Kniberg. Os dois eixos são independentes: mais autonomia se paga com um objetivo mais claro, não com menos alinhamento."}
```

Kniberg ilustrou os quatro cantos com um rio e uma ponte, e vale manter a imagem porque ela torna
cada canto concreto:

- **Alinhamento baixo, autonomia baixa.** Ninguém explica o objetivo e ninguém pode escolher. As
  pessoas fazem o que mandam sem saber por quê, o que é o pior dos dois mundos e mais comum do que
  qualquer um admite.
- **Alinhamento alto, autonomia baixa.** "Precisamos atravessar o rio. Construam uma ponte aqui,
  deste modelo." Todo mundo sabe o objetivo e a gestão também já decidiu a solução. Funciona
  enquanto a gestão está certa e disponível, e o time aprende a esperar.
- **Alinhamento baixo, autonomia alta.** Todo mundo é livre para fazer o que acha melhor, e ninguém
  sabe o que os outros estão tentando alcançar. Cada time constrói o próprio jeito de atravessar, ou
  decide que prefere ficar deste lado.
- **Alinhamento alto, autonomia alta.** "Precisamos chegar ao outro lado do rio, e o motivo é este."
  O problema é explicado a fundo e o time descobre a solução. Kniberg chamou isso de **autonomia
  alinhada**: o esforço da gestão vai para deixar o objetivo claro, e o do time vai para cumpri-lo.

## Por que o controle deslizante é a imagem errada

No controle deslizante, uma gestora que quer mais autonomia para o time fala menos. Nos dois eixos,
ela fala **mais sobre o objetivo** e menos sobre o método. A quantidade total de comunicação não
diminui. Ela muda de lugar.

A aula 3 já mostrou isso para um trabalho só: um resultado com o seu contexto leva mais tempo para
escrever do que uma tarefa. Autonomia alinhada é a mesma troca na escala do trimestre de um time.
Custa tempo da gestora no começo, explicando o problema até o time conseguir explicá-lo de volta, e
economiza toda semana depois, porque o time para de precisar de decisões da gestora sobre o como.

## O trimestre do Agenda

O primeiro trimestre inteiro da Renata mostra a diferença. A liderança da Caju queria menos
consultas perdidas, porque as clínicas perdem dinheiro a cada paciente que marca e não aparece. A
primeira versão do objetivo do Agenda, vinda do Otávio, era uma lista: construir confirmação de mão
dupla por mensagem, acrescentar uma lista de espera, mandar um segundo lembrete na véspera.

Isso é alinhamento alto e autonomia baixa. Diz ao time qual é a solução. A Renata pediu ao Otávio o
problema, e voltou ao time com isto:

> Neste trimestre, a Caju quer que as clínicas que usam o nosso produto percam menos consultas por
> falta do paciente. Hoje cerca de uma consulta em nove é uma falta, medida no último trimestre. As
> clínicas que nos contaram o motivo dizem que a maioria desses pacientes esqueceu, ou não pôde ir e
> não sabia como cancelar. O objetivo é baixar essa taxa, e saber quanto. As ideias do Otávio são
> confirmação por mensagem, lista de espera e um segundo lembrete. São ideias, não um plano.

O time olhou os dados e descobriu que a maioria das faltas vinha de consultas marcadas com mais de
três semanas de antecedência, coisa que nenhuma das três ideias atacava especificamente. Eles
puseram primeiro um link fácil de cancelamento no lembrete que já existia, porque um horário
cancelado pode ser dado a outra pessoa e um horário esquecido não. Duas das três ideias do Otávio
foram ao ar mais tarde no trimestre. A terceira foi descartada, com um motivo, por escrito.

## O que o alinhamento pede da gestão

O canto em que o time quer estar tem um preço, e a gestão paga a maior parte. Quatro coisas precisam
ser verdade antes que um time possa receber o "como":

1. **O objetivo está declarado como um problema e uma medida**, do jeito que um resultado estava na
   aula 3.
2. **O time sabe por que importa** para a empresa, em números se houver números.
3. **Os limites estão explícitos**: o que não pode mudar, quanto pode custar e até quando.
4. **Existe um jeito de saber** se o trabalho está mexendo na medida.

Se qualquer uma das quatro faltar, um time com autonomia fica à deriva, e a reação habitual é tirar
a autonomia. A próxima seção trata de por que essa reação piora o problema.
