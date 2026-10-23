---
title: Um modelo, muitas apresentações
version: 1
---

**Três apresentações numa semana são três chances de desenhar o sistema de três jeitos diferentes, e
um deck desenhado à mão começa a discordar do modelo no dia em que é feito.** A resposta é a que a
aula 12 deu para a documentação: manter um modelo só e gerar cada visão a partir dele.

## O deck que se descolou

Antes da revisão, os slides da Carcará tinham suas próprias cópias da arquitetura. O deck dos
diretores mostrava o back office das rodoviárias, que o programa da aula 8 já tinha aposentado.
Ninguém tinha mentido; alguém copiou um slide do deck do ano anterior, e um slide não sabe que ficou
desatualizado.

Os engenheiros perceberam na hora, e dali em diante passaram a duvidar do resto dos slides. **Uma
caixa errada num slide custa mais do que a caixa: custa a confiança de todo mundo que a notou.**

## Cada slide, uma visão do modelo

Para a semana do São João, Tainá fez de cada diagrama de cada slide uma visão exportada do workspace
do Structurizr da aula 12:

- o contexto dos diretores e o diagrama dinâmico do time de produto são **visões do mesmo modelo**,
  então um elemento renomeado no modelo é renomeado nos dois;
- cada visão traz **a versão e a data do modelo** no rodapé, a mesma data que o repositório mostra;
- quando o modelo muda depois que o deck foi enviado, a exportação roda de novo e o slide é
  substituído, em vez de editado.

Os slides não ficaram mais bonitos do que antes. Ficaram **consistentes**: quem foi a duas das três
reuniões viu os mesmos nomes, nos mesmos lugares, com a mesma legenda.

## O que pode variar entre as apresentações

Um modelo não quer dizer uma aparência só. Cada visão do workspace pode incluir elementos diferentes
e ter seu próprio título, e os decks podem variar em tudo o que não é o modelo: a ordem, as palavras
em volta do diagrama, o número de slides. **O que os decks não podem é discordar sobre um fato**,
como qual sistema é dono das reservas ou se o back office ainda existe.

Se não houver uma ferramenta que gere visões, a regra continua valendo numa forma mais fraca: guarde
os diagramas de um deck num lugar só, dê a cada um um responsável e uma data, como na aula 11, e
copie de lá, nunca de um deck antigo.
