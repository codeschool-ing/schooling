---
title: Uma imagem numa mensagem do LlamaIndex
version: 1
---

O LlamaIndex diz a mesma coisa com outros substantivos. Uma `ChatMessage` é feita de **blocos**, e o `ImageBlock` aceita um caminho, uma URL ou bytes e faz o base64 sozinho:

```python
"""The same cover through LlamaIndex: a ChatMessage made of blocks."""
import os
import sys

from llama_index.core.llms import ChatMessage, ImageBlock, TextBlock

message = ChatMessage(role="user", blocks=[TextBlock(text="Describe this cover."),
                                           ImageBlock(path="media/cover-b39.png")])
if sys.argv[1:] == ["openai"]:
    from llama_index.llms.openai import OpenAI
    llm = OpenAI(model="qwen2.5vl:3b")
else:
    from llama_index.llms.openai_like import OpenAILike
    print("default api_base:", OpenAILike(model="qwen2.5vl:3b").api_base)
    llm = OpenAILike(model="qwen2.5vl:3b", is_chat_model=True, api_base=os.environ["OPENAI_BASE_URL"])
reply = llm.chat([message])
print(reply.raw.usage.prompt_tokens, "tokens in:", reply.message.content[:60])
```

O programa roda de dois jeitos. Com `openai`, usa a integração que leva o nome do provedor; sem, usa o `OpenAILike`, a integração para servidores que falam o formato da OpenAI:

```
ana@lab:~/mm$ python li_cover.py openai 2>&1 | tail -n 1 | cut -c1-120
ValueError: Unknown model 'lab-vision-1'. Please provide a valid OpenAI model name in: o1, o1-2024-12-17, o1-pro, o1-pro
ana@lab:~/mm$ python li_cover.py
default api_base: https://api.openai.com/v1
772 tokens in: A book cover on a dark navy background. At the top right is 
ana@lab:~/mm$ tail -n 1 /var/log/labmm/requests.jsonl | python -c "import json, sys; r = json.loads(sys.stdin.read()); print(r[\"images\"][0][\"sha256\"], r[\"images\"][0][\"tokens\"], r[\"rule\"])"
88a80dab896d 765 l08-cover-describe
```

**A primeira execução nunca enviou nada.** A classe `OpenAI` do LlamaIndex guarda uma tabela própria de nomes de modelo, para saber a janela de contexto de cada um, e recusa um nome que não conhece, aqui o `lab-vision-1`. Um modelo novo do provedor recebe a mesma recusa até o pacote ser atualizado, e esse é um dos jeitos de um framework envelhecer mais rápido que a API por baixo dele.

**A segunda execução imprimiu o endereço padrão antes de enviar qualquer coisa**: `https://api.openai.com/v1`. O `OpenAILike` não lê `OPENAI_BASE_URL`, a variável que o SDK da OpenAI e o LangChain leem neste laboratório. Deixado no padrão, teria mandado a capa e a chave do laboratório para a OpenAI. O programa passa `api_base` de forma explícita, e o pedido chegou ao labmm com a mesma imagem, os mesmos 765 tokens e a mesma regra dos dois do LangChain.

As duas lições são sobre configuração, não sobre imagens. **Um framework lê as próprias configurações**, das próprias variáveis, com os próprios padrões, e dois pacotes num mesmo programa podem discordar sobre para onde vão os pedidos. O hábito que pega isso é barato: imprimir o endereço, ou ver o primeiro pedido chegar onde você esperava.
