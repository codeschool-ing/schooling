---
title: O que todo índice custa, em toda escrita
version: 1
---

A frase que as pessoas aprendem é *"um índice deixa consultas mais rápidas"*. A frase que elas não
aprendem é a outra metade:

> **Todo índice é mantido em toda inserção, em todo update que toca as colunas dele e em toda
> exclusão — pelo tempo que ele existir.**

Uma tabela com seis índices transforma um `INSERT` em sete pedaços de trabalho: a linha, e seis
estruturas ordenadas que cada uma precisa de uma entrada nova no lugar certo. Ninguém vê isso num
plano de consulta, porque não é uma consulta.

## Os três custos

**Escritas.** Cada índice acrescenta trabalho a toda escrita. Não é catastrófico — uma inserção em
árvore B são algumas leituras de bloco e uma escrita — mas é por índice e por linha, e acumula
exatamente nas tabelas que importam, que são as de mais movimento.

**Disco.** Um índice sobre uma coluna `text` facilmente é um terço do tamanho da tabela. Seis deles
podem ser maiores que a tabela. Isso é disco, e é memória: o conjunto de trabalho que o seu banco
mantém em cache agora inclui todo índice, então um índice que ninguém usa está expulsando páginas
que alguém usa.

**O tempo do planejador e as escolhas dele.** Mais índices significam mais planos a considerar.
Pior: um índice quase certo convida o planejador a escolhê-lo e depois seguir meio milhão de
ponteiros, quando ler a tabela teria sido mais rápido.

## Um update é pior do que parece

```sql
UPDATE customers SET last_seen = now() WHERE id = 7;
```

Só uma coluna mudou, então só um índice em `last_seen` deveria precisar de trabalho. No PostgreSQL
não é o que costuma acontecer: um update escreve uma **nova versão da linha inteira** em outro
lugar, então todo índice precisa ganhar uma entrada apontando para a nova posição. Existe uma
otimização para isso — a atualização que fica só no heap, que pula o trabalho de índice quando
nenhuma coluna indexada mudou e há espaço na mesma página — e ela é um melhor esforço, não uma
garantia.

O que dá um conselho específico e útil: **uma coluna escrita a cada requisição, como `last_seen`, é
uma coluna cara de indexar**, e o custo cai nas escritas em vez de em qualquer lugar onde você iria
olhar.

## Às vezes ler tudo é o certo

Um índice não é automaticamente melhor. Dois casos em que a varredura ganha, e eles são comuns:

**Uma tabela pequena.** Algumas centenas de linhas cabem numa ou duas páginas. Ler todas são uma ou
duas leituras; usar um índice é uma leitura do índice mais uma da tabela. O planejador sabe disso e
lê a tabela, e está correto.

**Uma consulta que casa muitas linhas.** Suponha que `WHERE active` case 60% de um milhão de linhas.
Usar o índice significa seiscentas mil entradas e seiscentas mil buscas aleatórias, cada uma caindo
numa página que provavelmente não é onde a anterior caiu. Ler a tabela direto é sequencial, no que o
armazenamento é muito melhor, e é o plano mais rápido por larga margem.

A regra prática varia por banco e por como as linhas estão dispostas, e o formato é sempre o mesmo:
**um índice compensa quando elimina a maior parte da tabela, e para de compensar quando não
elimina.** Uma coluna com dois valores possíveis — um booleano, um status com `active` e `inactive`
— é o caso clássico em que um índice comum não ganha nada, e a seção sobre índices parciais é o que
você quer em vez disso.

## Os que são perda pura

**Um índice que ninguém consulta.** Criado para um relatório que foi apagado, ou para um `WHERE` que
alguém planejava escrever. Custa escritas e disco e não devolve nada, e vai ficar lá por anos porque
removê-lo parece arriscado. A seção `maintaining-them` tem a consulta que os encontra.

**Um duplicado.** Um índice em `(customer_id)` ao lado de um em `(customer_id, created_at)` é
redundante: o segundo serve a toda consulta que o primeiro serve, pela razão que a seção
`composite-indexes` dá. As pessoas criam os dois porque dois chamados pediram duas consultas.

**Um que duplica uma restrição.** Uma `PRIMARY KEY` ou uma restrição `UNIQUE` é implementada como um
índice. Acrescentar o seu próprio índice na mesma coluna lhe dá duas estruturas fazendo um trabalho.

## A regra

> **Não acrescente um índice porque parece provável que ajude. Acrescente porque você mediu, e
> remova quando a medição não valer mais.**

Todo índice é um pequeno imposto permanente sobre as escritas, pago em troca de uma consulta
específica ser rápida. É uma boa troca quando a consulta é real e uma troca ruim quando ela é
hipotética, e o único jeito de distingui-las é olhar — que é a aula 10 inteira.
