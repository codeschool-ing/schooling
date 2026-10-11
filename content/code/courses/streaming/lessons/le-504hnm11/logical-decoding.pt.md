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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O caminho de uma mudança da tabela até o tópico. Uma transação é confirmada e o PostgreSQL a grava no write-ahead log. O slot de replicação debezium_stock marca até onde o leitor dele confirmou. O plugin pgoutput decodifica o log a partir desse ponto, ficando só com as tabelas citadas na publicação ponto_final. O Debezium, rodando dentro do Kafka Connect, transforma cada mudança de linha num evento e o grava num tópico por tabela: pf.public.books e pf.public.stock. A posição do slot só anda quando o Debezium confirma, então tudo o que vem depois dela fica no disco do banco.\" data-fig=\"l14-pipeline\"><defs><marker id=\"l14-pipeline-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"20\" width=\"400\" height=\"190\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">PostgreSQL</text><rect x=\"30\" y=\"55\" width=\"80\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">COMMIT</text><path d=\"M 110 70 L 140 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-ah-8343)\"></path><text x=\"260\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">write-ahead log (WAL)</text><rect x=\"145\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"169\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"193\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"217\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"241\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"265\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"289\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"313\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"337\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"361\" y=\"58\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><line x1=\"241\" y1=\"54\" x2=\"241\" y2=\"108\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"241\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">slot debezium_stock</text><text x=\"195\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">confirmado até aqui</text><text x=\"318\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">guardado em disco até a confirmação</text><rect x=\"150\" y=\"145\" width=\"230\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pgoutput</text><text x=\"265\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">publicação ponto_final</text><path d=\"M 330 108 L 330 143\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-ah-8343)\"></path><rect x=\"440\" y=\"110\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Kafka Connect</text><text x=\"500\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conector Debezium</text><path d=\"M 380 169 L 438 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-ah-8343)\"></path><rect x=\"590\" y=\"60\" width=\"115\" height=\"140\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"647\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">Kafka</text><rect x=\"598\" y=\"95\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"648\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">pf.public.books</text><rect x=\"598\" y=\"145\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"648\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">pf.public.stock</text><path d=\"M 560 135 L 596 112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-ah-8343)\"></path><path d=\"M 560 150 L 596 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-pipeline-ah-8343)\"></path></svg>", "caption": "Decodificação lógica: o próprio log do banco, lido a partir de uma posição lembrada, filtrado por uma publicação e transformado num tópico por tabela.", "same": ["PostgreSQL", "COMMIT", "write-ahead log (WAL)", "Kafka Connect", "Kafka"]}
```

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
