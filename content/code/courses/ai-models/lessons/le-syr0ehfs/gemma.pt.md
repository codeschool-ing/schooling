---
title: Gemma
version: 1
---

A Gemma é a família de pesos abertos do Google, a contraparte do Gemini fechado da aula 7. O
repositório a descreve numa frase:

```
# google-deepmind/gemma@e2e0a7d3 README.md
   7| [Gemma](https://ai.google.dev/gemma) is a family of open-weights Large Language
   8| Model (LLM) by [Google DeepMind](https://deepmind.google/), based on Gemini
   9| research and technology.
  10|
```

"Based on Gemini research and technology", e publicada como pesos. Os termos sob os quais a Gemma é
lançada ficam no site do próprio Google, que a máquina em que este curso foi gravado não conseguiu
alcançar, então esta aula não os cita. É exatamente o aviso da aula 2 seção 04 na prática: o
repositório acima é o código, e o arquivo de licença dele é o do código.

## Lendo os nomes da Gemma

As entradas Gemma 4 de um host, como a tabela as tem:

```
ana@desk:~/desk$ python sheet.py where google/gemma-4 | grep deepinfra
deepinfra/google/gemma-4-26B-A4B-it                  deepinfra                      0.07     0.34
deepinfra/google/gemma-4-31B-it                      deepinfra                      0.13     0.38
deepinfra/google/gemma-4-31B-it-Ultra                deepinfra                      0.27     0.76
deepinfra/google/gemma-4-31B-it-turbo                deepinfra                      0.09     0.34
deepinfra/google/gemma-4-E4B-it                      deepinfra                      0.02      0.1
```

- `-it` é o sufixo da Gemma para **ajustado para instruções**, o tipo ajustado da aula 1 seção 07,
  onde a Llama diz `instruct`.
- `26B-A4B` é a mesma convenção da Qwen: 26 bilhões de parâmetros no total, 4 bilhões ativos, uma
  mistura de especialistas.
- `31B` sem `A` é um modelo denso, todo parâmetro usado para todo token.
- `E4B` é um modelo pequeno para celulares e notebooks; o `E` se lê como parâmetros *efetivos*, uma
  contagem do que é calculado e não do que é guardado, a mesma distinção que a seção 03 fez com o `A`,
  medida de outro jeito. Trate como rótulo de tamanho e confira no cartão do modelo o que significa
  exatamente.
- `-turbo` e `-Ultra` são variantes **do host**, com preços diferentes, e a pergunta da aula 10 seção 05
  vale: o que o host mudou para ficar mais rápido ou mais caro?

De US$ 0,02 a US$ 0,27 o milhão de tokens de entrada, estas estão entre as entradas mais baratas que a
ana viu no curso. Pequena, aberta, barata e de um provedor cujos modelos fechados ela já avalia, uma
Gemma é candidata natural para a tarefa de classificação; a nota nos quarenta casos é o que a poria na
lista.
