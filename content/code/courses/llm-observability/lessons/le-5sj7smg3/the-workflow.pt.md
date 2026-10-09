---
title: O workflow
version: 2
---

Os testes rodam em qualquer lugar onde o pytest roda. No GitHub, um workflow os roda em todo pull request
que mexe em algo capaz de mudar uma resposta. Ele precisa que o repositório diga quais bibliotecas
instala, então anote-as em `~/obs`, nas versões que este curso instalou:

```sh
cat > requirements.txt <<'REQ'
openai==3.24.0
numpy==2.4.6
opentelemetry-sdk==1.45.0
presidio-analyzer==2.2.364
en_core_web_lg @ https://github.com/explosion/spacy-models/releases/download/en_core_web_lg-3.8.0/en_core_web_lg-3.8.0-py3-none-any.whl
pytest==9.1.1
REQ
```

O workflow fica em `.github/workflows/evaluation.yml`. Ele é mostrado aqui e não rodado, porque esta
máquina não é um runner do GitHub; os comandos nos seus passos são os que rodaram nas seções anteriores:

```yaml
name: evaluation

on:
  pull_request:
    paths:
      - "*.py"
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
    timeout-minutes: 90
    env:
      OPENAI_BASE_URL: http://127.0.0.1:11434/v1
      OPENAI_API_KEY: ollama
      PSEUDONYM_KEY: evaluation-${{ github.run_id }}
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt
      - name: The set, which calls no model
        run: python -m pytest -q tests/test_set.py
      - name: Ollama, and every model the releases name
        run: |
          curl -fsSL https://ollama.com/install.sh | OLLAMA_VERSION=0.40.0 sh
          timeout 60 sh -c 'until ollama list > /dev/null 2>&1; do sleep 1; done'
          ollama pull all-minilm
          for m in $(python -c 'import json; print(*{r["model"] for r in json.load(open("releases.json")).values()})'); do
            ollama pull "$m"
          done
      - name: The index, from the documents in this pull request
        run: python index.py
      - name: The candidate against production
        run: |
          CANDIDATE=$(python -c 'import json; r = json.load(open("releases.json")); print(max(r, key=lambda k: r[k]["from"]))')
          CANDIDATE=$CANDIDATE python -m pytest -q tests/test_regression.py
```

Cada escolha nele é uma lição de antes no curso:

- **Os caminhos são tudo o que pode mudar uma resposta**, não só o assistente: todo programa, os
  documentos que a busca lê, os preços em que o orçamento é medido, as dependências (uma atualização de
  biblioteca é uma mudança de modelo disfarçada), o conjunto e o portão. Um filtro que esquece um deixa
  esse tipo de mudança ser mesclado sem teste, em silêncio; um que inclui demais custa alguns minutos. Na
  dúvida, o filtro erra para o lado de rodar.
- **Os testes do conjunto vêm primeiro e não precisam de modelo**, então um pull request que quebra o
  conjunto falha em segundos, antes de qualquer download.
- **O runner recebe o mesmo modelo que você tem**, na mesma versão do Ollama, e nenhuma chave. Todo modelo
  que o `releases.json` nomeia é baixado, porque a candidata pode usar um que a produção não usa. Um
  runner sem GPU responde mais devagar que a sua máquina, e é para isso que servem os 90 minutos; e o
  orçamento de latência continua comparando igual com igual, porque as duas versões respondem no mesmo
  runner, na mesma execução.
- **O `PSEUDONYM_KEY` é novo a cada execução, e nunca o da produção.** O assistente da aula 2 se recusa
  a registrar um id de usuário sem ele, e o único usuário aqui é o `evalrun`, cujo pseudônimo ninguém
  precisa casar entre execuções. A chave que protege os ids de clientes reais fica onde é guardada.
- **O índice é construído a partir dos documentos do pull request**, então uma mudança num documento é
  testada contra o que o assistente vai buscar depois do merge, não contra o índice de antes.
- **A candidata é a versão mais nova no `releases.json`**, a que o pull request acrescenta. A produção é
  o que está no ar agora, decidido no `conftest.py` pela mesma função que o assistente usa.
- **As actions são fixadas em commits**, com a tag ao lado de cada uma, para que o que roda seja o que foi
  revisado, e não aquilo para onde uma tag aponta hoje.

No caminho online, o passo que instala o Ollama sai, e as duas variáveis viram uma chave dos secrets do
repositório, só para avaliação e com o seu próprio limite de gasto no provedor. Um pipeline que responde
32 perguntas duas vezes por pull request é uma conta previsível, e uma chave separada a torna visível,
como a aula 3 pediu de toda funcionalidade. Um pull request vindo de um fork não recebe secrets, então ali
só os testes do conjunto podem rodar, e o workflow deve dizer isso em vez de passar.

## O que um modelo acrescenta a um teste

Um teste de código comum dá a mesma resposta toda vez que roda no mesmo commit. Este não precisa dar. A
aula 14 achou a e31 respondida de dois jeitos pela mesma configuração com temperatura 0, e o orçamento
de latência acima passou numa execução e reprovou em outra. Então um caso pode falhar uma vez e passar na
execução seguinte sem nada ter mudado.

O portão continua o mesmo, e a resposta a uma falha também: **ler o caso**. Um caso que falha numa
execução da candidata e passa na seguinte é evidência de que a resposta é instável, uma propriedade da
versão que vale a pena saber. Não é motivo para rodar de novo até o portão ficar verde: um portão que é
rodado até passar é um portão que passa.
