---
title: Mantendo a main verde
version: 1
---

Um pipeline só é útil na medida dos hábitos da equipe em volta dele. Três hábitos transformam um
servidor de CI em integração contínua, e cada um responde a uma falha que o laboratório já mostrou.

## Conferir antes do merge, não só depois

O hook do laboratório rodou **depois** de cada push chegar à `main`, então as execuções 2 e 4
deixaram uma `main` quebrada por um tempo: quem puxou nesse meio-tempo recebeu um teste falhando. Um
serviço hospedado confere um pull request **antes** do merge, e um repositório pode tornar essa
verificação **obrigatória**: o botão de merge fica desabilitado até as verificações nomeadas
passarem. A aula 6 mostra onde isso se configura. Este repositório exige as verificações dele
exatamente por isso, e o workflow é escrito para um job pulado ainda relatar, porque uma verificação
obrigatória que nunca relata bloqueia todo merge.

## Main vermelha é o primeiro problema de todo mundo

Quando a `main` está vermelha, todo branch novo começa de uma base quebrada, e toda falha nova se
esconde atrás da antiga. A regra que as equipes adotam é simples: **consertar a `main` vem antes de
qualquer trabalho novo**, e o conserto mais rápido costuma ser uma reversão, como na seção 07. Quem
fez a mudança que quebrou é a pessoa natural para consertar, mas qualquer um pode reverter; uma
reversão é barata de desfazer e uma `main` vermelha é cara de manter.

## Integrar pouco e sempre

A palavra *contínua* é a prática. Uma mudança que vive três semanas num branch integra três semanas
de mudanças dos outros de uma vez, e quando essa execução fica vermelha ninguém sabe dizer qual de
quarenta commits causou. Uma mudança integrada no dia em que foi escrita é pequena, e a execução
dela, vermelha ou verde, é sobre essa mudança. **Branches de vida curta, integrados todo dia**, são o
que faz um resultado de CI apontar uma causa.

## O que a aula 6 acrescenta

Tudo nesta aula rodou num notebook, com um hook de cinquenta linhas. A aula 6 leva o mesmo ciclo
para os dois serviços que a maioria das equipes usa, GitHub Actions e GitLab CI: a matriz vira uma
`strategy`, os artefatos viram uploads, o cache vira uma action com chave, e o gatilho vira um pull
request com uma verificação obrigatória. As ideias valem sem mudança; só o formato do arquivo é novo.
