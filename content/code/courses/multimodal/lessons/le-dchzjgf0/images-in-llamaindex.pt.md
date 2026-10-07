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
ValueError: Unknown model 'qwen2.5vl:3b'. Please provide a valid OpenAI model name in: o1, o1-2024-12-17, o1-pro, o1-pro
ana@lab:~/mm$ python li_cover.py
default api_base: https://api.openai.com/v1
1105 tokens in: The cover of the book "Dom Casmurro" by Machado de Assis fea
```

**A primeira execução nunca enviou nada.** A classe `OpenAI` do LlamaIndex guarda uma tabela própria de nomes de modelo, para saber a janela de contexto de cada um, e recusa um nome que não conhece, aqui o `qwen2.5vl:3b`. Um modelo novo do provedor recebe a mesma recusa até o pacote ser atualizado, e esse é um dos jeitos de um framework envelhecer mais rápido que a API por baixo dele.

**A segunda execução imprimiu o endereço padrão antes de enviar qualquer coisa**: `https://api.openai.com/v1`. O `OpenAILike` não lê `OPENAI_BASE_URL`, a variável que o SDK da OpenAI e o LangChain leem, e que a montagem da aula 1 apontou para o Ollama. Deixado no padrão, ele teria mandado a capa para a OpenAI, e com uma chave de verdade em `OPENAI_API_KEY` teria mandado a chave também. O programa passa `api_base` explicitamente, e o pedido chegou ao Ollama com a mesma imagem e os mesmos 1.105 tokens dos dois do LangChain.

As duas lições são sobre configuração, não sobre imagens. **Um framework lê as próprias configurações**, das próprias variáveis, com os próprios padrões, e dois pacotes num mesmo programa podem discordar sobre para onde vão os pedidos. O hábito que pega isso é barato: imprimir o endereço, ou ver o primeiro pedido chegar onde você esperava.
