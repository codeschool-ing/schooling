---
title: Uma lista de conferência para o embrulho
version: 1
---

**Antes de um app ir a um revisor, passe por ele como uma pessoa passaria num celular**, e anote o que
acontece. Cada linha abaixo é uma das queixas da primeira seção desta aula, transformada numa conferência,
com o que o planner faz hoje:

| conferência | por que importa | o planner hoje |
|---|---|---|
| o gesto de voltar do sistema volta uma tela | no Android, senão, ele fecha o app | **não**: o voltar do Android sai do app numa página de curso |
| sem seleção de texto nem zoom de página onde um app não teria | é o primeiro sinal de uma página | **não**: valem os padrões de uma página |
| cada toque responde em um ou dois quadros | um toque lento é tocado de novo | **sim** no tamanho da demonstração, não com milhares |
| ele abre e funciona sem rede | uma pessoa o abre num trem | **sim**: tudo de que ele precisa está dentro do app |
| ele volta onde estava depois de o sistema fechá-lo | celulares fecham apps em segundo plano | **em parte**: o plano sobrevive, o curso aberto não |
| as permissões são pedidas na hora do uso, com um motivo | uma pergunta cedo ou sem explicação recebe um não | **sim**, desde a aula 4 |
| todo controle funciona com leitor de tela e teclado | quem não enxerga a tela continua usando o app, e a lei pede isso em muitos lugares | **sim**: botões e rótulos de verdade desde a aula 1 |
| ele faz algo que um site não faria | a regra 4.2 da Apple | **sim**: lembretes, a câmera, uma tela mantida ligada |

**Dois dos "não" têm causas de uma linha e soluções curtas**, e as duas são trabalho web. O botão de
voltar do Android chega ao app pelo plugin `@capacitor/app` do Capacitor, cujo evento `backButton` o
planner pode tratar voltando para a lista de cursos, e saindo do app só a partir dela. Seleção e zoom
são algumas linhas de CSS e a configuração `user-scalable` do viewport, aplicadas aos controles do app e
não ao conteúdo que alguém pode querer copiar.

*O planner os deixa como estão, para a aula poder mostrar um "não" de verdade; o seu app não deveria. As
conferências são as que este curso conseguiu rodar num navegador; num celular, o comportamento do gesto
de voltar e do sistema fechando o app tem que ser visto no celular.*

## A linha que decide

**A última linha é a que um revisor aplica**, e a única que acabamento nenhum resolve. Se a resposta
honesta é que o app mostra o mesmo que o site mostra, a pergunta deixa de ser como passar na revisão:
passa a ser se o app deveria existir, ou se o site, instalável como Progressive Web App, já faz o
trabalho sem loja nenhuma.
