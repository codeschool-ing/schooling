---
title: Três caminhos até a mesma tabela
version: 1
---

O boxoffice já conversou com uma tabela de três jeitos: pgx à mão na aula 6, GORM no `gormlab` da aula 7,
e sqlc nesta aula. Os três dão conta do mesmo serviço. **Eles diferem em quem escreve o SQL, quem escreve o
Go que lê os resultados, e quando um erro é encontrado.**

| | pgx à mão | GORM | sqlc |
|---|---|---|---|
| quem escreve o SQL | você | o GORM, a partir das suas structs e chamadas | você |
| quem escreve o scan para o Go | você | o GORM, por reflexão em tempo de execução | o sqlc, como código que você lê |
| onde o SQL pode ser lido | no arquivo Go | só no log | no `queries.sql`, e copiado no arquivo gerado |
| uma coluna com nome errado é encontrada | quando a consulta roda | quando a consulta roda | no `generate`, com um banco a quem perguntar |
| uma coluna e um campo fora de sincronia | quando a consulta roda | quando a consulta roda | impossível: gerados juntos |
| filtros opcionais | montar a string com cuidado | natural | desajeitado, seção 08 |
| o schema vem de | o seu arquivo SQL | as suas structs, ou o seu SQL | o seu arquivo SQL |
| ferramentas extras | nenhuma | nenhuma | o sqlc, e o gcc para compilá-lo |
| módulos novos | pgx | GORM, o driver dele, pgx | pgx |

**A coluna do meio esconde o SQL; as duas de fora o mantêm na sua frente.** Entre essas duas, a diferença
é quanto do Go repetitivo você escreve e quão cedo um erro aparece: à mão, uma coluna acrescentada ao
`SELECT` e esquecida no `Scan` é um erro em tempo de execução; com o sqlc isso não acontece.

## E o boxoffice

O boxoffice fica com o sqlc daqui em diante. As consultas dele são poucas e fixas, a mais importante é um
`UPDATE` escrito com cuidado, e o código gerado eliminou a única classe de erro que os scans escritos à mão
convidam, ao preço de um bug que a conversão introduziu e a seção 06 consertou. **Essa troca serve a este
serviço.** Um serviço com uma tela de busca e cinquenta filtros opcionais, ou uma equipe que pensa em
modelos, pesaria diferente, e a seção 08 da aula 7 e a seção 08 desta dizem onde.

A aula 9 se apoia neste código: a interface `DBTX` e o `WithTx` da seção 05 são exatamente o que uma
transação precisa.
