---
title: O mesmo workflow, corrigido
version: 1
---

Cada achado tem uma correção de poucos caracteres, e nenhuma delas tira do workflow algo de que ele
precisava. **O job testa a mudança; ele não precisa escrever nada, guardar segredo nenhum nem rodar
código que ninguém revisou com privilégios que ninguém concedeu.** O workflow corrigido, com cada
mudança respondendo a um achado da seção anterior.

### Fixe por commit, e confira o pin

Um pin é um hash de commit, e o hash tem de ser o que a versão nomeia. O `git ls-remote` pergunta a um
repositório para onde as tags dele apontam, sem cloná-lo:

```
ana@vm:~/linkbox$ git ls-remote https://github.com/actions/checkout refs/tags/v6 refs/tags/v6.1.0
d23441a48e516b6c34aea4fa41551a30e30af803	refs/tags/v6
d23441a48e516b6c34aea4fa41551a30e30af803	refs/tags/v6.1.0
ana@vm:~/linkbox$ git ls-remote https://github.com/astral-sh/setup-uv refs/tags/v9.0.0
c771a70e6277c0a99b617c7a806ffedaca235ff9	refs/tags/v9.0.0
```

Duas coisas a ler. **`v6` e `v6.1.0` nomeiam o mesmo commit hoje**, que é o propósito de uma tag de
major que se move: ela acompanha o último release, e vai nomear outro commit depois do próximo. O pin
é o hash ao lado de `v6.1.0`. E uma tag anotada imprimiria uma segunda linha terminada em `^{}`, o
commit para o qual o objeto da tag aponta, que é o que se fixa; estas duas tags são leves, então há
uma linha para cada. A versão vai num comentário ao lado do hash, porque um hash sozinho não diz nada
a quem lê depois, e porque as ferramentas que propõem atualizações, que a aula 18 configura, leem esse
comentário para saber qual release o pin representa.

### O arquivo

Salve-o como `.github/workflows/ci.yml`:

```yaml
# linkbox's tests on GitHub Actions, for a copy of the repository hosted
# there. Nothing in it runs with more than it needs: the token reads the
# code and nothing else, every action is pinned to a commit, and text that
# a pull request's author wrote reaches a shell only as data.
name: ci
on:
  pull_request:
  push:
    branches: [main]
permissions:
  contents: read
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true
jobs:
  test:
    name: tests
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@d23441a48e516b6c34aea4fa41551a30e30af803 # v6.1.0
        with:
          persist-credentials: false
      - uses: astral-sh/setup-uv@c771a70e6277c0a99b617c7a806ffedaca235ff9 # v9.0.0
      - name: Say which change this is
        env:
          TITLE: ${{ github.event.pull_request.title }}
        run: echo "testing $TITLE"
      - run: bash ci/test.sh
```

Linha a linha, contra os achados:

| achado | a correção |
|---|---|
| `dangerous-triggers` | `pull_request` em vez de `pull_request_target`, e sem `ref:`: o checkout pega o commit que o evento nomeia, com um token só de leitura |
| `excessive-permissions` | `permissions: contents: read` no topo, para todo job; um job que precise de mais diz isso ele mesmo |
| `template-injection` | o título vai para `TITLE` em `env:`, e o script lê `$TITLE`, um valor que o shell nunca interpreta como código |
| `unpinned-uses` | as duas actions por hash completo de commit, com a versão num comentário |
| `artipacked` | `persist-credentials: false`, para o token não ficar no `.git/config` |
| `anonymous-definition`, `concurrency-limits` | um `name` para o job, e uma execução por branch de cada vez, cancelando a mais antiga |

**O `permissions` é declarado no arquivo em vez de deixado para as configurações do repositório**,
porque uma configuração pode ser mudada por qualquer pessoa com permissão de admin e não deixa rastro
numa revisão, enquanto uma linha no workflow é revisada com o código. A documentação do GitHub descreve
o `GITHUB_TOKEN` como um token criado para cada job e que expira quando ele termina, com as permissões
que o workflow concede; quando o arquivo não diz nada, vale o padrão do repositório ou da organização.

A varredura, nas duas personas:

```
ana@vm:~/linkbox$ zizmor --quiet --offline .github; echo "exit status $?"
No findings to report. Good job!
exit status 0
ana@vm:~/linkbox$ zizmor --quiet --offline --persona auditor .github
No findings to report. Good job!
```

Nada reportado, e nada suprimido. **Este workflow nunca foi executado**: a máquina de gravação não
consegue rodar os runners hospedados do GitHub, então o que ele imprimiria no GitHub não aparece aqui.
O que foi conferido é o arquivo, que é onde estes erros moram.

### O que o arquivo não corrige

O workflow roda só o `ci/test.sh`. O resto do pipeline do linkbox precisa do registry, dos scanners e
da chave de assinatura da CI local, e levá-lo para um runner hospedado é um projeto à parte, com as
chaves indo para o cofre de segredos da plataforma ou, melhor, substituídas pela identidade federada
da aula 17. Os quatro controles acima se aplicam a ele sem mudança quando ele se mudar.
