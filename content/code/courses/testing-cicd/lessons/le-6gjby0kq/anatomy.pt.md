---
title: Um arquivo de workflow, linha por linha
version: 2
---

O GitHub Actions lê pipelines de arquivos YAML em `.github/workflows/` do repositório. Cada arquivo é
um **workflow**: os eventos que o disparam e os jobs que ele roda. Este faz o mesmo que o hook da
aula 5, mais a cobertura da aula 4, nas máquinas do GitHub. O diretório é novo,
`mkdir -p .github/workflows`, e o arquivo vai nele. Salve como `.github/workflows/ci.yml`:

```schooling-example
{
  "language": "yaml",
  "file": ".github/workflows/ci.yml",
  "parts": [
    {
      "code": "name: CI\n\non:\n  pull_request:\n    branches: [main]\n  push:\n    branches: [main]\n\npermissions:\n  contents: read\n\nconcurrency:\n  group: ci-${{ github.ref }}\n  cancel-in-progress: true\n",
      "note": "O nome mostrado na página, e os **gatilhos** da aula 5 seção 04: pull requests para a `main` e pushes na `main`. `permissions` limita o que o token que o GitHub dá a cada execução pode fazer, aqui só ler o código; a aula 9 trata dessa linha. `concurrency` cancela uma execução quando outra mais nova começa no mesmo branch, o que a seção 09 mostra acontecendo."
    },
    {
      "code": "jobs:\n  fast:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 5\n    steps:\n      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0\n      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0\n        with:\n          python-version: \"3.13\"\n          cache: pip\n          cache-dependency-path: requirements-dev.txt\n      - run: pip install -r requirements-dev.txt\n      - run: python -m pytest -q -m \"not integration and not functional and not acceptance\"\n",
      "note": "O primeiro **job**, `fast`. `runs-on` escolhe uma máquina virtual nova; `timeout-minutes` para um job que trava. Os **passos** rodam em ordem: `uses:` roda uma **action**, um passo empacotado que alguém publicou, e `run:` roda um comando de shell. O passo de preparação guarda em cache os downloads do pip, com uma chave tirada de `requirements-dev.txt`, que é a aula 5 seção 08 numa linha."
    },
    {
      "code": "  suite:\n    needs: fast\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10\n    strategy:\n      fail-fast: false\n      matrix:\n        python: [\"3.11\", \"3.12\", \"3.13\"]\n        tz: [\"America/Sao_Paulo\", \"UTC\"]\n    steps:",
      "note": "O segundo job só começa quando `fast` passa: `needs` é uma aresta no grafo de jobs. A `strategy.matrix` dele transforma um job em seis, três Pythons por dois fusos, e `fail-fast: false` deixa toda célula terminar, pelo motivo que a aula 5 seção 07 deu."
    },
    {
      "code": "      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0\n      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0\n        with:\n          python-version: ${{ matrix.python }}\n          cache: pip\n          cache-dependency-path: requirements-dev.txt\n      - run: pip install -r requirements-dev.txt\n      - name: Tests in ${{ matrix.tz }}\n        shell: bash\n        env:\n          TZ: ${{ matrix.tz }}\n        run: |\n          set -euo pipefail\n          coverage run -p -m pytest -q --junitxml=junit.xml",
      "note": "`${{ matrix.python }}` é preenchido por célula. O passo de teste declara o shell, então roda com `pipefail`, e começa com `set -euo pipefail` mesmo assim; o fuso chega aos testes pelo `env`."
    },
    {
      "code": "      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1\n        if: always()\n        with:\n          name: results-${{ strategy.job-index }}\n          path: |\n            junit.xml\n            .coverage.*\n          include-hidden-files: true\n",
      "note": "`if: always()` envia o relatório JUnit e os dados de cobertura **mesmo quando os testes falharam**, como um artefato com o índice da célula no nome, então seis células dão seis artefatos."
    },
    {
      "code": "  coverage:\n    needs: suite\n    if: always()\n    runs-on: ubuntu-24.04\n    timeout-minutes: 5\n    steps:\n      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0\n      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0\n        with:\n          python-version: \"3.13\"\n      - run: pip install coverage==7.16.2\n      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1\n        with:\n          pattern: results-*\n          merge-multiple: true\n      - run: coverage combine && coverage report",
      "note": "O último job roda depois da matriz, seja qual for o resultado dela, baixa os seis artefatos num diretório só e produz o relatório de cobertura combinado da aula 4 seção 09."
    }
  ]
}
```

## Conferido, não rodado

Este workflow **não rodou no GitHub**: o laboratório não tem repositório lá, e nada neste curso faz
push para um. Se você tem uma conta no GitHub, pode enviar o `shipquote` para um repositório seu e
vê-lo rodar, mas nenhuma aula depende disso. O que o laboratório consegue é conferir o arquivo com o
**actionlint**, um verificador estático de código aberto para workflows do GitHub Actions. Ele é
escrito em Go e se instala com o Go do próprio Ubuntu, em `~/go/bin`:

```sh
sudo apt-get install -y golang-go
go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.7
export PATH="$PATH:$HOME/go/bin"
```

O `export` dura enquanto o terminal durar; a mesma linha no fim do `~/.bashrc` o torna permanente.
Rodado do diretório do projeto, o actionlint acha os workflows sozinho:

```
ana@laptop:~/shipquote$ actionlint; echo "exit status $?"
exit status 0
```

Silêncio e código de saída 0 querem dizer que o actionlint não achou nada a relatar: o YAML é
válido, toda chave é uma que o GitHub conhece, e toda expressão `${{ }}` aponta para algo que existe.
(O actionlint também pode passar cada script `run:` pelo ShellCheck, que este laboratório não tem
instalado.) A próxima seção mostra o que ele relata, e o que não tem como saber, então faça antes o
commit do arquivo, com `git add .github && git commit -m "Run the checks on GitHub Actions"`, e a
próxima seção pode quebrá-lo e pô-lo de volta.

## De onde vieram as partes

Cada pedaço desse arquivo tem um par no hook da aula 5. O gatilho é o `if` no nome do branch; o job é
o corpo do laço; a matriz são os dois laços aninhados; o artefato é o diretório da execução; o
checkout limpo é o `actions/checkout` numa máquina nova. **Um arquivo de workflow é aquele script,
reescrito como uma descrição que o serviço transforma em máquinas.** A diferença que mais importa é
que o GitHub o roda no pull request, antes do merge, e pode recusar o merge quando ele falha, o que a
seção 08 configura.
