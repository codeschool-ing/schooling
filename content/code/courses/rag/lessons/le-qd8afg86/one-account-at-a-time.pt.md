---
title: Uma conta de cada vez
version: 2
---

Uma tabela de memória guarda as palavras de todos os clientes num lugar só, e a única coisa que impede
o assistente do Rafael de ler os turnos da Beatriz é um `WHERE account = %s` em cada consulta. Aqui
está a função de estado escrita uma vez sem ele, do jeito que poderia ser escrita com pressa, ou por um
teste que funcionava porque o banco só tinha um cliente:

```schooling-example
{
  "language": "python",
  "file": "careless.py",
  "parts": [
    {
      "code": "import sys\n\nfrom memory import ORDER\nfrom search import conn\n\n# memory.state, written without the account.\nsaid = \" \".join(t for (t,) in conn.execute(\"SELECT text FROM memories ORDER BY turn\"))\norders = list(dict.fromkeys(ORDER.findall(said)))\nprint(f\"The customer is {sys.argv[1]}. The customer's order number is {' and '.join(orders)}.\")",
      "note": "O `memory.state` escrito do jeito fácil de escrevê-lo: todo turno da tabela, seja de quem for."
    }
  ]
}
```
```
ana@vm:~/rag$ python careless.py "Rafael Lima"
The customer is Rafael Lima. The customer's order number is MG-31770254 and MG-20481937.
```

**O estado diz que o número do pedido do Rafael é MG-31770254 e MG-20481937**, e o segundo é o da
Beatriz. Nada falhou. A consulta devolveu linhas, a frase está bem formada, e ela vai em todo prompt da
conversa do Rafael como fonte [1]: o modelo citou o estado sem ninguém pedir no turno 10 da Beatriz, e
uma resposta que citasse este o referenciaria, e a verificação da aula 7 a aprovaria, porque o estado
diz exatamente isso. O único sintoma é um cliente lendo o número do pedido de um desconhecido, e numa
plataforma em que esse número abre uma página com um endereço, isso é um vazamento de dados pessoais.

Com a conta na consulta, a recuperação do próprio Rafael acha só os turnos dele:

```
ana@vm:~/rag$ python recalled.py chat-b A-1002 4
turn 4: Could you remind me of my order number?
   0.494  turn 1: Hello, this is Rafael Lima. My order MG-31770254 has not arrived.
   0.290  turn 3: I would prefer a refund rather than waiting for a new parcel.
```

## Tornando o filtro impossível de esquecer

Uma condição que toda consulta precisa lembrar é uma condição que alguma consulta vai esquecer. Três
hábitos a tiram da memória e a põem na estrutura:

- **A conta é parâmetro de toda função que lê memória**, nunca opcional e nunca com valor padrão, como
  em `recall(account, …)` e `state(account, …)`. Quem chama não consegue pedir memórias sem dizer de
  quem.
- **Um teste com dois clientes.** O vazamento acima é invisível com um cliente no banco e óbvio com
  dois, então o teste que importa carrega os dois e afirma que nenhum jamais vê o número de pedido do
  outro. É o mesmo teste que a aula 14 escreve para documentos.
- **O banco garante.** O Postgres pode associar uma política à tabela para que uma consulta veja só as
  linhas da conta para a qual a conexão foi aberta, diga o `WHERE` o que disser. A aula 14 constrói
  isso para documentos, e o mesmo mecanismo cobre esta tabela.

Um assistente que lembra é um assistente que pode lembrar da pessoa errada. É por isso que a memória é
construída por conta desde a primeira linha, e nunca filtrada depois.
