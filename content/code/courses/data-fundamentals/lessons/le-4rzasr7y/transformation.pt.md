---
title: Transformação: limpar, juntar e contar, e onde isso roda
version: 1
---

**A transformação converte linhas que descrevem o que um sistema fez em linhas que respondem a uma
pergunta, e quase tudo nela são três operações: limpar, juntar e agregar.** A tabela de viagens do
aplicativo diz que a bicicleta B014 saiu da ST10 às 06:01. A pergunta de Marta é quantas viagens cada
estação teve na segunda. Entre as duas coisas, o programa desta aula faz exatamente três operações.

| operação | o que ela faz | no programa desta aula |
|---|---|---|
| **limpar** | tirar ou consertar linhas que não querem dizer o que a pergunta quer dizer | uma viagem de menos de 2 minutos é uma **partida falsa** — uma bicicleta destravada e devolvida na hora — e sai |
| **juntar** | trazer o que outra tabela sabe | cada viagem ganha o nome da sua estação, buscado pelo `station_id` na tabela de estações |
| **agregar** | muitas linhas viram uma por grupo | uma linha por estação: quantas viagens, e quantos minutos |

Existem outras operações, e todas são variações dessas três: remover duplicatas é limpar, pôr todo
horário num só relógio é limpar, uma tabela de estações por bairro é uma junção. `data-cleaning` é o
curso que leva a primeira a sério, e `sql-databases` ensina a linguagem em que a maioria das
transformações é escrita.

## Uma regra é uma decisão, e fica escrita

"Menos de 2 minutos é partida falsa" não é um fato sobre viagens. É uma decisão que Marta e o time de
dados tomaram, e outro limite dá outro número no relatório. **O valor de pôr isso numa transformação
é que a regra fica escrita uma vez, em código, e é aplicada do mesmo jeito a todos os dias.** O
engenheiro de analytics da aula 1 existe exatamente para isso: uma definição, num lugar só, em vez de
uma por planilha.

É também por isso que uma transformação é escrita para ser **reconstruível**. Com os mesmos arquivos
brutos, ela produz os mesmos arquivos limpos e curados, byte a byte, quantas vezes rodar. O programa
desta aula sobrescreve a saída toda vez em vez de acrescentar a ela, e a seção 09 mostra
por que isso é metade do trabalho, e não ele todo.

## ETL ou ELT: onde o T roda

A aula 1 apresentou as duas ordens que a profissão já usou, e a diferença merece mais um olhar agora
que existe um pipeline para pô-la em cima.

- **ETL** — extrair, transformar, carregar. O dado é transformado no caminho, por um programa ou
  servidor à parte, e só o resultado é carregado no warehouse. As linhas não transformadas não ficam
  lá. Era a norma quando armazenamento e processamento no warehouse eram caros.
- **ELT** — extrair, carregar, transformar. As linhas brutas são carregadas primeiro, e a
  transformação roda depois, dentro do warehouse, em geral em SQL. Ferramentas como o dbt existem
  para organizar essas transformações em SQL. Virou a norma quando guardar tudo barato se tornou
  possível.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"ETL: as linhas vão da origem para uma transformação num servidor próprio, e só o resultado é carregado no warehouse. ELT: as linhas vão da origem para o warehouse, brutas, e a transformação roda dentro do warehouse, gravando o resultado ao lado.\" data-fig=\"etl-elt\"><defs><marker id=\"etl-elt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"14\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">ETL: transformado no caminho</text><rect x=\"14\" y=\"34\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"74.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a origem</text><line x1=\"134\" y1=\"59\" x2=\"172\" y2=\"59\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#etl-elt-ah)\"></line><rect x=\"174\" y=\"34\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"249.0\" y=\"51.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">transformar</text><text x=\"249.0\" y=\"66.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">num servidor próprio</text><line x1=\"324\" y1=\"59\" x2=\"554\" y2=\"59\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#etl-elt-ah)\"></line><rect x=\"364\" y=\"26\" width=\"342\" height=\"76\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"376\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">linhas brutas não ficam aqui</text><text x=\"376\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">o warehouse</text><rect x=\"556\" y=\"34\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"626.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o resultado</text><text x=\"14\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">ELT: carregado bruto, transformado dentro</text><rect x=\"14\" y=\"148\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"74.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a origem</text><line x1=\"134\" y1=\"173\" x2=\"182\" y2=\"173\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#etl-elt-ah)\"></line><rect x=\"164\" y=\"140\" width=\"542\" height=\"86\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"184\" y=\"148\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"244.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">linhas brutas</text><line x1=\"304\" y1=\"173\" x2=\"342\" y2=\"173\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#etl-elt-ah)\"></line><rect x=\"344\" y=\"148\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"419.0\" y=\"165.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">transformar</text><text x=\"419.0\" y=\"180.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">em geral em SQL</text><line x1=\"494\" y1=\"173\" x2=\"554\" y2=\"173\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#etl-elt-ah)\"></line><rect x=\"556\" y=\"148\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"626.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o resultado</text><text x=\"176\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">o warehouse</text></svg>", "caption": "O mesmo extrair, transformar e carregar em duas ordens. O que muda é onde a transformação roda, e se as linhas brutas ficam no warehouse ao lado do resultado."}
```

Uma leitura errada comum é que ELT quer dizer menos transformação, ou que ETL ficou obsoleto. Os dois
transformam a mesma quantidade; a diferença está em **onde a transformação roda, e se as linhas
brutas ficam guardadas ao lado do resultado**. Muitas empresas usam os dois: ELT para a maioria das
tabelas, e uma transformação na entrada onde as linhas brutas não podem ficar — um número de telefone
removido antes de ser guardado, por exemplo.

O pipeline desta aula pousa o bruto primeiro e transforma depois, que é a ordem do ELT, embora o
"warehouse" dele sejam três diretórios e a transformação seja em Python. Construir a coisa de
verdade, com um agendador e um warehouse, é `pipelines-etl`.
