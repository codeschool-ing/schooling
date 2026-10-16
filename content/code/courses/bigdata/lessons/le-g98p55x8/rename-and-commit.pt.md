---
title: Por que a falta do renomear importa
version: 1
---

**O Spark termina uma escrita com um renomear, e faz isso porque o HDFS torna o renomear barato e
atômico.** Cada tarefa escreve a sua saída num diretório temporário sob o destino. Quando a tarefa
dá certo, os arquivos dela são movidos para o lugar; quando o job inteiro dá certo, os do job são, e
o `_SUCCESS` da aula 1 aparece. Uma tarefa que falhou ou rodou duas vezes, como as da aula 2, deixa
os arquivos num diretório temporário que ninguém move, e eles são apagados. A saída que um leitor
vê é exatamente uma cópia do trabalho de cada tarefa, e aparece de uma vez.

Esse protocolo se chama *output committer*, e no HDFS ele quase não custa nada: cada movimento é uma
operação do namenode.

Num object store o mesmo protocolo roda, e cada um desses movimentos vira uma cópia de cada byte
seguida de um delete, requisição por requisição. Duas coisas dão errado:

- **É lento.** Um job que escreveu 10.000 arquivos gasta os últimos minutos copiando todos de novo,
  numa máquina só, depois que toda tarefa terminou. Os dados são escritos duas vezes.
- **Não é atômico.** No meio dos movimentos, metade dos arquivos está no lugar e metade não. Um
  leitor que lista o diretório nessa janela vê um resultado parcial e não tem como saber. Se o
  driver morre nessa janela, a única falha irrecuperável da aula 2, o resultado parcial fica.

Vale conhecer as curas pelo nome, porque você vai encontrá-las na configuração de um job:

- **Os committers do S3A**, que o conector do Hadoop oferece. Cada tarefa envia o arquivo em partes
  e deixa o envio inacabado; o commit do job termina todos os envios de uma vez, o que um object
  store faz com uma requisição por arquivo, sem copiar. Mais rápido, ainda que não atômico entre
  arquivos.
- **Um formato de tabela**, assunto da aula 11. Delta Lake, Iceberg e Hudi nunca renomeiam nada: uma
  escrita acrescenta arquivos novos com nomes novos, e então um único arquivo pequeno, o commit, diz
  que arquivos formam a tabela. Escrever esse arquivo é atômico em qualquer object store, então a
  tabela muda de uma vez. Esse é quase todo o motivo de os formatos de tabela existirem.

**O ponto a levar** é que "o mesmo código com `s3a://` em vez de `hdfs://`" vale para a leitura e
vale pela metade para a escrita. Um job levado do HDFS para um object store sem trocar o committer
roda, dá a resposta certa quase sempre, e é lento e às vezes errado de um jeito que nenhuma mensagem
de erro anuncia.
