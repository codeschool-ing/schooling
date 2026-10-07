---
title: A chave é o problema inteiro
version: 1
---

A aula 3 terminou com uma coluna perfeitamente cifrada e uma chave parada no log do servidor. Isso
não é uma história do pgcrypto; é o formato de quase toda falha de criptografia. **Os algoritmos
são a parte que ninguém erra mais. As chaves são a parte que todo mundo erra.**

Onde uma chave vai parar quando ninguém decidiu onde ela deveria ficar:

- **no código**, como constante, e portanto no repositório, em todo clone, em todo fork, e no
  histórico muito depois de alguém tê-la "removido";
- **num arquivo de configuração** ao lado da aplicação, legível por quem lê a aplicação, e copiado
  para todo backup do servidor;
- **numa variável de ambiente**, que acaba em listagens de processos, relatórios de erro e na
  saída de ferramentas de depuração;
- **na consulta**, como a aula 3 mostrou, e dali em todo log.

Cada um desses põe a chave **ao lado do dado que ela protege**, ou ao lado das pessoas de quem ela
deveria proteger o dado. Um backup cifrado com a chave no mesmo bucket é um backup com um passo a
mais.

## Uma chave tem uma vida

Tratar uma chave como um valor que se gera uma vez e se cola em algum lugar deixa de fora quase
tudo o que acontece com ela. Toda chave passa pelas mesmas etapas, e cada etapa tem uma pergunta
que alguém precisa responder:

| etapa | a pergunta |
|---|---|
| **gerar** | a partir de que aleatoriedade, em qual máquina, vista por quem? |
| **guardar** | onde, protegida por quê, legível por qual processo? |
| **usar** | quem pode pedir que ela seja usada, para qual operação, e isso fica registrado? |
| **rotacionar** | a cada quanto tempo se faz uma versão nova, e o que acontece com o dado cifrado pela antiga? |
| **revogar** | como uma versão sai de uso quando pode ter vazado? |
| **destruir** | como ela é apagada, e sobra algo que ela era o único jeito de ler? |

Um time que responde às seis para toda chave que tem está gerindo chaves. Um time que responde à
primeira e não às outras tem um segredo num arquivo.

## O que esta aula constrói

A resposta em que a indústria se acertou é parar de entregar chaves. Um **serviço de gestão de
chaves** guarda as chaves e oferece o *uso* delas: mande a ele um texto claro e o nome de uma
chave, receba um texto cifrado, e nunca veja a chave. Esta aula roda um — o **OpenBao**, o fork de
código aberto do HashiCorp Vault — e o usa para quatro trabalhos: cifrar o CPF na aplicação,
cifrar um backup, rotacionar uma chave sem perder o dado e destruir uma chave de propósito. Os
serviços dos provedores de nuvem fazem os mesmos trabalhos com comandos próprios, e a seção 12 os
mapeia.
