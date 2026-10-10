---
title: Um programa cuja regra ninguém escreveu
version: 1
---

Quase todo mundo chega a este curso pensando num modelo como um programa esperto. **Ele está mais
perto de uma tabela de números que um programa preencheu lendo exemplos.** O programa que os lê é
comum e de outra pessoa, quase sempre uma biblioteca; o que torna o resultado útil é quais exemplos
ele leu, e essa é a parte que pertence ao engenheiro de dados.

Pegue a pergunta que este curso carrega do começo ao fim. A Ponto Final, a rede de livrarias de
`warehouse-modeling` e `pipelines-etl`, tem um cartão de fidelidade. O time de marketing quer mandar
um voucher para os membros do cartão que estão prestes a parar de vir, antes que parem. Alguém
precisa dizer, para cada membro, qual a chance disso.

Há duas formas de responder, e a diferença entre elas é o assunto inteiro.

**Uma regra escrita por uma pessoa.** *Um membro que não aparece há 120 dias se afastou.* É uma
linha de SQL, todo mundo consegue ler, e ela erra nas duas direções: marca o membro que compra duas
vezes por ano e está bem, e deixa passar o membro que vinha toda semana até um mês atrás.

**Uma regra aprendida com exemplos.** Pegue os membros como estavam num dia do ano passado, descreva
cada um em números (quantos dias desde a última visita, quantas visitas, quanto gastou) e escreva ao
lado de cada um o que de fato aconteceu depois: voltou, ou não voltou. Um algoritmo de aprendizado lê
essas linhas e encontra os pesos que melhor separam os dois desfechos. O que ele produz é um
**modelo**: dados os números de um membro hoje, ele devolve uma probabilidade.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-rule-or-model\" aria-label=\"Duas formas de decidir se um membro se afastou. Em cima, uma regra que uma pessoa escreveu: um membro de hoje passa pela regra recency_days &gt; 120 e sai sim ou não. Embaixo, uma regra aprendida: os membros do ano passado, cada um com atributos e um rótulo conhecido, são lidos pelo treino, que produz um modelo; um membro de hoje passa pelo modelo e sai com uma probabilidade, 0,86.\"><defs><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">escrita por uma pessoa</text><rect x=\"40.0\" y=\"44.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">um membro hoje</text><rect x=\"280.0\" y=\"44.0\" width=\"180.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">uma regra</text><text x=\"370.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">recency_days &gt; 120</text><path d=\"M190.0 69.0 L278.0 69.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M460.0 69.0 L548.0 69.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"550.0\" y=\"50.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sim ou não</text><path d=\"M20.0 128.0 L700.0 128.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"20.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">aprendida com exemplos</text><rect x=\"40.0\" y=\"174.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">membros do ano passado</text><path d=\"M40.0 202.0 L240.0 202.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"105.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">atributos</text><text x=\"205.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">rótulo</text><path d=\"M170.0 202.0 L170.0 294.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"105.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4  4  33940</text><text x=\"205.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0</text><text x=\"105.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">105  1  4990</text><text x=\"205.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1</text><text x=\"105.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30  6  76870</text><text x=\"205.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0</text><path d=\"M240.0 234.0 L318.0 234.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><text x=\"279.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">treino</text><rect x=\"320.0\" y=\"204.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">um modelo</text><text x=\"400.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um peso por atributo</text><rect x=\"330.0\" y=\"300.0\" width=\"140.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um membro hoje</text><path d=\"M400.0 300.0 L400.0 266.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M480.0 234.0 L548.0 234.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"550.0\" y=\"215.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">p = 0,86</text></svg>", "caption": "A mesma pergunta respondida de duas formas. A regra é uma linha que qualquer um lê; o modelo é uma tabela de pesos que ninguém escreveu, e o que ele aprendeu depende de quais linhas lhe foram mostradas."}
```

Três palavras aparecem em todas as lições daqui em diante, então vale fixá-las agora:

- um **atributo** (*feature*) é um dos números que descrevem um exemplo: `recency_days`,
  `visits_180d`;
- um **rótulo** (*label*) é a resposta escrita ao lado de um exemplo, aqui `lapsed`, 1 ou 0;
- **treino** é o algoritmo lendo os exemplos e ajustando o modelo; **predição**, ou **inferência**,
  é o modelo respondendo sobre um exemplo que ele não viu.

## Onde fica o engenheiro de dados

Quem modela escolhe o algoritmo e julga o resultado. Tudo o que vem antes e depois disso é da
plataforma: **quais linhas viram exemplos, como cada atributo é calculado, como o rótulo é anexado
sem vazar o futuro para o passado, onde o modelo treinado fica guardado, como ele chega ao lugar que
lhe faz perguntas e como alguém descobre quando ele deixa de acertar.** Isso é a maior parte do
trabalho, e é a parte que quebra em produção.

Por isso este curso fica do lado do engenheiro de dados. As lições 1 a 4 dão o vocabulário que quem
modela vai usar com você: os tipos de aprendizado, as tarefas comuns, como os dados são divididos
para que uma nota signifique alguma coisa, e quais notas mentem. As lições 5 a 10 são o ciclo de
vida em si: o seu papel nele, atributos que podem ser reproduzidos, versões de dados e de modelos,
publicação, monitoramento, e o que fazer quando o mundo de onde o modelo aprendeu se move.

**Este não é um curso de estatística.** Os algoritmos vêm do scikit-learn, do mesmo jeito que um
motor de banco de dados vem do PostgreSQL: você precisa saber o que eles prometem e onde quebram, não
como escrever um.
