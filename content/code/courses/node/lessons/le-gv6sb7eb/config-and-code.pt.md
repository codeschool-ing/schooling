---
title: O que é configuração e o que é código
version: 1
---

**Configuração é tudo o que muda entre os lugares onde um programa roda; código é o que fica igual.** O
mesmo commit do serviço links roda no seu notebook, num teste e num servidor, e a porta, o endereço em
que escuta, onde guarda os dados e a chave de administração são diferentes em cada um. As rotas, a
validação e os códigos de status não são. É essa a linha a traçar, e o princípio que sai dela costuma
ser citado como parte do *Twelve-Factor App*, um conjunto curto de regras para serviços: **mantenha a
configuração no ambiente, não no código.**

| pertence à configuração | pertence ao código |
|---|---|
| a porta e o endereço onde escutar | as rotas e o que elas respondem |
| onde fica o arquivo de dados | o formato do arquivo de dados |
| a chave de administração | que apagar precisa de chave |
| o `NODE_ENV`, produção ou não | o que a produção muda, se muda algo |
| o endereço de um banco ou de outro serviço | como conversar com ele |

Traçar a linha ali tem três consequências:

- **Um build roda em todo lugar.** Nada é compilado nem editado por ambiente, então o que foi testado é
  o que vai para o ar, com valores diferentes em volta.
- **Os segredos ficam fora do repositório.** A chave de administração que está em `src/admin.js` desde
  a aula 6 está em toda cópia do código já feita, e o comentário ao lado dela vem dizendo isso. Esta
  aula a tira de lá.
- **Mudar um valor não é mudar o código.** Levar o serviço para outra porta é um deploy com uma variável
  nova, não um commit.

O que *não* pertence ao ambiente é qualquer coisa que mude o comportamento do programa de um jeito que
um teste não pegaria: chaves de funcionalidade que ninguém testa nas duas posições, um modo "debug" que
pula conferências. Uma variável custa pouco para criar, e cada uma é uma combinação que alguém precisa
ter rodado.
