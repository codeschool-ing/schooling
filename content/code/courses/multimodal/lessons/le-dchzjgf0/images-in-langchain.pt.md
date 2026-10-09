---
title: Uma imagem numa mensagem do LangChain
version: 2
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

llm = ChatOpenAI(model="qwen2.5vl:3b", temperature=0, seed=1)
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
    1105 tokens in: The cover of the book "Dom Casmurro" by Machado de Assis fea
standard -> image_url data:image/png;base64,iVBORw0K
    1105 tokens in: The cover of the book "Dom Casmurro" by Machado de Assis fea
```

**As duas grafias saíram como o mesmo pedido.** O `ChatOpenAI` converteu o bloco padrão num `image_url` com URL de dados, e o modelo cobrou os mesmos 1.105 tokens por cada um, a imagem e a pergunta curta ao lado dela. A resposta é do `qwen2.5vl:3b`, pelo mesmo endereço do Ollama que a aula 8 usou, porque o `ChatOpenAI` lê o `OPENAI_BASE_URL` como o SDK da OpenAI lê.

O que o bloco padrão compra é **uma mensagem para vários provedores**. O mesmo `HumanMessage` entregue ao `ChatGoogleGenerativeAI` ou ao `ChatAnthropic` é convertido para os formatos deles pelos pacotes de integração, e esse é um trabalho que um framework faz bem. O que ele custa é uma camada entre você e o pedido: a conversão acontece num pacote com versão própria, e o único jeito de saber o que foi enviado é olhar, como este programa fez.
