---
title: Por que o dado quebra entre times
version: 1
---

Dentro de um time, uma mudança numa tabela é uma conversa: quem renomeia uma coluna sabe quem a lê, ou
pergunta para a mesa ao lado. Entre times — e entre empresas —, ninguém sabe. O time de análise lê a
tabela de pedidos; o financeiro lê a view do time de análise; um parceiro recebe um arquivo feito a
partir do relatório do financeiro. Cada passo foi construído contra o jeito que o passo anterior
tinha **num dia específico**.

Então algo muda na origem, por um bom motivo, e uma de três coisas acontece no destino:

- **falha de forma visível** — uma coluna sumiu, uma consulta dá erro. Esse é o caso bom;
- **continua, errado** — uma coluna mantém o nome e muda de sentido: um preço que era em reais agora é
  em centavos, uma contagem de linhas vira contagem de unidades. Todo gráfico continua aparecendo;
- **continua, vazando** — uma coluna é acrescentada a uma view compartilhada, e um dado que ninguém
  combinou mandar começa a sair da empresa toda manhã.

O segundo e o terceiro são os que importam, e têm a mesma causa: **ninguém escreveu o que foi
prometido, então nada conseguia notar que a promessa foi quebrada.**

## Interoperabilidade é um acordo

*Interoperabilidade* é a capacidade de dois sistemas trocarem dados e os usarem corretamente. A
primeira metade são formatos e protocolos, e está em grande parte resolvida: CSV, JSON, Parquet, HTTP.
A segunda metade — **corretamente** — é sobre sentido, e nenhum formato a carrega sozinho. `2026-06-30`
não tem ambiguidade; uma coluna chamada `items` tem.

Um **contrato de dados** é o acordo escrito entre o time que produz um conjunto de dados e os times que
o consomem: o que ele contém, o que cada campo significa, quão bom e quão atual ele vai ser, quem é o
dono, e o que o consumidor pode fazer com ele. Esta aula escreve um para um conjunto de dados que a
Ipê manda a outra empresa, o confere automaticamente, e o quebra duas vezes para ver a verificação
funcionar.
