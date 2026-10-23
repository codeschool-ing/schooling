---
title: Um schema muda, e a mudança tem de viajar
version: 1
---

A tabela do boxoffice foi criada na aula 6 rodando o `schema.sql` uma vez com o `psql`, e esse arquivo
não roda duas vezes: na segunda, o `CREATE TABLE` falha porque a tabela existe. Isso servia para uma
tabela num notebook. **Esta aula acrescenta uma segunda tabela, `tickets`, e a pergunta passa a ser como
essa mudança chega a todo banco contra o qual o boxoffice roda**: o seu, o de um colega, o banco de
teste da aula 15 e, um dia, um banco de produção cheio de vendas que não podem se perder.

Rodar um `CREATE TABLE` novo à mão em cada um não passa da primeira vez em que alguém esquece. Nada
registra quais mudanças um banco já recebeu, então ninguém consegue dizer se o banco de produção está
atrás do código que está para ser publicado contra ele.

## Uma migração é uma mudança numerada

A resposta a que todo ecossistema chegou é a mesma. **Cada mudança no schema é um arquivo pequeno com um
número**, guardado no repositório ao lado do código que precisa dela. Uma ferramenta mantém, dentro de
cada banco, uma tabela com os números que aquele banco já recebeu, e aplicar migrações é rodar, em
ordem, todo arquivo cujo número ainda não está nessa tabela.

Isso dá três propriedades de uma vez:

- **todo banco sabe dizer onde está**, lendo a própria tabela;
- **os mesmos arquivos levam qualquer banco ao mesmo lugar**, esteja ele vazio ou uma mudança atrás;
- **o histórico fica no controle de versão**, revisado como código, com a mudança e o código que precisa
  dela no mesmo commit.

A maioria das ferramentas de migração também deixa cada arquivo dizer como se desfazer, uma migração
**down**. Ela é útil em desenvolvimento, para voltar um passo e tentar de novo. Em produção raramente é
a saída de uma mudança ruim, porque um down que remove uma coluna remove também os dados escritos nela
desde então; **a correção de uma migração ruim costuma ser uma migração nova que a corrige**.

## Duas ferramentas, uma ideia

O Go tem duas ferramentas de migração muito usadas, e elas diferem mais na forma do que na substância:

| | golang-migrate | goose |
|---|---|---|
| uma migração é | dois arquivos, `NNN_name.up.sql` e `NNN_name.down.sql` | um arquivo, com as seções `-- +goose Up` e `-- +goose Down` |
| escrita em | SQL | SQL, ou Go para uma mudança que o SQL não expressa |
| usada a partir de | uma ferramenta de linha de comando, ou uma biblioteca | uma ferramenta de linha de comando, ou uma biblioteca |

O boxoffice usa o **goose**: um arquivo por mudança lê melhor, e a biblioteca roda migrações compiladas
dentro do binário, que é o que a seção 04 faz. O sqlc entende os dois formatos, então os arquivos de
migração também servem de schema para o sqlc.
