---
title: Mudanças que reescrevem a tabela
version: 1
---

Depois que uma mudança tem a trava, o que importa é por quanto tempo ela a segura, e isso depende de
o PostgreSQL precisar tocar em toda linha. Um jeito simples de saber é o **filenode** da tabela, o
nome do arquivo no disco que guarda as linhas dela: uma mudança que reescreve a tabela grava um
arquivo novo, e o filenode muda.

Três mudanças, cada uma cronometrada, com o filenode conferido entre elas:

```
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT pg_relation_filenode('tickets')"
 pg_relation_filenode 
----------------------
                16395
(1 row)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ADD COLUMN printed boolean NOT NULL DEFAULT false'
Timing is on.
ALTER TABLE
Time: 2.125 ms
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT pg_relation_filenode('tickets')"
 pg_relation_filenode 
----------------------
                16395
(1 row)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ADD COLUMN printed_at timestamptz DEFAULT clock_timestamp()'
Timing is on.
ALTER TABLE
Time: 5405.595 ms (00:05.406)
ana@lab:~/tickets$ docker compose exec db psql -U tickets -c "SELECT pg_relation_filenode('tickets')"
 pg_relation_filenode 
----------------------
                16418
(1 row)

ana@lab:~/tickets$ docker compose exec db psql -U tickets -c '\timing on' -c 'ALTER TABLE tickets ALTER COLUMN seat TYPE bigint'
Timing is on.
ALTER TABLE
Time: 5048.176 ms (00:05.048)
```

- **Uma coluna nova com um padrão constante**, `printed boolean NOT NULL DEFAULT false`: **2,1 ms**,
  e o filenode continua 16395. Desde o PostgreSQL 11 um padrão constante é guardado uma vez no
  catálogo e devolvido para toda linha antiga que não tem a coluna, então nada é gravado.
- **Uma coluna nova cujo padrão é volátil**, `DEFAULT clock_timestamp()`, uma função que devolve um
  valor diferente a cada chamada: **5,4 segundos**, e o filenode agora é 16418. Toda linha precisa do
  próprio valor, então toda linha foi gravada de novo, num arquivo novo, com a tabela travada o tempo
  todo.
- **Um tipo mais largo**, `seat` de `int` para `bigint`: **5,0 segundos**, outra reescrita completa,
  mais a reconstrução do índice único que inclui a coluna.

Em dois milhões de linhas cada reescrita custou segundos de uma tabela que ninguém conseguia ler nem
gravar. Em duzentos milhões são vários minutos, e isso é uma queda com o nome de uma migração.

## Separando as mudanças comuns

| mudança | por quanto tempo segura `ACCESS EXCLUSIVE` |
|---|---|
| acrescentar uma coluna que aceita nulo, ou com padrão constante | um instante: só catálogo |
| descartar uma coluna | um instante: a coluna é escondida, o espaço recuperado depois |
| renomear uma coluna ou uma tabela | um instante, e quebra todo programa que usa o nome velho |
| acrescentar uma coluna com padrão volátil | uma reescrita completa |
| mudar o tipo de uma coluna, na maioria dos casos | uma reescrita completa, e os índices reconstruídos |
| `SET NOT NULL` | uma leitura completa, a menos que um `CHECK` válido o prove, que a seção 09 usa |
| acrescentar uma chave estrangeira ou um `CHECK` | uma leitura completa, a menos que acrescentado `NOT VALID` antes, como na seção 09 |

A regra que sai da tabela: **para cada mudança, saiba se ela é só catálogo, uma leitura ou uma
reescrita, antes de rodá-la numa tabela grande.** O teste é barato: rode numa cópia da produção, com
o tamanho da produção, e cronometre, como esta seção fez. As que reescrevem são feitas de outro
jeito, em passos, que é a seção 07.
