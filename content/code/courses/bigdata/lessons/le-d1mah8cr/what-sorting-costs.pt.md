---
title: O que a ordenação custou
version: 1
---

**A cópia ordenada tem 484,4 MiB, contra 388,8 da camada silver, com as mesmas linhas.** Ordenar por
uma coluna ajuda todo filtro sobre essa coluna e pode piorar o tamanho de todas as outras. Os dois
rodapés do 1º de janeiro, lado a lado:

| coluna | camada silver | ordenada por livro, 15 row groups |
|---|---|---|
| `event_id` | 257,9 KiB | 279,4 KiB |
| `ts` | 532,3 KiB | 562,5 KiB |
| `visitor_id` | 156,6 KiB | 448,7 KiB |
| `book_id` | 108,4 KiB | 24,5 KiB |

**O `book_id` encolheu para um quarto**, porque valores ordenados são trechos longos do mesmo número e
a codificação por trechos guarda um trecho como uma entrada só. **O `visitor_id` quase triplicou**, e
isso é mais culpa dos row groups que da ordenação. Um dicionário é mantido por row group, então quinze
row groups guardam quinze dicionários, e um visitante que aparece em dez deles é escrito por extenso
dez vezes. O `event_id` e o `ts` perderam a ordem, então o codec achou menos com que trabalhar.

**Então uma ordenação é uma escolha sobre quais perguntas ficam rápidas**, paga em tamanho e em todas
as outras colunas. A escolha de costume é a coluna que a maioria das consultas filtra e que ainda não
é partição: aqui, talvez o livro, se as perguntas dos analistas forem sobre livros. E o tamanho do
row group é uma escolha entre pular com precisão e manter os dicionários inteiros. Os 256 KB foram
escolhidos aqui para que um arquivo de 1 MB tivesse vários row groups; em tabelas reais, com arquivos
de centenas de megabytes, o row group padrão de 128 MB já dá vários a cada arquivo, e o problema
desta seção quase some.
