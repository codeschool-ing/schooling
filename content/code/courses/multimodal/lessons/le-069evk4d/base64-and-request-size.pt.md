---
title: Uma imagem dentro de um pedido fica um terço maior
version: 1
---

A aula 8 mandou imagens como URLs de dados: base64 dentro do JSON. O base64 gasta quatro caracteres a cada três bytes, então o pedido é maior que o arquivo que carrega:

```python
"""How much bigger a picture gets on its way into a JSON request."""
import base64
import json
import sys

for path in sys.argv[1:]:
    raw = open(path, "rb").read()
    body = json.dumps({"model": "lab-vision-1", "messages": [{"role": "user", "content": [
        {"type": "text", "text": "Read the total."},
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + base64.b64encode(raw).decode()}}]}]})
    print("%-22s file %9d   request %9d   x%.3f" % (path.split("/")[-1], len(raw), len(body), len(body) / len(raw)))
```

```
ana@lab:~/mm$ python base64_size.py media/invoice-0931-scan.jpg media/phone.jpg
invoice-0931-scan.jpg  file     95891   request    128043   x1.335
phone.jpg              file    883497   request   1178183   x1.334
```

**Cerca de 1,334**, os quatro terços do base64 mais algumas dezenas de bytes de JSON. Isso importa em dois lugares. Limites de tamanho de pedido valem para o pedido, não para o arquivo, então uma imagem logo abaixo de um limite documentado ainda pode gerar um pedido acima dele. E todo byte é enviado em toda chamada: 1,18 MB para uma foto de celular é uma espera visível na conexão de uma loja, e a mesma imagem perguntada cinco vezes é enviada cinco vezes.

Dois jeitos de contornar isso, onde o provedor oferece. **Uma URL** que o provedor busca, que a aula 8 mostrou e que passa o envio para o lado do provedor. **Um arquivo enviado**, mandado uma vez e depois citado por um id em cada pedido, que as APIs de arquivos da OpenAI e do Google oferecem. Os dois têm limites de tamanho e regras de retenção próprios, e os dois mandam a imagem para o armazenamento do provedor, o que é uma pergunta para a política de dados antes de ser uma para a conta.

Redimensionar antes para o tamanho do provedor, como a seção anterior fez, encolhe tudo isso junto.
