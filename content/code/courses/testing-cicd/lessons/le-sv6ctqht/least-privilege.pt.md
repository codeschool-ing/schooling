---
title: Menor privilégio para o próprio pipeline
version: 1
---

**Menor privilégio** é a regra de que toda credencial faz exatamente o que o trabalho de quem a tem
pede, e nada mais. Aplicado a segredos, limita o estrago de um vazamento: um token que só lê preços
vaza preços. Aplicado a um pipeline, quer dizer que cada job recebe o menor conjunto de permissões com
que consegue trabalhar.

O GitHub Actions dá a cada execução um token automático, `GITHUB_TOKEN`, que pode agir sobre o
repositório que a iniciou. O que ele pode fazer é definido por `permissions:` no workflow. O workflow
de CI deste repositório define isso uma vez, no topo, para todos os jobs:

```yaml
permissions:
  contents: read
```

Ler o código, e mais nada. Um job de teste comprometido, por uma dependência maliciosa digamos,
consegue ler o que qualquer um já lê e não consegue enviar um commit, abrir um release nem mudar uma
configuração. O workflow do `shipquote` da aula 6 declara o mesmo.

## Aumentando permissões por job, só onde precisa

O workflow de release começa do mesmo `contents: read` e o aumenta em dois jobs, cada um com um
comentário dizendo por quê. O job que cria o release:

```yaml
    permissions:
      contents: write # creating the release
```

e o job que implanta:

```yaml
    permissions:
      contents: read
      # The OIDC token the exchange is built on. It is the only reason this job
      # has any permission beyond reading the code.
      id-token: write
```

`contents: write` é preciso para criar um release e só o `Publish` tem. `id-token: write` é preciso para
pedir ao GitHub o token de que trata a seção 09, e o comentário ao lado diz que é a única permissão
que o job de deploy tem além de ler o código. **Uma permissão dada a um job não é dada ao workflow**,
então um job de teste rodando ao lado do deploy não consegue pegar nenhuma delas emprestada.

## A mesma ideia fora do GitHub

| credencial | versão de menor privilégio |
|---|---|
| uma conta de nuvem para deploys | um papel que atualiza um serviço, não um que administra o projeto |
| um usuário de banco para o app | direitos nas tabelas do app, não o dono do banco |
| um token da transportadora | só cotação, se o fornecedor oferece escopos; outro token para remessas |
| um runner | uma máquina nova por job, sem credenciais próprias deixadas para trás |

Menor privilégio custa alguma configuração e algum atrito: um job vai falhar um dia por faltar uma
permissão de que ele precisa de fato, e alguém vai ter de acrescentá-la, com um comentário. Essa falha
é o sistema funcionando. A alternativa, um token que faz tudo, falha em silêncio no dia em que vaza.
