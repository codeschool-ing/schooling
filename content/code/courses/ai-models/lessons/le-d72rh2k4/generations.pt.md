---
title: Quatro gerações num arquivo
version: 1
---

A Llama é a primeira família deste diretório que é **de pesos abertos desde o início**: os provedores
das aulas anteriores vendiam acesso, enquanto a Meta publica os pesos, e a maioria de quem usa uma
Llama chega a ela na máquina de outra pessoa.
Então a fonte aqui não é uma página de preços, e sim o repositório da própria Meta, que descreve cada
lançamento num arquivo Python, `models/sku_list.py`. A aula 3 leu os números de arquitetura dele. As
descrições listam todo modelo que a Meta publicou ali:

```
ana@desk:~/desk$ sources quote llama-skus 'description="Llama' | grep -o 'Llama [0-9.]* [^"]*' | sort -u
Llama 2 13b chat model
Llama 2 13b model
Llama 2 70b chat model
Llama 2 70b model
Llama 2 7b chat model
Llama 2 7b model
Llama 3 70b instruct model
Llama 3 70b model
Llama 3 8b instruct model
Llama 3 8b model
Llama 3.1 405b instruct model (BF16 weights for mp16)
Llama 3.1 405b instruct model (BF16 weights)
Llama 3.1 405b instruct model (FP8 quantized)
Llama 3.1 405b model (BF16 weights for mp16)
Llama 3.1 405b model (BF16 weights)
Llama 3.1 405b model (FP8 quantized)
Llama 3.1 70b instruct model
Llama 3.1 70b model
Llama 3.1 8b instruct model
Llama 3.1 8b model
Llama 3.2 11b vision instruct model
Llama 3.2 11b vision model
Llama 3.2 1b INT4 quantized LoRA
Llama 3.2 1b INT4 quantized SpinQuant
Llama 3.2 1b instruct model
Llama 3.2 1b model
Llama 3.2 3b INT4 quantized LoRA
Llama 3.2 3b INT4 quantized SpinQuant
Llama 3.2 3b instruct model
Llama 3.2 3b model
Llama 3.2 90b vision instruct model
Llama 3.2 90b vision model
Llama 3.3 70b instruct
Llama 4 Maverick (17b 128 experts instruct model)
Llama 4 Maverick (17b 128 experts model)
Llama 4 Maverick (FP8 quantized)
Llama 4 Scout (17b 16 experts instruct model)
Llama 4 Scout (17b 16 experts model)
```

Leia como quatro gerações, cada uma respondendo a uma pergunta diferente:

- **Llama 2 e Llama 3**: dois ou três tamanhos, cada um como `model` base e como modelo ajustado
  `chat` ou `instruct`, os dois tipos da aula 1 seção 07 lado a lado.
- **Llama 3.1**: 8B, 70B e 405B, os tamanhos para os quais a aula 3 calculou memória, e o 405B
  publicado de três jeitos: pesos BF16 para dois arranjos de máquina, e **FP8 quantized**, a precisão
  menor da aula 3 seção 04 lançada pelos próprios autores.
- **Llama 3.2**: modelos pequenos, **1B e 3B**, incluindo versões já quantizadas em INT4 para celulares
  e notebooks, e modelos de **visão** de 11B e 90B que leem imagens.
- **Llama 3.3**: um único modelo instruct de 70B, sem modelo base listado ao lado.
- **Llama 4**: dois modelos chamados Scout e Maverick, descritos por **especialistas** e não por
  tamanho, o que a seção 03 explica.

Duas coisas que essa lista ensina sobre famílias abertas em geral. **Nem sempre o modelo base é
publicado**, então fazer fine-tuning a partir de uma base (aula 1 seção 11) depende do lançamento. E
**o mesmo modelo pode sair em várias precisões**: "Llama 3.1 405B" são três downloads diferentes, e uma
avaliação precisa dizer em qual rodou.
