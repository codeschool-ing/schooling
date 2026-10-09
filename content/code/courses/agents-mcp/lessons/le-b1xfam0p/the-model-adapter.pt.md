---
title: O modelo atrás de um método
version: 2
---

O laço precisa de quatro coisas de uma chamada ao modelo: o texto, as chamadas de ferramenta, por que parou e quantos tokens levou. Todo o resto sobre o fornecedor (o SDK, o formato do pedido, as classes de resposta) é detalhe que o laço não deveria conhecer. O `minagent` põe tudo isso atrás de um método.

```schooling-example
{
  "language": "python",
  "file": "minagent.py",
  "parts": [
    {
      "code": "# ---------------------------------------------------------------- the model, behind one method\n\n@dataclass\n"
    },
    {
      "code": "class Call:\n    id: str\n    name: str\n    args: dict\n\n\n@dataclass\n",
      "note": "**Uma chamada de ferramenta, neutra quanto ao fornecedor**: um id, um nome, os argumentos."
    },
    {
      "code": "class Reply:\n    text: str\n    calls: list\n    stop: str\n    tokens_in: int\n    tokens_out: int\n",
      "note": "**Tudo o que o laço lê de uma resposta.** Cinco campos, mais a resposta na forma em que ela volta para a conversa."
    },
    {
      "code": "    content: list  # the reply as it goes back into the conversation\n\n\n",
      "note": "**O único pedaço do protocolo que vaza.** A conversa é guardada no formato da Anthropic, então o adaptador devolve os blocos a anexar como estão."
    },
    {
      "code": "class AnthropicModel:\n    \"\"\"The one place that knows a provider's wire. Anything with complete() can stand in for it.\"\"\"\n\n",
      "note": "**A única classe que importa o SDK de um fornecedor.** Um adaptador para OpenAI ou Gemini seria outra classe com o mesmo método."
    },
    {
      "code": "    def __init__(self, model=\"llama3.2:3b\", max_tokens=1024, max_retries=2):\n        import anthropic\n        self.client = anthropic.Anthropic(max_retries=max_retries)\n        self.model, self.max_tokens = model, max_tokens\n\n",
      "note": "**O `max_retries` é passado direto ao SDK**; a seção 07 é sobre o que isso significa."
    },
    {
      "code": "    def complete(self, system, messages, tools):\n        r = self.client.messages.create(model=self.model, max_tokens=self.max_tokens, system=system,\n                                        tools=tools, messages=messages)\n        return Reply(text=\"\".join(b.text for b in r.content if b.type == \"text\"),\n                     calls=[Call(b.id, b.name, b.input) for b in r.content if b.type == \"tool_use\"],\n                     stop=r.stop_reason, tokens_out=r.usage.output_tokens,\n                     tokens_in=r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0),\n                     content=[b.model_dump(exclude_none=True) for b in r.content])\n\n",
      "note": "**Um pedido, traduzido num `Reply`.** Blocos de texto são juntados, blocos `tool_use` viram `Call`s."
    }
  ]
}
```

## Por que a costura vale uma classe

**Testes.** Qualquer coisa com um método `complete` que devolva um `Reply` pode tomar o lugar do modelo. O `FakeModel` do `test_minagent.py` são oito linhas que repetem respostas que o teste escreveu, e o laço não percebe a diferença. A seção 09 roda sete testes com ele em um vigésimo de segundo.

**Fornecedores.** Mudar para outro fornecedor quer dizer escrever outro adaptador: montar o pedido daquele fornecedor a partir de `system`, `messages` e `tools`, e preencher um `Reply` a partir da resposta dele. A seção 07 da aula 4 listou o que difere entre os três protocolos: o formato de uma definição de ferramenta, os argumentos chegando como objeto ou como string, o motivo de parada que diz ou não diz que uma ferramenta foi chamada. Tudo isso mora no adaptador e em mais lugar nenhum.

**Custo e roteamento.** Um segundo adaptador num modelo mais barato, escolhido por tarefa, é como a aula 18 corta custo sem tocar no laço.

A costura não é perfeitamente limpa: o formato da conversa dentro do `Agent.run` é o da Anthropic (blocos `tool_use` e `tool_result`), então um adaptador para a OpenAI traduziria a conversa na ida, além da resposta na volta. O Ollama faz essa tradução dentro dele, e é assim que um único modelo respondeu a três protocolos na aula 4; um adaptador de produção guardaria, em vez disso, um tipo de mensagem neutro próprio. O `minagent` mantém o da Anthropic para continuar curto, e diz isso aqui.
