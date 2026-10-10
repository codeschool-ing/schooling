---
title: O hábito relacional, e por que ele funciona lá
version: 1
---

O primeiro esquema NoSQL que a maioria das equipes escreve é o seu esquema relacional sem os joins:
uma coleção por tabela, uma chave por linha, e a aplicação fazendo os joins. **É o erro mais comum no
assunto deste curso**, e ele vem de um hábito que está certo no lugar onde foi aprendido.

## Entidades primeiro, perguntas depois

O curso `sql-databases` projetou a loja perguntando que coisas existem e como se relacionam.
Clientes fazem pedidos, pedidos têm linhas, linhas nomeiam produtos. Cada fato é escrito uma vez, na
tabela da coisa que ele descreve: a cidade de um cliente mora em `customers`, o preço de um produto
em `products`, e uma linha de pedido guarda só as chaves que apontam para eles. Normalização é a
disciplina de pôr cada fato em exatamente um lugar, e a recompensa é que **nenhuma atualização
consegue deixar duas cópias discordando**, porque não há cópias.

Nada nesse projeto menciona uma consulta. O esquema descreve o mundo, e as perguntas vêm depois, de
qualquer pessoa, em qualquer forma.

## O que torna isso seguro: o join e o planejador

Funciona porque um banco relacional promete responder **uma pergunta que ninguém listou quando as
tabelas foram criadas**. Um analista escreve, meses depois do lançamento, "clientes de Recife que
compraram um monitor em setembro", uma consulta que toca quatro tabelas. O banco responde,
corretamente, sem mudar o esquema:

- **o join** remonta, na hora da leitura, as combinações que a normalização separou;
- **o planejador** decide como: por qual tabela começar, qual índice usar, em que ordem juntar, a
  partir de estatísticas que ele guarda sobre os dados.

Então num projeto relacional o custo de uma pergunta nova é pago **na hora da leitura**, e no pior
caso é um índice que alguém acrescenta depois. É um bom negócio quando as perguntas são muitas e
imprevisíveis, e quando todos os dados estão numa máquina só, onde um join é uma busca na memória ou
num disco local.

## O que muda nos armazenamentos deste curso

Os três produtos abrem mão de parte ou de toda essa maquinaria, cada um por um motivo que a aula 2
mostrou:

| | joins | um planejador escolhendo entre estratégias | então uma pergunta não prevista é |
|---|---|---|---|
| **Redis** | nenhum | nenhum: todo comando nomeia a sua chave | uma varredura de todas as chaves, feita pela aplicação |
| **Cassandra** | nenhum | nenhum: uma consulta precisa partir de uma partição | recusada, ou `ALLOW FILTERING` em todos os nós |
| **MongoDB** | `$lookup` num pipeline, aula 8 | sim, para índices dentro de uma coleção | possível, e lenta quando os dados estão espalhados por shards |

O motivo é o mesmo nos três. Eles espalham os dados por máquinas, e **um join entre máquinas é uma
conversa pela rede para cada linha que ele encontra**. Um armazenamento feito para responder em um
milissegundo a partir de uma partição não pode também prometer combinar quaisquer duas partições sob
demanda.

Então as perguntas mudam de lugar. Num projeto relacional elas são respondidas na leitura e ninguém
precisa listá-las antes. Aqui elas precisam ser conhecidas **na hora do projeto**, porque a forma dos
dados é a resposta a elas. Levar o esquema relacional para cá, com as entidades e sem os joins,
mantém o custo da normalização e joga fora o que pagava por ela.

A próxima seção escreve a lista da qual o projeto parte.
