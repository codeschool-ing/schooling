---
title: O mesmo pipeline no GitLab CI
version: 2
---

O GitLab lê o pipeline de um arquivo só na raiz do repositório, `.gitlab-ci.yml`. As ideias são as
das últimas quatro seções; o vocabulário e o arranjo mudam. O `shipquote` tem as mesmas
verificações escritas para ele, na raiz do projeto. Salve como `.gitlab-ci.yml`:

```schooling-example
{
  "language": "yaml",
  "file": ".gitlab-ci.yml",
  "parts": [
    {
      "code": "stages: [fast, test, report]\n\nworkflow:\n  rules:\n    - if: $CI_PIPELINE_SOURCE == \"merge_request_event\"\n    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH\n",
      "note": "**Estágios** rodam em ordem, e todo job de um estágio roda em paralelo. As regras do `workflow` são os gatilhos: um pipeline para um merge request, e um para o branch padrão."
    },
    {
      "code": "default:\n  image: python:3.13-slim\n\nvariables:\n  PIP_CACHE_DIR: \"$CI_PROJECT_DIR/.cache/pip\"\n\ncache:\n  key:\n    files: [requirements-dev.txt]\n  paths: [.cache/pip]",
      "note": "Todo job roda **num contêiner**, a partir de `image`. O cache do pip fica no diretório do projeto para o runner poder guardá-lo entre jobs, sob uma chave calculada de `requirements-dev.txt`."
    },
    {
      "code": "\nfast:\n  stage: fast\n  script:\n    - pip install -q -r requirements-dev.txt\n    - python -m pytest -q -m \"not integration and not functional and not acceptance\"",
      "note": "Um job é um nome no nível de cima com um `stage` e um `script`: uma lista de comandos de shell, e o primeiro que falha para o job."
    },
    {
      "code": "\nsuite:\n  stage: test\n  image: python:${PYTHON}-slim\n  parallel:\n    matrix:\n      - PYTHON: [\"3.11\", \"3.12\", \"3.13\"]\n        TZ: [\"America/Sao_Paulo\", \"UTC\"]\n  script:\n    - pip install -q -r requirements-dev.txt\n    - coverage run -p -m pytest -q --junitxml=junit.xml\n  artifacts:\n    when: always\n    paths: [\".coverage.*\"]\n    reports:\n      junit: junit.xml",
      "note": "`parallel: matrix` faz seis jobs a partir de duas listas, e as variáveis de cada célula chegam ao script como variáveis de ambiente, `TZ` incluída. A própria imagem depende da célula, então cada versão do Python roda no contêiner oficial dela. `artifacts: when: always` guarda os arquivos de cobertura e entrega o relatório JUnit ao GitLab, que mostra as falhas no merge request."
    },
    {
      "code": "\ncoverage:\n  stage: report\n  when: always\n  script:\n    - pip install -q coverage==7.16.2\n    - coverage combine\n    - coverage report\n  coverage: '/^TOTAL.*\\s(\\d+)%$/'",
      "note": "O estágio de relatório roda depois dos testes aconteça o que acontecer, recebe os artefatos dos estágios anteriores, combina, e uma expressão regular diz ao GitLab onde está a cobertura total na saída."
    }
  ]
}
```

## Rodando

Este arquivo **rodou**, nesta máquina, pelo `gitlab-ci-local`, um programa de código aberto que lê um
`.gitlab-ci.yml` e roda os jobs em Docker do jeito que o runner do GitLab rodaria. É um emulador, não o
GitLab, e o laboratório deixa isso claro porque importa: ele não mostra um merge request, não impõe
nada, e o comportamento dele pode diferir do GitLab em detalhes. Para conferir que um pipeline faz o
que quem o escreveu quis, antes do push, é uma boa ferramenta.

**Rodá-lo você mesmo é opcional**, porque ele precisa de Docker e de Node.js, o que são algumas
centenas de megabytes e um serviço rodando em segundo plano. No Ubuntu 24.04 os pacotes são os do
próprio sistema, e o seu usuário precisa entrar no grupo `docker`, o que vale a partir do próximo
login:

```sh
sudo apt-get install -y docker.io npm
sudo usermod -aG docker "$USER"
sudo npm install -g gitlab-ci-local@4.76.0
```

Essa instalação não foi executada para este curso; a transcrição abaixo é a mesma versão do
`gitlab-ci-local`, rodada contra o Docker 29. Se você pular, o que importa é a saída, e nada adiante
depende disso. De todo jeito, faça o commit do arquivo:
`git add .gitlab-ci.yml && git commit -m "Run the checks on GitLab CI"`.

Primeiro os jobs que o arquivo define, e depois o próprio pipeline:

```
ana@laptop:~/shipquote$ gitlab-ci-local --list
parsing and downloads finished in 87 ms.
json schema validated in 263 ms
name                             description  stage   when        allow_failure  environment  needs
fast                                          fast    on_success  false                     
suite: [3.11,America/Sao_Paulo]               test    on_success  false                     
suite: [3.11,UTC]                             test    on_success  false                     
suite: [3.12,America/Sao_Paulo]               test    on_success  false                     
suite: [3.12,UTC]                             test    on_success  false                     
suite: [3.13,America/Sao_Paulo]               test    on_success  false                     
suite: [3.13,UTC]                             test    on_success  false                     
coverage                                      report  always      false                     
ana@laptop:~/shipquote$ gitlab-ci-local > gcl.log 2>&1
ana@laptop:~/shipquote$ grep -E "^ (PASS|FAIL)|pipeline finished" gcl.log
 PASS  fast                           
 PASS  suite: [3.11,America/Sao_Paulo]
 PASS  suite: [3.11,UTC]              
 PASS  suite: [3.12,America/Sao_Paulo]
 PASS  suite: [3.12,UTC]              
 PASS  suite: [3.13,America/Sao_Paulo]
 PASS  suite: [3.13,UTC]              
 PASS  coverage                        81% coverage
pipeline finished in 30 s
ana@laptop:~/shipquote$ grep -E "^coverage .*(Combined|TOTAL)" gcl.log
coverage                        > Combined 2 files, skipped 4
coverage                        > TOTAL                     164     32     24      4    81%
```

Oito jobs: `fast`, as seis células da matriz com os valores no nome, e `coverage`, cujo `when` é
`always`. Os oito passaram, em **30 segundos** de relógio, com cada célula da matriz num contêiner
separado das imagens oficiais do Python 3.11, 3.12 e 3.13. O job de cobertura combinou os seis
arquivos de dados em **81%**, o mesmo número de todas as outras medições deste curso desde a aula 4.

A primeira linha da saída dele merece um olhar: `Combined 2 files, skipped 4`. O `coverage combine`
pula um arquivo de dados cujo conteúdo é idêntico a um que já combinou, e quatro das seis células
tinham medido exatamente as mesmas linhas que outra. Uma união não muda com uma duplicata, então nada
se perdeu; a linha lembra que o relatório é uma união do que rodou, não uma soma.

## O que o emulador não fez

Ele não aplicou as regras do `workflow` do jeito que o GitLab aplica para um merge request, já que não
há merge request; não bloqueia um merge; e rodou numa máquina só, onde o GitLab espalharia as seis
células pelos runners livres. Essas são as partes de um serviço de CI que tratam da equipe e não dos
jobs, e são o assunto da seção 08 para o GitHub. No GitLab a mesma proteção é a configuração do
projeto que só deixa um merge request entrar quando o pipeline dele dá certo.
