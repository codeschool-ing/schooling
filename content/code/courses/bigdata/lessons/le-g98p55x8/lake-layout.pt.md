---
title: Organizando um data lake
version: 1
---

**Um *data lake* são arquivos num sistema de arquivos distribuído ou num object store, organizados
para que os programas achem o que precisam sem ler tudo.** Não há motor no comando, ao contrário de
um warehouse: a organização é o único índice que existe, então a organização é o projeto.

A convenção que todo motor entende é a que o `generate.py` usou na aula 1:

```
data/raw/clicks/day=2025-01-01/part-00006-….csv.gz
data/raw/clicks/day=2025-01-02/part-00041-….csv.gz
…
```

**Um diretório chamado `coluna=valor` é uma *partição***, no sentido que o Hive deu à palavra, e a
aula 12 apresenta o Hive: todo arquivo sob ele tem aquele valor naquela coluna, e a coluna nem é
guardada nos arquivos. O job Spark da aula 1 leu o diretório e achou uma coluna `day` que nenhum
arquivo contém. Uma consulta que pede um dia pode então pular 364 diretórios sem abri-los, e a aula
6 mostra o Spark fazendo isso.

Três decisões fazem ou desfazem um lake, e cada uma tem uma regra de bolso:

- **Particione pelo que as consultas filtram, e por algo com poucos valores.** O dia é o clássico:
  um ano tem 365, e quase toda pergunta sobre cliques cita um período. Particionar por visitante
  daria dois milhões de diretórios de arquivos minúsculos, o problema dos arquivos pequenos com um
  diretório para cada.
- **Mire em arquivos de centenas de megabytes**, alguns blocos cada no HDFS. Menos que isso traz o
  custo da seção 07; muito mais traz uma tarefa por arquivo que demora demais e não pode ser
  dividida se o arquivo for compactado inteiro, como um gzip.
- **Mantenha as camadas separadas.** A maioria dos lakes guarda os dados como chegaram (*raw*, ou
  *bronze*), os mesmos dados limpos e tipados (*silver*) e tabelas feitas para perguntas (*gold*). A
  camada raw nunca é editada, então qualquer erro adiante pode ser refeito a partir dela. O
  `~/big/data/raw` é essa camada, e a aula 10 escreve a seguinte.

**O que um lake não tem, por construção, é algo que impeça dois escritores de colidir**, ou um
leitor de ver uma partição meio escrita, ou um esquema de mudar arquivo a arquivo. Isso era o que um
warehouse dava de graça. Os formatos de tabela abertos da aula 11 devolvem essas garantias por cima
de arquivos comuns, e é por isso que a palavra *lakehouse* existe.
