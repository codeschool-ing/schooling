---
title: Nível 4, código, e por que ele raramente é desenhado
version: 1
---

**O quarto nível mostra como um componente é implementado: as suas classes, interfaces, funções ou
tabelas.** Em geral é um diagrama de classes da UML, ou um diagrama entidade-relacionamento para um
armazenamento de dados, e o C4 diz com todas as letras que você só deve desenhá-lo quando ele
acrescentar algo que o código não diz.

## Por que ele é opcional

Três razões, cada uma suficiente sozinha:

- **O código já diz isso, com mais precisão.** Uma IDE mostra a hierarquia de classes, o grafo de
  chamadas e cada referência, e nunca está desatualizada.
- **Ele é o que desatualiza mais rápido.** Renomear uma classe ou extrair um método muda o nível de
  código; ninguém atualiza um diagrama por causa disso.
- **O público é pequeno.** Só quem trabalha dentro daquele componente precisa dele, e essas pessoas
  estão com o código aberto.

## Quando ele merece o lugar

Há casos em que um desenho no nível de código diz algo que o código esconde:

- **Um modelo de domínio que o negócio também lê.** O agregado de reserva da aula 2 é um diagrama no
  nível de código do componente de reservas, e merece o lugar porque gente de produto e engenheiros
  discutem sobre ele.
- **Um padrão que atravessa muitos arquivos.** O jeito como o adaptador de pagamento implementa uma
  porta definida pelo serviço de reservas é a inversão de dependência de `design-patterns`, e um
  diagrama pequeno mostra isso mais rápido do que cinco arquivos.
- **Um modelo de dados com restrições.** As tabelas, chaves e cardinalidades do banco de reservas têm
  a mesma forma do diagrama de classes, e o banco é compartilhado por mais gente do que o código.

Em cada caso, desenhe **os cinco ou seis elementos de que a pergunta precisa**, e não todo o
conteúdo do componente, exatamente como a aula 2 fez.

## A regra de consistência

Qualquer que seja o nível, a regra do diagrama de componentes vale: **um elemento num nível deve
poder ser rastreado até um elemento do nível de cima**. Toda classe num diagrama de código pertence a
um componente; todo componente a um container; todo container a um sistema. Quando uma classe não
tem onde ficar, ou falta um componente no diagrama, ou o código criou algo que a arquitetura nunca
decidiu, e vale a pena saber disso nos dois casos.
