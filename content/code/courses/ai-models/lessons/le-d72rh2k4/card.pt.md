---
title: O que diz o cartão da Llama 4
version: 1
---

A aula 1 leu o cartão da Llama 3.1. Três parágrafos do da Llama 4 respondem às mesmas perguntas, e duas
respostas mudaram:

```
# meta-llama/llama-models@0e0b8c51 models/llama4/MODEL_CARD.md
  48: **Supported languages:** Arabic, English, French, German, Hindi, Indonesian, Italian,
      Portuguese, Spanish, Tagalog, Thai, and Vietnamese.
  90: **Overview:** Llama 4 Scout was pretrained on \~40 trillion tokens and Llama 4 Maverick
      was pretrained on \~22 trillion tokens of multimodal data from a mix of publicly
      available, licensed data and information from Meta’s products and services. This
      includes publicly shared posts from Instagram and Facebook and people’s interactions
      with Meta AI.
  92: **Data Freshness:** The pretraining data has a cutoff of August 2024\.
```

**Doze idiomas suportados**, contra oito antes, e o português continua entre eles. Para os clientes da
Lantern Books isso mantém as duas gerações na lista curta para o português, sujeitas, como sempre, aos
casos.

**Os dados de treino agora incluem os produtos da própria Meta**: "publicly shared posts from Instagram
and Facebook and people's interactions with Meta AI", ao lado de dados públicos e licenciados. Para
escolher, isso é informação sobre o conhecimento do modelo (muito texto informal, de rede social) e,
para algumas organizações, uma questão de política sobre em quais modelos aceitam construir. O cartão
diz isso com todas as letras; a documentação de um provedor fechado muitas vezes diz menos.

**O corte é agosto de 2024.** A aula 1 disse que um corte pouco importa para as tarefas da ana e
importa muito para tarefas sobre o mundo. Uma Llama 4 lançada em 2025 não sabe nada depois de meados de
2024, e em outubro de 2026 isso são mais de dois anos. Os modelos fechados da aula 6 tinham cortes até
junho de 2026; lançamentos abertos vêm com menos frequência, e **a distância entre o corte de um modelo
aberto e hoje cresce até o próximo lançamento**.

## A licença

A Llama 4 tem licença própria, e a aula 2 seção 03 já citou as duas cláusulas dela que importam: o
limite de 700 milhões de usuários, medido na data de lançamento da Llama 4, e o *Built with Llama* em
tudo o que a distribui. Tudo o que foi dito ali sobre ler a licença da versão exata que você roda vale
aqui: os termos da Llama 3.1 respondiam às perguntas da Llama 3.1.
