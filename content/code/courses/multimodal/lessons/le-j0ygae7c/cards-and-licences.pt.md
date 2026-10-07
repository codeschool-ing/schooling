---
title: Cartões de modelo, e a licença que mora em outro lugar
version: 2
---

Um **cartão do modelo** (model card) é o documento publicado com um modelo: com o que ele foi treinado, para que serve, os limites conhecidos e a licença. É a primeira coisa a ler antes de um modelo entrar num produto, e os próprios modelos do laboratório mostram por que essa leitura não é formalidade. As três vozes Piper carregam os cartões consigo:

```
ana@lab:~/mm$ grep -H -E "Language|License|URL" /opt/multimodal/share/vits-piper-*/MODEL_CARD
/opt/multimodal/share/vits-piper-en_GB-alan-medium/MODEL_CARD:* Language: en_GB (English, Great Britain)
/opt/multimodal/share/vits-piper-en_GB-alan-medium/MODEL_CARD:* URL: https://github.com/MycroftAI/mimic3-voices/blob/master/voices/en_UK/apope_low
/opt/multimodal/share/vits-piper-en_GB-alan-medium/MODEL_CARD:* License: See URL
/opt/multimodal/share/vits-piper-en_US-lessac-medium/MODEL_CARD:* Language: en_US (English, United States)
/opt/multimodal/share/vits-piper-en_US-lessac-medium/MODEL_CARD:* URL: https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/
/opt/multimodal/share/vits-piper-en_US-lessac-medium/MODEL_CARD:* License: https://www.cstr.ed.ac.uk/projects/blizzard/2013/lessac_blizzard2013/license.html
/opt/multimodal/share/vits-piper-pt_BR-faber-medium/MODEL_CARD:* Language: pt_BR (Portuguese, Brazil)
/opt/multimodal/share/vits-piper-pt_BR-faber-medium/MODEL_CARD:* URL: https://github.com/OHF-Voice/voice-datasets
/opt/multimodal/share/vits-piper-pt_BR-faber-medium/MODEL_CARD:* License: CC0
ana@lab:~/mm$ head -3 /opt/multimodal/share/sherpa-onnx-pyannote-segmentation-3-0/LICENSE; sed -n "3,4p" /opt/multimodal/share/sherpa-onnx-pyannote-segmentation-3-0/README.md
MIT License

Copyright (c) 2022 CNRS
Models in this file are converted from
https://huggingface.co/pyannote/segmentation-3.0/tree/main
```

Três vozes, três situações diferentes:

- **faber** (português do Brasil) diz **CC0**: dedicada ao domínio público, utilizável para qualquer coisa.
- **lessac** (inglês americano) aponta para a **página de licença do conjunto de dados** com que foi treinada, um corpus lançado para o Blizzard Challenge 2013, uma avaliação de pesquisa. O repositório da voz ser aberto não resolve o que os dados permitem; aquela página resolve.
- **alan** (inglês britânico) diz **See URL**, e a URL é uma voz de outro projeto. A resposta está um salto adiante.

O modelo de segmentação de falantes é mais simples: a pasta dele traz uma licença MIT, copyright do CNRS de 2022, e um README dizendo que ele foi **convertido de `pyannote/segmentation-3.0` no Hub**. Essa conversão é a segunda coisa a notar.

**Um modelo convertido herda os termos do original.** Todo modelo deste laboratório é uma conversão: o sherpa-onnx transformou o Whisper, o pyannote e os modelos de falante em arquivos ONNX, e as vozes do Piper foram treinadas e exportadas pelo próprio projeto. Os termos que importam são os do original, então a corrente é: o arquivo convertido → o cartão do modelo original → o conjunto de dados com que ele foi treinado. Cada elo pode acrescentar uma restrição, e um modelo aberto para baixar não está, por isso, aberto para vender.

Uma regra prática para um produto: **mantenha uma tabela de todo modelo que você distribui**, com a origem, a licença, a licença do conjunto de dados quando o cartão cita uma, e a data em que você as leu. A lista de modelos do `setup.sh` da aula 1, cada arquivo com o endereço de onde veio e o seu SHA-256, é o começo de uma, e é o que um revisor pede.
