---
title: A string que o modelo realmente lê
version: 1
---

Uma API de chat recebe uma lista de mensagens, cada uma com um papel. A rede lá dentro não recebe
nada disso. Ela lê **uma única sequência de tokens**, e os papéis precisam ser escritos nessa
sequência de algum jeito. A convenção para escrevê-los é o **template de chat**, e cada família de
modelos tem o seu.

A Meta publica o da Llama 3.1 no mesmo documento. O `lab/template.py` segue o documento ao pé da
letra e monta o prompt de classificação da ana com o primeiro e-mail de `cases/triage.jsonl`:

```python
import json


def render(messages):
    """A conversation as Llama 3.1 reads it, from Meta's prompt_format.md."""
    out = "<|begin_of_text|>"
    for m in messages:
        out += f"<|start_header_id|>{m['role']}<|end_header_id|>\n\n{m['content']}<|eot_id|>"
    return out + "<|start_header_id|>assistant<|end_header_id|>\n\n"


case = json.loads(open("cases/triage.jsonl").readline())
print(render([{"role": "system", "content": open("prompts/triage.txt").read().strip()},
              {"role": "user", "content": case["text"]}]))
```

```
ana@desk:~/desk$ python lab/template.py
<|begin_of_text|><|start_header_id|>system<|end_header_id|>

You sort the e-mail of Lantern Books, an online bookshop.
Answer with exactly one label and nothing else:
order-status, refund, address-change, product-question, other.<|eot_id|><|start_header_id|>user<|end_header_id|>

Hi, I ordered two books on Monday (order LB-20417) and the tracking page still says 'preparing'. When will it ship?<|eot_id|><|start_header_id|>assistant<|end_header_id|>
```

Esse é todo o truque por trás de um chat. Cada vez na conversa fica cercada por tokens especiais que
dão nome ao papel, e a string **termina com o cabeçalho de uma vez do assistente que ainda não tem
conteúdo**. A única habilidade do modelo é continuar texto, então ele continua escrevendo a vez do
assistente, e o ajuste da seção 03 faz com que ele feche essa vez com `<|eot_id|>`.

## Por que saber disso quando uma API esconde

Por uma API você nunca vê essa string, e na maior parte do tempo tudo bem. Ela importa em três
lugares:

- **Rodar um modelo aberto por conta própria.** O template mora ao lado dos pesos, na
  configuração do tokenizador. Ferramentas como o Ollama (aula 14) aplicam por você; um script
  feito à mão que pula essa etapa manda texto puro para o modelo, e um modelo ajustado que não
  recebe marcadores de vez se comporta mais ou menos como um modelo base.
- **Levar um prompt de uma família para outra.** Dois modelos podem ler as mesmas mensagens por
  templates diferentes. Esse é um dos motivos de um prompt afinado para um modelo não servir
  automaticamente para outro, e de a aula 5 avaliar cada candidato nos mesmos casos em vez de
  confiar que o prompt se transfere.
- **O prompt de sistema não é mágico.** É texto na mesma sequência, sob um cabeçalho que diz
  `system`. O modelo foi treinado para dar peso a ele; nada garante esse peso.

**Os papéis são uma convenção que o modelo aprendeu**, escrita em tokens. Famílias diferentes
aprenderam convenções diferentes, e uma API poupa você de escrevê-las, não da existência delas.
