---
title: O workflow
version: 1
---

Os testes rodam em qualquer lugar onde o pytest roda. No GitHub, um workflow os roda em todo pull request
que mexe em algo capaz de mudar uma resposta. O arquivo abaixo é mostrado e não rodado aqui, já que esta
máquina não é um runner do GitHub; os comandos dos seus passos são os que rodaram nas seções anteriores:

```yaml
name: evaluation

on:
  pull_request:
    paths:
      - "assistant.py"
      - "releases.json"
      - "prices.json"
      - "requirements.txt"
      - "data/docs/**"
      - "data/eval-v2.jsonl"
      - "data/eval-v2.manifest.json"
      - "gate.json"
      - "tests/**"
      - ".github/workflows/evaluation.yml"

permissions:
  contents: read

jobs:
  gate:
    runs-on: ubuntu-24.04
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        with:
          python-version: "3.11"
      - run: pip install -r requirements.txt
      - name: The set, which calls no model
        run: python -m pytest -q tests/test_set.py
      - name: The candidate against production
        env:
          OPENAI_API_KEY: ${{ secrets.EVALUATION_OPENAI_KEY }}
        run: |
          CANDIDATE=$(python -c 'import json; r = json.load(open("releases.json")); print(max(r, key=lambda k: r[k]["from"]))')
          CANDIDATE=$CANDIDATE python -m pytest -q tests/test_regression.py
```

Cada escolha nele é uma lição de antes no curso:

- **Os caminhos são tudo o que pode mudar uma resposta**, não só o código: os documentos que a busca lê,
  os preços em que o orçamento é medido, as dependências (atualizar uma biblioteca é uma troca de modelo
  disfarçada), o conjunto e o portão. Um filtro que esquece um deixa esse tipo de mudança fazer merge sem
  teste, em silêncio; um que inclui demais custa alguns centavos. Na dúvida, o filtro erra para o lado de
  rodar.
- **Os testes do conjunto vêm primeiro e não precisam de segredo**, então um pull request vindo de um
  fork, que não recebe segredos, ainda tem o seu conjunto conferido.
- **A chave é um segredo, só para avaliação**, com limite de gasto próprio no provedor. Um pipeline que
  responde a quarenta e duas perguntas duas vezes por pull request é uma conta previsível, e uma chave
  separada a torna visível, como a aula 3 pediu de toda funcionalidade.
- **A candidata é a versão mais nova do `releases.json`**, a que o pull request acrescenta. A produção é a
  que está no ar agora, decidida no `conftest.py` pela mesma função que o assistente usa.
- **As actions são fixadas em commits**, com a tag ao lado de cada uma, como os próprios workflows deste
  repositório fixam as suas.

## Uma coisa que um modelo de verdade acrescenta

O extract-1 dá a mesma resposta à mesma pergunta toda vez, então um caso quebrado neste laboratório está
quebrado em toda execução. Um modelo de verdade, que sorteia os seus tokens, pode não dar: um caso pode
falhar uma vez e passar na próxima execução sem nada mudar. Pedir temperatura 0 torna isso mais raro e
não elimina. O portão continua o mesmo, e a resposta a uma falha também: ler o caso. Um caso que falha
numa execução da candidata e passa na seguinte é evidência de que a resposta é instável, uma propriedade
da versão que vale saber, e não motivo para rodar de novo até o portão ficar verde.
