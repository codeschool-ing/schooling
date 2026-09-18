---
title: Onde o mapeador cabe, e onde o SQL cabe
version: 1
---

A discussão sobre usar ou não um ORM existe desde que ORMs existem, e é em boa parte uma discussão
entre pessoas resolvendo problemas diferentes. A versão útil não é *se* e sim *para quais
instruções*, e a resposta se separa pela forma da instrução.

## O caminho de escrita: a casa do mapeador

Criar um cliente. Atualizar o endereço. Registrar um pedido com suas linhas. Apagar uma nota. Essas
são as instruções que uma aplicação mais roda, são as que têm mais repetição, e são aquelas em que
os quatro presentes de um mapeador — parâmetros, tipos que combinam, as instruções óbvias escritas
uma vez, migrações — pagam toda vez.

São também as instruções em que a aula 8 mais importa, e a unidade de trabalho de um mapeador é
uma boa forma para isso: o pedido e as linhas dele são uma transação só porque a sessão os
confirma juntos. As duas coisas a segurar da seção sobre o que ele esconde — o tamanho da
transação, e quais colunas são mandadas — são o preço, e é um preço pequeno.

## Leituras no caminho de escrita: o mapeador, com a instrução de carga ansiosa

Uma tela que mostra um cliente e seus últimos dez pedidos é a forma do N+1, e a própria correção
de carga ansiosa do mapeador é a ferramenta certa: uma instrução na consulta, duas instruções ao
servidor, e os objetos que a tela vai desenhar. A regra é a da segunda seção — leia o log uma vez
por tela — e mais nada é preciso.

## Relatórios: SQL

Receita por cidade por mês com total acumulado. Os clientes que pediram em março e não em abril. O
produto mais vendido de cada categoria. As aulas 6 e 7 construíram isso — `GROUP BY`, funções de
janela, `HAVING`, CTEs, `EXISTS` — e um mapeador expressa isso mal ou não expressa. O que sai da
tentativa é uma de duas coisas. Várias consultas e um laço na aplicação fazendo a agregação que o
banco teria feito numa passada; ou uma expressão tão longe do SQL que ela emite que ninguém
consegue ler o plano contra o código.

Escreva o SQL. Rode pela saída de emergência de consulta crua do mapeador com parâmetros, ou por
um query builder, e leia o resultado em registros simples em vez de objetos do modelo. A instrução
é então uma instrução — revisável, passível de `EXPLAIN`, indexável pelas regras da aula 9 — e
continua parametrizada.

## O query builder no meio

A maior parte do que não é nem um save simples nem um relatório é um `SELECT` com um `WHERE` que
varia: uma tela de busca com filtros opcionais, uma lista com a ordenação que o usuário escolhe. É
aqui que a concatenação de strings nasce, porque o SQL tem que mudar de forma com a entrada. É
exatamente para isso que um query builder serve: cada filtro acrescenta uma cláusula, cada
cláusula recebe um parâmetro, e o resultado é uma instrução só que o servidor planeja como um
todo.

A interface de consulta de um mapeador em geral é um query builder por baixo — os filtros
encadeados do Django, os scopes do ActiveRecord, o SQLAlchemy Core — e usá-la como um, com as
colunas nomeadas e o SQL no log, entrega a maior parte do benefício dos dois.

## A regra debaixo dos três

Seja o que for que emita a instrução, a instrução é o que roda, e as ferramentas da aula 10 a
leem. Então:

- **uma consulta lenta é um plano a ler**, tenha o mapeador escrito ou você;
- **uma consulta que roda muitas vezes é uma contagem a conferir** no `pg_stat_statements`, seja
  qual for a camada que a pôs no laço;
- **uma regra que o dado tem que seguir é uma restrição** na tabela, diga a classe o que disser;
- **um valor vai num parâmetro**, através de cada uma das três camadas.

Nenhuma dessas é sobre o ORM. Eram verdade na aula 1 e na aula 10, e o mapeador é mais um lugar
para aplicá-las — o lugar em que o SQL está mais longe da vista, que é o motivo de esta aula ter
gasto a maior parte do seu tamanho em como vê-lo.

## O que esta aula não decidiu

Qual ORM. As diferenças entre eles são reais e são do tipo que um time decide uma vez para a sua
linguagem, e os hábitos acima são os mesmos em cada um. A aula 12 faz o mesmo ponto sobre bancos:
as ferramentas mudam, as perguntas não.
