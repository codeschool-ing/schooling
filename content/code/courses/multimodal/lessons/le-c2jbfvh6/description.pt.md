---
title: Descrevendo uma imagem em palavras
version: 1
---

Um **modelo de visão e linguagem** (VLM, na sigla em inglês) lê uma imagem e um prompt de texto juntos e responde em texto. Ele não tem lista fixa: foi treinado com quantidades enormes de imagens acompanhadas de legendas e documentos, e responde no vocabulário aberto de um modelo de linguagem. O GPT-4o, o Gemini e o Claude recebem imagens assim, e também modelos abertos como o Qwen2.5-VL e o Llama 3.2 Vision (aula 11).

Essa única diferença muda o que se pode perguntar. Um detector diz `book 0.51`. A um VLM se pode perguntar *"que tipo de documento é este, quem o mandou e qual é o total?"* e ele responde numa frase, ou em JSON. Ele lê texto, então faz o trabalho do OCR também, e entende layout, então não precisa ser avisado sobre linhas. Ele consegue descrever a capa de *Dom Casmurro*, que o detector não conseguiu nomear de jeito nenhum.

O modelo de visão do curso é o `qwen2.5vl:3b`, o que o `setup.sh` deu ao Ollama: o Qwen2.5-VL com três bilhões de parâmetros, pequeno o bastante para responder num computador comum em um ou dois minutos. Este programa faz a ele uma pergunta sobre uma imagem. A aula 8 desmonta o pedido; aqui só a resposta importa.

`ask.py`:

```python
"""Ask the course's vision model one question about one picture, with the randomness turned down."""
import base64
import sys

from openai import OpenAI

path, question = sys.argv[1], sys.argv[2]
kind = "png" if path.endswith(".png") else "jpeg"
picture = f"data:image/{kind};base64," + base64.b64encode(open(path, "rb").read()).decode()
reply = OpenAI().chat.completions.create(
    model="qwen2.5vl:3b", temperature=0, seed=1,
    messages=[{"role": "user", "content": [{"type": "text", "text": question},
                                           {"type": "image_url", "image_url": {"url": picture}}]}])
print(reply.choices[0].message.content)
```

```
ana@lab:~/mm$ python ask.py media/cover-b39.png "Describe this book cover."
The book cover for "Dom Casmurro" by Machado de Assis features a minimalist design with a deep navy blue background. The title "DOM CASMURRO" is prominently displayed in large, white, uppercase letters at the top of the cover. Below the title, the author's name, "Machado de Assis," is written in a smaller, white, uppercase font. 

In the center of the cover, there is a large, black rectangular shape with two gold-colored rectangles inside it, creating a striking contrast against the dark background. The gold rectangles are positioned horizontally, with the left one slightly to the left and the right one slightly to the right of the black rectangle.

At the bottom of the cover, the publisher's name, "Marginalia Classics," is written in a small, white, uppercase font. The overall design is clean and modern, with a focus on the title and author's name, making it easy to read and visually appealing.
ana@lab:~/mm$ python ask.py media/cover-b39.png "List every piece of text on the cover, exactly as written."
DOM CASMURRO
Machado de Assis
Marginalia Classics
exit 0
```

Tudo nessa descrição pode ser conferido contra o que foi desenhado, porque a função `cover()` do `make_media.py` diz exatamente o que há na capa, forma por forma. O título, o autor e a linha da editora estão lá, e a segunda pergunta copiou os três exatamente, que é o trabalho mais fácil. A primeira resposta se saiu pior de três jeitos, e cada um é um tipo de erro a procurar:

- **Algo que está lá ficou sem ser dito.** A capa tem uma lua clara no canto superior direito, com um quinto da largura da imagem, e a descrição nunca a menciona.
- **Detalhes foram inventados com confiança.** As letras são creme, não brancas; *Machado de Assis* e *Marginalia Classics* estão em maiúsculas e minúsculas, não só em maiúsculas; a linha da loja é de um azul acinzentado. Nada disso importa muito aqui, e tudo foi afirmado com a mesma firmeza das partes certas.
- **As formas ficaram como formas.** *A large, black rectangular shape with two gold-colored rectangles inside it* está correto, e é o que o desenho é. Uma pessoa chamaria aquilo de uma casa com duas janelas acesas, o que é uma interpretação; o modelo não ofereceu nenhuma, e uma interpretação muitas vezes é o que você quer de uma descrição e nunca o que você quer de uma extração.

## Como conferir uma descrição

Uma descrição é a saída mais difícil de verificar neste curso, porque é prosa e não há uma única resposta certa. Três conferências pegam a maior parte dos problemas:

1. **Cruze os fatos que outra coisa consegue ler.** Se a descrição cita texto, rode OCR na mesma imagem e compare. O título e o autor estão na capa; o Tesseract os lê em milissegundos.
2. **Peça o que é conferível.** "Liste todo texto da capa, exatamente como está escrito" é verificável. "Descreva o clima da capa" não é, e nunca deve alimentar nada automático.
3. **Desconfie do acréscimo plausível.** O erro típico de um VLM não é absurdo: é o detalhe que uma capa assim *costuma* ter. Um código de barras, um preço, um subtítulo. Tudo o que você não esperava encontrar merece uma olhada antes de ser aceito.

A aula 8 manda imagens ao mesmo modelo no formato da API da OpenAI, e pede a resposta em JSON conferido contra um schema.
