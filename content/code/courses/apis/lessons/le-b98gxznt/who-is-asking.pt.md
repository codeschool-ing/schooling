---
title: Quem pergunta, e o que pode fazer
version: 1
---

**Autenticação responde "quem é este?". Autorização responde "ele pode fazer isto?".** São duas
perguntas, feitas nessa ordem, e uma API que mistura as duas acaba respondendo a segunda sempre que
responde a primeira.

A imagem comum é um portão só: você faz login e está dentro. Ela funciona num site pequeno com um tipo
de usuário e deixa de funcionar quando aparecem dois. Uma livraria parceira que lê o catálogo e um
funcionário que muda preços provaram, os dois, quem são, e só um deles deveria mudar um preço. Provar
quem você é não abre nada sozinho; dá ao servidor um nome sobre o qual tomar a próxima decisão.

As duas metades têm nomes que vale manter separados:

| | a pergunta | do que precisa | como é uma falha |
|---|---|---|---|
| **autenticação** | quem é este? | uma **credencial**: algo que prova um nome | 401, "não sei quem você é" |
| **autorização** | este pode fazer aquilo? | uma regra sobre o nome e a ação | 403, "sei quem você é, e não" |

Uma credencial não é o nome. `ana` é um nome que qualquer um digita; a senha que vai com ele, ou um
token que o servidor emitiu para ela, é o que o prova. Tudo nesta aula é algum tipo de credencial:
como ela é enviada, como o servidor a confere, o que o servidor guarda e como ela é retirada.

O shelf deixa a divisão visível num ponto só. O arquivo que esta aula constrói deixa todo mundo que
prova quem é ler todos os livros. Essa é toda a autorização que ele faz, com uma exceção: uma chave
de API pertence a uma aplicação, e uma aplicação não pode criar nem apagar chaves. Quando uma chave pede
a lista de chaves, o servidor sabe exatamente quem pergunta e recusa assim mesmo, e a seção sobre
chaves de API mostra essa resposta.

Onde a linha cai no resto do curso:

- as aulas 7 a 10 tratam da primeira pergunta: credenciais aqui, sessões e JWT na aula 8, dar acesso
  a outra aplicação e entrar por outro provedor na aula 9, e guardar senhas na aula 10;
- a aula 11 trata da segunda: papéis, permissões e escopos;
- as aulas 12 e 13 tratam do que acontece em volta das duas: com que frequência um cliente pode
  perguntar, e o que protege a requisição no caminho.
