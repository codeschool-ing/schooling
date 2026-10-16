---
title: Cinco etapas, e o que corre por baixo delas
version: 1
---

**Todo número de um relatório tem uma história, e a história tem cinco etapas: o dado foi gerado,
ingerido, armazenado, transformado e entregue.** Pegue uma viagem. Um cliente destrava a bicicleta
B014 no Batel às 06:01 da segunda-feira, 15 de setembro, e a devolve no Passeio Público 44 minutos
depois. O aplicativo grava uma linha para cobrar a viagem. À noite, um programa copia as viagens do
dia para fora do aplicativo; a cópia é guardada; outro programa limpa as viagens, acrescenta o nome
de cada estação e conta; e na terça de manhã Marta lê quantas viagens o Batel teve. Cinco etapas,
cinco lugares onde a viagem podia ter se perdido, sido contada duas vezes ou virado algo que nunca
foi.

A imagem errada mais comum é a de uma esteira: o dado entra pela esquerda, anda uma vez para a
direita, e o trabalho acabou. Há três coisas erradas nela.

- **Ela roda todo dia, não uma vez.** As viagens de segunda passam enquanto as de domingo estão sendo
  lidas e as de terça estão sendo geradas. Uma etapa que falha num dia tem de ser consertada sem
  parar as outras.
- **Ela roda mais de uma vez sobre o mesmo dia.** Uma cópia é repetida, um erro numa transformação é
  corrigido e o mês é reconstruído. Se rodar uma etapa de novo muda a resposta é o assunto da seção
  09 desta aula.
- **O armazenamento não é uma estação da esteira.** Todas as outras etapas leem dele ou escrevem nele,
  então ele fica melhor desenhado como o chão embaixo delas.

## As cinco, numa tabela

| etapa | a pergunta que ela responde | na Roda Livre |
|---|---|---|
| **geração** | onde o dado nasce, e para que aquele sistema foi feito? | o aplicativo grava uma linha por viagem, para cobrar o cliente |
| **ingestão** | como uma cópia sai, e com que frequência? | toda noite, um dia de viagens é copiado do banco do aplicativo |
| **armazenamento** | onde fica cada cópia, e em que estado? | a cópia como chegou, uma cópia limpa, e as contagens |
| **transformação** | o que transforma linhas que um sistema gravou em linhas que uma pessoa usa? | tirar partidas falsas, acrescentar nomes de estação, contar por estação |
| **entrega** | quem lê o resultado, e em que forma? | o relatório da manhã de Marta; depois um painel e o modelo de Caio |

A figura desenha as mesmas cinco com o armazenamento onde ele pertence, embaixo das outras, e com o
que corre por baixo de todas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Geração: o aplicativo grava uma linha por viagem. A ingestão copia um dia por noite para a zona bruta do armazenamento. A transformação lê o bruto e grava as zonas limpa e curada. A entrega lê o curado e produz o relatório da manhã. Embaixo de tudo, as correntes subjacentes: segurança, gestão de dados, DataOps, arquitetura, orquestração e engenharia de software.\" data-fig=\"lifecycle\"><defs><marker id=\"lifecycle-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"30\" width=\"152\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">geração</text><text x=\"90.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o aplicativo grava</text><text x=\"90.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma linha por viagem</text><rect x=\"194\" y=\"30\" width=\"152\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">ingestão</text><text x=\"270.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um dia copiado</text><text x=\"270.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a cada noite</text><rect x=\"374\" y=\"30\" width=\"152\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">transformação</text><text x=\"450.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">limpar, juntar,</text><text x=\"450.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">contar</text><rect x=\"554\" y=\"30\" width=\"152\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">entrega</text><text x=\"630.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o relatório</text><text x=\"630.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">da manhã</text><line x1=\"166\" y1=\"67\" x2=\"192\" y2=\"67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><rect x=\"180\" y=\"136\" width=\"528\" height=\"98\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"194\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">armazenamento: toda etapa lê e grava aqui</text><rect x=\"214\" y=\"148\" width=\"120\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">bruto</text><text x=\"274\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">raw/</text><rect x=\"394\" y=\"148\" width=\"120\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"454\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">limpo</text><text x=\"454\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">clean/</text><rect x=\"574\" y=\"148\" width=\"120\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"634\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">curado</text><text x=\"634\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curated/</text><line x1=\"270\" y1=\"104\" x2=\"270\" y2=\"146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><line x1=\"334\" y1=\"160\" x2=\"410\" y2=\"106\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><line x1=\"454\" y1=\"104\" x2=\"454\" y2=\"146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><line x1=\"514\" y1=\"175\" x2=\"572\" y2=\"175\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><line x1=\"634\" y1=\"148\" x2=\"634\" y2=\"106\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><rect x=\"14\" y=\"254\" width=\"694\" height=\"62\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"361\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">as correntes subjacentes</text><text x=\"361\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">segurança · gestão de dados · DataOps · arquitetura · orquestração · engenharia de software</text></svg>", "caption": "O ciclo de vida na Roda Livre. O armazenamento fica embaixo das outras etapas porque todas leem dele ou escrevem nele, e as correntes subjacentes valem para as cinco."}
```

## De onde vem a imagem

O ciclo de vida desenhado assim é de Joe Reis e Matt Housley, do livro *Fundamentals of Data
Engineering* (2022). Eles chamam a última etapa de **serving**, onde este curso diz entrega, e põem o
armazenamento em segundo lugar, porque o dado já está guardado no momento em que é gerado, antes de
alguém copiá-lo. Este curso segue a ordem em que uma viagem é tratada na Roda Livre. De um jeito ou
de outro, as cinco palavras são o vocabulário que o resto da trilha `data` supõe.

Embaixo das etapas eles desenham o que chamam de **undercurrents**, as correntes subjacentes:
segurança, gestão de dados, DataOps, arquitetura de dados, orquestração e engenharia de software. Não
são etapas pelas quais uma viagem passa. São preocupações que valem para todas as etapas ao mesmo
tempo — quem pode ler a cópia bruta, o que as colunas significam, como uma falha é percebida, o que
roda cada programa às 02:00. A aula 2 trata delas uma por uma; esta aula as deixa no canto da figura
e percorre as etapas.

**O resto da aula tem uma seção por etapa, e depois constrói as cinco como quatro programas
pequenos** que você roda na sua máquina, na seção 08.
