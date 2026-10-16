---
title: ORC
version: 1
---

**O ORC é o outro formato colunar, nascido no projeto Hive em 2013, o mesmo ano do Parquet**, e
construído sobre as mesmas ideias: dados em pedaços de coluna, codificações leves, um rodapé com
estatísticas. Onde o Parquet tem row groups, o ORC tem *stripes*, de 64 MB por padrão; dentro de cada
stripe ele mantém um índice com o mínimo e o máximo de cada coluna a cada 10.000 linhas, então um
leitor pode pular com mais precisão que um stripe inteiro.

Na seção 04 o ORC saiu o menor dos sete, 6,1 MiB contra os 7,2 do melhor Parquet, e o Spark não
precisou de opção nenhuma para isso: a codificação por trechos de inteiros do ORC, que os seus
timestamps também usam, inclui deltas e está sempre ligada, e nesta versão do Spark o codec é o zstd.
Lê-lo de volta foi mais lento que os arquivos Parquet neste laboratório, 4,3 segundos contra cerca de
2.

**A escolha entre os dois raramente é sobre os bytes.** Os dois são abertos, os dois são lidos por
todo motor que importa, e qualquer um é muito melhor que CSV para análise. O que decide é o resto do
sistema:

- **O Parquet é o padrão do Spark e dos formatos de tabela abertos** da aula 11, e o formato que mais
  ferramentas fora do mundo Hadoop leem e gravam: pandas, DuckDB, Arrow, os warehouses na nuvem.
- **O ORC é o padrão do Hive**, e as tabelas transacionais do Hive o exigem. Um lake montado em volta
  do Hive nos anos 2010 costuma ser ORC do começo ao fim.

Os dois também suportam **bloom filters**, um resumo por row group que responde "este valor com
certeza não está aqui" para uma coluna cujo mínimo e máximo não dizem nada, como um id de visitante
em que todo row group tem ids de `v0000000` a `v1999999`. Eles são ligados por coluna na gravação,
custam espaço em todo arquivo, e só compensam em filtros de igualdade sobre colunas assim.
