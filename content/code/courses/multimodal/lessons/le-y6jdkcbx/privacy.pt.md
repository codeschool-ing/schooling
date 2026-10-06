---
title: O que uma foto diz além da imagem
version: 1
---

Uma foto de celular carrega mais que pixels. Os metadados **EXIF** dela registram a câmera, o momento em que foi tirada e, muitas vezes, **onde**, como coordenadas de GPS precisas o bastante para achar uma casa. Um cliente que fotografa um livro danificado em casa e manda pelo formulário de devolução enviou à loja, a menos que algo os tenha tirado, o próprio endereço dentro do arquivo.

A fotografia do laboratório não tem metadados, então o programa escreve alguns numa cópia, como um celular faria, e depois os remove:

```python
"""What a phone photo says about where it was taken, and the same photo with that removed."""
from PIL import Image

# A phone writes EXIF tags like these into every photo; here they are added by hand, to a copy.
exif = Image.Exif()
exif[0x010F] = "ExamplePhone"                            # Make
exif[0x0132] = "2026:10:05 18:42:07"                     # DateTime
exif.get_ifd(0x8825).update({1: "S", 2: (23.0, 33.0, 27.0), 3: "W", 4: (46.0, 37.0, 39.0)})   # GPS
Image.open("media/cat_and_dog.jpg").save("phone.jpg", exif=exif)


def tell(path):
    tags = Image.open(path).getexif()
    gps = tags.get_ifd(0x8825)
    print(f"{path:10} {len(tags)} tags; make={tags.get(0x010F)}; gps={dict(gps) or None}")


tell("phone.jpg")
img = Image.open("phone.jpg")
clean = Image.frombytes(img.mode, img.size, img.tobytes())   # the pixels and nothing else
clean.save("clean.jpg", quality=90)
tell("clean.jpg")
```

```
ana@lab:~/mm$ python strip.py
phone.jpg  3 tags; make=ExamplePhone; gps={1: 'S', 2: (23.0, 33.0, 27.0), 3: 'W', 4: (46.0, 37.0, 39.0)}
clean.jpg  0 tags; make=None; gps=None
```

A cópia carrega três tags: uma marca de câmera, uma data e hora, e um bloco de GPS (23° 33′ 27″ sul, 46° 37′ 39″ oeste, o centro de São Paulo). A cópia limpa não carrega nenhuma: foi feita só com os pixels, então nada que não fosse pixel podia acompanhar.

**Tire antes que qualquer outra coisa veja o arquivo**: antes de guardar, antes de mandar a uma API de visão, antes de mostrar à equipe. Uma API de terceiros que recebe uma foto com GPS recebeu a localização do cliente, o que a política de privacidade tem de cobrir, e a loja não ganha nada com isso. Muitos serviços de upload tiram metadados por padrão, e "muitos" não é garantia; um programa que faz isso sozinho, e um teste que confere que um arquivo guardado não tem tag de GPS, é.

Mais duas coisas que uma imagem pode carregar, e sobre as quais um processo deve decidir de propósito:

- **Rostos e outras pessoas.** A foto de um pacote na porta pode incluir um vizinho. Um detector (aula 2) consegue achar rostos para que o processo os borre antes de guardar a imagem.
- **Documentos ao fundo.** A captura de tela de uma página de pedido pode mostrar um número de cartão ou um endereço em outra aba. O OCR consegue achar texto parecido com número de cartão ou CPF antes que a imagem vá a qualquer lugar.

Pela LGPD isso são dados pessoais, e alguns são sensíveis. A conformidade mais barata é não coletá-los.
