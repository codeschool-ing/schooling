---
title: Duas funções e uma ordenação
version: 1
---

**MapReduce é um jeito de escrever um job distribuído como duas funções pequenas, com a parte
difícil feita entre elas pelo framework.** O Google o descreveu num artigo em 2004; o Hadoop foi a
versão de código aberto, e durante boa parte da década seguinte era isso que "big data" queria
dizer.

Quem programa escreve:

- **map**, que recebe um registro de entrada e emite quantos *pares chave-valor* quiser. Ele vê um
  registro por vez e não guarda memória entre eles.
- **reduce**, que recebe uma chave e todos os valores emitidos para ela, e emite o resultado dessa
  chave.

O framework faz todo o resto, e esse resto é o assunto deste curso:

1. Ele **divide a entrada** em pedaços, um por bloco do HDFS, e roda uma tarefa de map em cada um,
   numa máquina que guarda o bloco, quando possível.
2. Ele **particiona** a saída de cada tarefa de map pela chave, para que todo par com a mesma chave
   vá para a mesma tarefa de reduce, onde quer que tenha sido produzido.
3. Ele **ordena** a entrada de cada tarefa de reduce pela chave e entrega ao reducer os valores de
   uma chave por vez.
4. Ele **roda de novo** qualquer tarefa cuja máquina falhe, a partir da entrada, que continua no
   HDFS.

Os passos 2 e 3 juntos são o *shuffle*, a mesma palavra que a aula 1 deu à primeira passada do
`buckets.py`. O `buckets.py` era um programa MapReduce escrito à mão: a primeira passada mapeava
cada evento para um visitante e o mandava ao arquivo que a chave decidia, e a segunda reduzia cada
arquivo. O framework acrescenta a distribuição e a recuperação, e tira a necessidade de escrever
qualquer uma das duas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l04-mapreduce\" aria-label=\"O fluxo de um job MapReduce. Três fatias da entrada alimentam três tarefas de map. Cada tarefa de map escreve os pares em duas partições, uma por tarefa de reduce, escolhidas pela chave. Cada tarefa de reduce busca a sua partição em toda tarefa de map, ordena o que recebeu pela chave e roda a função de reduce em cada chave.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"90.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">fatia 0</text><path d=\"M110.0 52.0 L148.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"30.0\" width=\"110.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">map</text><path d=\"M260.0 52.0 L468.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M260.0 52.0 L468.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"100.0\" width=\"90.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">fatia 1</text><path d=\"M110.0 122.0 L148.0 122.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"100.0\" width=\"110.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">map</text><path d=\"M260.0 122.0 L468.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M260.0 122.0 L468.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"170.0\" width=\"90.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">fatia 2</text><path d=\"M110.0 192.0 L148.0 192.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"150.0\" y=\"170.0\" width=\"110.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">map</text><path d=\"M260.0 192.0 L468.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M260.0 192.0 L468.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"470.0\" y=\"50.0\" width=\"110.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">reduce</text><path d=\"M580.0 75.0 L618.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"620.0\" y=\"50.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"660.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">saída</text><rect x=\"470.0\" y=\"150.0\" width=\"110.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"525.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">reduce</text><path d=\"M580.0 175.0 L618.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"620.0\" y=\"150.0\" width=\"80.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"660.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">saída</text><text x=\"365.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shuffle: partição por chave, depois ordenação</text></svg>", "caption": "Quem programa escreve as duas funções; o framework divide, particiona, move, ordena e roda de novo.", "same": ["map", "reduce"]}
```

**A restrição é o propósito.** Um programa que só pode ser um map e um reduce não consegue guardar
estado global, não pode depender da ordem da entrada e não pode perguntar o que outra tarefa está
fazendo. Em troca, o framework pode rodar quantas cópias quiser de cada função, em qualquer lugar,
rodar qualquer uma de novo, e saber que a resposta será a mesma. Cada restrição é uma promessa de
que o framework precisa para escalar.
