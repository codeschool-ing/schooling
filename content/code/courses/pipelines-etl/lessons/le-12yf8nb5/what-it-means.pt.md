---
title: O que é idempotente, e por que tudo precisa ser
version: 1
---

Um passo é **idempotente** quando rodá-lo duas vezes deixa o mesmo resultado que rodá-lo uma vez.
Não um resultado parecido, não um que está certo na média: as mesmas linhas, os mesmos valores, a
mesma contagem. Depois que ele rodou, rodá-lo de novo não muda nada.

Toda lição desde a oitava pressupôs isso sem dizer. Os **retries** da lição 10 rodam de novo uma
tarefa que falhou no meio. O **clear** da lição 10 a roda de novo dias depois. O **backfill** da lição
9 roda uma semana de execuções sobre dias que podem já estar carregados. O Prefect da lição 13 refez
tudo a cada chamada, e o Luigi e o `make` retomaram um pipeline depois de uma falha, rodando os passos
que não tinham terminado — alguns dos quais tinham começado. **Todo orquestrador deste curso roda
passos mais de uma vez**, e nada em nenhum deles sabe se isso é seguro. Só o passo pode ser.

O nome vem da matemática, em que uma função é idempotente quando aplicá-la duas vezes é o mesmo que
aplicá-la uma: arredondar um número, tirar um valor absoluto, ordenar uma lista. Num pipeline a
"função" é um passo e o "valor" é o estado que ele deixa para trás: uma tabela, um arquivo, uma linha
em outro sistema.

Esta lição faz três coisas com a ideia. Mostra uma carga que não é idempotente e o que isso custa, e
as formas que uma carga pode ter e que são. Transforma *idempotente* de uma afirmação num teste que é
rodado, como a lição 12 fez com as crenças sobre os dados. E termina o assunto que a lição 11 deixou
aberto: a tabela fato que derivava, tornada segura para refazer toda noite.
