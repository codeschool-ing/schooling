---
title: O que um alerta precisa carregar
version: 1
---

Um painel é lido quando alguém escolhe olhar. Um **alerta** interrompe. Esse custo é pago na atenção de
alguém, e um alerta precisa merecê-lo trazendo o bastante para uma pessoa agir sem antes abrir cinco
outras telas.

| um alerta traz | no alerta v2 da aula 4 |
|---|---|
| **o que disparou**, pelo nome e pelo id da regra | *Login accepted from an address that tried many accounts*, `5e7a1c40-…` |
| **por que importa**, numa frase | uma rodada de tentativas foi seguida de um login bem-sucedido |
| **os campos-chave** | o endereço, a conta que entrou, o host, os horários em UTC |
| **severidade** | crítica: um login funcionou, então alguém pode estar lá dentro |
| **a evidência**, com link | os ids dos eventos que a regra casou, para o analista abri-los |
| **o que fazer primeiro** | um link para o playbook ou runbook deste alerta |
| **quem é o dono** | a fila ou a pessoa para quem ele foi encaminhado |

A severidade merece cuidado, porque é o campo pelo qual todo mundo ordena. Ela é uma afirmação sobre **o que
o alerta significa se for verdadeiro**, não sobre quão segura a regra está. Uma regra que acerta metade das
vezes sobre algo crítico produz alertas críticos metade dos quais são falsos, e a aula 7 trata de
distingui-los. Uma equipe que baixa a severidade de uma regra porque ela é barulhenta escondeu um problema
justamente no campo feito para mostrá-lo; a correção honesta é na regra.

E um alerta sem dono é um alerta que ninguém tem a obrigação de ler. O encaminhamento faz parte do alerta,
não é algo que acontece a ele depois.
