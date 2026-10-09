---
title: Cache de prompt
version: 2
---

Os caches até aqui pulam o modelo. O **cache de prompt** mantém o modelo e torna parte do prompt
mais barata: o provedor guarda a forma processada de um prefixo longo que se repete entre
requisições, e uma requisição que começa com o mesmo prefixo paga menos por ele e começa mais
rápido. A API da OpenAI faz isso automaticamente para prompts longos; a da Anthropic deixa a
requisição marcar onde termina o prefixo que pode ir para o cache, com `cache_control`. O Ollama faz
uma coisa mais simples: guarda na memória o começo processado do último prompt, reaproveita-o quando
o prompt seguinte começa do mesmo jeito, e informa a parte reaproveitada como
`cache_read_input_tokens` pelo endpoint compatível com a Anthropic, que é como a aula 9 a viu.

As instruções da aula 7 têm 71 tokens, muito abaixo de qualquer mínimo, então este pipeline não ganha
nada com isso. O caso em que ajuda é um **prefixo longo e fixo**, e um comum é um conjunto de documentos
que o assistente sempre tem, as políticas centrais, mandadas antes de toda pergunta:

```schooling-example
{
  "language": "python",
  "file": "cached_prompt.py",
  "parts": [
    {
      "code": "import anthropic\nfrom chunking import load\n\ndocs = load()\nstanding = \"\\n\".join(f'<source id=\"{key}\">{body}</source>' for key, (meta, body) in docs.items()\n                     if key in (\"returns-policy\", \"shipping-and-delivery\", \"terms-of-sale\"))\nclient = anthropic.Anthropic()\nfor question in (\"How much is express delivery?\", \"How many days do I have to return a printed book?\"):\n    message = client.messages.create(\n        model=\"llama3.2:3b\", max_tokens=200,\n        system=[{\"type\": \"text\", \"text\": \"Answer Marginalia's customers from these documents.\\n\\n\" + standing,\n                 \"cache_control\": {\"type\": \"ephemeral\"}}],\n        messages=[{\"role\": \"user\", \"content\": question}])\n    u = message.usage\n    print(f\"{question}\\n  input {u.input_tokens}, written to cache {u.cache_creation_input_tokens}, \"\n          f\"read from cache {u.cache_read_input_tokens}, output {u.output_tokens}\")",
      "note": "Três documentos mandados à frente de toda pergunta como um prompt de sistema fixo, marcados como cacheáveis do jeito que a API da Anthropic pede, e o que o uso diz que foi lido do cache."
    }
  ]
}
```
```
ana@vm:~/rag$ python cached_prompt.py
How much is express delivery?
  input 2711, written to cache None, read from cache 15, output 20
How many days do I have to return a printed book?
  input 16, written to cache None, read from cache 2716, output 62
```

**2.716 tokens lidos do cache na segunda chamada**, e só 16 contados como entrada nova: os três
documentos vieram do cache e a pergunta nova não. A primeira chamada leu 15, o começo da mensagem de
sistema, deixado por uma requisição anterior. Nada foi gravado no cache segundo a resposta, `None`,
porque o Ollama mantém o cache sem que se peça e não cobra nada por ele; a marca `cache_control` foi
aceita e não mudou nada. Com um provedor que cobra, a leitura do cache custa uma fração do preço normal
de entrada e a gravação um acréscimo, então a economia começa na segunda requisição dentro da vida do
cache; confira a tabela de preços atual do provedor e o prefixo mínimo dele antes de contar com a
proporção.

Três condições decidem se ele se aplica:

- **O prefixo precisa ser idêntico**, byte a byte, desde o começo. As fontes da aula 12 mudam a cada
  pergunta, então não podem fazer parte dele; só o que vem antes delas pode.
- **Ele precisa ser longo o bastante**, acima do mínimo do provedor.
- **Ele precisa ser reusado dentro da vida dele**, o que um assistente movimentado faz e um quieto não.

O cache de prompt também muda o argumento de desenho da aula 1. Mandar um acervo pequeno e fixo inteiro a
cada chamada fica mais barato quando o acervo está em cache, e para um punhado de documentos que nunca
mudam pode ser mais simples que a recuperação. Ainda é limitado pela janela, ainda paga a distração que a
aula 12 descreveu, e ainda precisa das permissões da aula 14, que um prefixo compartilhado por todos não
consegue expressar.
