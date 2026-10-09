---
title: O que volta para o modelo
version: 2
---

A observação é o único jeito de o mundo chegar ao modelo, então o que uma ferramenta devolve molda todos os passos depois dela. Ela também viaja em todo pedido seguinte, o que faz do tamanho dela um custo pago de novo a cada passo.

Para medir esse tamanho nos tokens do próprio modelo, pergunte ao Ollama. Este programa curto manda um texto ao `llama3.2:3b` sem template de conversa em volta, deixa-o escrever um token e imprime quantos tokens o texto tinha. Salve-o como `~/agents/tokens.py`:

```python
"""tokens.py: how many tokens llama3.2:3b reads in the text on standard input, counted by Ollama."""
import json
import sys
import urllib.request


def count(text, model="llama3.2:3b"):
    body = {"model": model, "prompt": text, "raw": True, "stream": False, "options": {"num_predict": 1}}
    req = urllib.request.Request("http://127.0.0.1:11434/api/generate", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.load(r)["prompt_eval_count"]


if __name__ == "__main__":
    print(count(sys.stdin.read()))
```

Depois meça as três observações que esta aula encontrou: o pedido inteiro, os três campos de que uma pergunta de reembolso precisa, e o que o `search_help` devolve.

```
ana@lab:~/agents$ python -c "import json, shop; print(json.dumps(shop.get_order(\"M-1047\")))" | python tokens.py
105
ana@lab:~/agents$ python -c "import json, shop; o = shop.get_order(\"M-1047\"); print(json.dumps({k: o[k] for k in (\"status\", \"delivered_on\", \"total\")}))" | python tokens.py
28
ana@lab:~/agents$ python -c "import json, shop; print(json.dumps(shop.search_help(\"refund after a return\")))" | python tokens.py
230
```

O M-1047 inteiro, como o `get_order` o devolve, tem 105 tokens. Os três campos de que a pergunta de reembolso precisa (`status`, `delivered_on`, `total`) têm 28. Os três artigos de ajuda que o `search_help` devolve têm 230. Cada contagem inclui dois tokens que não são o JSON, o que o modelo põe no início de qualquer texto e a quebra de linha que o `print` deixa no fim, então as diferenças são exatas e cada total está dois acima. Numa execução de três passos, uma observação devolvida no passo 1 é mandada também nos passos 2 e 3, então cortá-la economiza os tokens dela duas vezes; numa execução de vinte passos, dezenove. **Devolva o que o modelo precisa para decidir o próximo passo, e nada que ele tenha de atravessar.**

Cortar também tem custo: um campo deixado de fora é um campo que o modelo não pode usar. O `customer_id` parece irrelevante para uma pergunta de reembolso, e é exatamente o que a aula 17 precisa para conferir que quem pergunta é dono do pedido. O meio-termo comum é uma ferramenta por finalidade (um resumo do pedido para o agente, o registro completo para o código que precisa dele) em vez de uma ferramenta que devolve tudo.

## Quatro regras para observações

- **Estruturadas, e rotuladas.** `{"status": "delivered", "delivered_on": "2026-09-18"}` é melhor que `delivered 2026-09-18`, porque o modelo não precisa adivinhar qual data é qual.
- **Unidades no nome do campo ou no valor.** O `get_order` devolve `"total": 7780` sem nada que diga que são centavos, e o modelo da seção 03 inventou um total de "120 centavos" antes de ter visto qualquer um. Um `total_cents` diria isso; uma ferramenta que devolve dinheiro sem unidade convida a um reembolso cem vezes maior.
- **Erros também são observações.** Uma consulta que falha deve voltar como uma mensagem curta e específica (*"no order M-9999"*) marcada como erro, para que o modelo corrija o id ou pergunte ao cliente. A aula 4 constrói isso, e é o que impede um erro de digitação de virar uma queda do programa.
- **Limitadas.** Uma busca que poderia devolver mil linhas devolve as primeiras e diz quantas eram. Uma observação que não cabe na janela de contexto encerra a execução, e uma que quase cabe não deixa espaço para a resposta.

## Observações não são instruções

Tudo o que uma ferramenta devolve é texto que o modelo lê, e parte dele foi escrita por pessoas que não são o usuário: um artigo de ajuda, uma resenha de produto, uma mensagem anterior de um cliente. **Um modelo pode confundir texto dentro de uma observação com uma instrução**, e é assim que funciona a injeção de prompt indireta (aula 7 do `prompt-engineering`). A aula 17 constrói a defesa no hospedeiro, que é onde ela fica; por ora, o hábito a formar é tratar uma observação como dado que chegou de fora, diga o que disser.
