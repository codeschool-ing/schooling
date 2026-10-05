---
title: Fechado, de pesos abertos e de código aberto
version: 1
---

As palavras do dia a dia para isso são *fechado* e *aberto*, e elas escondem um terceiro caso que é
o mais comum de todos. Ordene os modelos pelo **que você recebe**, e são três:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três tipos de modelo pelo que você recebe. Fechado: um endpoint e uma chave, com os pesos guardados pelo provedor. Pesos abertos: os pesos, sob uma licença com condições. Código aberto: os pesos sob uma licença sem condições e, na definição mais estrita, também o código de treino e informação sobre os dados.\"><defs><marker id=\"l2kinds-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">fechado</text><text x=\"120\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">você recebe</text><text x=\"120\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um endpoint</text><text x=\"120\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma chave de API</text><text x=\"120\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">o provedor guarda os pesos</text><rect x=\"270\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">pesos abertos</text><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">você recebe</text><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os pesos</text><text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma licença</text><text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">com condições</text><rect x=\"510\" y=\"20\" width=\"180\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">código aberto</text><text x=\"600\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">você recebe</text><text x=\"600\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os pesos</text><text x=\"600\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma licença</text><text x=\"600\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sem condições</text><text x=\"600\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">e, a rigor, o</text><text x=\"600\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">código de treino e</text><text x=\"600\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">informação dos dados</text><line x1=\"40\" y1=\"245\" x2=\"680\" y2=\"245\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#l2kinds-ah)\"></line><text x=\"360\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais do modelo fica nas suas mãos</text></svg>", "caption": "Ordenados pelo que você recebe. A maioria dos “modelos abertos” é a coluna do meio, e a abertura se mede na licença."}
```

**Fechado.** Você recebe um endpoint. Os pesos nunca saem do provedor; você manda uma requisição,
paga por token e aceita os termos de serviço dele. Claude, Gemini e a família GPT são oferecidos
assim. As aulas 6 a 9 passam por eles um a um.

**De pesos abertos** (*open-weight*). Você recebe os pesos, para baixar e rodar onde quiser, sob uma
**licença que os autores escreveram**. É o que a maioria das pessoas chama de "modelo aberto", e é
na licença que a abertura se mede. A concessão da Meta para a Llama 3.1 é generosa nos verbos e
cuidadosa nos adjetivos:

```
ana@desk:~/desk$ sources quote llama3.1-licence "Grant of Rights"
# meta-llama/llama-models@0e0b8c51 models/llama3_1/LICENSE
  21: a. Grant of Rights. You are granted a non-exclusive, worldwide, non-transferable and
      royalty-free limited license under Meta’s intellectual property or other rights owned by
      Meta embodied in the Llama Materials to use, reproduce, distribute, copy, create
      derivative works of, and make modifications to the Llama Materials.
```

*Non-exclusive, non-transferable, limited*: é uma permissão, com condições que a seção 03 lê. Os
pesos são seus para rodar; os termos vêm junto.

**De código aberto** (*open source*). Os pesos sob uma licença que não impõe condições de uso, muitas
vezes uma das licenças que o software usa há décadas. A DeepSeek diz isso do R1, no próprio README:

```
ana@desk:~/desk$ sources quote deepseek-r1-readme "^This code repository and the model weights"
# deepseek-ai/DeepSeek-R1@0cf78561 README.md
 257: This code repository and the model weights are licensed under the [MIT
      License](https://github.com/deepseek-ai/DeepSeek-R1/blob/main/LICENSE).
```

A definição de IA de código aberto da Open Source Initiative pede mais ainda: informação suficiente
sobre os dados de treino, e o código que treinou o modelo, para outra pessoa estudar e reconstruir
o modelo. Pouquíssimos modelos publicados chegam lá. **Para escolher, a linha que importa é a
licença**: se ela impõe condições que você precisa conferir contra o seu uso.

## O que cada um custa a você

| | fechado | pesos abertos | código aberto |
|---|---|---|---|
| você tem | uma chave de API | os pesos, com condições | os pesos, sem condições |
| você paga | por token | pela máquina que roda, ou por token a um host | o mesmo |
| muda quando | o provedor decide | você baixa uma versão nova | o mesmo |
| seus dados vão | para o provedor | para onde você rodar | o mesmo |

O resto desta aula pega essas linhas uma de cada vez: as condições (seção 03), as licenças que
valem para o código e não para os pesos (04), o preço (05), a mudança (06) e os dados (07).
