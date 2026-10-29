---
title: O workflow, linha a linha
version: 1
---

**Um workflow do GitHub Actions é um arquivo YAML em `.github/workflows/` que diz quando rodar, em que tipo
de máquina e quais comandos.** O GitHub lê todo arquivo dessa pasta a cada push e pull request, e roda os
que têm gatilhos que combinam. Este é o do planner, e ele roda os quatro passos da primeira seção desta
aula. **Ele não foi executado para este curso**: precisa do repositório no GitHub. Tudo o que ele roda,
você rodou nas três seções anteriores.

```schooling-example
{"language": "yaml", "file": ".github/workflows/ci.yml", "parts": [
 {"code": "# .github/workflows/ci.yml\nname: CI", "note": "O nome que o GitHub mostra ao lado das conferências de um pull request."},
 {"code": "\non:\n  pull_request:\n  push:\n    branches: [main]", "note": "Quando roda: em todo pull request, sobre o código que o merge produziria, e em todo push no `main`, para o próprio branch ser conferido depois de cada merge."},
 {"code": "\npermissions:\n  contents: read", "note": "O que o token do próprio workflow pode fazer. Ler o repositório é tudo de que os quatro passos precisam, e o que um workflow não recebe, um passo comprometido não consegue usar."},
 {"code": "\nconcurrency:\n  group: ci-${{ github.ref }}\n  cancel-in-progress: true", "note": "Dois pushes no mesmo branch num minuto: a primeira execução é cancelada, já que só o resultado mais novo importa."},
 {"code": "\njobs:\n  check:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10", "note": "Um job, numa máquina Ubuntu 24.04 nova que o GitHub sobe para ele e joga fora depois. Uma versão, e não `ubuntu-latest`, para a máquina mudar quando você decidir. O tempo limite impede um passo travado de queimar uma hora de minutos."},
 {"code": "    steps:\n      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1\n        with:\n          persist-credentials: false", "note": "Clonar o repositório: a cópia limpa. `persist-credentials: false` impede o token de ficar na configuração git do clone, onde um passo seguinte poderia lê-lo."},
 {"code": "      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0\n        with:\n          node-version: 22.22.0\n          cache: npm", "note": "O Node na versão exata que o curso usa, e o cache de downloads do npm guardado entre execuções, com o lockfile como chave. A próxima seção mede quanto isso economiza."},
 {"code": "      - run: npm ci\n      - run: npx tsc\n      - run: npm test\n      - run: npx vite build", "note": "O pipeline: instalar a partir do lockfile, tipos, testes, build. Um passo que sai com erro para o job e o deixa vermelho."}
]}
```

## Por que um commit e não uma versão

`uses: actions/checkout@v7` funcionaria, e significaria **o que quer que a tag `v7` aponte no dia em que o
workflow rodar**. Uma tag no repositório de outra pessoa pode ser movida, pelos donos ou por quem tomar a
conta deles, e o código para o qual ela passa a apontar roda então no seu pipeline, com o seu token.
Quarenta caracteres de commit não podem ser movidos: eles nomeiam uma versão exata do código da action. O
comentário ao lado de cada um é para quem precisa decidir se ele está velho; uma ferramenta como o
Dependabot atualiza os dois juntos.

As duas actions daqui foram conferidas quanto ao runtime que declaram, porque o GitHub aposenta runtimes
antigos de Node para actions no próprio ritmo: as duas dizem `node24` no seu `action.yml`.

## O que você vê num pull request

O GitHub mostra uma linha por job no pull request, `CI / check`, com uma bolinha amarela enquanto roda,
depois um visto verde ou um X vermelho. Um clique abre o log, uma seção dobrável por passo, e um passo
vermelho já vem aberto na linha que falhou. **Esse log é o mesmo texto que o seu terminal imprimiu** nas
três últimas seções: a recusa do `npm ci`, o teste que esperava 85 e recebeu 130, o erro de tipo em
`./format`. Nada no CI é novo; são as suas conferências, rodando onde todo mundo vê.

Acrescente o arquivo ao planner, para o repositório levar o próprio pipeline:

```
ana@dev:~/planner$ git add .github/workflows/ci.yml
ana@dev:~/planner$ git commit -qm "Run the checks on every pull request"
```
