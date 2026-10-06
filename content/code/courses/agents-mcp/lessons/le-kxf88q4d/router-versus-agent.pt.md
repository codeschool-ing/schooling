---
title: As mesmas três mensagens, um roteador e um agente
version: 1
---

Aqui está um workflow de roteamento para as mensagens da Marginalia. Uma chamada de modelo lê a mensagem e devolve uma palavra; o código faz o resto. **Os rótulos que ele devolve foram escritos pelo curso**, como regras para o modelo substituto do laboratório; o código, as consultas e as contagens são reais.

```schooling-example
{
  "language": "python",
  "file": "router.py",
  "parts": [
    {
      "code": "\"\"\"A workflow with routing: the model picks a branch once, and the code does the rest.\"\"\"\nimport re\nimport sys\n\nimport anthropic\n\nimport shop\n\n"
    },
    {
      "code": "client = anthropic.Anthropic()\nmessage = sys.argv[1]\nlabel = client.messages.create(\n    model=\"scripted-1\",\n    max_tokens=5,\n    system=\"Classify the customer's message with one word: order, policy or other.\",\n    messages=[{\"role\": \"user\", \"content\": message}],\n).content[0].text.strip()\n\n",
      "note": "**Um pedido, no máximo cinco tokens de saída.** O trabalho inteiro do modelo é escolher uma de três palavras."
    },
    {
      "code": "if label == \"order\":\n    order = shop.get_order(re.search(r\"M-\\d{4}\", message).group())\n    print(f\"[order] {order['id']} is {order['status']}\"\n          + (f\", delivered on {order['delivered_on']}\" if order[\"delivered_on\"] else \"\"))\n",
      "note": "**Todo ramo é código.** O id do pedido é achado com uma expressão regular, não pelo modelo; a resposta é um modelo de texto."
    },
    {
      "code": "elif label == \"policy\":\n    best = shop.search_help(message, k=1)[0]\n    print(f\"[policy] {best['title']}: {best['body']}\")\n",
      "note": "**O ramo de política busca na central de ajuda** e imprime o melhor artigo como ele está."
    },
    {
      "code": "else:\n    print(\"[other] passed to a person\")",
      "note": "**Qualquer outra coisa vai para uma pessoa**, uma decisão que o programador tomou de antemão."
    }
  ]
}
```

O `tally.py` lê o log do labllm e soma o que as execuções custaram. O log foi esvaziado antes de cada lote:

```python
"""What the runs since the log was emptied cost: requests, tokens and model time."""
import json

rows = [json.loads(line) for line in open("/var/log/labllm/requests.jsonl")]
tokens_in = sum(r["usage"]["input_tokens"] for r in rows)
tokens_out = sum(r["usage"]["output_tokens"] for r in rows)
seconds = sum(r["ms"] for r in rows) / 1000
print(f"requests {len(rows)}   input tokens {tokens_in}   output tokens {tokens_out}   model time {seconds:.1f} s")
```

O roteador, nas três mensagens da aula 1 e em mais uma:

```
ana@lab:~/agents$ python router.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[order] M-1042 is delivered, delivered on 2026-09-24
ana@lab:~/agents$ python router.py "My order M-1043 has not arrived yet. Where is it?"
[order] M-1043 is shipped
ana@lab:~/agents$ python router.py "Which ways can I pay?"
[policy] Payment methods we accept: We accept Visa, Mastercard and American Express, PayPal, Pix and Marginalia gift cards. A card payment can be split into up to three instalments with no interest on orders over 120. We do not accept cash on delivery.
ana@lab:~/agents$ python router.py "The courier was rude to me at the door yesterday."
[other] passed to a person
ana@lab:~/agents$ python tally.py
requests 4   input tokens 130   output tokens 4   model time 1.0 s
```

E o agente da aula 1, sem mudança, nas mesmas três:

```
ana@lab:~/agents$ python agent.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[1] get_order({"order_id": "M-1042"})
[2] search_help({"query": "return a book"})
[3] answer: Yes, Bia. Order M-1042 was delivered on 24 September 2026, and printed books can be returned within 30 days of delivery, so you have until 24 October. Start the return from the order in your account, print the prepaid label and drop the parcel at any post office. Returns are free.
ana@lab:~/agents$ python agent.py "My order M-1043 has not arrived yet. Where is it?"
[1] get_order({"order_id": "M-1043"})
[2] search_help({"query": "tracking a parcel"})
[3] answer: Order M-1043 is on its way: it has shipped and has not been delivered yet. The carrier's tracking code is BR5512340003, and the tracking link in your shipping email updates at each step of the journey.
ana@lab:~/agents$ python agent.py "Which ways can I pay?"
[1] search_help({"query": "payment methods"})
[2] answer: We accept Visa, Mastercard and American Express, PayPal, Pix and Marginalia gift cards. A card payment can be split into up to three instalments with no interest on orders over 120. We do not accept cash on delivery.
ana@lab:~/agents$ python tally.py
requests 8   input tokens 2551   output tokens 208   model time 9.9 s
```

## Lendo as duas contagens

| | roteador, 4 mensagens | agente, 3 mensagens |
|---|---|---|
| pedidos ao modelo | 4 | 8 |
| tokens de entrada | 130 | 2551 |
| tokens de saída | 4 | 208 |
| tempo de modelo | 1,0 s | 9,9 s |

O tempo de modelo é a regra do labllm, 200 ms antes do primeiro token e 40 ms por token depois dele, então a razão é do laboratório e não de um fornecedor. O que vale para qualquer fornecedor é a forma: **o roteador mandou um pedido curto por mensagem, enquanto o agente mandou dois ou três pedidos crescentes**, e escreveu as respostas token a token.

Agora leia as respostas, porque os números são só metade da história. Para o M-1043 e a pergunta de pagamento, a saída do roteador é tão útil quanto a do agente. Para a Bia ele imprimiu `M-1042 is delivered, delivered on 2026-09-24`, o que é verdade e não responde à pergunta da mensagem, se o livro ainda pode voltar. **O roteador não tem ramo para "uma pergunta de devolução sobre um pedido específico"**, então respondeu a metade para a qual tinha ramo. O agente juntou o pedido e o artigo de devolução porque escolheu consultar os dois.

Essa é a troca, medida. Uma equipe que quer que o roteador responda à Bia escreve mais um ramo: consultar o pedido, calcular a janela, imprimi-la. Custa uma tarde e nenhum pedido a mais. Uma equipe que vive encontrando mensagens que nenhum ramo cobre tem a evidência que a primeira pergunta da seção 03 pede, e a reclamação do entregador mandada a uma pessoa é a cara dessa evidência quando ela é coletada em vez de adivinhada.
