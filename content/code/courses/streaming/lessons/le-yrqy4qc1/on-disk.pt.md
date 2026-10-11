---
title: Como uma partição aparece no disco
version: 1
---

**Uma partição é um diretório, e o log dentro dele é uma fileira de arquivos chamados segmentos.**
Cada segmento guarda uma sequência de offsets consecutivos, e só o último, o **segmento ativo**, recebe
escritas. Quando ele chega ao limite de tamanho ou de idade, o Kafka o fecha e abre um novo. Todo o
resto desta lição, de achar um offset depressa a apagar dados antigos, funciona um segmento de cada
vez.

O diretório tem o nome do tópico e da partição. A partição 1 de `sales`, que tem a maior parte das mil
vendas:

@@fence@@

Um segmento só, por enquanto, então três arquivos dividem um nome, e o nome é o **offset base** do
segmento, o primeiro offset dele, completado até vinte dígitos:

- **`.log`** guarda as próprias mensagens, uma depois da outra, como chegaram: 106 916 bytes para 789
  vendas, cerca de 135 bytes cada.
- **`.index`** mapeia offsets para posições em bytes no `.log`, para que um leitor que pede o offset
  500 não precise ler desde o começo, que era o problema do `minilog.py` na lição 2. Ele aparece com
  10 485 760 bytes porque o Kafka dá ao índice do segmento ativo o tamanho inteiro de antemão, e o
  corta para o que ele guarda quando o segmento é fechado.
- **`.timeindex`** mapeia horários para offsets, para um leitor que pede *das 10 horas em diante*, o
  que a lição 4 faz.
- `partition.metadata` guarda o id do tópico, e `leader-epoch-checkpoint` registra qual líder escreveu
  qual faixa de offsets, o que importa quando há réplicas (lição 5).

## Dentro do .log

O `kafka-dump-log.sh` lê um segmento e o imprime. Com `--print-data-log` ele mostra também a chave e o
valor de cada mensagem:

@@fence@@

As duas primeiras linhas dão o nome do arquivo e o primeiro offset dele. A terceira não é uma
mensagem: é um **lote**, `baseOffset: 0 lastOffset: 760 count: 761`, que diz que 761 mensagens
chegaram juntas, como um lote do produtor, e são guardadas juntas. **O Kafka guarda o que o produtor
mandou, um lote de cada vez**, sem desmontá-lo, e isso explica boa parte da velocidade dele. Os campos
`producerId: -1` e `isTransactional: false` estão vazios aqui e são preenchidos nas lições 7 e 8.
Depois vêm as mensagens: cada uma com o seu offset, o seu `CreateTime` (a hora em que o produtor a
criou, em milissegundos desde 1970, não o `at` da própria venda, uma diferença de que trata a lição
9), a sua chave e o seu valor.

## Dentro do .index

@@fence@@

Uma entrada: o lote que termina no offset 788 começa no byte 103 095 do `.log`. **O índice é
esparso**: o Kafka só acrescenta uma entrada depois de passarem uns 4 096 bytes de mensagens
(`index.interval.bytes`), e uma entrada sempre aponta para o começo de um lote, então um lote de 761
mensagens não ganha nenhuma só dele. Para achar o offset 500, o leitor pega a entrada mais próxima
igual ou abaixo dele, aqui nenhuma, então o começo do arquivo, e lê para a frente a partir dali. Num
segmento de um gibibyte as entradas são milhares, e achar um offset é uma busca binária no índice e
uma leitura curta no log.
