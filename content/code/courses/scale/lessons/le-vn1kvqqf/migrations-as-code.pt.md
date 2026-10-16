---
title: Migrações como código, e a lista de conferência
version: 1
---

Toda mudança desta aula foi digitada no psql, que é como se aprende o que cada uma faz e não é como
uma equipe deveria aplicá-las. Num sistema que muda com frequência, **uma mudança de esquema é
código**: escrita num arquivo, revisada como qualquer outro diff, aplicada por uma ferramenta na
mesma ordem em todo lugar e registrada no banco para nunca ser aplicada duas vezes.

## O que uma ferramenta de migração dá

As ferramentas diferem em linguagem e detalhes, Flyway, Liquibase, Alembic, as migrações do Rails,
golang-migrate e muitas outras, e dividem um modelo:

- **migrações são arquivos numerados**, aplicados em ordem, cada um uma vez;
- **o banco registra quais já rodaram**, numa tabela própria, para a ferramenta saber onde cada
  ambiente está;
- **migrações rodam antes ou junto com a implantação**, pelo pipeline e não por uma pessoa, para que
  esquema e código cheguem juntos, na ordem que a seção 07 exige;
- **elas andam para a frente.** Uma migração de "volta" que desfaz uma mudança é útil em
  desenvolvimento e perigosa em produção, onde desfazer o descarte de uma coluna não traz os dados
  dela de volta. Em produção um erro é corrigido com uma migração nova.

## A lista de conferência

O que esta aula mediu se reduz a uma lista que um revisor consegue usar contra uma migração:

1. **Ela toma `ACCESS EXCLUSIVE`?** Então roda com um `lock_timeout` curto e é tentada de novo,
   nunca deixada esperando (seções 03 e 04).
2. **Ela reescreve ou lê a tabela com a trava segura?** Então é refeita de outro jeito: um padrão
   constante, um índice construído `CONCURRENTLY`, uma restrição acrescentada `NOT VALID` e validada
   (seções 05, 06 e 09).
3. **Ela quebra uma versão do programa em execução?** Então é dividida em expandir e contrair, em
   várias implantações (seção 07).
4. **Ela muda muitas linhas?** Então é um preenchimento em lotes, retomável, acompanhado nas
   réplicas (seção 08).
5. **Ela foi cronometrada numa cópia da produção, no tamanho da produção?** Dois milissegundos num
   banco de desenvolvimento não dizem nada sobre duzentos milhões de linhas.

A última é a que as equipes pulam, e é a que teria pegado todo o resto da lista.
