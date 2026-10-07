---
title: Quanto tempo é tempo demais
version: 1
---

O tempo de vida de uma cópia é o maior tempo durante o qual alguém pode ver um valor que já não é
verdade. Então a primeira ferramenta contra dado velho não é mecanismo nenhum: **escolha cada tempo de
vida perguntando por quanto tempo uma resposta errada pode viver, e não quanto descanso o servidor
gostaria de ter.**

| o quê | por quanto tempo pode estar errado | um tempo de vida razoável |
|---|---|---|
| uma folha de estilo com o hash no nome | nunca; uma mudança é uma URL nova | um ano, `immutable` |
| o logo, as fontes | até o próximo deploy | um dia, com validação |
| a descrição de um livro | uma hora não custa nada | uma hora |
| a listagem do catálogo, com preços | um minuto é um incômodo | um minuto |
| o estoque restante, "só 2 em estoque" | segundos; vender o que não há é real | fora do cache compartilhado, ou segundos |
| o carrinho, o pedido, o pagamento | nunca | `no-store` |

Duas consequências merecem ser ditas com todas as letras.

**Um tempo de vida curto não é de graça.** Com um segundo, o cache só poupa a aplicação das requisições
que chegam dentro do mesmo segundo, e a aula 5 mostrou que a taxa de acerto desaba quando o tempo de
vida é menor que o intervalo entre as requisições. Todo tempo de vida é uma troca entre a carga na
aplicação e a idade do que as pessoas veem.

**Um tempo de vida longo precisa de uma saída.** Se uma descrição fica em cache por uma hora e alguém
nota um erro de digitação nela, esperar uma hora é bobagem. Todo tempo de vida longo deve vir com um
jeito de trocar a cópia agora, e as duas próximas seções são os dois jeitos que o Nginx oferece. A seção
depois delas elimina o problema dos arquivos estáticos por completo, nunca mudando o conteúdo de uma URL.
