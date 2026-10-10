---
title: O log, em vinte linhas de Python
version: 1
---

**Um log é uma sequência de registros que só cresce por uma ponta.** Cada registro recebe um
número, o seu **offset**, que é a sua posição contando a partir de zero, e fica com ele enquanto
existir. Ninguém insere no meio, ninguém edita, e ler um registro não o remove. Essa é a estrutura
de dados inteira, e é sobre ela que o Kafka é construído.

A palavra engana em duas direções. Para um programador, *log* é o texto que um servidor escreve
sobre si mesmo, o `server.log`, em que alguém dá grep quando algo dá errado. Para muita gente que já
usou brokers de mensagens, um stream é uma **fila**: a mensagem é entregue a um leitor e some. O log
desta lição não é nenhum dos dois. Ele é o próprio dado, guardado em ordem, e qualquer número de
leitores pode percorrê-lo, cada um no seu lugar.

@@fig:l2-log-readers@@

## Um log que se lê de uma sentada

O log do Kafka é espalhado por máquinas e discos, com índices e réplicas, que as lições 3 e 5 abrem.
A ideia cabe num arquivo. Salve isto como `~/work/minilog.py`:

```schooling-example
@same
--- O que ele faz. Um registro é uma linha de texto, e **o offset dele é o número da linha**, contando a partir de zero.
--- Anexar abre o arquivo no modo `"a"`, que **só consegue escrever no fim**: o sistema operacional não deixa esta função inserir nem sobrescrever. Depois ela conta as linhas para saber o offset do registro novo.
--- Ler começa num offset e vai até o fim. Não muda nada no arquivo, então dois leitores não conseguem atrapalhar um ao outro.
--- A linha de comando. `append` acrescenta um registro.
--- `read` é onde entram os leitores. **O lugar de cada leitor é um arquivo próprio** ao lado do log, com o offset do próximo registro que ele ainda não viu. O log nunca fica sabendo quem leu o quê.
```

Anexe três vendas. Cada `append` imprime o offset que o registro recebeu:

@@fence@@

Agora leia como o sistema de estoque, duas vezes:

@@fence@@

A segunda leitura não imprime nada, porque o leitor do estoque já viu tudo o que existe. **Não é
porque os registros sumiram.** Acrescente uma quarta venda, e leia como o sistema de estoque e
depois como um programa de fidelidade que nunca leu nada:

@@fence@@

O leitor do estoque recebeu só o registro novo; o de fidelidade recebeu os quatro, desde o offset 0.
Os dois leram o mesmo arquivo, e nenhum sabia que o outro existia. Os lugares deles são dois
arquivinhos ao lado do log:

@@fence@@

Cada um guarda o offset do próximo registro que aquele leitor vai pedir. Os dois dizem 4, porque os
dois já leram até o fim, e o último registro do log é o offset 3.

## O que o Kafka acrescenta à mesma ideia

Tudo o que está acima existe no Kafka, com outros nomes: um log é uma **partição**, o lugar de um
leitor é um **offset commitado**, e o leitor é um **consumer group**. O que o `minilog.py` faz mal é
justamente o que o Kafka foi construído para fazer bem, e cada falha é uma lição mais adiante:

| o que o minilog.py faz | o que dá errado | onde o Kafka responde |
|---|---|---|
| conta todas as linhas para achar um offset | ler a partir do offset 1 000 000 lê um milhão de linhas antes | um índice ao lado de cada arquivo, lição 3 |
| guarda todo registro para sempre | o disco enche | retenção e compactação, lição 3 |
| um arquivo num disco | o disco morre e o log junto | réplicas em outras máquinas, lição 5 |
| grava o lugar do leitor depois de imprimir | uma queda no meio imprime alguns registros duas vezes | commit de offsets, lições 4 e 7 |

Vale olhar a última linha de novo antes que a lição 7 faça dela o assunto. Se o programa caísse
depois de imprimir o registro 3 e antes de gravar o arquivo de lugar, a próxima execução começaria
do lugar antigo e imprimiria o registro 3 de novo. **Onde um leitor anota o seu lugar, em relação a
quando faz o trabalho, decide o que uma queda custa**, e nenhum log pode decidir isso pelo leitor.
