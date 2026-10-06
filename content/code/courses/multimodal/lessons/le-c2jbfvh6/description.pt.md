---
title: Descrevendo uma imagem em palavras
version: 1
---

Um **modelo de visão e linguagem** (VLM, na sigla em inglês) lê uma imagem e um prompt de texto juntos e responde em texto. Ele não tem lista fixa: foi treinado com quantidades enormes de imagens acompanhadas de legendas e documentos, e responde no vocabulário aberto de um modelo de linguagem. O GPT-4o, o Gemini e o Claude recebem imagens assim, e também modelos abertos como o Qwen2.5-VL e o Llama 3.2 Vision (aula 11).

Essa única diferença muda o que se pode perguntar. Um detector diz `book 0.51`. A um VLM se pode perguntar *"que tipo de documento é este, quem o mandou e qual é o total?"* e ele responde numa frase, ou em JSON. Ele lê texto, então faz o trabalho do OCR também, e entende layout, então não precisa ser avisado sobre linhas. Ele consegue descrever a capa de *Dom Casmurro*, que o detector não conseguiu nomear de jeito nenhum.

**Nenhum VLM roda neste laboratório**, e nenhum podia ser alcançado da máquina em que o curso foi gravado. Abaixo está como uma descrição dessas se parece, escrita pelo curso para esta imagem e não produzida por modelo algum. Ela mostra o tipo de resposta que você recebe, e o tipo de erro a procurar:

> *A book cover with a dark blue background. At the top right is a pale yellow full moon. The title DOM CASMURRO is printed in large cream serif letters, with the author's name, Machado de Assis, beneath it. Below is a dark building with two lit windows, and at the bottom the words "Marginalia Classics". The style is flat and minimalist, suggesting a night scene.*

Tudo nessa descrição pode ser conferido contra o que o laboratório desenhou, porque o `build_media.py` diz exatamente o que há na capa. A lua, o título, o autor e a linha da editora estão lá. **"A dark building" é uma interpretação**: o desenho é um retângulo escuro com dois retângulos dourados dentro, e *prédio*, *janela* e *cena noturna* são a história de quem lê, o que muitas vezes é o que você quer de uma descrição e nunca o que você quer de uma extração.

## Como conferir uma descrição

Uma descrição é a saída mais difícil de verificar neste curso, porque é prosa e não há uma única resposta certa. Três conferências pegam a maior parte dos problemas:

1. **Cruze os fatos que outra coisa consegue ler.** Se a descrição cita texto, rode OCR na mesma imagem e compare. O título e o autor estão na capa; o Tesseract os lê em milissegundos.
2. **Peça o que é conferível.** "Liste todo texto da capa, exatamente como está escrito" é verificável. "Descreva o clima da capa" não é, e nunca deve alimentar nada automático.
3. **Desconfie do acréscimo plausível.** O erro típico de um VLM não é absurdo: é o detalhe que uma capa assim *costuma* ter. Um código de barras, um preço, um subtítulo. Tudo o que você não esperava encontrar merece uma olhada antes de ser aceito.

A aula 8 manda imagens a um VLM pela API da OpenAI, no substituto do laboratório, e pede a resposta em JSON conferido contra um schema.
