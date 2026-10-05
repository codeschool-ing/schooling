---
title: O que o pré-treino produz
version: 1
---

Todo modelo que este curso cita começou do mesmo jeito. Alguém juntou uma quantidade enorme de
texto, e uma rede foi treinada numa única tarefa, repetida sem parar: **dado o texto até aqui,
prever o próximo token.** Ninguém ensinou gramática, fatos ou aritmética como matérias separadas. A
rede aprendeu o que ajudava a prever, e acontece que prever bem a próxima palavra de uma receita, de
uma sentença judicial e de um relatório de bug exige bastante das três coisas.

O resultado é um **modelo pré-treinado**: aquilo que uma empresa levou meses e uma conta muito alta
para produzir, para que você não precise. Este curso trata de escolher um e usá-lo, então vale ser
preciso sobre o que essa coisa é, fisicamente.

O cartão do modelo Llama 3.1, da Meta, é um dos poucos que dizem isso em números. O `sources` lê o
cartão no repositório da própria Meta, no commit que o laboratório fixa:

```
ana@desk:~/desk$ sources quote llama3.1-card "collection of pretrained|~15 trillion"
# meta-llama/llama-models@0e0b8c51 models/llama3_1/MODEL_CARD.md
   3: The Meta Llama 3.1 collection of multilingual large language models (LLMs) is a
      collection of pretrained and instruction tuned generative models in 8B, 70B and 405B
      sizes (text in/text out). The Llama 3.1 instruction tuned text only models (8B, 70B,
      405B) are optimized for multilingual dialogue use cases and outperform many of the
      available open source and closed chat models on common industry benchmarks.
 186: **Overview:** Llama 3.1 was pretrained on ~15 trillion tokens of data from publicly
      available sources. The fine-tuning data includes publicly available instruction
      datasets, as well as over 25M synthetically generated examples.
```

Três coisas desses dois parágrafos voltam em todas as aulas deste curso:

- **"pretrained and instruction tuned"**. Há dois tipos de modelo na coleção, e a seção 03
  desta aula trata da diferença.
- **"8B, 70B and 405B"**: o número de parâmetros, em bilhões. Um parâmetro é um número da
  rede, e esta vem em três tamanhos. A aula 3 transforma uma contagem de parâmetros na memória
  que uma máquina precisa para rodar o modelo.
- **"~15 trillion tokens of data from publicly available sources"**: de onde ele aprendeu. Texto
  público é tudo o que ele sabe. O histórico de pedidos da Lantern Books nunca esteve lá e nunca
  vai estar, que é o assunto da seção 06.

## O que vem na caixa

O que você recebe ao pegar um modelo pré-treinado é mais do que a rede. Quatro outras coisas
viajam com os pesos, e a falta de qualquer uma pode travar você:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"O que é um modelo pré-treinado quando você o recebe: um conjunto de pesos no centro e, em volta, as quatro coisas necessárias para usá-los — um tokenizador, um template de chat, um cartão do modelo e uma licença. Por uma API você não segura nenhuma delas; o provedor roda as cinco atrás de um endpoint.\"><defs><marker id=\"l1box-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"100\" width=\"220\" height=\"80\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">os pesos</text><text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">bilhões de números</text><text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aprendidos de texto</text><rect x=\"30\" y=\"30\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tokenizador</text><text x=\"120.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">texto vira números</text><rect x=\"510\" y=\"30\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">template de chat</text><text x=\"600.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">papéis numa string só</text><rect x=\"30\" y=\"200\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cartão do modelo</text><text x=\"120.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para que foi feito</text><rect x=\"510\" y=\"200\" width=\"180\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">licença</text><text x=\"600.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que você pode fazer</text><line x1=\"210\" y1=\"56\" x2=\"250\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l1box-ah)\"></line><line x1=\"510\" y1=\"56\" x2=\"470\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l1box-ah)\"></line><line x1=\"210\" y1=\"226\" x2=\"250\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l1box-ah)\"></line><line x1=\"510\" y1=\"226\" x2=\"470\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l1box-ah)\"></line><text x=\"360\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um modelo aberto entrega as cinco</text><text x=\"360\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">uma API entrega um endpoint</text></svg>", "caption": "O que vem na caixa. Um modelo aberto traz todas as partes; uma API guarda todas atrás de um endereço."}
```

- **os pesos**, os bilhões de números em si;
- **um tokenizador**, que transforma texto nos números que os pesos esperam. O tokenizador
  errado produz bobagem, não um erro;
- **um template de chat**, a string exata em que uma conversa precisa se transformar antes de o
  modelo lê-la (seção 04);
- **um cartão do modelo**, que diz com o que ele foi treinado, para quê, e onde falha (seção 05);
- **uma licença**, que diz o que você pode fazer com tudo isso. A aula 2 lê três delas.

**Um modelo aberto entrega as cinco.** **Um modelo atrás de uma API não entrega nenhuma**: o
provedor guarda os pesos, tokeniza por você, aplica o próprio template e conta do cartão o que
quiser. Você manda uma lista de mensagens para um endereço e recebe texto de volta. Essa
diferença é o assunto da aula 2, e decide quase tudo sobre custo e controle.
