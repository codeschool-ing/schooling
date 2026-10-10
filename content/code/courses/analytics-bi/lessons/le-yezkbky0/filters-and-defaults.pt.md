---
title: Filtros, e o que o leitor não vê
version: 1
---

Um filtro transforma um painel em muitos: a mesma página para cada região, cada segmento, qualquer
intervalo de datas. Também cria a falha mais silenciosa do painel, que é um filtro que o leitor não
sabe que está ligado.

## Os padrões decidem o que a maioria vê

A maioria dos leitores nunca mexe num filtro. **O que estiver no padrão é o painel** para eles. Três
escolhas importam:

- **O intervalo de datas padrão.** "Este mês" no dia 2 são dois dias de dados. "Últimos 12 meses, só
  meses completos" dá a um leitor de segunda um retrato estável; o mês corrente fica num cartão
  próprio, comparado com os mesmos dias do anterior.
- **O padrão de todo outro filtro é "todos".** Uma página que abre filtrada num segmento porque foi o
  que o autor olhou por último mostra a todo mundo a pergunta do autor.
- **Quais cartões um filtro move.** No Metabase, cada filtro é ligado cartão a cartão. Um filtro de
  região ligado à tendência e não aos cartões mostra uma página cuja metade de cima é sobre o Sul e cuja
  metade de baixo é sobre todo mundo, sem nada nela dizendo isso.

## Diga o que está filtrado

O leitor deveria conseguir dizer, sem abrir nada, o que a página está mostrando: os valores atuais dos
filtros visíveis no alto, o período no título de cada cartão — *Receita líquida, maio de 2026* em vez
de *Receita líquida* — e um cartão que não responde a um filtro dizendo isso no título.

**E um filtro não pode tirar linhas em silêncio.** Um filtro de região montado sobre `customers` exclui
os pedidos cujo cliente não está na tabela — na camada da Lantern, a conta de teste, de propósito. Um
filtro sobre uma coluna que às vezes está vazia também exclui as linhas vazias, e um total que cai
quando "todos" é escolhido pelo filtro, em vez de sem filtro, é o sintoma. Confira um total com o
filtro em "todos" contra o mesmo total sem filtro nenhum.
