---
title: As mesmas três mensagens, um roteador e um agente
version: 2
---

Aqui está um workflow de roteamento para as mensagens da Marginalia. Uma chamada de modelo lê a mensagem e devolve uma palavra; o código faz o resto. Dois detalhes dele vêm do encontro com o `llama3.2:3b`: a instrução diz *exatamente* uma palavra, porque, pedido "uma palavra", ele às vezes começava uma frase, e o código tira um ponto final e passa para minúsculas antes de comparar, porque um rótulo continua sendo texto. Ele também poria `temperature` em zero, para o rótulo mais estável, mas a versão da biblioteca `anthropic` fixada na aula 1 não aceita mais esse argumento.

```schooling-example
{
  "language": "python",
  "file": "router.py",
  "parts": [
    {
      "code": "\"\"\"A workflow with routing: the model picks a branch once, and the code does the rest.\"\"\"\nimport re\nimport sys\n\nimport anthropic\n\nimport shop\n\n"
    },
    {
      "code": "client = anthropic.Anthropic()\nmessage = sys.argv[1]\nlabel = client.messages.create(\n    model=\"llama3.2:3b\",\n    max_tokens=5,\n    system=\"Classify the customer's message. Answer with exactly one word: order, policy or other.\",\n    messages=[{\"role\": \"user\", \"content\": message}],\n).content[0].text.strip().strip(\".\").lower()\n\n",
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

O `tally.py` lê o `requests.jsonl` do gravador da aula 1 e soma o que as execuções custaram. Com o gravador iniciado e o `ANTHROPIC_BASE_URL` exportado para apontar para ele, todo programa deste terminal passa por ele; `rm requests.jsonl` começa uma contagem nova.

```python
"""What the runs since requests.jsonl was emptied cost: requests, tokens and model time."""
import json

rows = [json.loads(line) for line in open("requests.jsonl")]
tokens_in = sum(r["usage"]["input_tokens"] for r in rows)
tokens_out = sum(r["usage"]["output_tokens"] for r in rows)
seconds = sum(r["ms"] for r in rows) / 1000
print(f"requests {len(rows)}   input tokens {tokens_in}   output tokens {tokens_out}   model time {seconds:.1f} s")
```

O roteador, nas três mensagens da aula 1 e em mais uma:

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ export ANTHROPIC_BASE_URL=http://127.0.0.1:11435
ana@lab:~/agents$ python router.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[order] M-1042 is delivered, delivered on 2026-09-24
ana@lab:~/agents$ python router.py "My order M-1043 has not arrived yet. Where is it?"
[order] M-1043 is shipped
ana@lab:~/agents$ python router.py "Which ways can I pay?"
[other] passed to a person
ana@lab:~/agents$ python router.py "The courier was rude to me at the door yesterday."
[other] passed to a person
ana@lab:~/agents$ python tally.py
requests 4   input tokens 234   output tokens 8   model time 2.0 s
```

E o agente da aula 1, sem mudança, nas mesmas três:

```
ana@lab:~/agents$ rm requests.jsonl
ana@lab:~/agents$ python agent.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[1] get_order({"order_id": "M-1042"})
[2] answer: Unfortunately, since your order was delivered on September 24th, you will no longer be able to return it. According to our return policy, items that have been delivered to the customer cannot be returned. However, I can help you with any other concerns or issues you may have with your order.
ana@lab:~/agents$ python agent.py "My order M-1043 has not arrived yet. Where is it?"
[1] search_help({"query": "M-1043"})
[2] answer: It's possible that the tracking information for your order M-1043 is not yet available, as it can take 12 hours for the carrier to scan the parcel after it leaves the warehouse. You can check the tracking link provided by the carrier to see if there are any updates. If you haven't received an update after 12 hours, you can try contacting our customer service team to assist you further. We can also help you check if the parcel has been delivered to your neighbors or around the building, as it's common for carriers to leave parcels in a safe place. If the parcel still hasn't arrived after 48 hours, we can open a claim with the carrier and send a replacement or a refund, whichever you prefer.
ana@lab:~/agents$ python agent.py "Which ways can I pay?"
[1] search_help({"query": "ways to pay"})
[2] answer: We accept the following payment methods: 

* Visa
* Mastercard
* American Express
* PayPal
* Pix
* Marginalia gift cards

Please note that we do not accept cash on delivery.
ana@lab:~/agents$ python tally.py
requests 6   input tokens 1641   output tokens 302   model time 37.4 s
```

## Lendo as duas contagens

| | roteador, 4 mensagens | agente, 3 mensagens |
|---|---|---|
| pedidos ao modelo | 4 | 6 |
| tokens de entrada | 234 | 1641 |
| tokens de saída | 8 | 302 |
| tempo de modelo | 2,0 s | 37,4 s |

É um modelo pequeno em quatro processadores e sem chip gráfico, então os segundos são desta máquina e não de um fornecedor; uma API paga responde mais rápido, e a sua máquina talvez também. O que vale para qualquer modelo é o formato: **o roteador mandou um pedido curto por mensagem e leu dois tokens de volta, enquanto o agente mandou dois pedidos crescentes por mensagem** e escreveu as respostas token a token. Nesta máquina a diferença é dezoito vezes a espera.

Agora leia as respostas, porque os números são só metade da história. O roteador respondeu ao M-1043 com o status do pedido, que é a metade útil de uma resposta. Para a Bia ele imprimiu `M-1042 is delivered, delivered on 2026-09-24`, que é verdade e não responde à pergunta da mensagem, se o livro ainda pode voltar: **o roteador não tem ramo para "uma pergunta de devolução sobre um pedido específico"**, então respondeu a metade para a qual tinha ramo. E mandou a pergunta de pagamento para uma pessoa, porque o modelo a rotulou como `other`. É um rótulo errado, mas falhou do lado seguro: uma pessoa recebe a mensagem, e ninguém ouviu nada falso.

As falhas do agente são de outro tipo. Ele disse à Bia que livro entregue não pode ser devolvido, o que é falso e foi dito direto à cliente. Para o M-1043 ele buscou o id do pedido na central de ajuda em vez de consultar o pedido, e respondeu com um artigo genérico sobre rastreio. Acertou a pergunta de pagamento. **Os erros do roteador terminaram numa pessoa; os do agente, na cliente.**

Essa é a troca, medida. Uma equipe que quer que o roteador responda à Bia escreve mais um ramo: consultar o pedido, calcular a janela, imprimi-la. Custa uma tarde e nenhum pedido a mais, e a resposta sai certa toda vez. Uma equipe que vive encontrando mensagens que nenhum ramo cobre tem a evidência que a primeira pergunta da seção 03 pede, e a reclamação do entregador encaminhada a uma pessoa é a cara dessa evidência quando ela é coletada em vez de adivinhada.
