---
title: Entregando um segredo a um job do pipeline
version: 1
---

Um serviço de CI guarda segredos num cofre próprio, criptografado, e os entrega aos jobs na hora de
rodar. No GitHub Actions eles são **segredos de repositório**, **de organização** ou **de ambiente**, e
um workflow se refere a um pelo nome:

```yaml
  contract:
    runs-on: ubuntu-24.04
    environment: staging
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - run: pip install -r requirements-dev.txt
      - run: python -m pytest -m contract -rs
        env:
          CARRIER_URL: https://sandbox.carrier.example
          CARRIER_TOKEN: ${{ secrets.CARRIER_SANDBOX_TOKEN }}
```

Este é um esboço do job que rodaria os testes de contrato da aula 2 contra a sandbox de uma
transportadora; não está no workflow do `shipquote`, porque o laboratório não tem repositório no GitHub
nem conta numa transportadora. Três escolhas nele são o ponto.

**O segredo é entregue a um passo, pelo `env`.** Só o passo que precisa o recebe, e como variável de
ambiente e não como argumento, pelo motivo da seção 04. Um segredo posto no `env` do nível do workflow
estaria em todo passo de todo job, inclusive nos que rodam código que ninguém da equipe escreveu.

**O job nomeia um ambiente.** `environment: staging` quer dizer que o segredo vem do cofre do ambiente
de homologação, e o job fica sujeito às regras de proteção desse ambiente. Um token de produção só
vive no ambiente de produção, então um job que não o declara não tem como recebê-lo, diga o YAML dele
o que disser. É a tabela da aula 8 seção 10, imposta.

**O teste é o de contrato, e ele não pula.** A aula 2 avisou que um teste de contrato sem
`CARRIER_URL` é pulado para sempre e relata sucesso; este job é onde a variável finalmente é
definida, e o `-rs` torna visível no log um pulo, se ele voltar a acontecer.

## Os equivalentes no GitLab

O GitLab guarda **variáveis de CI/CD** por projeto, grupo ou instância. Uma variável pode ser
**mascarada**, para o valor ficar escondido nos logs dos jobs (a seção 06 mostra o que isso cobre e o
que não cobre), e **protegida**, para só ser entregue a pipelines em branches e tags protegidos. Uma
variável não protegida chega a qualquer pipeline, inclusive o de um branch que alguém enviou cinco
minutos atrás, e é por isso que credenciais de produção são sempre protegidas e em geral restritas a um
ambiente protegido também.
