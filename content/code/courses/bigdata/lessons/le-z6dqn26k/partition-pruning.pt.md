---
title: Poda de partições
version: 1
---

**Um filtro sobre uma coluna de partição é respondido pelos nomes dos diretórios, antes de qualquer
arquivo ser aberto.** A camada silver está organizada como a aula 3 descreveu, um diretório por dia,
então `day = '2025-03-14'` nomeia exatamente um diretório. O planejador transforma o filtro em
`PartitionFilters` no scan, a listagem pula 364 diretórios, e um arquivo é lido: o segundo scan da
seção anterior.

Os números do `pruning.py`, lado a lado:

| | arquivos abertos | linhas entregues |
|---|---|---|
| todos os dias | 365 | 24.000.000 |
| um dia | 1 | 65.753 |

**Essa é a otimização mais barata que existe**, e quem decide é a organização, não a consulta. A
regra de bolso da aula 3, particionar pelo que as consultas filtram, é o motivo: uma consulta sobre
os cliques que cita um período lê só aquele período, e nada mais nesta aula economiza tanto.

Duas coisas a fazem falhar em silêncio:

- **Um filtro sobre outra coluna que não a de partição.** O `ts` guarda a mesma informação que o
  `day`, até o segundo, mas um filtro sobre `ts` entre dois horários não é um filtro sobre `day`, e o
  planejador não sabe que um implica o outro. Todo diretório é aberto. Filtre em `day`, ou nos dois.
- **Uma função que o planejador não enxerga**, que é o exemplo da próxima seção, e o jeito mais caro
  de escrever uma consulta correta nesta aula.
