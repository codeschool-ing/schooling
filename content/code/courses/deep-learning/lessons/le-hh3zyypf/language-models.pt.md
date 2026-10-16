---
title: As mesmas decisões num modelo de linguagem
version: 1
---

Tudo nesta aula foi decidido numa rede de 37.957 parâmetros. **As decisões são as mesmas para um
modelo de linguagem com bilhões deles**: quais pesos aprendem, com que taxa, o que o modelo esquece,
e se vale treinar os pesos ou uma correção pequena ao lado deles. O que muda é que, nesse tamanho, a
primeira decisão também resolve se o treino cabe na máquina que você tem.

Nada disso roda aqui. Os pesos ficam no `huggingface.co`, que este laboratório não alcança, e o
treino em 4 bits do fim precisa de uma placa de vídeo NVIDIA. **A aritmética roda em qualquer
lugar**, e usa a classe `LoRA` da seção anterior numa camada real do tamanho certo. Salve como
`~/dl/sizes.py`, ao lado do `lora.py`:

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
ana@vm:~/dl$ python sizes.py
weights in the model: 6,738,415,616
one attention projection: 16,777,216 frozen, rank 8 adds 65,536
rank 8 on q and v in all 32 layers: 4,194,304 trainable, 0.062% of the model
the adapter saved in 16 bits: 8 MiB
the frozen weights in 32 bits:  25.1 GiB
the frozen weights in 16 bits:  12.6 GiB
the frozen weights in  4 bits:   3.1 GiB
```

## O que os números decidem

**O fine-tuning completo treina todos os 6.738.415.616 pesos.** Cada um deles precisa então de um
gradiente e, com o Adam, de mais dois números de estado do otimizador, e a aula 19 soma quanto isso
custa em memória. Antes de tudo isso, só os pesos congelados ocupam 12,6 GiB em 16 bits. Um
fine-tuning completo de um modelo desse tamanho é trabalho para várias placas de vídeo de data
center.

**O LoRA treina 4.194.304 deles**, 0,062% do modelo, com rank 8 em duas das quatro projeções de
atenção de cada bloco. Gradientes e estado do otimizador existem só para esses, e o resultado é um
adaptador de 8 MiB que fica ao lado de um modelo base inalterado, como o `adapt.py` fez com o
`base.pt`. A família de métodos que treinam um número pequeno de parâmetros novos ou escolhidos se
chama **PEFT**, parameter-efficient fine-tuning, e o LoRA é o mais usado; PEFT também é o nome da
biblioteca do Hugging Face que os implementa.

**O QLoRA guarda a base congelada em 4 bits**, 3,1 GiB aqui em vez de 12,6, e treina por cima um
adaptador LoRA em 16 bits. Os pesos congelados são desempacotados para 16 bits na hora de cada
conta, e o gradiente passa por eles até o adaptador sem nunca ser guardado para eles. É o que torna
possível adaptar um modelo desse tamanho numa única placa de vídeo de consumidor.

As outras decisões passam sem mudança:

- **Quais camadas.** O `target_modules` abaixo é o dicionário `LEARNS` desta aula com outro nome. As
  projeções de atenção são a primeira escolha de costume; somar as matrizes do MLP treina mais e às
  vezes compensa, medido do jeito que o `depths.py` mediu as profundidades.
- **Esquecimento.** Um modelo de chat ajustado com força num tipo estreito de texto piora no resto,
  pelo motivo que o `forget.py` mostrou. As defesas são as mesmas: uma taxa menor, menos épocas,
  algum dado geral misturado de volta, ou um adaptador que deixa a base intacta.
- **A referência.** Para um modelo de linguagem ela raramente é treinar do zero. É o modelo base com
  um prompt bem escrito, e um fine-tuning que não o supera não valeu a execução.

## Como fica, sem rodar

Este é o formato de costume do QLoRA com as bibliotecas `transformers`, `bitsandbytes` e `peft` do
Hugging Face, e nenhuma delas é instalada neste curso. **Não executado neste curso**: a primeira
chamada baixa os 12,6 GiB de pesos em 16 bits que o `sizes.py` contou do `huggingface.co`, que este
laboratório não alcança, e o `load_in_4bit` precisa de uma placa de vídeo NVIDIA. A página do modelo
lá também pede que você aceite a licença dele antes do download.

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

`r` e `lora_alpha` são o `rank` e o `alpha` do `lora.py`, e `q_proj` e `v_proj` são as duas
projeções que o `sizes.py` contou. O laço de treino que vem depois é o que você conhece, com texto em
vez de dígitos, e o `merge_and_unload()` do `peft` faz o que o `merged()` fez: dobra o adaptador nos
pesos para servir o modelo.
