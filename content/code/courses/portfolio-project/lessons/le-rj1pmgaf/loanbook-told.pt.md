---
title: O loanbook em dois minutos
version: 1
---

Aqui está a versão do loanbook, escrita por inteiro. Falada num ritmo calmo, leva um pouco menos de dois
minutos. Leia em voz alta uma vez, com um relógio, antes de ler as notas abaixo.

```localised
A sala de TI de uma escola empresta projetores e notebooks para as professoras, e o único registro era
uma folha de papel na porta. Ela errava nos dois sentidos: coisas marcadas como fora estavam na
prateleira, e numa manhã duas professoras apareceram para o mesmo projetor, cada uma certa de que tinha
reservado.

Construí o loanbook para substituir a folha: uma página que mostra o que está fora, com quem e quando
volta. A parte interessante foi aquela manhã. Se duas pessoas apertam Emprestar no mesmo instante, uma
verificação no código lê "disponível" duas vezes e deixa as duas passarem. Então deixei o banco recusar:
um índice único parcial permite um empréstimo aberto por item, e a segunda requisição recebe uma mensagem
clara dizendo com quem está. Escrevi um teste para isso, e depois tirei o índice para ter certeza de que o
teste falhava.

O custo é que não há contas. Quem pega emprestado é um nome digitado, então qualquer pessoa que abra a
página pode emprestar. Para uma sala dos professores essa foi a troca certa; para várias escolas seria a
primeira coisa a mudar.

Está implantado num servidor, num container, atrás de HTTPS, e voltou sozinho quando eu o derrubei. O
README tem as decisões, e a próxima coisa que eu construiria são lembretes por e-mail para os atrasos.
```

Repare no que o roteiro não contém: a palavra *Python* não aparece, e *SQLite* só dentro de *o banco*. Quem
ouve e quer o stack vai perguntar, e a pergunta é uma abertura. O que o roteiro contém é **uma história, uma
decisão com o motivo, um custo, e três evidências**: o teste que foi feito para falhar, o deploy que
sobreviveu a uma pane, e um README que quem avalia consegue abrir.

O seu terá outras frases e os mesmos quatro parágrafos.
