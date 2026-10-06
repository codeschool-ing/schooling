---
title: Quando um floco de neve é a resposta certa
version: 1
---

A estrela é o padrão porque a maioria das dimensões é pequena e a maioria dos leitores é gente. Cada
caso abaixo quebra uma dessas premissas, e cada um é motivo para normalizar **um galho** de uma
dimensão, nunca o modelo inteiro.

**Uma dimensão muito grande, com uma parte que não é.** A dimensão de clientes de uma operadora de
telefonia pode ter dezenas de milhões de linhas, e a descrição demográfica de onde cada cliente mora,
talvez duzentas colunas de dados do censo, é compartilhada por milhares deles. Repetir essas colunas em
cada linha de cliente é armazenamento de verdade e tempo de carga de verdade. Movê-las para uma tabela
própria, apontada pelo cliente, é um floco de neve num galho, e Kimball chama uma tabela usada assim de
**outrigger**.

**Uma descrição compartilhada por várias dimensões.** Se lojas e clientes têm endereço numa cidade, e
a cidade tem atributos próprios (população, região, o território de vendas a que pertence), os dois
podem apontar para uma `dim_city` única. Uma tabela só evita que os dois descrevam a mesma cidade de
jeitos diferentes. É um segundo outrigger, e também é o que a seção 09 chama de conformar.

**Uma hierarquia que muda no seu próprio ritmo.** Se a rede reorganizasse seus departamentos a cada
trimestre e guardasse o histórico de cada versão, a árvore de categorias seria uma dimensão com vida
própria. As técnicas da lição 5 se aplicariam a ela separadamente dos livros.

**Uma camada semântica na frente do warehouse.** Algumas ferramentas de relatório, e as camadas de
modelagem de alguns warehouses na nuvem, preferem um modelo normalizado e o achatam elas mesmas para o
leitor. Aí a pessoa nunca vê as junções, e o argumento sobre leitores da seção 06 não se aplica.

O que **não** está na lista: "é mais correto", "economiza espaço" e "a origem é normalizada". O
primeiro é o padrão do banco operacional aplicado a outro trabalho. A seção 06 mediu o segundo. O
terceiro é o motivo da maioria dos flocos de neve existirem, e o motivo de os quatro passos da lição 2
começarem pelo processo de negócio e não pelas tabelas de origem.

**O teste, para qualquer galho que você tenha vontade de separar:** diga que leitor ou que carga fica
melhor com isso. Se o único beneficiado é o diagrama, deixe na estrela.
