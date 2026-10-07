---
title: Código que você não revisou, rodando com seus segredos
version: 1
---

Um pipeline roda código. Em geral é o código da própria equipe, revisado, mais actions e dependências
que a equipe escolheu. Duas situações quebram essa suposição, e as duas são de onde segredos já
vazaram em projetos de verdade.

## Pull requests de forks

Num repositório público, qualquer pessoa pode fazer um fork, mudar o workflow ou os testes, e abrir um
pull request. Se o pipeline rodasse esse pull request **com os segredos do repositório**, um estranho
poderia escrever um teste que os imprime, ou os manda para algum lugar. Então os serviços hospedados
não fazem isso: no GitHub Actions, um workflow disparado por `pull_request` vindo de um fork **não
recebe segredos** e o `GITHUB_TOKEN` dele é só de leitura. O GitLab trata merge requests de forks de
forma parecida por padrão. O pipeline ainda roda, e ainda confere a mudança; só não segura nada que
valha a pena levar.

## O gatilho que os devolve

O GitHub também oferece o `pull_request_target`, que roda no contexto do repositório **de base**, com
os segredos dele e um token que grava. Ele existe para jobs que precisam desses poderes num pull
request vindo de um fork, como rotulá-lo ou postar um comentário, e só é seguro enquanto **o job nunca
fizer checkout do código do pull request nem rodá-lo**. Um workflow que usa `pull_request_target` e
depois faz checkout da cabeça do pull request e roda os testes dela entregou ao código de um estranho
os segredos do repositório. A própria orientação de segurança do GitHub aponta esse padrão como
perigoso, e a defesa é a regra simples: com `pull_request_target`, trate o conteúdo do pull request
como dado, nunca como código.

## Actions e dependências de terceiros

Toda action que um job usa e todo pacote que ele instala rodam com as permissões do job e os segredos
dados ao job. A aula 6 seção 04 fixou actions em hashes de commit por esse motivo; o mesmo raciocínio
vale para as dependências, que estão fixadas em `requirements-dev.txt`. Dois hábitos a mais limitam o
estrago quando algo nessa cadeia vira hostil:

- **Entregue segredos aos passos que precisam deles**, como a seção 05 fez, não ao workflow inteiro.
- **Mantenha pequenos os jobs que seguram segredos.** Um job de deploy que só baixa um artefato e roda
  um script de deploy roda muito pouco código de terceiros; um job de deploy que também instala e roda
  todo o ferramental de testes roda muito.

Na trilha `devsecops`, a aula 16 de `secure-pipeline` endurece runners e actions a fundo.
