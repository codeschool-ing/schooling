---
title: Um cartão é metadado e texto
version: 1
---

A aula 1 seção 05 leu um cartão de modelo como documento. No Hub ele também é **dado**, e a documentação
do Hub diz como:

```
ana@desk:~/desk$ sources quote hub-model-cards "simple Markdown files with additional metadata|YAML.*section at the top"
# huggingface/hub-docs@08175d0f docs/hub/model-cards.md
   6: Model cards are files that accompany the models and provide handy information. Under the
      hood, model cards are simple Markdown files with additional metadata. Model cards are
      essential for discoverability, reproducibility, and sharing! You can find a model card
      as the `README.md` file in any model repo.
  25: A model repo will render its `README.md` as a model card. The model card is a
      [Markdown](https://en.wikipedia.org/wiki/Markdown) file, with a
      [YAML](https://en.wikipedia.org/wiki/YAML) section at the top that contains metadata
      about the model.
```

O YAML no topo é por onde o Hub filtra e liga: a licença, os idiomas, a tarefa, o modelo de onde ele
partiu. O `lab/cards.py` escreve os metadados que um fine-tuning da ana teria, se ela um dia publicasse
um, com as classes da própria `huggingface_hub`, e lê de volta:

```python
from huggingface_hub import ModelCard, ModelCardData

# The metadata a fine-tune of ana's would carry, if she ever published one.
data = ModelCardData(language=["en", "pt"], license="apache-2.0", base_model="Qwen/Qwen3-8B",
                     pipeline_tag="text-classification", tags=["customer-support"])
content = f"---\n{data.to_yaml()}\n---\n\n# lantern-books/email-sorter\n\nSorts a bookshop's e-mail.\n"
print(content)
card = ModelCard(content)
print("read back:", card.data.license, card.data.base_model, card.data.language)
```

```
ana@desk:~/desk$ python lab/cards.py
---
base_model: Qwen/Qwen3-8B
language:
- en
- pt
license: apache-2.0
pipeline_tag: text-classification
tags:
- customer-support
---

# lantern-books/email-sorter

Sorts a bookshop's e-mail.

read back: apache-2.0 Qwen/Qwen3-8B ['en', 'pt']
```

Cinco campos trazem quase tudo o que um comprador precisa antes de baixar qualquer coisa:

| campo | responde | aula |
|---|---|---|
| `license` | posso usar, e como | 2 |
| `language` | foi testado no meu idioma | 1, seção 05 |
| `pipeline_tag` | para que tarefa foi feito | 12, seção 02 |
| `base_model` | de onde partiu, e portanto que licença herda | 2, seção 04 |
| `tags` | qualquer outra coisa que o autor quis tornar buscável | |

**Metadado é uma afirmação que o autor digitou.** Nada confere se `license: apache-2.0` bate com a
licença que o modelo base permite, ou se `language: pt` foi medido algum dia. Os campos são por onde
começar a ler, e as cinco perguntas da aula 2 continuam valendo para o texto abaixo deles.
