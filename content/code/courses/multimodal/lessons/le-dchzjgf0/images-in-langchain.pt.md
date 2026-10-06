---
title: Uma imagem numa mensagem do LangChain
version: 1
---

A aula 10 de `rag` conheceu o LangChain como um conjunto de peças para recuperação: carregadores, divisores, um depósito de vetores, uma cadeia. Os modelos de chat dele também aceitam **blocos de conteúdo**: o `content` de uma mensagem pode ser uma lista, e cada item é texto, imagem, áudio ou arquivo. O LangChain aceita duas grafias de um bloco de imagem, e este programa manda a capa da aula 8 uma vez em cada:

```python
"""The cover, sent through LangChain twice: once in OpenAI's own block, once in LangChain's."""
import base64

from langchain_core.messages import HumanMessage
from langchain_openai import ChatOpenAI

data = base64.b64encode(open("media/cover-b39.png", "rb").read()).decode()
openai_block = {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{data}"}}
standard_block = {"type": "image", "base64": data, "mime_type": "image/png"}

llm = ChatOpenAI(model="lab-vision-1")
for name, block in (("openai", openai_block), ("standard", standard_block)):
    message = HumanMessage(content=[{"type": "text", "text": "Describe this cover."}, block])
    sent = llm._get_request_payload([message])["messages"][0]["content"][1]   # what goes on the wire
    print(name, "->", sent["type"], sent["image_url"]["url"][:30])
    reply = llm.invoke([message])
    print("   ", reply.usage_metadata["input_tokens"], "tokens in:", reply.content[:60])
```

O primeiro bloco é o formato da própria OpenAI, o `image_url` com uma URL de dados que a aula 8 montou à mão. O segundo é o **bloco padrão do LangChain**: `type`, os dados em base64 e o `mime_type`, sem o nome de nenhum provedor. O `_get_request_payload` é um método privado do `ChatOpenAI`, usado aqui só para olhar o que iria para a rede:

```
ana@lab:~/mm$ python lc_cover.py
openai -> image_url data:image/png;base64,iVBORw0K
    772 tokens in: A book cover on a dark navy background. At the top right is 
standard -> image_url data:image/png;base64,iVBORw0K
    772 tokens in: A book cover on a dark navy background. At the top right is 
ana@lab:~/mm$ tail -n 2 /var/log/labmm/requests.jsonl | python -c "import json, sys; [print(r[\"images\"][0][\"sha256\"], r[\"images\"][0][\"tokens\"], r[\"rule\"]) for r in map(json.loads, sys.stdin)]"
88a80dab896d 765 l08-cover-describe
88a80dab896d 765 l08-cover-describe
```

**As duas grafias saíram como o mesmo pedido.** O `ChatOpenAI` converteu o bloco padrão num `image_url` com URL de dados, e o log do labmm mostra a mesma imagem (`88a80dab896d`) custando os mesmos 765 tokens nas duas vezes, a regra de blocos da aula 8 para uma figura de 600 por 900. Os 772 tokens do `usage_metadata` da resposta são esses 765 mais o texto e o custo fixo da mensagem.

A resposta não é de um modelo. O labmm casou a imagem e as palavras "Describe this cover" com a regra `l08-cover-describe`, que o curso escreveu para a aula 8, e o log dá o nome dessa regra ao lado de cada pedido.

O que o bloco padrão compra é **uma mensagem para vários provedores**. O mesmo `HumanMessage` entregue ao `ChatGoogleGenerativeAI` ou ao `ChatAnthropic` é convertido para os formatos deles pelos pacotes de integração, e esse é um trabalho que um framework faz bem. O que ele custa é uma camada entre você e o pedido: a conversão acontece num pacote com versão própria, e o único jeito de saber o que foi enviado é olhar, como este programa fez.
