---
title: O estado é a soma do log
version: 1
---

**O estado atual de qualquer coisa é o resultado de aplicar os seus eventos, em ordem, a um começo
vazio.** O estoque de um livro numa loja é a última contagem, mais toda entrega desde então, menos
toda venda desde então. Um programa que guarda esse número numa tabela está guardando uma resposta
corrente a uma pergunta que ele sempre poderia responder de novo a partir do log. Programadores
funcionais chamam isso de **fold**: percorrer uma lista carregando um valor, e mudar o valor a cada
elemento.

A Ponto Final conta as prateleiras antes de as lojas abrirem. Esta é a manhã no Recife e em Olinda
para um livro, em eventos. Salve como `~/work/stock.log`:

@@fence@@

Cada linha é um evento, exatamente o formato que o `minilog.py` escreve, então este arquivo é um log
que o código da seção anterior consegue ler. Três tipos de evento: uma **contagem** diz quantos
exemplares há na prateleira, uma **entrega** acrescenta exemplares e uma **venda** os tira.

O programa que faz o fold lê o log com o próprio `read` do `minilog.py`, então mantenha os dois
arquivos em `~/work`. Salve isto como `~/work/balance.py`:

```schooling-example
@same
--- `read` vem importado do arquivo da seção anterior, então este programa lê o log exatamente como qualquer outro leitor.
--- **Um evento, uma mudança.** Uma contagem substitui o número; uma entrega e uma venda o movem. A chave é o par loja e livro, então os exemplares do Recife e os de Olinda são linhas separadas.
--- O fold: uma tabela vazia, todo evento desde o offset 0, e com `--trace` a linha que cada evento mudou, como ficou depois da mudança.
--- A tabela no fim: uma linha por loja e livro.
```

Rode:

@@fence@@

O Recife contou 4, vendeu 1, recebeu 6, vendeu 2 e vendeu 1, e tem 6. Olinda contou 2, vendeu 2 e
recebeu 3, e tem 3. Nada guardou esses dois números; eles foram calculados a partir dos oito eventos,
e vão ser calculados do mesmo jeito toda vez que o programa rodar.

## Uma tabela e um stream são duas vistas da mesma coisa

Agora peça o trace:

@@fence@@

Cada linha do trace é uma mudança na tabela: no offset 4, a linha `recife bk-03` virou 9. Leia o
trace de cima a baixo e você tem **um stream de mudanças**; fique só com a última linha de cada chave
e você tem **a tabela**. É a ideia que o pessoal chama de **dualidade stream–tabela**, e ela vale nos
dois sentidos:

- uma **tabela é um stream dobrado**: aplique as mudanças em ordem e fique com o valor mais recente
  de cada chave;
- um **stream é a história de uma tabela**: anote cada mudança da tabela, em ordem, e você tem um log
  a partir do qual a tabela pode ser reconstruída.

Os dois sentidos voltam mais adiante como ferramentas. O Kafka consegue manter num tópico só o
registro mais recente de cada chave, o que transforma um stream numa tabela em disco (lição 3,
compactação). O Kafka Streams chama um stream dobrado de `KTable` e o sustenta exatamente com um log
desses (lição 13). E a captura de dados de mudança lê o registro que o próprio banco faz das suas
mudanças e transforma as tabelas dele de volta em streams (lição 14).

## A tabela é um cache

**Se o log é guardado, a tabela pode ser jogada fora**, porque rodar o fold de novo a reconstrói.
Isso muda o preço de um bug. Um sistema de estoque que subtraía devoluções em vez de somá-las tem
uma tabela errada, e num sistema que só guardasse a tabela os números certos se perderam. Com o log,
a correção é consertar o `apply` e refazer o fold desde o offset 0.

O contrário não vale. A partir de `recife bk-03 6` ninguém consegue dizer se foi 4 − 1 + 6 − 2 − 1
ou uma contagem nova de 6, nem qual venda aconteceu quando. **Os eventos contêm o estado; o estado
não contém os eventos.** O preço disso é espaço, já que o log cresce a cada venda enquanto a tabela
continua com uma linha por livro, e a lição 3 é onde o Kafka decide quanto de um log guardar.
