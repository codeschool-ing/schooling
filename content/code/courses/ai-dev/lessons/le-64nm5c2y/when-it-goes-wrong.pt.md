---
title: Quando o laço dá errado
version: 2
---

Um agente erra em duas direções. Para cedo demais, respondendo a partir do que adivinhou e não do que
as ferramentas devolveram; ou não para, pedindo a mesma coisa de novo ou explorando sem convergir. O
modelo não percebe nenhuma das duas, porque cada passo é uma decisão nova a partir de uma conversa que
parece em ordem. **O host tem de perceber**, com guardas que não dependem do juízo do modelo.

## Parar cedo demais

```
ana@dev:~/shop$ python agent.py "Which is the cheapest lamp you sell?"
Tool 'read_handbook' failed: "Error executing tool read_handbook: 'cheapest_lamp' is not a page of the handbook; the pages are: account, contact, coupons, payment-errors, products, returns, shipping, warranty"
[1] call:   read_handbook({"name": "cheapest_lamp"})
[1] result: Error executing tool read_handbook: 'cheapest_lamp' is not a page of the
[2] model:  It seems that the tool "read_handbook" is not able to provide information on the cheapest lamp. However, I can suggest some options to help you find a affordable lamp.

Our most basic lamp is the "Classic Table Lamp" which is priced at $19.99. It's a simple and functional lamp that can provide adequate lighting for a small space. Please note that prices may vary depending on the location and availability.

If you're looking for something even more affordable, you can consider our "String Lights" which are priced at $9.99. They're a great option for adding some ambiance to a room without breaking the bank.

Please let me know if you have any other questions or if there's anything else I can help you with.
host: 2 requests, 421 input tokens: [285, 136]
```

O modelo pediu uma página do manual chamada `cheapest_lamp`, que não existe, e a ferramenta disse isso
e listou as páginas que existem. Depois respondeu mesmo assim: uma "Classic Table Lamp" a $19.99 e
"String Lights" a $9.99. **A loja não vende nenhuma das duas**, nada nesta conversa menciona qualquer
uma, e os preços estão em dólares numa loja que cobra em reais. O manual não lista preços, então a
resposta certa era que as ferramentas não sabiam dizer. Outra rodada do mesmo comando, enquanto esta
aula era preparada, chamou-a de "Basic Table Lamp" pelos mesmos $19.99, que é como fatos inventados se
comportam: a forma fica e os detalhes mudam.

O host pode dizer ao modelo o que ele não sabe e qual é a regra. O `--rules` acrescenta o prompt de
sistema da aula 7 seção 03, a data de hoje e "todo fato tem de vir de um resultado de ferramenta":

```
ana@dev:~/shop$ python agent.py --rules "Which is the cheapest lamp you sell?"
Tool 'read_handbook' failed: "Error executing tool read_handbook: 'cheapest lamp' is not a page of the handbook; the pages are: account, contact, coupons, payment-errors, products, returns, shipping, warranty"
[1] call:   read_handbook({"name": "cheapest lamp"})
[1] result: Error executing tool read_handbook: 'cheapest lamp' is not a page of the
[2] model:  It seems that the tool "read_handbook" couldn't find the information on the cheapest lamp. I couldn't find the answer to your question in the handbook. Can I help you with something else?
host: 2 requests, 509 input tokens: [330, 179]
ana@dev:~/shop$ python agent.py --rules "Can the customer of order 1042 still return it?"
[1] call:   read_handbook({"name": "returns"})
[1] result: # Returns and refunds A customer may return any item within 30 days of d
[2] model:  The customer of order 1042 can still return it within 30 days of delivery. To start a return, the customer needs to open the order in their account and choose "Return an item". The shop will email a prepaid label within one working day. The refund will be processed once the item arrives at the warehouse and is checked, which takes up to five working days. Shipping costs will be refunded only when the whole order is returned.
host: 2 requests, 635 input tokens: [334, 301]
```

A pergunta da luminária agora termina onde devia: o modelo não achou. A de devolução lê a página de
devoluções desta vez, e dá a regra, 30 dias a partir da entrega, que é verdade. Mas nunca consulta o
pedido, então "can still return it" é uma conclusão sem data de entrega por trás; está certa por
acaso, nove dias depois da entrega, e diria o mesmo no dia quarenta. **Um prompt de sistema torna a
invenção mais rara; não torna uma resposta conferida.** A conferência ainda é uma pessoa, ou um
programa, comparando cada fato com um resultado de ferramenta.

## Não parar

A aula 7 seção 03 achou por que este modelo para tão cedo: depois de um resultado de ferramenta, o
template do Ollama para o `llama3.2:3b` não lhe mostra ferramenta nenhuma. O `--remind` acrescenta uma
frase do host depois de cada lote de resultados, *Call another tool if you need one; otherwise
answer.*, o que faz a última mensagem voltar a ser do usuário, e as ferramentas voltam a ser listadas:

```
ana@dev:~/shop$ python agent.py --remind "Which is the cheapest lamp you sell?"
Tool 'read_handbook' failed: "Error executing tool read_handbook: 'cheapest_lamp' is not a page of the handbook; the pages are: account, contact, coupons, payment-errors, products, returns, shipping, warranty"
[1] call:   read_handbook({"name": "cheapest_lamp"})
[1] result: Error executing tool read_handbook: 'cheapest_lamp' is not a page of the
[2] call:   read_handbook({"name": "products"})
[2] result: # Products The shop sells mugs, glasses, lamps and small furniture. Mugs
[3] call:   read_handbook({"name": "products"})
[3] host:   the same call twice in one task; stopping
host: 3 requests, 1193 input tokens: [285, 372, 536]
ana@dev:~/shop$ python agent.py --remind "Can the customer of order 1042 still return it?"
[1] call:   get_order({"order_id": "1042"})
[1] result: { "status": "delivered", "delivered_on": "2026-09-28", "lines": [ { "sku
[2] call:   issue_refund({"order_id": "1042", "cents": "0"})
allow issue_refund({"order_id": "1042", "cents": "0"})? [y/N] 
[2] result: refused by the operator
[3] call:   issue_refund({"order_id": "1042", "cents": "0"})
[3] host:   the same call twice in one task; stopping
host: 3 requests, 1147 input tokens: [289, 402, 456]
```

**Agora ele nunca responde.** Com as ferramentas na frente dele, a instrução do template, *respond with
a JSON for a function call*, vale em todo passo, então todo passo é uma chamada. A pergunta da
luminária lê a página de produtos, que não tem preços, e a pede de novo; a de devolução consulta o
pedido e depois pede, duas vezes, para reembolsá-lo, em `"0"` centavos, o que ninguém queria. **A
guarda de repetição encerra as duas no passo 3**, a aprovação já tinha recusado o reembolso uma vez, e
a última linha diz quanto cada uma custou: 1.193 e 1.147 tokens de entrada, cada requisição maior que
a anterior porque leva tudo até ali. Com as ferramentas à vista, a segunda requisição é a maior, como
devia ter sido desde o começo.

Nenhuma das duas opções faz deste modelo um agente que funciona neste servidor: sem o lembrete ele tem
uma rodada de ferramentas, com ele nunca para de chamá-las. Dois outros modelos mais ou menos deste
tamanho, `qwen2.5:3b` e `qwen2.5:7b`, receberam as mesmas perguntas enquanto esta aula era preparada;
os templates deles mantêm as ferramentas à vista, e os dois ainda responderam depois de uma chamada,
com a mesma conclusão errada sobre o pedido 1042. **As guardas do host são o que deixou cada uma
dessas falhas barata**, e são a parte desta aula que não depende do modelo. Um laço de cinco passos
sobre resultados de ferramenta de verdade, páginas de documentos ou linhas de dados, soma depressa.

## As guardas

- **Um limite de passos**, imposto pelo laço, com uma mensagem que diz que a tarefa não terminou.
  Escolha-o a partir da tarefa legítima mais longa, medida.
- **Uma checagem de repetição** na mesma ferramenta com os mesmos argumentos.
- **Um orçamento** em tokens ou dinheiro por tarefa, a guarda da aula 2 seção 09 aplicada ao laço
  inteiro e não a uma requisição.
- **Um limite de tempo**, para ferramentas que podem travar.
- **Um registro de todo passo**, para uma execução parada poder ser lida depois e o caso entrar numa
  avaliação (aula 5 seção 09) de tarefas que o agente deveria conseguir terminar.

A maioria dos agentes descontrolados em produção não é maliciosa nem está quebrada. É um modelo
fazendo a próxima coisa provável, corretamente, para sempre, sem nada no host para dizer pare.
