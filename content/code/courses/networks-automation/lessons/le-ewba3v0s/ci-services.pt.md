---
title: O mesmo pipeline num serviço de CI
version: 1
---

Serviços de CI hospedados, GitHub Actions, GitLab CI, Jenkins e outros, rodam os mesmos dois
estágios com mais coisa em volta: uma página web por execução, logs guardados por meses, aprovações,
agendamentos, e runners em máquinas que você escolhe. **O workflow abaixo não foi rodado no
laboratório**, que não tem serviço de CI; é o pipeline da aula escrito para o GitHub Actions, para
mostrar onde vai cada peça:

```yaml
name: network
on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt
      - run: sh ci/test.sh

  deploy:
    if: github.ref == 'refs/heads/main'
    needs: test
    runs-on: [self-hosted, netops]
    environment: production
    steps:
      - uses: actions/checkout@v4
      - run: sh ci/deploy.sh
```

O job `test` é o `pre-receive`: roda em todo pull request, numa máquina sem acesso à rede, e uma
falha bloqueia o merge quando a branch é protegida. O job `deploy` é o `post-receive`: roda só na
`main`, só depois que `test` passou, e num **runner self-hosted**, uma máquina sua dentro da rede de
gerência, já que um runner na internet não consegue alcançar os roteadores e não deveria conseguir.
`environment: production` é onde se anexam uma etapa de aprovação e os secrets do job de deploy.

O único arquivo de que ele precisa e que o projeto do laboratório não tem é o `requirements.txt`, as
bibliotecas e suas versões, que no `ctl` vêm do ambiente virtual do laboratório. **Os scripts em
`ci/` não mudaram.** Esse é o motivo de mantê-los no projeto em vez de na configuração do serviço de
CI: o pipeline pode ser rodado à mão, testado no laboratório, e levado para outro serviço
reescrevendo as vinte linhas em volta dele.
