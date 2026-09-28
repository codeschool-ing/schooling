---
title: Marcando um marco no git
version: 1
---

Um marco que só está na sua cabeça não pode ser encontrado de novo. O git tem um nome para um commit que
você quer encontrar de novo: uma **tag**. Uma tag anotada carrega uma mensagem, e a mensagem é onde vai a
descrição de uma linha do marco:

```
ana@laptop:~/loanbook$ git tag -a v0.2.0 -m 'The rules: one loan at a time, overdue after seven days'
ana@laptop:~/loanbook$ git tag -n
v0.1.0          The skeleton: list, lend and take back, end to end
v0.2.0          The rules: one loan at a time, overdue after seven days
```

`git tag -a` cria a tag anotada no commit atual, e `git tag -n` lista todas as tags com a primeira linha
da mensagem. No fim do projeto a lista se lê como um sumário:

```
ana@laptop:~/loanbook$ git tag -n
v0.1.0          The skeleton: list, lend and take back, end to end
v0.2.0          The rules: one loan at a time, overdue after seven days
v0.3.0          Deployed: a container under systemd, behind Caddy
v1.0.0          First version worth showing
```

Os nomes seguem o **versionamento semântico**: `MAJOR.MINOR.PATCH`, com `0` como número maior enquanto o
projeto ainda não é a primeira versão que vale mostrar. `v1.0.0` é a afirmação de que é. Ninguém confere
os números contra uma regra, mas quem avalia e vê `v1.0.0` espera o *terminado* da aula 2, e um projeto
que marca o primeiro commit como `v1.0.0` gastou a palavra cedo demais.

As tags também facilitam comparações. Tudo o que mudou entre *as regras valem* e *está implantado* é um
comando só:

```
ana@laptop:~/loanbook$ git diff --stat v0.2.0 v0.3.0
 .gitignore                |  1 +
 Containerfile             |  8 +++++++
 app.py                    | 10 +++++++--
 deploy/Caddyfile          |  4 ++++
 deploy/loanbook.container | 15 +++++++++++++
 static/app.js             | 80 +++++++++++++++++++++++++++++++++++++++++++++++--------------------
 static/index.html         | 17 +++++++++------
 static/style.css          | 21 ++++++++++++++----
 test_app.py               |  5 +++++
 9 files changed, 124 insertions(+), 37 deletions(-)
```

Essa é a resposta para *quanto custou o marco do deploy?*, e é evidência para a aula 21. No GitHub ou no
GitLab cada tag também pode virar uma **release**, uma página com notas e downloads; para um projeto de
portfólio, enviar as tags com `git push --tags` e escrever duas linhas de notas em cada uma basta.
