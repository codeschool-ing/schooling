---
title: Decodificação lógica, o log por baixo da tabela
version: 1
---

**O PostgreSQL já guarda um log de toda mudança, porque precisa dele para sobreviver a uma queda.**
Antes de o `COMMIT` de uma transação retornar, as mudanças dela são gravadas no **write-ahead log**
(WAL), uma sequência de arquivos dentro do diretório de dados; as tabelas em si são atualizadas
depois. Se o servidor morre, ele reaplica o WAL ao voltar. O WAL é ordenado, só recebe acréscimos e
é endereçado por posição, o que o torna a mesma estrutura de dados que uma partição do Kafka da
lição 2.

O que o WAL guarda, por padrão, não se lê como linhas. Ele registra páginas e bytes, o suficiente
para o PostgreSQL repetir o próprio trabalho e nada mais. A **decodificação lógica** (*logical
decoding*) é o recurso que o transforma de volta em mudanças de linha — *esta linha de `stock` foi
de 3 para 2* — e ela precisa de quatro coisas, cada uma das quais você vai ver pelo nome no resto
desta lição:

| peça | o que é | nesta lição |
|---|---|---|
| `wal_level = logical` | uma configuração do servidor que faz o WAL carregar o suficiente para reconstruir linhas; mudá-la exige reiniciar | definida na instalação, na próxima seção |
| um **slot de replicação** | uma posição com nome no WAL, mantida pelo servidor para um leitor | `debezium_stock`, criado pelo Debezium na primeira conexão |
| um **plugin de saída** | o código que transforma registros do WAL num formato | `pgoutput`, o do próprio PostgreSQL, que a replicação nativa dele usa |
| uma **publicação** | a lista de tabelas cujas mudanças o `pgoutput` envia | `ponto_final`: as tabelas `books` e `stock` |

@@fig:l14-pipeline@@

## O slot é o consumer group do banco

**Um slot está para o PostgreSQL como um offset confirmado está para o Kafka**: a posição do leitor,
guardada no servidor. Quando o Debezium termina de gravar com segurança um lote de mudanças no
Kafka, ele avisa o servidor *tenho tudo até aqui*, e o `confirmed_flush_lsn` do slot avança. Um
**LSN**, *log sequence number*, como `0/1A2B3C8`, é uma posição em bytes no WAL, a palavra do banco
para offset.

A comparação quebra num ponto, e é o ponto que causa incidentes. O Kafka apaga os segmentos antigos
de uma partição pela configuração de retenção, tenha alguém lido ou não (lição 3); um consumidor que
fica atrasado demais perde dados, e o disco do broker não se importa. **O PostgreSQL faz o oposto:
ele guarda todo arquivo de WAL que um slot ainda não confirmou**, pelo tempo que for preciso. Um
leitor que para deixa o slot para trás, e o disco do banco enche de WAL que ninguém vai ler. A
última seção desta lição provoca isso de propósito e mede.

## Por que pgoutput e uma publicação

Instalações mais antigas de Debezium punham no PostgreSQL um plugin à parte, `decoderbufs` ou
`wal2json`. O `pgoutput` faz parte do PostgreSQL desde a versão 10, então não há nada para
compilar, e os serviços gerenciados, entre eles Amazon RDS e Cloud SQL, o suportam. Ele envia só
as tabelas de uma **publicação**, que é um objeto comum do banco:

```sql
CREATE PUBLICATION ponto_final FOR TABLE books, stock;
```

O Debezium pode criar a publicação sozinho, para todas as tabelas, na primeira vez que sobe. Esta
lição a cria à mão, com o usuário dono das tabelas, para que o usuário de banco do conector não precise de
mais do que precisa: o direito de replicar, e de ler as duas tabelas. **Um usuário de CDC que lê
todas as tabelas do banco é uma cópia de tudo, a caminho de um broker.** Nomear as tabelas numa
publicação é como você decide quais saem.
