---
title: Achando objetos: caixas, classes e notas
version: 1
---

Um **detector de objetos** responde a uma pergunta diferente da do OCR: *o que há nesta imagem, e onde?* Para cada coisa que acha, ele devolve uma caixa, um rótulo e uma nota. O detector do MediaPipe com o modelo EfficientDet-Lite0 é pequeno (14 MB no laboratório) e rápido o bastante para um celular:

```python
"""Every object MediaPipe's detector reports above a threshold, with its box in pixels."""
import sys

import mediapipe as mp

import mmlab

threshold = float(sys.argv[1])
with mmlab.detector(score=threshold) as det:
    for path in sys.argv[2:]:
        found = det.detect(mp.Image.create_from_file(path)).detections
        print(f"{path}: {len(found)} above {threshold}")
        for d in found:
            c, b = d.categories[0], d.bounding_box
            print(f"  {c.category_name:10} {c.score:.2f}  x={b.origin_x} y={b.origin_y} w={b.width} h={b.height}")
```

```
ana@lab:~/mm$ python detect.py 0.3 media/cat_and_dog.jpg media/cover-b39.png media/invoice-0931.png 2>/dev/null
media/cat_and_dog.jpg: 2 above 0.3
  cat        0.78  x=72 y=162 w=252 h=191
  dog        0.76  x=303 y=27 w=249 h=345
media/cover-b39.png: 0 above 0.3
media/invoice-0931.png: 1 above 0.3
  book       0.51  x=0 y=0 w=1239 h=1754
ana@lab:~/mm$ python detect.py 0.05 media/cat_and_dog.jpg media/cover-b39.png 2>/dev/null
media/cat_and_dog.jpg: 2 above 0.05
  cat        0.78  x=72 y=162 w=252 h=191
  dog        0.76  x=303 y=27 w=249 h=345
media/cover-b39.png: 0 above 0.05
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"A moldura da fotografia cat_and_dog.jpg, 640 por 416 pixels, com as duas caixas que o detector devolveu desenhadas em escala: uma caixa chamada cat 0.78, de x 72 a 324 e y 162 a 353, embaixo à esquerda, e uma caixa chamada dog 0.76, de x 303 a 552 e y 27 a 372, alta à direita. As duas caixas se sobrepõem um pouco. A fotografia em si não é reproduzida.\"><rect x=\"40\" y=\"20\" width=\"480.0\" height=\"312.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"346.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">640 x 416</text><rect x=\"94.0\" y=\"141.5\" width=\"189.0\" height=\"143.25\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"100.0\" y=\"153.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">cat 0.78</text><rect x=\"267.25\" y=\"40.25\" width=\"186.75\" height=\"258.75\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"273.25\" y=\"52.25\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">dog 0.76</text><text x=\"46\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">(0, 0)</text><text x=\"540\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Uma caixa são quatro números:</text><text x=\"540\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">onde começa, x e y,</text><text x=\"540\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e a largura e a altura,</text><text x=\"540\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">em pixels da imagem.</text><text x=\"540\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">O rótulo é um de 80</text><text x=\"540\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">classes do COCO.</text><text x=\"540\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">A nota é a certeza</text><text x=\"540\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">do modelo, não o quanto</text><text x=\"540\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ele está certo.</text></svg>", "caption": "O que um detector devolve: onde, o quê e com que certeza. Nada sobre a fotografia além disso."}
```

Na fotografia ele vai bem: um gato e um cachorro, cada um com uma caixa que encaixa, os dois com nota acima de 0,75. Nos dois desenhos do laboratório ele mostra o que é.

**A capa de *Dom Casmurro* não teve nada**, mesmo com o limite baixado para 0,05. A capa é cor chapada, uma lua e uma janela. O modelo foi treinado com fotografias, e o desenho chapado de uma janela não é algo que ele aprendeu a chamar de nada.

**A nota fiscal recebeu `book`, com 0,51, e uma caixa do tamanho da página inteira.** O detector tem uma lista fixa de coisas que pode dizer, e toda resposta é uma delas:

```
ana@lab:~/mm$ unzip -p /opt/multimodal/share/efficientdet_lite0.tflite labels.txt | grep -vc "^???"
80
ana@lab:~/mm$ unzip -p /opt/multimodal/share/efficientdet_lite0.tflite labels.txt | grep -v "^???" | sed -n "62,76p" | tr "\n" " "; echo
toilet tv laptop mouse remote keyboard cell phone microwave oven toaster sink refrigerator book clock vase 
```

Oitenta classes, do conjunto de dados COCO com que ele foi treinado: pessoas, veículos, animais, coisas de cozinha, móveis, e uns poucos objetos como `book`, `clock` e `vase`. Não há `invoice`, `document`, `page` nem `paper`. Quando o detector encontra uma página de texto, a coisa mais próxima que ele conhece é um livro, e ele diz isso com confiança mediana.

Isso se chama **vocabulário fechado**, e é o limite que define um detector clássico. Ele não sabe que não sabe. Uma nota de 0,51 significa que a evidência interna do modelo para `book` foi moderada. Não significa "provavelmente um livro", e muito menos "51% de chance de ser um livro". Notas servem para ordenar as respostas de um mesmo modelo entre si, e o limite que você mantém é uma decisão que se testa nas suas próprias imagens.

## Quando um detector é a ferramenta certa

Quando as classes que importam estão na lista, ou você pode treiná-lo com as suas (o Model Maker do MediaPipe retreina este modelo com imagens que você rotula), um detector é barato, rápido, roda no aparelho e devolve geometria: você recebe o *onde*, que uma frase de um modelo de visão e linguagem não entrega numa forma que um programa use. Contar pessoas numa fila, achar o produto na foto de um cliente antes de recortá-la, borrar todo rosto antes de guardar uma imagem: tudo isso é trabalho de detector.

Quando a pergunta é aberta (*o que há de errado com este livro?*) a lista fechada é o instrumento errado, e a próxima seção trata do instrumento sem lista.
