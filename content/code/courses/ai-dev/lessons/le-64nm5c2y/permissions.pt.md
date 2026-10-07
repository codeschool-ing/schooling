---
title: Menor privilégio para um agente
version: 2
---

Um agente pode fazer o que as ferramentas dele podem fazer, e a escolha de ferramenta e de argumentos
de um modelo é a saída do laço da aula 1 seção 06: provável, não garantida. A aula 11 acrescenta um
caso pior, texto dentro de um resultado de ferramenta escrito para conduzir o modelo. **Então todo
limite é imposto abaixo do modelo, no host ou na ferramenta, onde as escolhas do modelo não
alcançam.**

## A ferramenta recusa o que não deve fazer

Um modelo que pede uma página do manual chamada `../../.env` está pedindo à ferramenta para ler um
arquivo fora do manual. A ferramenta não confia no argumento:

```
ana@dev:~/shop$ python scratch/tools.py read_handbook shipping
is_error: False | # Shipping

Orders ship within two working days from the warehouse in Campinas. Delivery
i
ana@dev:~/shop$ python scratch/tools.py read_handbook ../../.env
Tool 'read_handbook' failed: "Error executing tool read_handbook: '../../.env' is not a page of the handbook; the pages are: account, contact, coupons, payment-errors, products, returns, shipping, warranty"
is_error: True | Error executing tool read_handbook: '../../.env' is not a page of the handbook; the pages 
```

A primeira chamada lê a página. A segunda é recusada pela ferramenta, com uma mensagem sobre a qual o
modelo pode agir, e o servidor a registra na própria saída de erro, a primeira linha. **A checagem é
sobre aonde o argumento leva**, não sobre a cara dele: o `resolve()` transforma `../../.env` num
caminho real, e o caminho é comparado com a pasta do manual.

## Uma pessoa aprova o que muda as coisas

O `issue_refund` é a única ferramenta que não é só leitura, então o host pergunta antes de chamá-la.
Aqui o operador diz não:

```
ana@dev:~/shop$ echo n | python agent.py "Refund order 1042, the customer changed their mind."
[1] call:   issue_refund({"cents": "0", "order_id": "1042"})
allow issue_refund({"cents": "0", "order_id": "1042"})? [y/N] n
[1] result: refused by the operator
[2] model:  Unfortunately, the refund for order 1042 has been refused by the operator. Can I assist you with anything else?
host: 2 requests, 398 input tokens: [290, 108]
ana@dev:~/shop$ cat data/refunds.log
cat: data/refunds.log: No such file or directory
```

O host devolveu *refused by the operator* ao modelo como um resultado de erro, o modelo informou
isso, e o registro de reembolsos não existe: **nada foi pago.** O mesmo pedido com um sim:

```
ana@dev:~/shop$ echo y | python agent.py "Refund order 1042, the customer changed their mind."
[1] call:   issue_refund({"cents": "0", "order_id": "1042"})
allow issue_refund({"cents": "0", "order_id": "1042"})? [y/N] y
[1] result: refunded 0 cents on order 1042
[2] model:  Refund of 0 cents has been processed for order 1042.
host: 2 requests, 403 input tokens: [290, 113]
ana@dev:~/shop$ cat data/refunds.log
1042 0
```

**Um reembolso de zero, aprovado, pago e registrado.** O modelo pediu `"cents": "0"`, uma string,
para um pedido de 79,80 em canecas. O esquema do servidor diz que `cents` é um inteiro e transformou
`"0"` em `0` sem dizer nada, a ferramenta não tem regra contra reembolsar nada, e o operador respondeu
`y` a uma pergunta que mostrava o zero à vista. Cada camada fez o que foi construída para fazer, e
nenhuma foi construída para recusar isto.

Esse é o argumento para a aprovação mostrar os argumentos exatos, e para lê-los: uma pessoa que aprova
"um reembolso" não está aprovando "um reembolso de 0 centavos no pedido 1042". E é o argumento para a
segunda regra abaixo. O `issue_refund` deveria recusar um valor abaixo de um centavo ou acima do que o
pedido custou, quem quer que tenha pedido e quem quer que tenha aprovado, porque a ferramenta é o único
lugar por onde toda chamada passa.

## As regras

- **Só leitura por padrão.** Dê a um agente ferramentas que só leem até ele ter motivo para mudar
  algo, e então uma ferramenta estreita para essa mudança.
- **Confira os argumentos na ferramenta.** Caminhos, valores, ids que precisam ser do cliente atual. O
  esquema confere tipos; a ferramenta confere sentido.
- **Pergunte a uma pessoa antes de tudo o que custa dinheiro, manda uma mensagem, apaga ou publica**,
  e mostre os argumentos, não um resumo.
- **Rode o agente com o menor acesso que funciona**: credenciais próprias, restritas ao que as
  ferramentas dele precisam, nunca as do próprio dev.
- **Registre toda chamada e todo resultado**, com quem aprovou o quê. Quando um agente faz algo
  surpreendente, o registro é o único relato do porquê.
