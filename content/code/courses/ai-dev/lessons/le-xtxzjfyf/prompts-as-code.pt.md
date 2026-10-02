---
title: Prompts são código
version: 1
---

Um prompt que uma funcionalidade manda a um modelo faz parte do programa. Ele decide o que a
funcionalidade faz tanto quanto qualquer função, e quebra dos mesmos jeitos: um campo esquecido, um
arquivo que cresceu além do orçamento, uma mudança que ninguém revisou. **Então ele mora onde o
código mora**: no repositório, revisado em pull requests, montado por uma função, coberto por
testes.

## Um modelo e um montador

A ana transforma o prompt da vírgula da aula 5 seção 02 num modelo, com campos `$` para o que muda
de uma tarefa para outra:

```
Goal: $goal

Context: the files below. CONVENTIONS.md is the project's rules; money is
integer cents and a float must never hold it.

$files

Constraints: change only what the goal needs. Do not change any existing test.

Done when: $done

Answer with: a unified diff, and nothing else.
```

e um montador que o preenche, sempre acrescenta o `CONVENTIONS.md` e recusa um prompt acima do
orçamento:

```schooling-example
{
  "language": "python",
  "file": "prompts/build.py",
  "parts": [
    {
      "code": "\"\"\"Build a prompt from a template in prompts/ and the files it names.\"\"\"\nfrom pathlib import Path\nfrom string import Template\n\nimport tiktoken\n\n"
    },
    {
      "code": "BUDGET = 3000\nENC = tiktoken.get_encoding(\"o200k_base\")\n\n\n",
      "note": "**Um orçamento para o prompt inteiro**, contado com a mesma codificação da aula 1."
    },
    {
      "code": "def build(template: str, files: list[str], **fields: str) -> str:\n    body = \"\\n\".join(f\"### {f}\\n{Path(f).read_text()}\" for f in [\"CONVENTIONS.md\", *files])\n",
      "note": "**As convenções entram toda vez**, primeiro, quaisquer que sejam os arquivos pedidos. Uma regra que depende de todo chamador lembrar dela é uma regra que às vezes falta."
    },
    {
      "code": "    prompt = Template(Path(\"prompts\", template).read_text()).substitute(files=body, **fields)\n    if len(ENC.encode(prompt)) > BUDGET:\n        raise ValueError(f\"{template}: over the budget of {BUDGET} tokens\")\n    return prompt",
      "note": "**Preencha o modelo com rigor, depois confira o tamanho.** Um prompt acima do orçamento é recusado aqui, antes de custar alguma coisa."
    }
  ]
}
```

## Testes para um prompt

Os testes conferem as coisas que quebram em silêncio, que são exatamente as que uma pessoa lendo o
prompt num log não notaria:

```python
import pytest

from prompts.build import build

FILES = ["shop/money.py", "tests/test_money.py"]


def test_every_field_is_filled():
    prompt = build("fix.md", FILES, goal="accept a decimal comma", done="the suite passes")
    assert "$" not in prompt


def test_a_missing_field_is_an_error_not_a_blank():
    with pytest.raises(KeyError):
        build("fix.md", FILES, goal="accept a decimal comma")


def test_the_conventions_are_always_included():
    prompt = build("fix.md", FILES, goal="g", done="d")
    assert "integer number of cents" in prompt


def test_the_prompt_fits_the_budget():
    build("fix.md", ["shop/money.py", "shop/cart.py", "shop/coupons.py"], goal="g", done="d")
```

```
ana@dev:~/shop$ touch prompts/__init__.py && python -m pytest -q tests/test_prompts.py
....                                                                     [100%]
4 passed in 0.82s
```

**O `Template.substitute` levanta `KeyError` para um campo que falta**, onde a alternativa,
`safe_substitute`, mandaria ao modelo o texto literal `$done`, que ele leria como parte da tarefa.
Um teste que falha é o desfecho melhor. O teste de orçamento é a guarda da aula 2 seção 09, escrita
uma vez, e falha no dia em que alguém acrescentar um arquivo grande ao contexto padrão.

O que esses testes não fazem é chamar um modelo. Eles testam o que é enviado, que é determinístico e
de graça; o que volta é assunto da aula 5 seção 09.

## Para o repositório

```
ana@dev:~/shop$ git add prompts/ tests/test_prompts.py && git commit -qm "Keep prompts in the repository, with tests" && git show --stat --format=%s HEAD
Keep prompts in the repository, with tests

 prompts/__init__.py   |  0
 prompts/build.py      | 16 ++++++++++++++++
 prompts/comma.md      | 13 +++++++++++++
 prompts/fix.md        | 12 ++++++++++++
 tests/test_prompts.py | 24 ++++++++++++++++++++++++
 5 files changed, 65 insertions(+)
```

Daqui em diante, uma mudança no que a loja pede a um modelo é um diff que alguém pode revisar, com um
motivo no commit, e o `git log -- prompts/` é a história de toda instrução que a funcionalidade já
deu.
