---
title: O que um evento de mudança diz
version: 1
---

**Toda mensagem que o Debezium grava é um envelope: a linha antes, a linha depois, o que aconteceu,
e onde no banco aconteceu.** As primeiras mensagens de `pf.public.stock` nem são mudanças. Quando um
conector sobe com um slot vazio, ele tira um **snapshot**: lê toda linha que as tabelas publicadas
têm, numa transação consistente, e grava cada uma como evento, para que um leitor do tópico comece
com a tabela inteira e não só com o que mudar daqui em diante. Leia a primeira, e deixe o `jq`
organizá-la:

@@fence@@

Os campos, de cima para baixo:

| campo | o que guarda |
|---|---|
| `before` | a linha como era; `null` aqui, porque um snapshot não tem nada antes |
| `after` | a linha como é agora: o Recife tem três exemplares do `bk-01` |
| `source` | de onde veio: a versão do conector, o banco, o schema e a tabela, o id da transação e o **LSN**, a posição dela no WAL |
| `source.snapshot` | `first_in_data_collection` na primeira linha do snapshot de uma tabela, `true` nas demais, `last` na última de todas, e `false` em tudo o que vem depois |
| `op` | o que aconteceu: `r` para uma leitura de snapshot, `c` criação, `u` atualização, `d` remoção |
| `ts_ms` | quando o Debezium o processou, em milissegundos desde 1970; `source.ts_ms` é quando o banco o fez |

**Os dois `ts_ms` são o tempo do evento e o tempo de processamento**, os dois relógios da lição 9,
um dentro do outro. A diferença entre eles é o quanto o conector está atrasado. Os valores na sua
máquina são outros, assim como `txId` e `lsn`, e nada nesta lição depende deles.

## A chave

O valor da mensagem é o envelope. A **chave** é a chave primária da linha, sozinha:

@@fence@@

Tudo o que acontecer com o `bk-01` do Recife tem essa chave, então vai para a mesma partição e é lido
na ordem em que foi confirmado. Um consumidor que guarda o `after` mais recente de cada chave tem
uma cópia da tabela; é a dualidade tabela–stream da lição 2, com o PostgreSQL no papel da tabela.

## Uma mudança enquanto acontece

O snapshot é história. Agora faça uma mudança e veja-a chegar. Um livro novo entra no catálogo:

@@fence@@

A `books` tinha oito linhas, então o snapshot dela ocupou os offsets 0 a 7 e o insert é o offset 8.
Leia essa mensagem, e só os campos que importam aqui:

@@fence@@

O `op` é `c`, o `before` é `null` porque a linha não existia, e o `after` é a linha como foi
inserida. **Nada no código do site menciona o Kafka**, e nada precisa mencionar: o `INSERT` podia
ter vindo de uma migração, de uma pessoa num prompt do `psql` ou de um programa escrito dez anos
atrás, e estaria no tópico do mesmo jeito. É a escrita dupla resolvida — há uma escrita, e o evento
é derivado do próprio registro que o banco faz dela.

Repare no preço, que é `cents` como inteiro. O conversor JSON grava o que o `integer` do PostgreSQL
guarda. Uma coluna `numeric` chegaria, por padrão, como uma string de bytes em base64, o jeito do
Debezium de manter a precisão exata; o `decimal.handling.mode` do conector pode transformá-la numa
string ou num double. **É a primeira coisa a conferir quando uma coluna parece lixo no tópico**, e o
motivo de o dinheiro neste curso ser sempre centavos inteiros.
