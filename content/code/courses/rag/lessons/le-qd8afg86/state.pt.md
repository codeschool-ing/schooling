---
title: Um estado que o programa escreve
version: 2
---

O turno 12 pediu o número do pedido. O histórico inteiro respondeu, mandando o turno 1 de novo com
todo turno seguinte, a 1.201 tokens por essa pergunta; a recuperação deixou o turno 1 de fora com
0,491, e nenhum documento o tem. O número do pedido não é algo a buscar. **É um fato que a aplicação
já sabe**, e o jeito de dá-lo ao modelo é escrevê-lo.

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def state(account, name):\n    \"\"\"What the program knows for certain, written as sentences a reply to the customer can quote.\"\"\"\n    said = \" \".join(t for (t,) in conn.execute(\"SELECT text FROM memories WHERE account = %s ORDER BY turn\",\n                                               (account,)))\n    orders = list(dict.fromkeys(ORDER.findall(said)))\n    lines = [f\"The customer is {name}.\"]\n    if orders:\n        lines.append(f\"The customer's order number is {' and '.join(orders)}.\")\n    return \" \".join(lines)",
      "note": "Só o que o programa pode garantir: o nome, da conta, e os números de pedido achados nas palavras do próprio cliente pelo padrão exato. Cada fato é escrito como uma frase sobre o cliente, para que uma resposta possa citá-la e referenciá-la."
    }
  ]
}
```

```
ana@vm:~/rag$ python -c "import memory; print(memory.state(\"A-1001\", \"Beatriz Costa\"))"
The customer is Beatriz Costa. The customer's order number is MG-20481937.
```

O estado são duas frases, e cada uma vem de um lugar certo. O nome vem da conta que está logada, que
neste curso é um dicionário no `chat.py` no lugar da tabela de contas da loja. O número do
pedido é achado nas palavras do próprio cliente pelo formato exato, `MG-` e oito dígitos, que uma
expressão regular reconhece sem adivinhar. Nada ali é interpretação de um modelo, então nada ali pode
ser erro de um modelo.

O `chat.py` manda o estado como fonte [1], antes dos documentos, para que uma resposta possa citá-lo e
referenciá-lo como qualquer fonte:

```schooling-example
{
  "language": "python",
  "parts": [
    {
      "code": "def remembered(text, past, account, name):\n    \"\"\"The earlier turns most like this one, if they are like it at all, put in front of it to make\n    a search that stands on its own; the state as a source; and the documents that search finds. The customer's own words steer\n    the search and are never sources to cite; the model is asked what the customer asked.\"\"\"\n    recalled = [r for r in memory.recall(account, text, RECALL) if r[2] >= LIKE]\n    search = \" \".join([t for _, t, _ in recalled] + [text])\n    state = {\"path\": \"what we know about this customer\", \"text\": memory.state(account, name)}\n    return ask([state] + sources_for(search), text)",
      "note": "O turno recuperado, se passar do `LIKE`, vai na frente da pergunta só para a busca. O modelo recebe o estado como fonte [1], os documentos depois dele, e a pergunta do cliente como ele a fez."
    }
  ]
}
```

```
ana@vm:~/rag$ python chat.py chat-b memory
 1   132 tokens
 2   306 tokens
 3   312 tokens
 4   135 tokens  Could you remind me of my order number?
   no document above the floor
   I could not find that in our documents.
885 prompt tokens over 4 turns
```

A conversa de Rafael Lima, a segunda em `data/`, pergunta a mesma coisa no quarto turno, e **a
resposta é a recusa, com a resposta certa como fonte [1]**. O turno 12 da Beatriz, na próxima seção, é
recusado do mesmo jeito. O modelo lê o estado: naquela seção, a resposta dele ao turno 10 cita o número
do pedido tirado dali, sem ninguém pedir. O que ele não faz é responder a uma pergunta a partir do
estado. A instrução da aula 7 manda recusar quando as fontes não respondem, e o llama3.2:3b decidiu
que uma linha sobre o cliente não é um dos *our documents*.

Então o estado, como fonte, funciona pela metade com este modelo: informa as respostas e não responde
a pergunta para a qual foi escrito. **Um fato que o programa sabe com certeza é o programa que deve
dizê-lo**, e passá-lo pelo modelo dá ao modelo a chance de recusá-lo. Uma página da conta que mostra o
número do pedido, ou uma resposta que o próprio programa escreve quando a pergunta é sobre a conta, não
pode ser recusada por uma instrução escrita para políticas. O estado continua servindo para tudo o mais
que o modelo escreve: uma resposta que sabe com quem fala e de que pedido o chat trata.

## O que cabe num estado

Um estado é para o que o programa **sabe**: a conta, o pedido de que o chat trata, o que o cliente
escolheu num formulário, o que uma ferramenta devolveu. É um mau lugar para o que um modelo
**inferiu**, como "o cliente prefere e-mail", porque uma inferência escrita como fato é citada como
fato. A Beatriz disse, sim, "Please write to me by email only", e um sistema de atendimento ia querer
lembrar disso; o lugar disso é a preferência de contato da conta, definida por uma pessoa ou
confirmada pelo cliente, e de lá o estado pode lê-la como certa.
