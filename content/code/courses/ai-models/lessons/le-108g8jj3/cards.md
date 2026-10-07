---
title: A card is metadata and prose
version: 1
---

Lesson 1 section 09 read a model card as a document. On the Hub it is also **data**, and the Hub's
documentation says how:

```
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

The YAML at the top is what the Hub filters and links by: the licence, the languages, the task, the
model it was built from. `cards.py` writes the metadata a fine-tune of ana's would carry, if she
ever published one, with `huggingface_hub`'s own classes, and reads it back:

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
ana@desk:~/desk$ python cards.py
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

Five fields carry most of what a buyer needs before downloading anything:

| field | answers | lesson |
|---|---|---|
| `license` | may I use it, and how | 2 |
| `language` | was it tested in mine | 1, section 05 |
| `pipeline_tag` | which task it was made for | 12, section 02 |
| `base_model` | what it started as, and so which licence it inherits | 2, section 04 |
| `tags` | anything else the author wanted searchable | |

**Metadata is a claim the author typed.** Nothing checks that `license: apache-2.0` matches the
licence the base model allows, or that `language: pt` was ever measured. The fields are where to
start reading, and lesson 2's five questions still apply to the text below them.
