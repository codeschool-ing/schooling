---
title: The same decisions on a language model
version: 1
---

Everything in this lesson was decided on a network of 37,957 parameters. **The decisions are the
same for a language model with billions of them**: which weights learn, at what rate, what the
model forgets, and whether to train the weights at all or a small correction beside them. What
changes is that at that size the first decision also settles whether the training fits on the
machine you have.

None of it can run here. The weights live on `huggingface.co`, which this lab cannot reach, and
the 4-bit training at the end needs an NVIDIA graphics card. **The arithmetic runs anywhere**, and
it uses the `LoRA` class of the previous section on a real layer of the right size. Save as
`~/dl/sizes.py`, next to `lora.py`:

```schooling-example
{
  "language": "python",
  "file": "sizes.py",
  "parts": [
    {
      "code": "\"\"\"sizes: LoRA's arithmetic on a language model with seven billion weights.\"\"\"\nimport torch.nn as nn\n\nfrom lora import LoRA\n\nlayers, width, mlp, vocab = 32, 4096, 11008, 32000\nper_layer = 4 * width * width + 3 * width * mlp + 2 * width\ntotal = layers * per_layer + 2 * vocab * width + width\nprint(f\"weights in the model: {total:,}\")",
      "note": "Os formatos publicados do Llama 2 7B: 32 blocos de transformer com largura 4.096, um MLP de 11.008, e 32.000 tokens. Cada bloco tem quatro projeções de atenção (query, key, value e saída), três matrizes de MLP e dois vetores de normalização; a embedding e a camada de saída são uma linha por token."
    },
    {
      "code": "q = LoRA(nn.Linear(width, width, bias=False), rank=8, alpha=16)\nfrozen = sum(p.numel() for p in q.parameters() if not p.requires_grad)\nadded = sum(p.numel() for p in q.parameters() if p.requires_grad)\nprint(f\"one attention projection: {frozen:,} frozen, rank 8 adds {added:,}\")",
      "note": "Uma projeção real de 4.096 por 4.096, montada na memória com pesos aleatórios, e o `LoRA` desta aula em volta dela com rank 8. As contagens são lidas dos tensores, não calculadas à mão."
    },
    {
      "code": "trainable = layers * 2 * added\nprint(f\"rank 8 on q and v in all {layers} layers: {trainable:,} trainable,\"\n      f\" {100 * trainable / total:.3f}% of the model\")\nprint(f\"the adapter saved in 16 bits: {trainable * 2 / 2**20:.0f} MiB\")\nfor bits in (32, 16, 4):\n    print(f\"the frozen weights in {bits:2d} bits: {total * bits / 8 / 2**30:5.1f} GiB\")",
      "note": "Um adaptador nas projeções de query e value de todo bloco, a primeira escolha de costume. Depois os tamanhos em bytes: o adaptador guardado em 16 bits, e o modelo congelado guardado em 32, 16 e 4 bits por peso."
    }
  ]
}
```

```
PENDING sizes
```

## What the numbers decide

**Full fine-tuning trains all 6,738,415,616 weights.** Every one of them then needs a gradient and,
with Adam, two more numbers of optimiser state, and lesson 19 adds up what that costs in memory.
Even before any of that, the frozen weights alone take 12.6 GiB in 16 bits. A full fine-tune of a
model this size is a job for several data-centre graphics cards.

**LoRA trains 4,194,304 of them**, 0.062% of the model, with rank 8 on two of the four attention
projections of every block. Gradients and optimiser state exist only for those, and the result is
an adapter of 8 MiB that sits beside an unchanged base model, as `adapt.py` did with `base.pt`.
The family of methods that train a small number of new or chosen parameters is called **PEFT**,
parameter-efficient fine-tuning, and LoRA is the one most used; PEFT is also the name of Hugging
Face's library that implements them.

**QLoRA stores the frozen base in 4 bits**, 3.1 GiB here instead of 12.6, and trains a 16-bit LoRA
adapter on top of it. The frozen weights are unpacked to 16 bits on the fly for each computation,
and the gradient flows through them to the adapter without ever being stored for them. It is what
makes adapting a model of this size possible on one consumer graphics card.

The other decisions carry over unchanged:

- **Which layers.** `target_modules` below is this lesson's `LEARNS` dictionary under another
  name. The attention projections are the usual first choice; adding the MLP matrices trains more
  and sometimes earns it, measured the way `depths.py` measured the depths.
- **Forgetting.** A chat model fine-tuned hard on one narrow kind of text gets worse at the rest,
  for the reason `forget.py` showed. The defences are the same: a lower rate, fewer epochs, some
  general data mixed back in, or an adapter that leaves the base intact.
- **The baseline.** For a language model it is rarely training from scratch. It is the base model
  with a well-written prompt, and a fine-tune that does not beat it was not worth running.

## What it looks like, not run

This is the usual shape of QLoRA with Hugging Face's `transformers`, `bitsandbytes` and `peft`
libraries, none of which this course installs. **Not run for this course**: the first call
downloads the 12.6 GiB of 16-bit weights `sizes.py` counted, from `huggingface.co`, which this
lab cannot reach and where the model's page asks you to accept its licence first, and `load_in_4bit` needs an NVIDIA graphics card.

```python
import torch
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from transformers import AutoModelForCausalLM, BitsAndBytesConfig

quant = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_quant_type="nf4",
                           bnb_4bit_compute_dtype=torch.bfloat16)   # QLoRA: the base in 4 bits
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-2-7b-hf",
                                             quantization_config=quant, device_map="auto")
model = prepare_model_for_kbit_training(model)

config = LoraConfig(r=8, lora_alpha=16, lora_dropout=0.05,
                    target_modules=["q_proj", "v_proj"], task_type="CAUSAL_LM")
model = get_peft_model(model, config)       # freezes the base, adds A and B beside q and v
model.print_trainable_parameters()
```

`r` and `lora_alpha` are the `rank` and `alpha` of `lora.py`, and `q_proj` and `v_proj` are the
two projections `sizes.py` counted. The training loop that follows is the one you know, on text
instead of digits, and `peft`'s `merge_and_unload()` does what `merged()` did: it folds the adapter
into the weights for serving.
